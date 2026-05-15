//
//  ShareViewController.swift
//  MyVoyageShareExtension
//
//  Accepts PDF booking confirmations shared from Mail.app, Files, Safari,
//  drops them into the App-Group "BookingInbox", and asks the host app
//  to take over via `myvoyage://import?name=<filename>`.
//

import UIKit
import UniformTypeIdentifiers

private let appGroupID = "group.hoepker-consult.MyVoyage"
private let inboxFolderName = "BookingInbox"

@objc(ShareViewController)
final class ShareViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear
        Task { await handleAttachments() }
    }

    private func handleAttachments() async {
        guard let items = extensionContext?.inputItems as? [NSExtensionItem] else {
            return finish(success: false, errorMessage: "Keine Inhalte gefunden.")
        }

        var inboxURL: URL? = FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: appGroupID)?
            .appendingPathComponent(inboxFolderName, isDirectory: true)
        if let url = inboxURL {
            try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        }
        guard let inbox = inboxURL else {
            return finish(success: false, errorMessage: "App-Group nicht erreichbar.")
        }

        var savedFilename: String?
        outer: for item in items {
            for provider in item.attachments ?? [] {
                if let url = await loadPDF(from: provider, into: inbox) {
                    savedFilename = url.lastPathComponent
                    break outer
                }
            }
        }

        guard let name = savedFilename else {
            return finish(success: false, errorMessage: "Keine PDF-Datei gefunden.")
        }

        await MainActor.run {
            openHostApp(filename: name)
        }
    }

    /// Asks the provider for a PDF representation. Copies the data into the
    /// shared inbox with a unique filename. Returns the saved URL on success.
    private func loadPDF(from provider: NSItemProvider, into inbox: URL) async -> URL? {
        let pdfType = UTType.pdf.identifier
        let supportedTypes = [pdfType, "com.adobe.pdf", "public.file-url"]
        guard let type = supportedTypes.first(where: { provider.hasItemConformingToTypeIdentifier($0) }) else {
            return nil
        }

        return await withCheckedContinuation { cont in
            provider.loadItem(forTypeIdentifier: type, options: nil) { coding, error in
                guard error == nil, let coding else {
                    cont.resume(returning: nil); return
                }

                let sourceData: Data?
                let sourceName: String

                if let url = coding as? URL, url.isFileURL {
                    sourceData = try? Data(contentsOf: url)
                    sourceName = url.lastPathComponent
                } else if let data = coding as? Data {
                    sourceData = data
                    sourceName = "Buchung-\(Int(Date().timeIntervalSince1970)).pdf"
                } else {
                    sourceData = nil
                    sourceName = ""
                }

                guard let data = sourceData else {
                    cont.resume(returning: nil); return
                }

                let safeName: String = {
                    if sourceName.lowercased().hasSuffix(".pdf") { return sourceName }
                    return "\(sourceName).pdf"
                }()
                let dst = inbox.appendingPathComponent(
                    "\(Int(Date().timeIntervalSince1970))-\(safeName)"
                )
                do {
                    try data.write(to: dst, options: .atomic)
                    cont.resume(returning: dst)
                } catch {
                    cont.resume(returning: nil)
                }
            }
        }
    }

    private func openHostApp(filename: String) {
        let escaped = filename
            .addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? filename
        guard let url = URL(string: "myvoyage://import?name=\(escaped)") else {
            return finish(success: false, errorMessage: "URL konnte nicht erzeugt werden.")
        }

        // UIApplication.shared is not directly accessible from an app extension;
        // walk the responder chain to find a UIApplication that exposes `open`.
        var responder: UIResponder? = self
        while let r = responder {
            if let app = r as? UIApplication {
                app.open(url, options: [:]) { [weak self] _ in
                    self?.finish(success: true)
                }
                return
            }
            responder = responder?.next
        }
        // Fallback: just finish — the file is already in the inbox and the
        // main app's foreground sweep will pick it up next time it opens.
        finish(success: true)
    }

    private func finish(success: Bool, errorMessage: String? = nil) {
        if let msg = errorMessage {
            print("MyVoyage Share Extension: \(msg)")
        }
        Task { @MainActor in
            extensionContext?.completeRequest(returningItems: nil)
        }
    }
}
