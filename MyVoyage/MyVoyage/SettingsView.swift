//
//  SettingsView.swift
//  MyVoyage
//

import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var settings = AppSettings.shared

    @State private var newSender: String = ""
    @State private var showMigrationError = false
    @State private var migrationErrorText = ""

    var body: some View {
        NavigationStack {
            Form {
                profileSection
                importSection
                trustedSendersSection
                iCloudSection
                aboutSection
            }
            .navigationTitle("Einstellungen")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Fertig") {
                        settings.save()
                        dismiss()
                    }
                }
            }
            .alert("Migration fehlgeschlagen", isPresented: $showMigrationError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(migrationErrorText)
            }
        }
    }

    // MARK: Sections

    private var profileSection: some View {
        Section {
            TextField("Anzeigename", text: $settings.userDisplayName)
                .textContentType(.name)
            TextField("E-Mail-Adresse", text: $settings.userEmail)
                .textContentType(.emailAddress)
                .keyboardType(.emailAddress)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
        } header: {
            Text("Profil")
        } footer: {
            Text("Wird verwendet, um Buchungen dir zuzuordnen, wenn mehrere Reisende dieselbe iCloud-Reise teilen.")
        }
    }

    private var importSection: some View {
        Section {
            Toggle("Reise automatisch zuordnen", isOn: $settings.autoMatchTripOnImport)
        } header: {
            Text("Buchungs-Import")
        } footer: {
            Text("Wenn aktiviert, schlägt MyVoyage beim Import einer PDF-Bestätigung automatisch die passende Reise vor (anhand von Stadt und Datum). Sonst musst du die Reise im Review-Schritt wählen.")
        }
    }

    private var trustedSendersSection: some View {
        Section {
            ForEach(settings.trustedSenders, id: \.self) { sender in
                HStack {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundStyle(.green)
                    Text(sender)
                    Spacer()
                }
            }
            .onDelete { indexSet in
                settings.trustedSenders.remove(atOffsets: indexSet)
            }
            HStack {
                TextField("z. B. booking.com", text: $newSender)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                Button {
                    addSender()
                } label: {
                    Image(systemName: "plus.circle.fill")
                }
                .disabled(newSender.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        } header: {
            Text("Vertrauenswürdige Absender")
        } footer: {
            Text("Wenn eine importierte Buchungs-PDF von einem dieser Absender stammt, markiert MyVoyage sie als verifiziert. Lege Domains an (z. B. booking.com) — keine vollen E-Mail-Adressen.")
        }
    }

    private var iCloudSection: some View {
        Section {
            HStack {
                Image(systemName: CloudSync.isAccountAvailable ? "icloud.fill" : "icloud.slash")
                    .foregroundStyle(CloudSync.isAccountAvailable ? .blue : .secondary)
                Text(CloudSync.isAccountAvailable ? "iCloud-Konto aktiv" : "Nicht in iCloud angemeldet")
                    .foregroundStyle(.secondary)
            }
            Toggle("Reisen via iCloud synchronisieren", isOn: Binding(
                get: { settings.iCloudSyncEnabled },
                set: { newValue in toggleICloud(to: newValue) }
            ))
            .disabled(!CloudSync.isAccountAvailable)
        } header: {
            Text("iCloud-Sync")
        } footer: {
            if CloudSync.isAccountAvailable {
                Text("Speichert trips.json im iCloud-Drive-Container 'MyVoyage'. Änderungen auf iPhone, iPad und Mac werden über iCloud abgeglichen. Schalte den Schalter aus, wenn du nur lokal speichern willst.")
            } else {
                Text("Melde dich in den iOS-Einstellungen mit deiner Apple-ID an, um iCloud-Sync zu aktivieren.")
            }
        }
    }

    private var aboutSection: some View {
        Section("Über") {
            HStack {
                Text("Version")
                Spacer()
                Text(Bundle.main.appVersionString)
                    .foregroundStyle(.secondary)
            }
            HStack {
                Text("Apple Intelligence")
                Spacer()
                Text(BookingExtractor.availabilityShortLabel)
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: Actions

    private func addSender() {
        let cleaned = newSender
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
        guard !cleaned.isEmpty,
              !settings.trustedSenders.contains(cleaned) else { return }
        settings.trustedSenders.append(cleaned)
        newSender = ""
    }

    private func toggleICloud(to newValue: Bool) {
        if newValue && !CloudSync.isAccountAvailable {
            migrationErrorText = "Bitte melde dich erst in den iOS-Einstellungen bei iCloud an."
            showMigrationError = true
            return
        }
        let ok = PersistenceMigrator.migrate(toICloud: newValue)
        if !ok {
            migrationErrorText = "Reisen konnten nicht zwischen lokalem Speicher und iCloud verschoben werden. Versuche es später erneut."
            showMigrationError = true
            return
        }
        settings.iCloudSyncEnabled = newValue
        settings.save()
    }
}

private extension Bundle {
    var appVersionString: String {
        let v = infoDictionary?["CFBundleShortVersionString"] as? String ?? "?"
        let b = infoDictionary?["CFBundleVersion"] as? String ?? "?"
        return "\(v) (\(b))"
    }
}
