//
//  CloudSync.swift
//  MyVoyage
//
//  iCloud Ubiquity + App-Group plumbing + global app settings.
//

import Foundation
import Observation

enum CloudConfig {
    static let appGroupID = "group.hoepker-consult.MyVoyage"
    static let iCloudContainerID = "iCloud.hoepker-consult.MyVoyage"
    static let tripsFileName = "trips.json"
    static let settingsFileName = "settings.json"
    static let inboxFolderName = "BookingInbox"
}

enum CloudSync {
    /// `true` if the user is signed into iCloud on this device.
    static var isAccountAvailable: Bool {
        FileManager.default.ubiquityIdentityToken != nil
    }

    /// Container root (`Library/Mobile Documents/iCloud~...`). Triggers a
    /// metadata-only round-trip the first time so the OS sets the container up.
    static var containerURL: URL? {
        FileManager.default.url(forUbiquityContainerIdentifier: CloudConfig.iCloudContainerID)
    }

    /// `…/Documents` inside the container. This is where user-visible files
    /// (`trips.json`) live so they show up in Files.app under iCloud Drive.
    static var documentsURL: URL? {
        guard let container = containerURL else { return nil }
        let docs = container.appendingPathComponent("Documents", isDirectory: true)
        try? FileManager.default.createDirectory(at: docs, withIntermediateDirectories: true)
        return docs
    }

    /// Shared container reachable from the main app and the Share Extension.
    static var appGroupURL: URL? {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: CloudConfig.appGroupID)
    }

    /// Folder where the Share Extension drops incoming PDF booking
    /// confirmations. The main app picks them up via `BookingInbox`.
    static var inboxURL: URL {
        let base = appGroupURL
            ?? FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let url = base.appendingPathComponent(CloudConfig.inboxFolderName, isDirectory: true)
        try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }
}

// MARK: - App Settings

/// User-tunable preferences. Persisted to disk as JSON (mirrored to the
/// Ubiquity container when iCloud sync is enabled so the same email profile
/// shows up on every device). Cheap to read/write; we do not bother with
/// `NSUbiquitousKeyValueStore` to keep one persistence story.
@Observable
final class AppSettings: Codable {
    static let shared: AppSettings = AppSettings.load() ?? AppSettings()

    // Profile
    var userDisplayName: String = ""
    var userEmail: String = ""

    // Booking import
    /// Domains/strings that are considered trusted booking senders. Used as
    /// a hint in the import sheet so the user knows the source is reputable.
    var trustedSenders: [String] = [
        "booking.com", "hotels.com", "airbnb.com",
        "expedia.de", "expedia.com", "trivago.de",
        "lufthansa.com", "eurowings.com", "ryanair.com",
        "bahn.de", "flixbus.de"
    ]
    /// When `true`, the import flow auto-picks the closest matching trip and
    /// jumps straight to review. When `false`, the user picks the trip first.
    var autoMatchTripOnImport: Bool = true

    // Cloud
    /// When `true`, `trips.json` lives in the iCloud Ubiquity container so it
    /// syncs across the user's devices. Toggling this triggers a migration
    /// (see `PersistenceMigrator`).
    var iCloudSyncEnabled: Bool = false

    private init() {}

    // MARK: Codable

    enum CodingKeys: String, CodingKey {
        case userDisplayName, userEmail, trustedSenders, autoMatchTripOnImport, iCloudSyncEnabled
    }

    required init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        userDisplayName = (try? c.decode(String.self, forKey: .userDisplayName)) ?? ""
        userEmail = (try? c.decode(String.self, forKey: .userEmail)) ?? ""
        trustedSenders = (try? c.decode([String].self, forKey: .trustedSenders))
            ?? AppSettings().trustedSenders
        autoMatchTripOnImport = (try? c.decode(Bool.self, forKey: .autoMatchTripOnImport)) ?? true
        iCloudSyncEnabled = (try? c.decode(Bool.self, forKey: .iCloudSyncEnabled)) ?? false
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(userDisplayName, forKey: .userDisplayName)
        try c.encode(userEmail, forKey: .userEmail)
        try c.encode(trustedSenders, forKey: .trustedSenders)
        try c.encode(autoMatchTripOnImport, forKey: .autoMatchTripOnImport)
        try c.encode(iCloudSyncEnabled, forKey: .iCloudSyncEnabled)
    }

    // MARK: Persistence

    private static var primaryURL: URL {
        // Settings always live locally — they describe the per-device choice
        // (incl. whether iCloud sync is on), so syncing them would be circular.
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
            .first!
            .appendingPathComponent(CloudConfig.settingsFileName)
    }

    private static func load() -> AppSettings? {
        guard let data = try? Data(contentsOf: primaryURL) else { return nil }
        let d = JSONDecoder()
        return try? d.decode(AppSettings.self, from: data)
    }

    func save() {
        do {
            let e = JSONEncoder()
            e.outputFormatting = [.prettyPrinted, .sortedKeys]
            let data = try e.encode(self)
            try data.write(to: Self.primaryURL, options: .atomic)
        } catch {
            print("AppSettings.save error: \(error)")
        }
    }

    var sanitizedTrustedSenders: [String] {
        trustedSenders
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() }
            .filter { !$0.isEmpty }
    }
}

// MARK: - Migration helper

enum PersistenceMigrator {
    /// Copies `trips.json` between the local Documents folder and the iCloud
    /// container in either direction. Used when the user toggles iCloud sync.
    @discardableResult
    static func migrate(toICloud: Bool) -> Bool {
        let local = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
            .first!
            .appendingPathComponent(CloudConfig.tripsFileName)
        guard let cloudDocs = CloudSync.documentsURL else { return false }
        let cloud = cloudDocs.appendingPathComponent(CloudConfig.tripsFileName)

        let src = toICloud ? local : cloud
        let dst = toICloud ? cloud : local
        guard FileManager.default.fileExists(atPath: src.path) else { return true }

        // Use a file coordinator so iCloud's bookkeeping doesn't fight us.
        var coordinatorError: NSError?
        var copyError: Error?
        NSFileCoordinator().coordinate(
            writingItemAt: src, options: .forMoving,
            writingItemAt: dst, options: .forReplacing,
            error: &coordinatorError
        ) { (srcURL, dstURL) in
            do {
                try? FileManager.default.removeItem(at: dstURL)
                try FileManager.default.copyItem(at: srcURL, to: dstURL)
            } catch {
                copyError = error
            }
        }
        return coordinatorError == nil && copyError == nil
    }
}
