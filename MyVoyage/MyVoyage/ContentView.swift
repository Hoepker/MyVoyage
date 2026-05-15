import SwiftUI

// MARK: - Theme

enum AppTheme {
    // Solid mittel-blau für Toolbar, Sheets, Chip-Text — passt zur
    // Mitte des Gradients.
    static let bg = Color(red: 0.10, green: 0.20, blue: 0.42)
    // Hellerer Blau-Verlauf für die App-Hintergründe — gleiche Farb-
    // welt wie der MyScanPilot-Splash.
    static let bgGradient = LinearGradient(
        colors: [
            Color(red: 0.05, green: 0.15, blue: 0.35),
            Color(red: 0.15, green: 0.25, blue: 0.50),
            Color(red: 0.10, green: 0.20, blue: 0.45)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    static let surface = Color.white.opacity(0.05)
    static let border = Color.white.opacity(0.10)
    static let text = Color(hex: 0xE8E4D9)
    static let textSubtle = Color(hex: 0xE8E4D9).opacity(0.45)
    static let textMuted = Color(hex: 0xE8E4D9).opacity(0.65)
    static let accent = Color(hex: 0x60A5FA)  // helleres Blau für Kontrast auf blauem Hintergrund
}

extension Color {
    init(hex: UInt32, opacity: Double = 1.0) {
        let r = Double((hex >> 16) & 0xFF) / 255.0
        let g = Double((hex >> 8) & 0xFF) / 255.0
        let b = Double(hex & 0xFF) / 255.0
        self.init(.sRGB, red: r, green: g, blue: b, opacity: opacity)
    }
}

// MARK: - Models

enum TransportType: String, CaseIterable, Identifiable, Codable {
    case flight, train, car, bus, hotel

    var id: String { rawValue }

    var label: String {
        switch self {
        case .flight: "Flug"
        case .train: "Zug"
        case .car: "Mietwagen"
        case .bus: "Bus"
        case .hotel: "Hotel"
        }
    }

    var systemImage: String {
        switch self {
        case .flight: "airplane"
        case .train: "tram.fill"
        case .car: "car.fill"
        case .bus: "bus.fill"
        case .hotel: "bed.double.fill"
        }
    }

    var color: Color {
        switch self {
        case .flight: Color(hex: 0x3B82F6)
        case .train: Color(hex: 0x10B981)
        case .car: Color(hex: 0xF59E0B)
        case .bus: Color(hex: 0x8B5CF6)
        case .hotel: Color(hex: 0xEC4899)
        }
    }
}

struct TripSegment: Identifiable, Equatable, Codable {
    var id: UUID
    var type: TransportType
    var from: String
    var to: String
    var date: Date?
    var note: String
    var hotelCandidates: [HotelCandidate]

    init(
        id: UUID = UUID(),
        type: TransportType = .flight,
        from: String = "",
        to: String = "",
        date: Date? = nil,
        note: String = "",
        hotelCandidates: [HotelCandidate] = []
    ) {
        self.id = id
        self.type = type
        self.from = from
        self.to = to
        self.date = date
        self.note = note
        self.hotelCandidates = hotelCandidates
    }

    private enum CodingKeys: String, CodingKey {
        case id, type, from, to, date, note, hotelCandidates
    }

    // Manueller Codable-Init, damit bestehende Reise-JSONs ohne
    // `hotelCandidates` weiter geladen werden können.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        type = try c.decodeIfPresent(TransportType.self, forKey: .type) ?? .flight
        from = try c.decodeIfPresent(String.self, forKey: .from) ?? ""
        to = try c.decodeIfPresent(String.self, forKey: .to) ?? ""
        date = try c.decodeIfPresent(Date.self, forKey: .date)
        note = try c.decodeIfPresent(String.self, forKey: .note) ?? ""
        hotelCandidates = try c.decodeIfPresent([HotelCandidate].self, forKey: .hotelCandidates) ?? []
    }
}

// MARK: - Hotel Candidates

enum HotelStatus: String, CaseIterable, Codable {
    case considered    // ⏳ Vorgemerkt
    case selected      // ⭐ Ausgewählt
    case booked        // ✅ Gebucht
    case confirmed     // ✓ Bestätigt

    var label: String {
        switch self {
        case .considered: "Vorgemerkt"
        case .selected:   "Ausgewählt"
        case .booked:     "Gebucht"
        case .confirmed:  "Bestätigt"
        }
    }

    var icon: String {
        switch self {
        case .considered: "hourglass"
        case .selected:   "star.fill"
        case .booked:     "checkmark.circle.fill"
        case .confirmed:  "checkmark.seal.fill"
        }
    }

    var color: Color {
        switch self {
        case .considered: Color(hex: 0xF59E0B)
        case .selected:   Color(hex: 0x3B82F6)
        case .booked:     Color(hex: 0xF97316)
        case .confirmed:  Color(hex: 0x10B981)
        }
    }
}

struct HotelCandidate: Identifiable, Equatable, Codable {
    var id: UUID = UUID()
    var name: String
    var urlString: String?
    var imageURLString: String?
    var subtitle: String = ""           // og:description / kurzer Beschreibungstext
    var pricePerNight: Double?
    var stars: Int?
    var notes: String = ""
    var status: HotelStatus = .considered
    var bookingReference: String?
    var createdAt: Date = Date()

    var url: URL? { urlString.flatMap(URL.init(string:)) }
    var imageURL: URL? { imageURLString.flatMap(URL.init(string:)) }
}

struct Travelers: Equatable, Codable {
    var adults: Int = 2
    var children: [Int] = []

    var total: Int { adults + children.count }

    var summary: String {
        if children.isEmpty {
            return "\(adults) Erwachsene\(adults == 1 ? "r" : "")"
        }
        return "\(adults) Erw. · \(children.count) Kind\(children.count > 1 ? "er" : "")"
    }
}

// MARK: - Trip

@Observable
final class Trip: Identifiable, Hashable, Codable {
    let id: UUID
    var name: String
    var travelers: Travelers
    var segments: [TripSegment]
    var accentHex: UInt32

    init(
        name: String,
        travelers: Travelers = Travelers(),
        segments: [TripSegment] = [],
        accentHex: UInt32 = 0x3B82F6,
        id: UUID = UUID()
    ) {
        self.id = id
        self.name = name
        self.travelers = travelers
        self.segments = segments
        self.accentHex = accentHex
    }

    private enum CodingKeys: String, CodingKey {
        case id, name, travelers, segments, accentHex
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try c.decode(UUID.self, forKey: .id)
        self.name = try c.decode(String.self, forKey: .name)
        self.travelers = try c.decode(Travelers.self, forKey: .travelers)
        self.segments = try c.decode([TripSegment].self, forKey: .segments)
        self.accentHex = try c.decode(UInt32.self, forKey: .accentHex)
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(name, forKey: .name)
        try c.encode(travelers, forKey: .travelers)
        try c.encode(segments, forKey: .segments)
        try c.encode(accentHex, forKey: .accentHex)
    }

    var accent: Color { Color(hex: accentHex) }

    var startDate: Date? { segments.compactMap { $0.date }.min() }
    var endDate: Date? { segments.compactMap { $0.date }.max() }

    var dateRangeLabel: String {
        guard let s = startDate else { return "Datum offen" }
        let f = DateFormatter()
        f.locale = Locale(identifier: "de_DE")
        if let e = endDate, !Calendar.current.isDate(s, inSameDayAs: e) {
            f.dateFormat = "d. MMM"
            let sStr = f.string(from: s)
            f.dateFormat = "d. MMM yyyy"
            return "\(sStr) – \(f.string(from: e))"
        } else {
            f.dateFormat = "d. MMMM yyyy"
            return f.string(from: s)
        }
    }

    var primaryDestination: String {
        let hotels = segments.filter { $0.type == .hotel }.compactMap { $0.to.isEmpty ? nil : $0.to }
        if let first = hotels.first { return first }
        return segments.compactMap { $0.to.isEmpty ? nil : $0.to }.first ?? ""
    }

    var coverEmoji: String {
        let dest = primaryDestination.lowercased()
        for (key, emoji) in Trip.emojiMap {
            if dest.contains(key) { return emoji }
        }
        return "🌍"
    }

    private static let emojiMap: [(String, String)] = [
        ("paris", "🗼"),
        ("london", "🌉"),
        ("rom", "🏛️"),
        ("rome", "🏛️"),
        ("florenz", "🎨"),
        ("venedig", "🛶"),
        ("venice", "🛶"),
        ("verona", "🏟️"),
        ("mailand", "👗"),
        ("milan", "👗"),
        ("neapel", "🍕"),
        ("naples", "🍕"),
        ("new york", "🗽"),
        ("tokio", "⛩️"),
        ("tokyo", "⛩️"),
        ("kyoto", "🏯"),
        ("osaka", "🏯"),
        ("istanbul", "🕌"),
        ("barcelona", "🏝️"),
        ("madrid", "💃"),
        ("valencia", "🍊"),
        ("sevilla", "💃"),
        ("seville", "💃"),
        ("lissabon", "🌊"),
        ("lisbon", "🌊"),
        ("porto", "🍷"),
        ("münchen", "🍺"),
        ("munich", "🍺"),
        ("berlin", "🐻"),
        ("hamburg", "⚓"),
        ("frankfurt", "🏙️"),
        ("köln", "⛪"),
        ("cologne", "⛪"),
        ("stuttgart", "🚗"),
        ("düsseldorf", "🎨"),
        ("dresden", "🎭"),
        ("wien", "🎶"),
        ("vienna", "🎶"),
        ("prag", "🌉"),
        ("prague", "🌉"),
        ("athen", "🏛️"),
        ("athens", "🏛️"),
        ("amsterdam", "🌷"),
        ("brüssel", "🍫"),
        ("brussels", "🍫"),
        ("kopenhagen", "🧜‍♀️"),
        ("copenhagen", "🧜‍♀️"),
        ("stockholm", "🛥️"),
        ("oslo", "🏔️"),
        ("helsinki", "🧖"),
        ("dublin", "🍀"),
        ("edinburgh", "🏰"),
        ("zürich", "🏔️"),
        ("zurich", "🏔️"),
        ("rio", "🏖️"),
        ("rio de janeiro", "🏖️"),
        ("vegas", "🎰"),
        ("las vegas", "🎰"),
        ("san francisco", "🌉"),
        ("los angeles", "🌴"),
        ("miami", "🌴"),
        ("chicago", "🌭"),
        ("dubai", "🏙️"),
        ("bangkok", "🛕"),
        ("singapur", "🦁"),
        ("singapore", "🦁"),
        ("hongkong", "🏙️"),
        ("hong kong", "🏙️"),
        ("sydney", "🦘"),
        ("melbourne", "☕"),
        ("kapstadt", "🦓"),
        ("cape town", "🦓"),
        ("marrakech", "🐪"),
        ("marrakesch", "🐪"),
        ("kairo", "🐫"),
        ("cairo", "🐫"),
        ("jerusalem", "🕍"),
        ("mallorca", "🏝️"),
        ("ibiza", "🏝️"),
        ("kreta", "🏝️"),
        ("santorini", "⛪"),
    ]

    var uniquePlaceCount: Int {
        Set(segments.flatMap { [$0.from, $0.to] }.filter { !$0.isEmpty }).count
    }

    func count(of type: TransportType) -> Int {
        segments.filter { $0.type == type }.count
    }

    func addSegment() {
        segments.append(TripSegment())
    }

    func remove(_ segment: TripSegment) {
        segments.removeAll { $0.id == segment.id }
    }

    func update(_ segment: TripSegment) {
        guard let idx = segments.firstIndex(where: { $0.id == segment.id }) else { return }
        segments[idx] = segment
    }

    static func == (lhs: Trip, rhs: Trip) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}

// MARK: - Persistence

enum PersistenceService {
    /// File path that the app currently reads from / writes to. Tracks the
    /// `iCloudSyncEnabled` setting — when on and an iCloud container is
    /// reachable, this points into `iCloud Drive/MyVoyage/Documents/`.
    /// Falls back to the local Documents folder otherwise.
    static var fileURL: URL {
        if AppSettings.shared.iCloudSyncEnabled,
           let cloudDocs = CloudSync.documentsURL {
            return cloudDocs.appendingPathComponent(CloudConfig.tripsFileName)
        }
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return dir.appendingPathComponent(CloudConfig.tripsFileName)
    }

    private static let encoder: JSONEncoder = {
        let e = JSONEncoder()
        e.dateEncodingStrategy = .iso8601
        e.outputFormatting = [.prettyPrinted, .sortedKeys]
        return e
    }()

    private static let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return d
    }()

    static func load() -> [Trip]? {
        let url = fileURL
        // Ask iCloud to materialise the file if it's a placeholder. Best-effort.
        if AppSettings.shared.iCloudSyncEnabled {
            try? FileManager.default.startDownloadingUbiquitousItem(at: url)
        }
        guard let data = try? Data(contentsOf: url),
              let trips = try? decoder.decode([Trip].self, from: data) else {
            return nil
        }
        return trips
    }

    static func save(_ trips: [Trip]) {
        do {
            let data = try encoder.encode(trips)
            let url = fileURL
            // Make sure the destination directory exists (Ubiquity-Documents
            // is auto-created by `CloudSync.documentsURL`, local Documents
            // always exists — this guard is for safety).
            try? FileManager.default.createDirectory(
                at: url.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            try data.write(to: url, options: .atomic)
        } catch {
            print("PersistenceService.save error: \(error)")
        }
    }

    static func clear() {
        try? FileManager.default.removeItem(at: fileURL)
    }
}

// MARK: - Trips Store

@Observable
final class TripsStore {
    var trips: [Trip] = []

    init() {
        if let loaded = PersistenceService.load() {
            trips = loaded
        } else {
            seedDemo()
            save()
        }
    }

    func save() {
        PersistenceService.save(trips)
    }

    func resetToDemo() {
        seedDemo()
        save()
    }

    func removeAll() {
        trips.removeAll()
        save()
    }

    func add(named name: String = "Neue Reise") -> Trip {
        let trip = Trip(name: name, accentHex: nextAccent())
        trips.append(trip)
        save()
        return trip
    }

    @discardableResult
    func add(_ trip: Trip) -> Trip {
        if trip.accentHex == 0x3B82F6 {
            trip.accentHex = nextAccent()
        }
        trips.append(trip)
        save()
        return trip
    }

    func remove(_ trip: Trip) {
        trips.removeAll { $0.id == trip.id }
        save()
    }

    private func nextAccent() -> UInt32 {
        let palette: [UInt32] = [0x3B82F6, 0xEC4899, 0x10B981, 0xF59E0B, 0x8B5CF6, 0xEF4444]
        return palette[trips.count % palette.count]
    }

    private func seedDemo() {
        let cal = Calendar.current

        let spainStart = cal.date(from: DateComponents(year: 2026, month: 6, day: 1))!
        let spain = Trip(
            name: "Spanien-Rundreise",
            travelers: Travelers(adults: 2, children: [8]),
            segments: [
                TripSegment(type: .flight, from: "Berlin", to: "Barcelona", date: spainStart),
                TripSegment(type: .hotel, from: "", to: "Barcelona", date: spainStart),
                TripSegment(type: .car, from: "Barcelona", to: "Valencia", date: cal.date(byAdding: .day, value: 3, to: spainStart)),
                TripSegment(type: .train, from: "Valencia", to: "Madrid", date: cal.date(byAdding: .day, value: 6, to: spainStart)),
                TripSegment(type: .flight, from: "Madrid", to: "Berlin", date: cal.date(byAdding: .day, value: 13, to: spainStart)),
            ],
            accentHex: 0xF59E0B
        )

        let italyStart = cal.date(from: DateComponents(year: 2026, month: 8, day: 12))!
        let italy = Trip(
            name: "Italien Roadtrip",
            travelers: Travelers(adults: 2, children: []),
            segments: [
                TripSegment(type: .flight, from: "Frankfurt", to: "Rom", date: italyStart),
                TripSegment(type: .hotel, from: "", to: "Rom", date: italyStart),
                TripSegment(type: .train, from: "Rom", to: "Florenz", date: cal.date(byAdding: .day, value: 3, to: italyStart)),
                TripSegment(type: .train, from: "Florenz", to: "Venedig", date: cal.date(byAdding: .day, value: 6, to: italyStart)),
            ],
            accentHex: 0xEC4899
        )

        let tokyoStart = cal.date(from: DateComponents(year: 2027, month: 4, day: 3))!
        let tokyo = Trip(
            name: "Kirschblüte in Japan",
            travelers: Travelers(adults: 2, children: []),
            segments: [
                TripSegment(type: .flight, from: "München", to: "Tokio", date: tokyoStart),
                TripSegment(type: .hotel, from: "", to: "Tokio", date: tokyoStart),
                TripSegment(type: .train, from: "Tokio", to: "Kyoto", date: cal.date(byAdding: .day, value: 5, to: tokyoStart)),
            ],
            accentHex: 0x8B5CF6
        )

        let nycStart = cal.date(from: DateComponents(year: 2026, month: 11, day: 22))!
        let nyc = Trip(
            name: "Long Weekend NYC",
            travelers: Travelers(adults: 2, children: []),
            segments: [
                TripSegment(type: .flight, from: "Frankfurt", to: "New York", date: nycStart),
                TripSegment(type: .hotel, from: "", to: "New York", date: nycStart),
                TripSegment(type: .flight, from: "New York", to: "Frankfurt", date: cal.date(byAdding: .day, value: 4, to: nycStart)),
            ],
            accentHex: 0x10B981
        )

        trips = [spain, italy, tokyo, nyc]
    }
}

// MARK: - Root

struct ContentView: View {
    @State private var store = TripsStore()
    @Environment(\.scenePhase) private var scenePhase

    /// PDF that arrived via the Share Extension (or `myvoyage://` URL) and
    /// is waiting to be imported. We hand it off to `BookingImportSheet`,
    /// then delete the inbox copy.
    @State private var pendingShareImport: URL?
    @State private var showSettings = false

    var body: some View {
        NavigationStack {
            TripsListView(store: store, onOpenSettings: { showSettings = true })
                .navigationDestination(for: Trip.self) { trip in
                    TripDetailView(trip: trip, store: store)
                }
        }
        .tint(AppTheme.accent)
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                checkShareInbox()
            } else {
                store.save()
            }
        }
        .onOpenURL { url in
            handleIncomingURL(url)
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
                .presentationDetents([.large])
        }
        .sheet(item: $pendingShareImport) { url in
            BookingImportSheet(
                trip: store.trips.first,
                store: store,
                preloadedPDF: url
            )
            .onDisappear {
                try? FileManager.default.removeItem(at: url)
                pendingShareImport = nil
            }
        }
    }

    private func handleIncomingURL(_ url: URL) {
        // Two supported shapes:
        //   myvoyage://import?name=<inbox filename>     (from Share Extension)
        //   file:///…/<some>.pdf                        (open-in from Files)
        if url.isFileURL {
            pendingShareImport = url
            return
        }
        guard url.scheme == "myvoyage", url.host == "import" else { return }
        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        let name = components?.queryItems?.first(where: { $0.name == "name" })?.value
        guard let name, !name.isEmpty else { return }
        let candidate = CloudSync.inboxURL.appendingPathComponent(name)
        if FileManager.default.fileExists(atPath: candidate.path) {
            pendingShareImport = candidate
        }
    }

    /// On app foreground, sweep the Share Extension inbox so anything dropped
    /// while we were away gets picked up too.
    private func checkShareInbox() {
        let inbox = CloudSync.inboxURL
        let pdfs = (try? FileManager.default.contentsOfDirectory(at: inbox, includingPropertiesForKeys: nil))
            ?? []
        let firstPDF = pdfs.first { $0.pathExtension.lowercased() == "pdf" }
        if let firstPDF, pendingShareImport == nil {
            pendingShareImport = firstPDF
        }
    }
}

extension URL: @retroactive Identifiable {
    public var id: String { absoluteString }
}

// MARK: - Trips List (Übersicht)

struct TripsListView: View {
    let store: TripsStore
    var onOpenSettings: (() -> Void)? = nil

    @State private var pushNewTrip: Trip? = nil
    @State private var showWizard = false
    @State private var showResetConfirm = false
    @State private var showDeleteAllConfirm = false
    @State private var deletionTarget: Trip? = nil
    @State private var showImportPDFPicker = false
    @State private var importPDFURL: URL? = nil

    private let columns = [GridItem(.adaptive(minimum: 160, maximum: 220), spacing: 14)]

    var body: some View {
        ZStack {
            AppTheme.bgGradient.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    header
                    flowHint
                    grid
                    Color.clear.frame(height: 24)
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(AppTheme.bg, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button {
                        showImportPDFPicker = true
                    } label: {
                        Label("Buchung importieren (PDF)", systemImage: "doc.text.magnifyingglass")
                    }
                    Divider()
                    Button {
                        onOpenSettings?()
                    } label: {
                        Label("Einstellungen", systemImage: "gear")
                    }
                    Divider()
                    Button {
                        showResetConfirm = true
                    } label: {
                        Label("Demo wiederherstellen", systemImage: "arrow.counterclockwise")
                    }
                    Button(role: .destructive) {
                        showDeleteAllConfirm = true
                    } label: {
                        Label("Alle Reisen löschen", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .foregroundStyle(AppTheme.text)
                }
            }
        }
        .fileImporter(
            isPresented: $showImportPDFPicker,
            allowedContentTypes: [.pdf],
            allowsMultipleSelection: false
        ) { result in
            if case let .success(urls) = result, let url = urls.first {
                importPDFURL = url
            }
        }
        .sheet(item: $importPDFURL) { url in
            BookingImportSheet(
                trip: store.trips.first,
                store: store,
                preloadedPDF: url
            )
        }
        .navigationDestination(item: $pushNewTrip) { trip in
            TripDetailView(trip: trip, store: store)
        }
        .fullScreenCover(isPresented: $showWizard) {
            TripWizardView(store: store, pushTrip: $pushNewTrip)
        }
        .confirmationDialog(
            "Demo-Reisen wiederherstellen?",
            isPresented: $showResetConfirm,
            titleVisibility: .visible
        ) {
            Button("Wiederherstellen", role: .destructive) { store.resetToDemo() }
            Button("Abbrechen", role: .cancel) {}
        } message: {
            Text("Alle aktuellen Reisen werden ersetzt durch die 4 Demo-Reisen.")
        }
        .confirmationDialog(
            "Alle Reisen löschen?",
            isPresented: $showDeleteAllConfirm,
            titleVisibility: .visible
        ) {
            Button("Alle löschen", role: .destructive) { store.removeAll() }
            Button("Abbrechen", role: .cancel) {}
        } message: {
            Text("Diese Aktion lässt sich nicht rückgängig machen.")
        }
        .confirmationDialog(
            deletionTarget.map { "„\($0.name)" + "\u{201C}" + " wirklich löschen?" } ?? "Reise löschen?",
            isPresented: Binding(
                get: { deletionTarget != nil },
                set: { if !$0 { deletionTarget = nil } }
            ),
            titleVisibility: .visible
        ) {
            Button("Löschen", role: .destructive) {
                if let t = deletionTarget { store.remove(t) }
                deletionTarget = nil
            }
            Button("Abbrechen", role: .cancel) { deletionTarget = nil }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                Image("LogoMark")
                    .resizable()
                    .frame(width: 36, height: 36)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                HStack(spacing: 0) {
                    Text("My").font(.system(.title2, design: .serif).weight(.bold))
                    Text("Voyage").font(.system(.title2, design: .serif).weight(.bold))
                        .foregroundStyle(AppTheme.accent)
                }
                Spacer()
            }
            Text("Meine Traumreisen")
                .font(.system(.largeTitle, design: .serif).weight(.bold))
                .foregroundStyle(AppTheme.text)
                .padding(.top, 4)
            Text("\(store.trips.count) geplante Reisen")
                .font(.system(size: 13))
                .foregroundStyle(AppTheme.textMuted)
        }
    }

    private var flowHint: some View {
        HStack(spacing: 10) {
            Image(systemName: "hand.tap.fill")
                .font(.system(size: 13))
                .foregroundStyle(AppTheme.accent)
            Text("Tippe eine Reise an, um Etappen und Buchungen zu sehen.")
                .font(.system(size: 12))
                .foregroundStyle(AppTheme.textMuted)
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(AppTheme.accent.opacity(0.06), in: RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(AppTheme.accent.opacity(0.18), lineWidth: 1)
        )
    }

    private var grid: some View {
        LazyVGrid(columns: columns, spacing: 14) {
            ForEach(store.trips) { trip in
                NavigationLink(value: trip) {
                    TripCard(trip: trip)
                }
                .buttonStyle(.plain)
                .contextMenu {
                    Button(role: .destructive) {
                        deletionTarget = trip
                    } label: {
                        Label("Reise löschen", systemImage: "trash")
                    }
                }
            }
            newTripCard
        }
    }

    private var newTripCard: some View {
        Button {
            showWizard = true
        } label: {
            VStack(spacing: 10) {
                Image(systemName: "plus")
                    .font(.system(size: 26, weight: .light))
                    .foregroundStyle(AppTheme.accent)
                    .frame(width: 56, height: 56)
                    .background(AppTheme.accent.opacity(0.1), in: Circle())
                    .overlay(Circle().stroke(AppTheme.accent.opacity(0.3), lineWidth: 1))
                Text("Neue Reise")
                    .font(.system(.headline, design: .serif))
                    .foregroundStyle(AppTheme.text)
                Text("Eine leere Reise anlegen")
                    .font(.system(size: 11))
                    .foregroundStyle(AppTheme.textSubtle)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity, minHeight: 200, maxHeight: 200)
            .background(Color.clear)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(style: StrokeStyle(lineWidth: 1.5, dash: [6, 4]))
                    .foregroundStyle(AppTheme.border)
            )
        }
        .buttonStyle(.plain)
    }
}

private struct TripCard: View {
    let trip: Trip

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack(alignment: .topTrailing) {
                DestinationImageView(destination: trip.primaryDestination) {
                    LinearGradient(
                        colors: [trip.accent.opacity(0.85), trip.accent.opacity(0.35), Color.black.opacity(0.6)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                LinearGradient(
                    colors: [Color.clear, Color.black.opacity(0.55)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .allowsHitTesting(false)

                Text(trip.coverEmoji)
                    .font(.system(size: 36))
                    .padding(.top, 8)
                    .padding(.trailing, 10)
                    .shadow(color: .black.opacity(0.5), radius: 8)
            }
            .frame(maxWidth: .infinity, minHeight: 110, maxHeight: 110)
            .clipped()

            VStack(alignment: .leading, spacing: 4) {
                Text(trip.name)
                    .font(.system(.headline, design: .serif).weight(.semibold))
                    .foregroundStyle(AppTheme.text)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                Text(trip.dateRangeLabel)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(AppTheme.textMuted)
                    .lineLimit(1)
                Spacer(minLength: 4)
                HStack(spacing: 10) {
                    Label("\(trip.segments.count)", systemImage: "list.bullet")
                    Label("\(trip.travelers.total)", systemImage: "person.2.fill")
                    Spacer()
                }
                .font(.system(size: 10))
                .foregroundStyle(AppTheme.textSubtle)
            }
            .padding(12)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
        .frame(maxWidth: .infinity, minHeight: 200, maxHeight: 200)
        .background(AppTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(AppTheme.border, lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.4), radius: 12, y: 6)
    }
}

// MARK: - Trip Detail

struct TripDetailView: View {
    @Bindable var trip: Trip
    let store: TripsStore

    @State private var showTravelers = false
    @State private var showDeleteConfirm = false
    @State private var showBookingImport = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            AppTheme.bgGradient.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    detailHeader
                    SummaryBar(trip: trip)
                    sectionTitle("Reiseplan")
                    Timeline(trip: trip)
                    addSegmentButton
                    if !trip.segments.isEmpty {
                        sectionTitle("Buchungsübersicht")
                            .padding(.top, 12)
                        BookingOverview(trip: trip)
                    }
                    Color.clear.frame(height: 60)
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(AppTheme.bg, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text(trip.name)
                    .font(.system(.headline, design: .serif).weight(.semibold))
                    .foregroundStyle(AppTheme.text)
            }
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button {
                        showBookingImport = true
                    } label: {
                        Label("Buchung importieren (PDF)", systemImage: "doc.text.magnifyingglass")
                    }
                    Divider()
                    Button(role: .destructive) {
                        showDeleteConfirm = true
                    } label: {
                        Label("Reise löschen", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .foregroundStyle(AppTheme.text)
                }
            }
        }
        .sheet(isPresented: $showTravelers) {
            TravelersSheet(travelers: $trip.travelers)
                .presentationDetents([.medium, .large])
                .presentationBackground(AppTheme.bg)
        }
        .sheet(isPresented: $showBookingImport) {
            BookingImportSheet(trip: trip, store: store)
        }
        .confirmationDialog("Reise wirklich löschen?", isPresented: $showDeleteConfirm, titleVisibility: .visible) {
            Button("Löschen", role: .destructive) {
                store.remove(trip)
                dismiss()
            }
            Button("Abbrechen", role: .cancel) {}
        }
    }

    private var detailHeader: some View {
        VStack(alignment: .leading, spacing: 12) {
            ZStack(alignment: .bottomLeading) {
                DestinationImageView(destination: trip.primaryDestination) {
                    LinearGradient(
                        colors: [trip.accent.opacity(0.7), trip.accent.opacity(0.25), Color.black.opacity(0.6)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                }
                .frame(height: 200)
                .clipped()

                LinearGradient(
                    colors: [Color.clear, Color.black.opacity(0.7)],
                    startPoint: .center,
                    endPoint: .bottom
                )
                .allowsHitTesting(false)

                HStack(alignment: .bottom) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(trip.coverEmoji).font(.system(size: 32))
                            .shadow(color: .black.opacity(0.5), radius: 8)
                        Text(trip.dateRangeLabel)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(.white.opacity(0.85))
                            .shadow(color: .black.opacity(0.6), radius: 4)
                    }
                    Spacer()
                    travelersButton
                }
                .padding(14)
            }
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(AppTheme.border, lineWidth: 1)
            )

            TextField("", text: $trip.name, prompt: Text("Name deiner Reise...").foregroundStyle(AppTheme.text.opacity(0.25)))
                .font(.system(.title2, design: .serif))
                .foregroundStyle(AppTheme.text)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(Color.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 8))
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(AppTheme.border, lineWidth: 1))
                .submitLabel(.done)

            HStack(spacing: 4) {
                Image(systemName: "info.circle").font(.system(size: 9))
                Text("Coverfotos: Wikimedia Commons")
                    .font(.system(size: 10))
                Spacer()
            }
            .foregroundStyle(AppTheme.textSubtle)
            .padding(.top, -4)
        }
    }

    private var travelersButton: some View {
        Button {
            showTravelers = true
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "person.2.fill").font(.system(size: 12))
                Text(trip.travelers.summary).font(.system(size: 13))
                Text("\(trip.travelers.total)")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 20, height: 20)
                    .background(AppTheme.accent, in: Circle())
            }
            .foregroundStyle(AppTheme.text)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 8))
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(AppTheme.border, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    private func sectionTitle(_ text: String) -> some View {
        HStack(spacing: 12) {
            Text(text.uppercased())
                .font(.system(size: 11).weight(.medium))
                .tracking(2.5)
                .foregroundStyle(AppTheme.textSubtle)
            Rectangle().frame(height: 1).foregroundStyle(AppTheme.border)
        }
    }

    private var addSegmentButton: some View {
        Button {
            withAnimation(.snappy) { trip.addSegment() }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "plus")
                Text("Etappe hinzufügen")
            }
            .font(.system(size: 14))
            .foregroundStyle(AppTheme.textMuted)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(Color.clear)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .strokeBorder(style: StrokeStyle(lineWidth: 1, dash: [5, 4]))
                    .foregroundStyle(AppTheme.border)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Summary Bar

struct SummaryBar: View {
    let trip: Trip

    var body: some View {
        if trip.segments.isEmpty {
            EmptyState()
        } else {
            HStack(spacing: 18) {
                stat("\(trip.travelers.total)", "Reisende", accent: true)
                stat("\(trip.segments.count)", "Etappen")
                stat("\(trip.uniquePlaceCount)", "Orte")
                stat("\(trip.count(of: .flight))", "Flüge")
                stat("\(trip.count(of: .hotel))", "Hotels")
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(AppTheme.surface, in: RoundedRectangle(cornerRadius: 10))
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(AppTheme.border, lineWidth: 1))
        }
    }

    private func stat(_ value: String, _ label: String, accent: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(value)
                .font(.system(.title2, design: .serif))
                .foregroundStyle(accent ? AppTheme.accent : AppTheme.text)
            Text(label.uppercased())
                .font(.system(size: 9).weight(.medium))
                .tracking(1.5)
                .foregroundStyle(AppTheme.textSubtle)
        }
    }
}

private struct EmptyState: View {
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "lightbulb.fill")
                .font(.system(size: 14))
                .foregroundStyle(.yellow.opacity(0.85))
            Text("Noch keine Etappen — füge unten Flüge, Hotels oder Mietwagen hinzu.")
                .font(.system(size: 12))
                .foregroundStyle(AppTheme.textMuted)
            Spacer()
        }
        .padding(12)
        .background(.yellow.opacity(0.05), in: RoundedRectangle(cornerRadius: 10))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(.yellow.opacity(0.2), lineWidth: 1))
    }
}

// MARK: - Timeline

struct Timeline: View {
    let trip: Trip

    var body: some View {
        if trip.segments.isEmpty {
            EmptyView()
        } else {
            VStack(spacing: 0) {
                ForEach(Array(trip.segments.enumerated()), id: \.element.id) { index, segment in
                    HStack(alignment: .top, spacing: 12) {
                        TimelineDot(type: segment.type, isLast: index == trip.segments.count - 1)
                        SegmentCard(
                            segment: segment,
                            travelers: trip.travelers,
                            trip: trip,
                            onChange: { trip.update($0) },
                            onRemove: { trip.remove(segment) }
                        )
                    }
                }
            }
        }
    }
}

private struct TimelineDot: View {
    let type: TransportType
    let isLast: Bool

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                Circle().fill(type.color.opacity(0.18))
                Circle().stroke(type.color.opacity(0.45), lineWidth: 2)
                Image(systemName: type.systemImage)
                    .font(.system(size: 14))
                    .foregroundStyle(type.color)
            }
            .frame(width: 36, height: 36)
            if !isLast {
                Rectangle()
                    .fill(AppTheme.border)
                    .frame(width: 2)
                    .frame(maxHeight: .infinity)
            }
        }
        .frame(width: 36)
        .padding(.top, 14)
    }
}

// MARK: - Segment Card

struct SegmentCard: View {
    let segment: TripSegment
    let travelers: Travelers
    let trip: Trip
    let onChange: (TripSegment) -> Void
    let onRemove: () -> Void

    @State private var showNote = false

    private var portals: [BookingPortal] { BookingPortals.portals(for: segment.type) }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(TransportType.allCases) { type in
                            TypeChip(
                                type: type,
                                isSelected: segment.type == type
                            ) {
                                var s = segment
                                s.type = type
                                onChange(s)
                            }
                        }
                    }
                }
                Spacer(minLength: 4)
                Menu {
                    ForEach(portals) { portal in
                        if let url = portal.urlBuilder(segment, travelers, trip) {
                            Link(portal.name, destination: url)
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text("Buchen")
                        Image(systemName: "chevron.down").font(.system(size: 9))
                    }
                    .font(.system(size: 12))
                    .foregroundStyle(AppTheme.text)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 6))
                    .overlay(RoundedRectangle(cornerRadius: 6).stroke(AppTheme.border, lineWidth: 1))
                }

                Button(role: .destructive, action: onRemove) {
                    Image(systemName: "trash").font(.system(size: 12))
                        .foregroundStyle(AppTheme.textMuted)
                        .frame(width: 28, height: 28)
                        .background(Color.clear, in: RoundedRectangle(cornerRadius: 6))
                        .overlay(RoundedRectangle(cornerRadius: 6).stroke(AppTheme.border, lineWidth: 1))
                }
                .buttonStyle(.plain)
            }

            VStack(spacing: 8) {
                if segment.type != .hotel {
                    field("VON", placeholder: "z.B. Berlin", text: Binding(
                        get: { segment.from },
                        set: { var s = segment; s.from = $0; onChange(s) }
                    ))
                }
                field(segment.type == .hotel ? "ORT" : "NACH", placeholder: "z.B. Paris", text: Binding(
                    get: { segment.to },
                    set: { var s = segment; s.to = $0; onChange(s) }
                ))
                dateField
            }

            Button { withAnimation(.snappy) { showNote.toggle() } } label: {
                Text(showNote ? "Notiz ausblenden" : "+ Notiz hinzufügen")
                    .font(.system(size: 11))
                    .foregroundStyle(AppTheme.textSubtle)
            }
            .buttonStyle(.plain)

            if showNote {
                TextField("", text: Binding(
                    get: { segment.note },
                    set: { var s = segment; s.note = $0; onChange(s) }
                ), prompt: Text("Hinweise, Buchungsnummern...").foregroundStyle(AppTheme.text.opacity(0.18)),
                axis: .vertical)
                    .lineLimit(2...4)
                    .font(.system(size: 12))
                    .foregroundStyle(AppTheme.textMuted)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                    .background(Color.white.opacity(0.03), in: RoundedRectangle(cornerRadius: 7))
                    .overlay(RoundedRectangle(cornerRadius: 7).stroke(AppTheme.border, lineWidth: 1))
            }

            if segment.type == .hotel {
                Divider().background(AppTheme.border).padding(.vertical, 2)
                HotelCandidatesSection(segment: segment, onChange: onChange)
            }
        }
        .padding(14)
        .background(AppTheme.surface, in: RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(AppTheme.border, lineWidth: 1))
        .padding(.vertical, 6)
    }

    private func field(_ label: String, placeholder: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label).font(.system(size: 9).weight(.medium)).tracking(1.2).foregroundStyle(AppTheme.textSubtle)
            TextField("", text: text, prompt: Text(placeholder).foregroundStyle(AppTheme.text.opacity(0.18)))
                .font(.system(size: 14))
                .foregroundStyle(AppTheme.text)
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background(Color.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 7))
                .overlay(RoundedRectangle(cornerRadius: 7).stroke(AppTheme.border, lineWidth: 1))
        }
    }

    private var dateField: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("DATUM").font(.system(size: 9).weight(.medium)).tracking(1.2).foregroundStyle(AppTheme.textSubtle)
            DatePicker(
                "",
                selection: Binding(
                    get: { segment.date ?? Date() },
                    set: { var s = segment; s.date = $0; onChange(s) }
                ),
                displayedComponents: .date
            )
            .datePickerStyle(.compact)
            .labelsHidden()
            .colorScheme(.dark)
            .tint(AppTheme.accent)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 7))
            .overlay(RoundedRectangle(cornerRadius: 7).stroke(AppTheme.border, lineWidth: 1))
        }
    }
}

private struct TypeChip: View {
    let type: TransportType
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 4) {
                Image(systemName: type.systemImage).font(.system(size: 10))
                Text(type.label).font(.system(size: 12))
            }
            .foregroundStyle(isSelected ? AppTheme.bg : AppTheme.textMuted)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(isSelected ? type.color : Color.clear, in: RoundedRectangle(cornerRadius: 6))
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(isSelected ? Color.clear : AppTheme.border, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Travelers Sheet

struct TravelersSheet: View {
    @Binding var travelers: Travelers
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                counter(
                    label: "Erwachsene",
                    sub: "Ab 12 Jahren",
                    value: travelers.adults,
                    canDecrement: travelers.adults > 1,
                    canIncrement: travelers.adults < 9,
                    onDecrement: { travelers.adults -= 1 },
                    onIncrement: { travelers.adults += 1 }
                )
                Divider().background(AppTheme.border)
                counter(
                    label: "Kinder",
                    sub: "Bis 11 Jahre",
                    value: travelers.children.count,
                    canDecrement: !travelers.children.isEmpty,
                    canIncrement: travelers.children.count < 8,
                    onDecrement: { travelers.children.removeLast() },
                    onIncrement: { travelers.children.append(5) }
                )

                if !travelers.children.isEmpty {
                    Divider().background(AppTheme.border)
                    Text("ALTER DER KINDER BEI REISEANTRITT")
                        .font(.system(size: 10).weight(.medium))
                        .tracking(1.5)
                        .foregroundStyle(AppTheme.textSubtle)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(Array(travelers.children.enumerated()), id: \.offset) { idx, _ in
                                HStack(spacing: 6) {
                                    Text("Kind \(idx + 1)").font(.system(size: 11)).foregroundStyle(AppTheme.textMuted)
                                    Picker("", selection: Binding(
                                        get: { travelers.children[idx] },
                                        set: { travelers.children[idx] = $0 }
                                    )) {
                                        ForEach(0..<18, id: \.self) { age in
                                            Text(age == 0 ? "<1 J" : "\(age) J").tag(age)
                                        }
                                    }
                                    .pickerStyle(.menu)
                                    .tint(AppTheme.text)
                                }
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(Color.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 8))
                                .overlay(RoundedRectangle(cornerRadius: 8).stroke(AppTheme.border, lineWidth: 1))
                            }
                        }
                    }

                    Text("Das Alter wird an Buchungsportale übergeben und beeinflusst Ticketpreise und Zimmertypen.")
                        .font(.system(size: 11))
                        .foregroundStyle(AppTheme.textSubtle)
                        .padding(.top, 4)
                }

                Spacer()
            }
            .padding(20)
            .background(AppTheme.bg)
            .navigationTitle("Reisende")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Fertig") { dismiss() }
                        .foregroundStyle(AppTheme.accent)
                }
            }
            .toolbarBackground(AppTheme.bg, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }

    private func counter(
        label: String,
        sub: String,
        value: Int,
        canDecrement: Bool,
        canIncrement: Bool,
        onDecrement: @escaping () -> Void,
        onIncrement: @escaping () -> Void
    ) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(label).font(.system(size: 15)).foregroundStyle(AppTheme.text)
                Text(sub).font(.system(size: 11)).foregroundStyle(AppTheme.textSubtle)
            }
            Spacer()
            HStack(spacing: 12) {
                counterButton(systemImage: "minus", enabled: canDecrement, action: onDecrement)
                Text("\(value)").font(.system(size: 16, weight: .medium))
                    .foregroundStyle(AppTheme.text).frame(minWidth: 22)
                counterButton(systemImage: "plus", enabled: canIncrement, action: onIncrement)
            }
        }
    }

    private func counterButton(systemImage: String, enabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(enabled ? AppTheme.text : AppTheme.text.opacity(0.2))
                .frame(width: 28, height: 28)
                .background(Color.white.opacity(0.05), in: Circle())
                .overlay(Circle().stroke(AppTheme.border, lineWidth: 1))
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
    }
}

// MARK: - Booking Overview

struct BookingOverview: View {
    let trip: Trip

    private var validSegments: [TripSegment] {
        trip.segments.filter { !$0.from.isEmpty || !$0.to.isEmpty }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: "person.2.fill").font(.system(size: 11))
                Text(trip.travelers.summary).font(.system(size: 12))
            }
            .foregroundStyle(AppTheme.textMuted)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(AppTheme.accent.opacity(0.08), in: Capsule())
            .overlay(Capsule().stroke(AppTheme.accent.opacity(0.2), lineWidth: 1))

            ForEach(validSegments) { segment in
                bookingRow(for: segment)
            }
        }
        .padding(16)
        .background(AppTheme.surface, in: RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(AppTheme.border, lineWidth: 1))
    }

    @ViewBuilder
    private func bookingRow(for segment: TripSegment) -> some View {
        let portals = BookingPortals.portals(for: segment.type)
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: segment.type.systemImage)
                    .font(.system(size: 14))
                    .foregroundStyle(segment.type.color)
                    .frame(width: 20)
                VStack(alignment: .leading, spacing: 2) {
                    Text(routeTitle(segment))
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(AppTheme.text)
                    Text(dateLabel(segment))
                        .font(.system(size: 11))
                        .foregroundStyle(AppTheme.textSubtle)
                }
                Spacer()
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(portals) { portal in
                        if let url = portal.urlBuilder(segment, trip.travelers, trip) {
                            Link(destination: url) {
                                HStack(spacing: 4) {
                                    Text(portal.name)
                                    Image(systemName: "arrow.up.right").font(.system(size: 9))
                                }
                                .font(.system(size: 12))
                                .foregroundStyle(AppTheme.text)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(Color.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 7))
                                .overlay(RoundedRectangle(cornerRadius: 7).stroke(AppTheme.border, lineWidth: 1))
                            }
                        }
                    }
                }
            }
        }
        .padding(12)
        .background(Color.white.opacity(0.02), in: RoundedRectangle(cornerRadius: 10))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(AppTheme.border, lineWidth: 1))
    }

    private func routeTitle(_ s: TripSegment) -> String {
        var parts: [String] = [s.type.label]
        if s.type != .hotel, !s.from.isEmpty { parts.append(s.from) }
        if !s.to.isEmpty {
            parts.append(s.type == .hotel ? s.to : "→ \(s.to)")
        }
        return parts.joined(separator: " · ")
    }

    private func dateLabel(_ s: TripSegment) -> String {
        guard let date = s.date else { return "Datum nicht gesetzt" }
        let f = DateFormatter()
        f.locale = Locale(identifier: "de_DE")
        f.dateFormat = "d. MMMM yyyy"
        return f.string(from: date)
    }
}

// MARK: - Booking Portals

struct BookingPortal: Identifiable {
    let id = UUID()
    let name: String
    /// Trip wird mit übergeben, damit Hotel-URLs aus dem nächsten
    /// Reise-Segment ein korrektes Checkout-Datum ableiten können.
    let urlBuilder: (TripSegment, Travelers, Trip) -> URL?
}

enum BookingPortals {
    /// Booking.com Affiliate-Programm: https://www.booking.com/affiliate-program
    /// Sobald angemeldet hier die AID eintragen und `affiliateAID` an die
    /// Hotel-URLs übergeben — bringt ~25–40 % Provision pro Buchung.
    static var affiliateAID: String? = nil

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.locale = Locale(identifier: "en_US_POSIX")
        return f
    }()

    private static func dateString(_ date: Date?) -> String {
        guard let date else { return "" }
        return dateFormatter.string(from: date)
    }

    private static func encode(_ s: String) -> String {
        s.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? s
    }

    /// Sucht das nächste Reise-Segment NACH der Hotel-Übernachtung und
    /// nutzt dessen Datum als Checkout. Beispiel: Hotel Barcelona ab 1.6.,
    /// nächstes Segment "Mietwagen Barcelona→Valencia" am 4.6. → Checkout = 4.6.
    /// Fallback: checkin + 1 Tag.
    private static func checkoutDate(for hotel: TripSegment, in trip: Trip) -> Date? {
        guard let checkin = hotel.date else { return nil }
        let nextSegmentDate = trip.segments
            .compactMap { seg -> Date? in
                guard seg.id != hotel.id, let d = seg.date, d > checkin else { return nil }
                return d
            }
            .min()
        return nextSegmentDate ?? Calendar.current.date(byAdding: .day, value: 1, to: checkin)
    }

    /// Robustes URL-Building mit URLComponents — erlaubt mehrfache Query-Items
    /// mit gleichem Namen (z.B. `age=8&age=5`) und kümmert sich automatisch
    /// um URL-Encoding von Sonderzeichen wie "München" oder "São Paulo".
    private static func buildURL(base: String, items: [URLQueryItem]) -> URL? {
        var components = URLComponents(string: base)
        components?.queryItems = items.filter { ($0.value ?? "").isEmpty == false }
        return components?.url
    }

    static func portals(for type: TransportType) -> [BookingPortal] {
        switch type {
        case .flight:
            return [
                BookingPortal(name: "Skyscanner") { seg, tr, _ in
                    let d = dateString(seg.date).replacingOccurrences(of: "-", with: "")
                    let urlStr = "https://www.skyscanner.de/transport/flights/\(encode(seg.from))/\(encode(seg.to))/\(d)/?adults=\(tr.adults)&children=\(tr.children.count)"
                    return URL(string: urlStr)
                },
                BookingPortal(name: "Google Flights") { seg, tr, _ in
                    let q = "Flights from \(seg.from) to \(seg.to) on \(dateString(seg.date))"
                    let urlStr = "https://www.google.com/travel/flights?q=\(encode(q))&adults=\(tr.adults)&children=\(tr.children.count)"
                    return URL(string: urlStr)
                },
                BookingPortal(name: "Expedia") { seg, tr, _ in
                    let urlStr = "https://www.expedia.de/Flights-Search?trip=oneway&leg1=from:\(encode(seg.from)),to:\(encode(seg.to)),departure:\(dateString(seg.date))&passengers=adults:\(tr.adults)"
                    return URL(string: urlStr)
                },
            ]
        case .train:
            return [
                BookingPortal(name: "DB Bahn") { seg, _, _ in
                    let urlStr = "https://www.bahn.de/buchung/fahrplan/suche#sts=true&so=\(encode(seg.from))&zo=\(encode(seg.to))"
                    return URL(string: urlStr)
                },
                BookingPortal(name: "Omio") { seg, tr, _ in
                    let urlStr = "https://www.omio.de/trains/\(encode(seg.from))-\(encode(seg.to))?date=\(dateString(seg.date))&adults=\(tr.adults)&children=\(tr.children.count)"
                    return URL(string: urlStr)
                },
            ]
        case .car:
            return [
                BookingPortal(name: "Rentalcars") { seg, _, _ in
                    let urlStr = "https://www.rentalcars.com/de/search/?pickUpPlace=\(encode(seg.from))&puDay=\(dateString(seg.date))"
                    return URL(string: urlStr)
                },
                BookingPortal(name: "Booking.com") { seg, _, _ in
                    let urlStr = "https://www.booking.com/cars/search.de.html?pickup_location=\(encode(seg.from))&pickup_date=\(dateString(seg.date))"
                    return URL(string: urlStr)
                },
            ]
        case .bus:
            return [
                BookingPortal(name: "FlixBus") { seg, tr, _ in
                    let urlStr = "https://global.flixbus.com/bus-tickets/\(encode(seg.from))-\(encode(seg.to))?departureDate=\(dateString(seg.date))&adult=\(tr.adults)&children=\(tr.children.count)"
                    return URL(string: urlStr)
                },
                BookingPortal(name: "Omio") { seg, tr, _ in
                    let urlStr = "https://www.omio.de/buses/\(encode(seg.from))-\(encode(seg.to))?date=\(dateString(seg.date))&adults=\(tr.adults)&children=\(tr.children.count)"
                    return URL(string: urlStr)
                },
            ]
        case .hotel:
            return [
                BookingPortal(name: "Booking.com") { seg, tr, trip in
                    var items: [URLQueryItem] = [
                        URLQueryItem(name: "ss", value: seg.to),
                        URLQueryItem(name: "checkin", value: dateString(seg.date)),
                        URLQueryItem(name: "checkout", value: dateString(checkoutDate(for: seg, in: trip))),
                        URLQueryItem(name: "group_adults", value: "\(tr.adults)"),
                        URLQueryItem(name: "group_children", value: "\(tr.children.count)"),
                        URLQueryItem(name: "no_rooms", value: "1"),
                        URLQueryItem(name: "lang", value: "de"),
                        URLQueryItem(name: "selected_currency", value: "EUR"),
                    ]
                    // Booking erwartet pro Kind ein eigenes `age=<n>`
                    for age in tr.children {
                        items.append(URLQueryItem(name: "age", value: "\(age)"))
                    }
                    if let aid = affiliateAID {
                        items.append(URLQueryItem(name: "aid", value: aid))
                        items.append(URLQueryItem(name: "label", value: "myvoyage-ios"))
                    }
                    return buildURL(base: "https://www.booking.com/searchresults.de.html", items: items)
                },
                BookingPortal(name: "Hotels.com") { seg, tr, trip in
                    var items: [URLQueryItem] = [
                        URLQueryItem(name: "q-destination", value: seg.to),
                        URLQueryItem(name: "q-check-in", value: dateString(seg.date)),
                        URLQueryItem(name: "q-check-out", value: dateString(checkoutDate(for: seg, in: trip))),
                        URLQueryItem(name: "q-rooms", value: "1"),
                        URLQueryItem(name: "q-room-0-adults", value: "\(tr.adults)"),
                        URLQueryItem(name: "q-room-0-children", value: "\(tr.children.count)"),
                        URLQueryItem(name: "locale", value: "de_DE"),
                    ]
                    for (idx, age) in tr.children.enumerated() {
                        items.append(URLQueryItem(name: "q-room-0-child-\(idx)-age", value: "\(age)"))
                    }
                    return buildURL(base: "https://de.hotels.com/search.do", items: items)
                },
                BookingPortal(name: "Expedia") { seg, tr, trip in
                    var items: [URLQueryItem] = [
                        URLQueryItem(name: "destination", value: seg.to),
                        URLQueryItem(name: "startDate", value: dateString(seg.date)),
                        URLQueryItem(name: "endDate", value: dateString(checkoutDate(for: seg, in: trip))),
                        URLQueryItem(name: "adults", value: "\(tr.adults)"),
                        URLQueryItem(name: "children", value: "\(tr.children.count)"),
                        URLQueryItem(name: "rooms", value: "1"),
                    ]
                    for age in tr.children {
                        items.append(URLQueryItem(name: "childAge", value: "\(age)"))
                    }
                    return buildURL(base: "https://www.expedia.de/Hotel-Search", items: items)
                },
            ]
        }
    }
}

// MARK: - Destination Image Service

struct DestinationImage: Equatable, Codable {
    let url: URL
    let attribution: String  // "Wikipedia / <author>"
}

@MainActor
@Observable
final class DestinationImageService {
    static let shared = DestinationImageService()

    private static let persistedCacheURL: URL = {
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return dir.appendingPathComponent("destination_images.json")
    }()

    private var cache: [String: DestinationImage] = [:]
    private var inflight: [String: Task<DestinationImage?, Never>] = [:]

    private init() {
        if let data = try? Data(contentsOf: Self.persistedCacheURL),
           let decoded = try? JSONDecoder().decode([String: DestinationImage].self, from: data) {
            cache = decoded
        }
    }

    private func savePersistedCache() {
        guard let data = try? JSONEncoder().encode(cache) else { return }
        try? data.write(to: Self.persistedCacheURL, options: .atomic)
    }

    /// City (lowercased) → Wikipedia article title (English wiki has the
    /// best image coverage for landmarks). Add more here over time.
    private static let landmarkMap: [String: String] = [
        "barcelona": "Sagrada Família",
        "paris": "Eiffel Tower",
        "london": "Tower Bridge",
        "rom": "Colosseum",
        "rome": "Colosseum",
        "florenz": "Florence Cathedral",
        "venedig": "St Mark's Square",
        "venice": "St Mark's Square",
        "verona": "Verona Arena",
        "mailand": "Milan Cathedral",
        "milan": "Milan Cathedral",
        "neapel": "Mount Vesuvius",
        "naples": "Mount Vesuvius",
        "tokio": "Tokyo Tower",
        "tokyo": "Tokyo Tower",
        "kyoto": "Kinkaku-ji",
        "osaka": "Osaka Castle",
        "new york": "Statue of Liberty",
        "münchen": "Frauenkirche, Munich",
        "munich": "Frauenkirche, Munich",
        "berlin": "Brandenburg Gate",
        "hamburg": "Elbphilharmonie",
        "frankfurt": "Frankfurt Skyline",
        "madrid": "Royal Palace of Madrid",
        "valencia": "City of Arts and Sciences",
        "amsterdam": "Anne Frank House",
        "istanbul": "Hagia Sophia",
        "dubai": "Burj Khalifa",
        "bangkok": "Wat Arun",
        "rio": "Christ the Redeemer",
        "rio de janeiro": "Christ the Redeemer",
        "vegas": "Las Vegas Strip",
        "las vegas": "Las Vegas Strip",
        "san francisco": "Golden Gate Bridge",
        "lisbon": "Belém Tower",
        "lissabon": "Belém Tower",
        "athens": "Parthenon",
        "athen": "Parthenon",
        "prag": "Charles Bridge",
        "prague": "Charles Bridge",
        "wien": "Schönbrunn Palace",
        "vienna": "Schönbrunn Palace",
    ]

    func image(for destination: String) async -> DestinationImage? {
        let key = destination.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        guard !key.isEmpty else { return nil }

        if let cached = cache[key] { return cached }
        if let task = inflight[key] { return await task.value }

        let task = Task<DestinationImage?, Never> { [weak self] in
            guard let self else { return nil }
            let title = Self.landmarkMap[key] ?? destination
            if let primary = await self.fetchWikipedia(title: title) {
                return primary
            }
            if title != destination {
                return await self.fetchWikipedia(title: destination)
            }
            return nil
        }
        inflight[key] = task
        let result = await task.value
        inflight[key] = nil
        // Only cache successful lookups so transient network failures
        // (e.g. on cold start before Wi-Fi is up) don't permanently
        // poison the destination.
        if let result {
            cache[key] = result
            savePersistedCache()
        }
        return result
    }

    private nonisolated func fetchWikipedia(title: String) async -> DestinationImage? {
        let normalized = title.replacingOccurrences(of: " ", with: "_")
        guard let encoded = normalized.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed),
              let url = URL(string: "https://en.wikipedia.org/api/rest_v1/page/summary/\(encoded)")
        else { return nil }

        var request = URLRequest(url: url)
        request.setValue("MyVoyage iOS prototype (https://github.com/Hoepker/MyVoyage)", forHTTPHeaderField: "User-Agent")

        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else { return nil }

            let imageDict = (json["originalimage"] as? [String: Any]) ?? (json["thumbnail"] as? [String: Any])
            guard let source = imageDict?["source"] as? String,
                  let imageURL = URL(string: source) else { return nil }

            let pageTitle = (json["title"] as? String) ?? title
            return DestinationImage(url: imageURL, attribution: "Wikipedia · \(pageTitle)")
        } catch {
            return nil
        }
    }
}

// MARK: - Destination Image View

struct DestinationImageView<Fallback: View>: View {
    let destination: String
    let contentMode: ContentMode
    let fallback: () -> Fallback

    @State private var image: DestinationImage?

    init(
        destination: String,
        contentMode: ContentMode = .fill,
        @ViewBuilder fallback: @escaping () -> Fallback
    ) {
        self.destination = destination
        self.contentMode = contentMode
        self.fallback = fallback
    }

    var body: some View {
        // Color.clear acts as the size anchor; whatever frame the parent
        // proposes is what this view occupies. The AsyncImage in the
        // overlay is forced inside those bounds — without this anchor
        // an .aspectRatio(.fill) image would otherwise dictate the size
        // upward and inflate the surrounding tile when it finally loads.
        Color.clear
            .overlay {
                Group {
                    if let image {
                        AsyncImage(
                            url: image.url,
                            transaction: Transaction(animation: .easeInOut(duration: 0.35))
                        ) { phase in
                            switch phase {
                            case .success(let img):
                                img.resizable().aspectRatio(contentMode: contentMode)
                            case .failure:
                                fallback()
                            case .empty:
                                fallback()
                            @unknown default:
                                fallback()
                            }
                        }
                    } else {
                        fallback()
                    }
                }
            }
            .clipped()
            .task(id: destination) {
                guard !destination.isEmpty else { image = nil; return }
                image = await DestinationImageService.shared.image(for: destination)
            }
    }
}

// MARK: - Hotel Metadata Service

/// Holt Open-Graph-Tags aus einer Hotel-URL (Booking.com, Hotels.com, Airbnb …)
/// und liefert Titel / Bild-URL / Beschreibung. Funktioniert weil alle großen
/// Portale OG-Tags für Link-Previews ausspielen. Preis ist über OG nicht
/// abrufbar — den gibt der User manuell ein.
struct HotelMetadata: Equatable {
    let title: String?
    let imageURL: URL?
    let subtitle: String?
}

enum HotelMetadataService {
    static func fetch(url: URL) async -> HotelMetadata? {
        var request = URLRequest(url: url)
        // Safari-iOS-User-Agent reduziert die Wahrscheinlichkeit, dass
        // Portale uns als Bot blocken. Booking.com setzt AWS WAF und
        // blockt trotzdem; Hotels.com und Expedia rendern OG-Tags erst
        // per JS — in diesen Fällen kommt nichts zurück und der User
        // füllt die Felder im Sheet manuell aus.
        request.setValue(
            "Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1",
            forHTTPHeaderField: "User-Agent"
        )
        request.setValue("text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8", forHTTPHeaderField: "Accept")
        request.setValue("de-DE,de;q=0.9,en;q=0.8", forHTTPHeaderField: "Accept-Language")
        request.timeoutInterval = 12

        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            guard let html = String(data: data, encoding: .utf8) else { return nil }
            let title = extractOG(property: "title", in: html) ?? extractTitle(in: html)
            let imageStr = extractOG(property: "image", in: html)
            let imageURL = imageStr.flatMap { URL(string: $0) }
            let description = extractOG(property: "description", in: html)
            return HotelMetadata(title: title, imageURL: imageURL, subtitle: description)
        } catch {
            return nil
        }
    }

    private static func extractOG(property: String, in html: String) -> String? {
        let patterns = [
            #"<meta[^>]+property=["']og:\#(property)["'][^>]+content=["']([^"']+)["']"#,
            #"<meta[^>]+content=["']([^"']+)["'][^>]+property=["']og:\#(property)["']"#,
        ]
        for pattern in patterns {
            guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else { continue }
            let range = NSRange(html.startIndex..., in: html)
            if let match = regex.firstMatch(in: html, range: range),
               match.numberOfRanges > 1,
               let captureRange = Range(match.range(at: 1), in: html) {
                return String(html[captureRange]).htmlDecoded
            }
        }
        return nil
    }

    private static func extractTitle(in html: String) -> String? {
        let pattern = #"<title[^>]*>([^<]+)</title>"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else { return nil }
        let range = NSRange(html.startIndex..., in: html)
        if let match = regex.firstMatch(in: html, range: range),
           match.numberOfRanges > 1,
           let captureRange = Range(match.range(at: 1), in: html) {
            return String(html[captureRange]).htmlDecoded
        }
        return nil
    }
}

private extension String {
    var htmlDecoded: String {
        self
            .replacingOccurrences(of: "&amp;", with: "&")
            .replacingOccurrences(of: "&lt;", with: "<")
            .replacingOccurrences(of: "&gt;", with: ">")
            .replacingOccurrences(of: "&quot;", with: "\"")
            .replacingOccurrences(of: "&#039;", with: "'")
            .replacingOccurrences(of: "&apos;", with: "'")
            .replacingOccurrences(of: "&nbsp;", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

// MARK: - Trip Wizard

enum TripStyle: String, CaseIterable {
    case singleStop, roundtrip
    var label: String {
        switch self {
        case .singleStop: "Eine Stadt entdecken"
        case .roundtrip:  "Mehrere Orte besuchen"
        }
    }
    var sub: String {
        switch self {
        case .singleStop: "Standort, Tagesausflüge, kein Umzug"
        case .roundtrip:  "Rundreise mit mehreren Stops"
        }
    }
    var icon: String {
        switch self {
        case .singleStop: "mappin.and.ellipse"
        case .roundtrip:  "map.fill"
        }
    }
}

enum AccommodationStyle: String, CaseIterable {
    case hotel, apartment, both, later
    var label: String {
        switch self {
        case .hotel:     "Hotel"
        case .apartment: "Ferienwohnung"
        case .both:      "Beides"
        case .later:     "Entscheide ich später"
        }
    }
    var icon: String {
        switch self {
        case .hotel:     "bed.double.fill"
        case .apartment: "house.fill"
        case .both:      "square.grid.2x2.fill"
        case .later:     "clock.fill"
        }
    }
}

@Observable
final class WizardData {
    var destinations: [String] = [""]
    var startDate: Date? = nil
    var endDate: Date? = nil
    var travelers: Travelers = Travelers(adults: 2, children: [])
    var style: TripStyle = .singleStop
    var transportTo: TransportType? = nil
    var transportBetween: TransportType? = nil
    var accommodation: AccommodationStyle? = nil

    var primaryDestination: String {
        destinations.first(where: { !$0.isEmpty }) ?? ""
    }

    var validDestinations: [String] {
        destinations.filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
    }

    func canContinue(from step: WizardStep) -> Bool {
        switch step {
        case .where_:        return !primaryDestination.isEmpty
        case .when_:         return true
        case .who:           return true
        case .style:         return true
        case .moreDestinations: return validDestinations.count >= 2
        case .transport:     return transportTo != nil && (style == .singleStop || transportBetween != nil)
        case .accommodation: return accommodation != nil
        case .summary:       return true
        }
    }
}

enum WizardStep: Int, CaseIterable {
    case where_, when_, who, style, moreDestinations, transport, accommodation, summary

    var titleNumber: Int {
        WizardStep.allCases.firstIndex(of: self).map { $0 + 1 } ?? 0
    }

    var accent: Color {
        switch self {
        case .where_:           Color(hex: 0x3B82F6)
        case .when_:            Color(hex: 0x10B981)
        case .who:              Color(hex: 0x8B5CF6)
        case .style:            Color(hex: 0xF59E0B)
        case .moreDestinations: Color(hex: 0x06B6D4)
        case .transport:        Color(hex: 0xEC4899)
        case .accommodation:    Color(hex: 0xF97316)
        case .summary:          Color(hex: 0x10B981)
        }
    }
}

struct TripWizardView: View {
    let store: TripsStore
    @Binding var pushTrip: Trip?
    @Environment(\.dismiss) private var dismiss

    @State private var data = WizardData()
    @State private var currentIndex = 0
    @State private var goingForward = true

    private var visibleSteps: [WizardStep] {
        WizardStep.allCases.filter { step in
            if step == .moreDestinations { return data.style == .roundtrip }
            return true
        }
    }

    private var currentStep: WizardStep {
        visibleSteps[min(currentIndex, visibleSteps.count - 1)]
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    progressBar

                    Group {
                        switch currentStep {
                        case .where_:           WhereStepView(data: data)
                        case .when_:            WhenStepView(data: data)
                        case .who:              WhoStepView(data: data)
                        case .style:            StyleStepView(data: data)
                        case .moreDestinations: MoreDestinationsStepView(data: data)
                        case .transport:        TransportStepView(data: data)
                        case .accommodation:    AccommodationStepView(data: data)
                        case .summary:          SummaryStepView(data: data)
                        }
                    }
                    .id(currentStep)
                    .transition(.opacity)
                }
                .padding()
            }
            .background(AppTheme.bg)
            .navigationTitle("Schritt \(currentIndex + 1) von \(visibleSteps.count)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(AppTheme.bg, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") { dismiss() }
                }
                ToolbarItem(placement: .bottomBar) {
                    HStack {
                        if currentIndex > 0 {
                            Button {
                                goingForward = false
                                withAnimation { currentIndex -= 1 }
                            } label: {
                                Label("Zurück", systemImage: "chevron.left")
                            }
                        }
                        Spacer()
                        Button {
                            advance()
                        } label: {
                            HStack(spacing: 4) {
                                Text(currentStep == .summary ? "Reise erstellen" : "Weiter")
                                Image(systemName: currentStep == .summary ? "sparkles" : "chevron.right")
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(currentStep.accent)
                        .disabled(!data.canContinue(from: currentStep))
                    }
                }
            }
            .toolbar(.visible, for: .bottomBar)
            .toolbarBackground(.visible, for: .bottomBar)
        }
        .preferredColorScheme(.dark)
    }

    private var progressBar: some View {
        HStack(spacing: 4) {
            ForEach(0..<visibleSteps.count, id: \.self) { i in
                Capsule()
                    .fill(i <= currentIndex ? currentStep.accent : Color.gray.opacity(0.25))
                    .frame(height: 4)
            }
        }
        .frame(maxWidth: .infinity)
        .animation(.spring(response: 0.4, dampingFraction: 0.85), value: currentIndex)
    }

    private func advance() {
        if currentStep == .summary {
            finish()
            return
        }
        goingForward = true
        withAnimation(.spring(response: 0.45, dampingFraction: 0.82)) {
            currentIndex = min(currentIndex + 1, visibleSteps.count - 1)
        }
    }

    private func finish() {
        let trip = TripBuilder.build(from: data)
        store.add(trip)
        pushTrip = trip
        dismiss()
    }
}

// MARK: - Wizard Step Hero

private struct WizardHero: View {
    let icon: String
    let accent: Color
    let title: String
    let subtitle: String

    @State private var animate = false

    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle().fill(accent.opacity(0.15)).frame(width: 110, height: 110)
                Circle().stroke(accent.opacity(0.4), lineWidth: 1.5).frame(width: 130, height: 130)
                Image(systemName: icon)
                    .font(.system(size: 44, weight: .light))
                    .foregroundStyle(accent)
            }
            .scaleEffect(animate ? 1 : 0.6)
            .opacity(animate ? 1 : 0)
            .animation(.spring(response: 0.55, dampingFraction: 0.7), value: animate)
            .onAppear { animate = true }

            Text(title)
                .font(.system(.title, design: .serif).weight(.bold))
                .foregroundStyle(AppTheme.text)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            Text(subtitle)
                .font(.system(size: 14))
                .foregroundStyle(AppTheme.textMuted)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 8)
        .padding(.bottom, 18)
    }
}

// MARK: - Wizard: Where

private struct WhereStepView: View {
    @Bindable var data: WizardData
    private let suggestions = ["Paris", "Rom", "Barcelona", "London", "New York", "Tokio", "Lissabon", "Wien"]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            WizardHero(
                icon: "globe.europe.africa.fill",
                accent: WizardStep.where_.accent,
                title: "Wohin geht es?",
                subtitle: "Dein Hauptziel — die Stadt oder Region, um die sich die Reise dreht."
            )

            TextField("z.B. Barcelona", text: Binding(
                get: { data.destinations.first ?? "" },
                set: {
                    if data.destinations.isEmpty { data.destinations = [$0] }
                    else { data.destinations[0] = $0 }
                }
            ))
                .textFieldStyle(.roundedBorder)
                .font(.title3)
                .submitLabel(.done)

            VStack(alignment: .leading, spacing: 8) {
                Text("BELIEBTE ZIELE")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                FlexibleChips(items: suggestions, selected: data.destinations.first ?? "") { city in
                    if data.destinations.isEmpty { data.destinations = [city] }
                    else { data.destinations[0] = city }
                }
            }
        }
    }
}

// MARK: - Wizard: When

private struct WhenStepView: View {
    @Bindable var data: WizardData

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            WizardHero(
                icon: "calendar",
                accent: WizardStep.when_.accent,
                title: "Wann möchtest du reisen?",
                subtitle: "Reisezeit eingrenzen — du kannst es später jederzeit anpassen."
            )

            VStack(alignment: .leading, spacing: 10) {
                Text("ABREISE")
                    .font(.system(size: 10, weight: .medium)).tracking(1.5)
                    .foregroundStyle(AppTheme.textSubtle)
                DatePicker("", selection: Binding(
                    get: { data.startDate ?? Date() },
                    set: { data.startDate = $0 }
                ), in: Date()..., displayedComponents: .date)
                    .datePickerStyle(.compact).labelsHidden()
                    .colorScheme(.dark).tint(WizardStep.when_.accent)
            }
            .padding(14)
            .background(Color.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(AppTheme.border, lineWidth: 1))

            VStack(alignment: .leading, spacing: 10) {
                Text("RÜCKKEHR")
                    .font(.system(size: 10, weight: .medium)).tracking(1.5)
                    .foregroundStyle(AppTheme.textSubtle)
                DatePicker("", selection: Binding(
                    get: { data.endDate ?? data.startDate ?? Date() },
                    set: { data.endDate = $0 }
                ), in: (data.startDate ?? Date())..., displayedComponents: .date)
                    .datePickerStyle(.compact).labelsHidden()
                    .colorScheme(.dark).tint(WizardStep.when_.accent)
            }
            .padding(14)
            .background(Color.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(AppTheme.border, lineWidth: 1))

            HStack(spacing: 8) {
                quickRange("Wochenende", days: 3)
                quickRange("1 Woche", days: 7)
                quickRange("2 Wochen", days: 14)
            }
            .padding(.top, 4)

            Button {
                data.startDate = nil
                data.endDate = nil
            } label: {
                Text("Datum noch flexibel")
                    .font(.system(size: 12))
                    .foregroundStyle(AppTheme.textSubtle)
                    .underline()
            }
            .padding(.top, 4)
        }
    }

    private func quickRange(_ label: String, days: Int) -> some View {
        Button {
            let start = data.startDate ?? Date()
            data.startDate = start
            data.endDate = Calendar.current.date(byAdding: .day, value: days, to: start)
        } label: {
            Text(label)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(AppTheme.text)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.white.opacity(0.06), in: Capsule())
                .overlay(Capsule().stroke(WizardStep.when_.accent.opacity(0.4), lineWidth: 1))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Wizard: Who

private struct WhoStepView: View {
    @Bindable var data: WizardData

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            WizardHero(
                icon: "person.2.fill",
                accent: WizardStep.who.accent,
                title: "Wer reist mit?",
                subtitle: "Damit Buchungsportale gleich die richtige Anzahl an Tickets vorschlagen."
            )

            counterRow(
                title: "Erwachsene",
                sub: "Ab 12 Jahren",
                value: data.travelers.adults,
                canDec: data.travelers.adults > 1,
                canInc: data.travelers.adults < 9,
                onDec: { data.travelers.adults -= 1 },
                onInc: { data.travelers.adults += 1 }
            )
            counterRow(
                title: "Kinder",
                sub: "Bis 11 Jahre",
                value: data.travelers.children.count,
                canDec: !data.travelers.children.isEmpty,
                canInc: data.travelers.children.count < 8,
                onDec: { data.travelers.children.removeLast() },
                onInc: { data.travelers.children.append(5) }
            )
        }
    }

    private func counterRow(
        title: String, sub: String, value: Int,
        canDec: Bool, canInc: Bool,
        onDec: @escaping () -> Void, onInc: @escaping () -> Void
    ) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.system(size: 16, weight: .medium)).foregroundStyle(AppTheme.text)
                Text(sub).font(.system(size: 11)).foregroundStyle(AppTheme.textSubtle)
            }
            Spacer()
            HStack(spacing: 14) {
                circleBtn(systemName: "minus", enabled: canDec, action: onDec)
                Text("\(value)")
                    .font(.system(size: 20, weight: .semibold, design: .serif))
                    .foregroundStyle(AppTheme.text).frame(minWidth: 28)
                circleBtn(systemName: "plus", enabled: canInc, action: onInc)
            }
        }
        .padding(16)
        .background(Color.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(AppTheme.border, lineWidth: 1))
    }

    private func circleBtn(systemName: String, enabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(enabled ? AppTheme.text : AppTheme.text.opacity(0.2))
                .frame(width: 34, height: 34)
                .background(Color.white.opacity(0.06), in: Circle())
                .overlay(Circle().stroke(WizardStep.who.accent.opacity(enabled ? 0.45 : 0.12), lineWidth: 1))
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
    }
}

// MARK: - Wizard: Style

private struct StyleStepView: View {
    @Bindable var data: WizardData

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            WizardHero(
                icon: "map.fill",
                accent: WizardStep.style.accent,
                title: "Wie soll deine Reise aussehen?",
                subtitle: "Bestimmst, ob wir nur einen Aufenthalt oder mehrere Stops planen."
            )
            ForEach(TripStyle.allCases, id: \.self) { style in
                styleCard(style)
            }
        }
    }

    private func styleCard(_ style: TripStyle) -> some View {
        let selected = data.style == style
        return Button {
            data.style = style
        } label: {
            HStack(spacing: 14) {
                Image(systemName: style.icon)
                    .font(.system(size: 22, weight: .light))
                    .foregroundStyle(selected ? .white : WizardStep.style.accent)
                    .frame(width: 50, height: 50)
                    .background(selected ? WizardStep.style.accent : WizardStep.style.accent.opacity(0.15), in: Circle())
                VStack(alignment: .leading, spacing: 3) {
                    Text(style.label)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(AppTheme.text)
                    Text(style.sub)
                        .font(.system(size: 12))
                        .foregroundStyle(AppTheme.textMuted)
                }
                Spacer()
                if selected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(WizardStep.style.accent)
                }
            }
            .padding(16)
            .background(Color.white.opacity(selected ? 0.07 : 0.04), in: RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(selected ? WizardStep.style.accent : AppTheme.border, lineWidth: selected ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Wizard: More Destinations

private struct MoreDestinationsStepView: View {
    @Bindable var data: WizardData

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            WizardHero(
                icon: "list.bullet.indent",
                accent: WizardStep.moreDestinations.accent,
                title: "Welche weiteren Stops?",
                subtitle: "Reihenfolge entspricht der Reise-Route. Mindestens zwei Ziele."
            )

            VStack(spacing: 8) {
                ForEach(Array(data.destinations.enumerated()), id: \.offset) { idx, _ in
                    HStack(spacing: 10) {
                        Text("\(idx + 1)")
                            .font(.system(size: 12, weight: .bold, design: .serif))
                            .foregroundStyle(WizardStep.moreDestinations.accent)
                            .frame(width: 26, height: 26)
                            .background(WizardStep.moreDestinations.accent.opacity(0.15), in: Circle())
                        TextField("", text: Binding(
                            get: { data.destinations[idx] },
                            set: { data.destinations[idx] = $0 }
                        ), prompt: Text(idx == 0 ? "Erstes Ziel" : "Nächster Stop")
                            .foregroundStyle(AppTheme.text.opacity(0.25)))
                            .font(.system(size: 15))
                            .foregroundStyle(AppTheme.text)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 10)
                            .background(Color.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 8))
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(AppTheme.border, lineWidth: 1))
                        if data.destinations.count > 1 {
                            Button(role: .destructive) {
                                data.destinations.remove(at: idx)
                            } label: {
                                Image(systemName: "minus.circle.fill")
                                    .foregroundStyle(.red.opacity(0.7))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }

            Button {
                data.destinations.append("")
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "plus")
                    Text("Weiteres Ziel hinzufügen")
                }
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(WizardStep.moreDestinations.accent)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(WizardStep.moreDestinations.accent.opacity(0.1), in: Capsule())
                .overlay(Capsule().stroke(WizardStep.moreDestinations.accent.opacity(0.4), lineWidth: 1))
            }
            .buttonStyle(.plain)
        }
    }
}

// MARK: - Wizard: Transport

private struct TransportStepView: View {
    @Bindable var data: WizardData

    private let toOptions: [TransportType] = [.flight, .train, .car, .bus]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            WizardHero(
                icon: "airplane.departure",
                accent: WizardStep.transport.accent,
                title: "Wie kommst du hin?",
                subtitle: "Erste Etappe — von zu Hause zum ersten Ziel."
            )

            transportGrid(selected: data.transportTo) { picked in
                data.transportTo = picked
            }

            if data.style == .roundtrip {
                Text("ZWISCHEN DEN STOPS")
                    .font(.system(size: 10, weight: .medium)).tracking(1.5)
                    .foregroundStyle(AppTheme.textSubtle)
                    .padding(.top, 8)
                transportGrid(selected: data.transportBetween) { picked in
                    data.transportBetween = picked
                }
            }
        }
    }

    private func transportGrid(selected: TransportType?, onSelect: @escaping (TransportType) -> Void) -> some View {
        let columns = [GridItem(.adaptive(minimum: 130), spacing: 10)]
        return LazyVGrid(columns: columns, spacing: 10) {
            ForEach(toOptions) { type in
                let isSel = selected == type
                Button { onSelect(type) } label: {
                    VStack(spacing: 6) {
                        Image(systemName: type.systemImage)
                            .font(.system(size: 22, weight: .light))
                            .foregroundStyle(isSel ? .white : type.color)
                        Text(type.label)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(AppTheme.text)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(isSel ? type.color.opacity(0.4) : Color.white.opacity(0.04),
                                in: RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSel ? type.color : AppTheme.border, lineWidth: isSel ? 2 : 1)
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }
}

// MARK: - Wizard: Accommodation

private struct AccommodationStepView: View {
    @Bindable var data: WizardData

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            WizardHero(
                icon: "bed.double.fill",
                accent: WizardStep.accommodation.accent,
                title: "Wo übernachtest du?",
                subtitle: "Wir legen dir pro Stadt einen Eintrag an — Details ergänzt du später."
            )
            ForEach(AccommodationStyle.allCases, id: \.self) { opt in
                let sel = data.accommodation == opt
                Button {
                    data.accommodation = opt
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: opt.icon)
                            .font(.system(size: 18, weight: .light))
                            .foregroundStyle(sel ? .white : WizardStep.accommodation.accent)
                            .frame(width: 42, height: 42)
                            .background(sel ? WizardStep.accommodation.accent : WizardStep.accommodation.accent.opacity(0.14), in: Circle())
                        Text(opt.label)
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(AppTheme.text)
                        Spacer()
                        if sel { Image(systemName: "checkmark.circle.fill").foregroundStyle(WizardStep.accommodation.accent) }
                    }
                    .padding(14)
                    .background(Color.white.opacity(sel ? 0.07 : 0.04), in: RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(sel ? WizardStep.accommodation.accent : AppTheme.border, lineWidth: sel ? 2 : 1)
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }
}

// MARK: - Wizard: Summary

private struct SummaryStepView: View {
    @Bindable var data: WizardData

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            WizardHero(
                icon: "sparkles",
                accent: WizardStep.summary.accent,
                title: "Bereit?",
                subtitle: "Wir bauen dir das Gerüst deiner Reise — Details kannst du danach ergänzen."
            )

            VStack(alignment: .leading, spacing: 8) {
                summaryRow("globe.europe.africa.fill", "Ziele",
                           data.validDestinations.isEmpty ? "—" : data.validDestinations.joined(separator: " · "))
                summaryRow("calendar", "Zeitraum", dateLabel)
                summaryRow("person.2.fill", "Reisende", data.travelers.summary)
                summaryRow(data.style.icon, "Stil", data.style.label)
                summaryRow("airplane",
                           "Anreise",
                           data.transportTo.map { $0.label } ?? "—")
                if data.style == .roundtrip {
                    summaryRow("arrow.triangle.swap", "Zwischen Stops",
                               data.transportBetween.map { $0.label } ?? "—")
                }
                summaryRow("bed.double.fill", "Übernachtung",
                           data.accommodation?.label ?? "—")
            }
            .padding(14)
            .background(Color.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(AppTheme.border, lineWidth: 1))
        }
    }

    private var dateLabel: String {
        guard let s = data.startDate else { return "Flexibel" }
        let f = DateFormatter()
        f.locale = Locale(identifier: "de_DE")
        f.dateFormat = "d. MMM yyyy"
        if let e = data.endDate, e != s {
            return "\(f.string(from: s)) – \(f.string(from: e))"
        }
        return f.string(from: s)
    }

    private func summaryRow(_ icon: String, _ label: String, _ value: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 13))
                .foregroundStyle(WizardStep.summary.accent)
                .frame(width: 22)
            VStack(alignment: .leading, spacing: 2) {
                Text(label.uppercased())
                    .font(.system(size: 9, weight: .medium)).tracking(1.2)
                    .foregroundStyle(AppTheme.textSubtle)
                Text(value).font(.system(size: 14)).foregroundStyle(AppTheme.text)
            }
            Spacer()
        }
    }
}

// MARK: - Flexible Chips

private struct FlexibleChips: View {
    let items: [String]
    let selected: String
    let onTap: (String) -> Void

    var body: some View {
        FlowLayout(spacing: 8) {
            ForEach(items, id: \.self) { item in
                let sel = item == selected
                Button { onTap(item) } label: {
                    Text(item)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(sel ? .white : AppTheme.text)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(sel ? WizardStep.where_.accent : Color.white.opacity(0.05), in: Capsule())
                        .overlay(Capsule().stroke(sel ? Color.clear : AppTheme.border, lineWidth: 1))
                }
                .buttonStyle(.plain)
            }
        }
    }
}

private struct FlowLayout: Layout {
    var spacing: CGFloat = 6

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        // Fall back to a sane width when the parent doesn't propose one
        // (e.g. inside an unconstrained ScrollView). Without this the
        // layout reported its full unwrapped intrinsic width and pushed
        // every ancestor wider than the screen.
        let maxWidth: CGFloat = {
            if let w = proposal.width, w > 0 { return w }
            return 320
        }()
        var x: CGFloat = 0, y: CGFloat = 0, lineH: CGFloat = 0
        for s in subviews {
            let size = s.sizeThatFits(.unspecified)
            if x + size.width > maxWidth, x > 0 {
                x = 0; y += lineH + spacing; lineH = 0
            }
            x += size.width + spacing
            lineH = max(lineH, size.height)
        }
        return CGSize(width: maxWidth, height: y + lineH)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x: CGFloat = bounds.minX, y: CGFloat = bounds.minY, lineH: CGFloat = 0
        for s in subviews {
            let size = s.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX {
                x = bounds.minX; y += lineH + spacing; lineH = 0
            }
            s.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            lineH = max(lineH, size.height)
        }
    }
}

// MARK: - Trip Builder

enum TripBuilder {
    static func build(from data: WizardData) -> Trip {
        let dests = data.validDestinations.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        let cal = Calendar.current
        let totalDays: Int = {
            guard let s = data.startDate, let e = data.endDate else { return 7 }
            return max(1, cal.dateComponents([.day], from: s, to: e).day ?? 7)
        }()
        let perStop = max(1, totalDays / max(1, dests.count))
        let baseDate = data.startDate ?? Date()

        var segments: [TripSegment] = []

        if let mode = data.transportTo, let first = dests.first {
            segments.append(TripSegment(type: mode, from: "", to: first, date: baseDate))
        }

        for (idx, dest) in dests.enumerated() {
            let arrival = cal.date(byAdding: .day, value: idx * perStop, to: baseDate) ?? baseDate

            if data.accommodation != .later {
                segments.append(TripSegment(type: .hotel, from: "", to: dest, date: arrival))
            }
            if data.style == .roundtrip,
               idx < dests.count - 1,
               let between = data.transportBetween {
                let next = dests[idx + 1]
                let depart = cal.date(byAdding: .day, value: (idx + 1) * perStop, to: baseDate) ?? arrival
                segments.append(TripSegment(type: between, from: dest, to: next, date: depart))
            }
        }

        if let mode = data.transportTo, let last = dests.last {
            let returnDate = data.endDate ?? cal.date(byAdding: .day, value: totalDays, to: baseDate)
            segments.append(TripSegment(type: mode, from: last, to: "", date: returnDate))
        }

        let primary = (dests.first ?? "Neue Reise").trimmingCharacters(in: .whitespacesAndNewlines)
        let f = DateFormatter()
        f.locale = Locale(identifier: "de_DE")
        f.dateFormat = "MMMM yyyy"
        let monthLabel = data.startDate.map { f.string(from: $0) } ?? ""
        let name = monthLabel.isEmpty ? primary : "\(primary) · \(monthLabel)"

        return Trip(name: name, travelers: data.travelers, segments: segments)
    }
}

// MARK: - Hotel Candidates UI

/// Liste der gemerkten Hotel-Vorschläge unter einer Hotel-Etappe.
/// Klick auf eine Zeile öffnet das Edit-Sheet, "+ Hotel hinzufügen" öffnet
/// das Add-Sheet mit URL-Paste-Flow.
struct HotelCandidatesSection: View {
    let segment: TripSegment
    let onChange: (TripSegment) -> Void

    @State private var showAddSheet = false
    @State private var editingCandidate: HotelCandidate? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: "bed.double.fill")
                    .font(.system(size: 11))
                Text("HOTEL-VORSCHLÄGE\(segment.hotelCandidates.isEmpty ? "" : " (\(segment.hotelCandidates.count))")")
                    .font(.system(size: 9, weight: .medium))
                    .tracking(1.2)
                Spacer()
            }
            .foregroundStyle(AppTheme.textSubtle)

            ForEach(segment.hotelCandidates) { candidate in
                Button {
                    editingCandidate = candidate
                } label: {
                    HotelCandidateRow(candidate: candidate)
                }
                .buttonStyle(.plain)
            }

            Button {
                showAddSheet = true
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "plus")
                    Text(segment.hotelCandidates.isEmpty ? "Hotel hinzufügen" : "Weiteres Hotel hinzufügen")
                }
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(AppTheme.accent)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(AppTheme.accent.opacity(0.1), in: Capsule())
                .overlay(Capsule().stroke(AppTheme.accent.opacity(0.3), lineWidth: 1))
            }
            .buttonStyle(.plain)
        }
        .sheet(isPresented: $showAddSheet) {
            HotelEditorSheet(initial: nil) { newCandidate in
                var s = segment
                s.hotelCandidates.append(newCandidate)
                onChange(s)
            }
        }
        .sheet(item: $editingCandidate) { candidate in
            HotelEditorSheet(initial: candidate) { updated in
                var s = segment
                if let idx = s.hotelCandidates.firstIndex(where: { $0.id == updated.id }) {
                    s.hotelCandidates[idx] = updated
                }
                onChange(s)
            } onDelete: {
                var s = segment
                s.hotelCandidates.removeAll { $0.id == candidate.id }
                onChange(s)
            }
        }
    }
}

struct HotelCandidateRow: View {
    let candidate: HotelCandidate

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            // Thumbnail
            Group {
                if let url = candidate.imageURL {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let img):
                            img.resizable().aspectRatio(contentMode: .fill)
                        default:
                            placeholderThumbnail
                        }
                    }
                } else {
                    placeholderThumbnail
                }
            }
            .frame(width: 60, height: 60)
            .clipShape(RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 3) {
                Text(candidate.name)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(AppTheme.text)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)

                HStack(spacing: 6) {
                    if let stars = candidate.stars, stars > 0 {
                        Text(String(repeating: "★", count: stars))
                            .font(.system(size: 10))
                            .foregroundStyle(.yellow)
                    }
                    if let price = candidate.pricePerNight {
                        Text("\(Int(price)) €/Nacht")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(AppTheme.text)
                    }
                }

                HStack(spacing: 4) {
                    Image(systemName: candidate.status.icon).font(.system(size: 9))
                    Text(candidate.status.label).font(.system(size: 10, weight: .medium))
                    if candidate.status == .confirmed || candidate.status == .booked,
                       let ref = candidate.bookingReference, !ref.isEmpty {
                        Text("·").foregroundStyle(AppTheme.textSubtle)
                        Text(ref).font(.system(size: 10))
                            .foregroundStyle(AppTheme.textMuted)
                    }
                }
                .foregroundStyle(candidate.status.color)
                .padding(.top, 1)
            }

            Spacer(minLength: 0)
        }
        .padding(8)
        .background(Color.white.opacity(0.03), in: RoundedRectangle(cornerRadius: 10))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(AppTheme.border, lineWidth: 1))
    }

    private var placeholderThumbnail: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(AppTheme.accent.opacity(0.15))
            .overlay(
                Image(systemName: "bed.double.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(AppTheme.accent.opacity(0.6))
            )
    }
}

// MARK: - Hotel Editor Sheet

struct HotelEditorSheet: View {
    let initial: HotelCandidate?
    let onSave: (HotelCandidate) -> Void
    var onDelete: (() -> Void)? = nil

    @Environment(\.dismiss) private var dismiss

    @State private var name: String = ""
    @State private var urlString: String = ""
    @State private var imageURLString: String = ""
    @State private var subtitle: String = ""
    @State private var pricePerNight: String = ""
    @State private var stars: Int = 0
    @State private var notes: String = ""
    @State private var status: HotelStatus = .considered
    @State private var bookingReference: String = ""

    @State private var isFetching = false
    @State private var fetchError: String?

    private var isEditing: Bool { initial != nil }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    // Großer Apple-PasteButton als ganze Zeile — kein
                    // iOS-Privacy-Dialog, weil der User durch den Tap selbst
                    // zustimmt. labelStyle(.titleAndIcon) bringt Text + Icon
                    // statt nur das Symbol.
                    PasteButton(payloadType: String.self) { strings in
                        guard let pasted = strings.first else { return }
                        let trimmed = pasted.trimmingCharacters(in: .whitespacesAndNewlines)
                        urlString = trimmed
                        Task { await fetchMetadata() }
                    }
                    .labelStyle(.titleAndIcon)
                    .buttonBorderShape(.capsule)
                    .tint(AppTheme.accent)
                    .frame(maxWidth: .infinity)

                    HStack {
                        TextField("…oder Link manuell eintippen", text: $urlString)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .keyboardType(.URL)
                            .onSubmit { Task { await fetchMetadata() } }
                        if isFetching {
                            ProgressView().scaleEffect(0.8)
                        } else if !urlString.isEmpty {
                            Button {
                                Task { await fetchMetadata() }
                            } label: {
                                Image(systemName: "arrow.down.circle.fill")
                                    .foregroundStyle(AppTheme.accent)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    if let err = fetchError {
                        Text(err).font(.caption).foregroundStyle(.red)
                    }
                } header: {
                    Text("Hotel-Seite")
                } footer: {
                    Text("Workflow: in Safari/Booking den Hotel-Link mit 'Kopieren' in die Zwischenablage legen → hier oben den blauen 'Einfügen'-Button tippen → die URL erscheint und wir versuchen, Hotel-Daten zu laden. Klappt Auto-Import bei Booking/Hotels.com oft nicht (Bot-Schutz) — dann unten einfach Name + Foto-URL manuell eintragen, der Link wird trotzdem gespeichert.")
                }

                Section("Hotel-Details") {
                    if let url = URL(string: imageURLString), !imageURLString.isEmpty {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .success(let img):
                                img.resizable().aspectRatio(contentMode: .fill)
                            default:
                                Color.gray.opacity(0.2)
                            }
                        }
                        .frame(height: 140)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .listRowInsets(EdgeInsets(top: 4, leading: 0, bottom: 4, trailing: 0))
                    }
                    TextField("Hotel-Name", text: $name)
                    TextField("Foto-URL (optional)", text: $imageURLString)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .keyboardType(.URL)
                        .font(.caption)
                    HStack {
                        Text("Preis / Nacht")
                        Spacer()
                        TextField("z.B. 189", text: $pricePerNight)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 100)
                        Text("€").foregroundStyle(.secondary)
                    }
                    Stepper(value: $stars, in: 0...5) {
                        HStack {
                            Text("Sterne")
                            Spacer()
                            Text(stars == 0 ? "—" : String(repeating: "★", count: stars))
                                .foregroundStyle(.yellow)
                        }
                    }
                    TextField("Notizen", text: $notes, axis: .vertical).lineLimit(2...4)
                }

                Section("Status") {
                    Picker("Status", selection: $status) {
                        ForEach(HotelStatus.allCases, id: \.self) { s in
                            Label(s.label, systemImage: s.icon).tag(s)
                        }
                    }
                    .pickerStyle(.menu)

                    if status == .booked || status == .confirmed {
                        TextField("Buchungs-Referenz", text: $bookingReference)
                            .textInputAutocapitalization(.characters)
                    }
                }

                if isEditing, let onDelete {
                    Section {
                        Button(role: .destructive) {
                            onDelete()
                            dismiss()
                        } label: {
                            Label("Hotel-Vorschlag löschen", systemImage: "trash")
                        }
                    }
                }
            }
            .navigationTitle(isEditing ? "Hotel bearbeiten" : "Hotel hinzufügen")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Sichern") { save() }
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onAppear {
                if let i = initial {
                    name = i.name
                    urlString = i.urlString ?? ""
                    imageURLString = i.imageURLString ?? ""
                    subtitle = i.subtitle
                    pricePerNight = i.pricePerNight.map { String(Int($0)) } ?? ""
                    stars = i.stars ?? 0
                    notes = i.notes
                    status = i.status
                    bookingReference = i.bookingReference ?? ""
                }
            }
        }
    }

    private func fetchMetadata() async {
        let trimmed = urlString.trimmingCharacters(in: .whitespaces)
        guard let url = URL(string: trimmed),
              url.scheme?.hasPrefix("http") == true else {
            fetchError = "Bitte gültige URL eingeben (https://…)"
            return
        }
        fetchError = nil
        isFetching = true
        defer { isFetching = false }

        if let meta = await HotelMetadataService.fetch(url: url) {
            if name.isEmpty, let t = meta.title { name = t }
            if imageURLString.isEmpty, let img = meta.imageURL {
                imageURLString = img.absoluteString
            }
            if subtitle.isEmpty, let s = meta.subtitle { subtitle = s }
        } else {
            fetchError = "Hotel-Details konnten nicht geladen werden. Name bitte selbst eintragen."
        }
    }

    private func save() {
        var candidate = initial ?? HotelCandidate(name: "")
        candidate.name = name.trimmingCharacters(in: .whitespaces)
        candidate.urlString = urlString.trimmingCharacters(in: .whitespaces).isEmpty ? nil : urlString
        candidate.imageURLString = imageURLString.isEmpty ? nil : imageURLString
        candidate.subtitle = subtitle
        candidate.pricePerNight = Double(pricePerNight.trimmingCharacters(in: .whitespaces))
        candidate.stars = stars == 0 ? nil : stars
        candidate.notes = notes
        candidate.status = status
        candidate.bookingReference = (status == .booked || status == .confirmed) && !bookingReference.isEmpty
            ? bookingReference
            : nil
        onSave(candidate)
        dismiss()
    }
}

// MARK: - Booking Import (PDF → Apple Intelligence → Trip)

import FoundationModels
import PDFKit
import Vision
import UniformTypeIdentifiers

/// Strukturierter Output, den Apple Intelligence aus dem PDF-Text extrahieren
/// soll. Per `@Generable` markiert + jedes Feld mit `@Guide` beschrieben,
/// damit das on-device LLM weiß was rein gehört. Wird in `BookingExtractor`
/// als generating-Type an `LanguageModelSession.respond` übergeben.
@Generable
struct ExtractedBooking: Equatable {
    @Guide(description: "Type of booking. Must be one of: hotel, flight, train, car, bus")
    var bookingType: String

    @Guide(description: "Hotel name, flight number with airline, or train number. Examples: 'H10 Casa Mimosa', 'LH4291 Lufthansa', 'ICE 615'")
    var name: String

    @Guide(description: "Departure or hotel city. For flights: city of origin airport. For hotels: city the hotel is in.")
    var fromLocation: String?

    @Guide(description: "Arrival city. Empty for hotels.")
    var toLocation: String?

    @Guide(description: "Check-in date or departure date in ISO format YYYY-MM-DD")
    var startDate: String?

    @Guide(description: "Check-out date or arrival date in ISO format YYYY-MM-DD")
    var endDate: String?

    @Guide(description: "Booking confirmation number or PNR")
    var bookingReference: String?

    @Guide(description: "Total amount as a number, no currency symbol")
    var totalPrice: Double?

    @Guide(description: "Currency code, e.g. EUR, USD, GBP")
    var currency: String?

    @Guide(description: "Number of adult travelers")
    var adults: Int?

    @Guide(description: "Number of child travelers")
    var children: Int?
}

extension ExtractedBooking {
    /// Konvertiert das LLM-Output in unseren internen TransportType, falls möglich.
    var transportType: TransportType? {
        switch bookingType.lowercased() {
        case "hotel": .hotel
        case "flight", "flug": .flight
        case "train", "zug", "rail": .train
        case "car", "rental", "mietwagen": .car
        case "bus", "coach": .bus
        default: nil
        }
    }

    var parsedStartDate: Date? { parseISODate(startDate) }
    var parsedEndDate: Date? { parseISODate(endDate) }

    private func parseISODate(_ s: String?) -> Date? {
        guard let s = s?.trimmingCharacters(in: .whitespaces), !s.isEmpty else { return nil }
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyy-MM-dd"
        return f.date(from: s)
    }
}

// MARK: - PDF Text Extraction

enum BookingPDFExtractor {
    /// Versucht erst PDFKit (schnell, wenn PDF einen Text-Layer hat), fällt
    /// auf Vision-OCR zurück wenn das PDF nur Bilder enthält (Scans).
    static func extractText(from url: URL) async -> String? {
        if let text = textViaPDFKit(url: url), !text.isEmpty {
            return text
        }
        return await textViaVisionOCR(url: url)
    }

    private static func textViaPDFKit(url: URL) -> String? {
        guard let pdf = PDFDocument(url: url) else { return nil }
        var combined = ""
        for i in 0..<pdf.pageCount {
            if let s = pdf.page(at: i)?.string {
                combined += s + "\n"
            }
        }
        let trimmed = combined.trimmingCharacters(in: .whitespacesAndNewlines)
        // Wenn weniger als ~50 Zeichen → wahrscheinlich nur Bilder im PDF
        return trimmed.count >= 50 ? trimmed : nil
    }

    private static func textViaVisionOCR(url: URL) async -> String? {
        guard let pdf = PDFDocument(url: url) else { return nil }
        var combined = ""
        for i in 0..<pdf.pageCount {
            guard let page = pdf.page(at: i) else { continue }
            let bounds = page.bounds(for: .mediaBox)
            let renderer = UIGraphicsImageRenderer(size: bounds.size)
            let image = renderer.image { ctx in
                UIColor.white.set()
                ctx.fill(bounds)
                ctx.cgContext.translateBy(x: 0, y: bounds.height)
                ctx.cgContext.scaleBy(x: 1, y: -1)
                page.draw(with: .mediaBox, to: ctx.cgContext)
            }
            guard let cgImage = image.cgImage else { continue }
            let pageText = await Self.recognizeText(in: cgImage)
            combined += pageText + "\n"
        }
        let trimmed = combined.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    private static func recognizeText(in cgImage: CGImage) async -> String {
        await withCheckedContinuation { continuation in
            let request = VNRecognizeTextRequest { req, _ in
                let observations = req.results as? [VNRecognizedTextObservation] ?? []
                let lines = observations.compactMap { $0.topCandidates(1).first?.string }
                continuation.resume(returning: lines.joined(separator: "\n"))
            }
            request.recognitionLanguages = ["de-DE", "en-US"]
            request.usesLanguageCorrection = true
            request.recognitionLevel = .accurate

            let handler = VNImageRequestHandler(cgImage: cgImage)
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(returning: "")
            }
        }
    }
}

// MARK: - Apple Intelligence Extraction

enum BookingExtractor {
    enum ExtractorError: LocalizedError {
        case appleIntelligenceUnavailable(String)
        case llmFailed(String)
        case noContent

        var errorDescription: String? {
            switch self {
            case .appleIntelligenceUnavailable(let detail):
                "Apple Intelligence ist nicht verfügbar: \(detail)"
            case .llmFailed(let detail):
                "Apple Intelligence konnte die Bestätigung nicht auswerten: \(detail)"
            case .noContent:
                "Keine Daten aus dem PDF gelesen."
            }
        }
    }

    /// Short label for the Settings → About row.
    static var availabilityShortLabel: String {
        switch SystemLanguageModel.default.availability {
        case .available: "Aktiv (on-device)"
        case .unavailable(.appleIntelligenceNotEnabled): "Deaktiviert"
        case .unavailable(.deviceNotEligible): "Gerät nicht unterstützt"
        case .unavailable(.modelNotReady): "Modell wird geladen"
        case .unavailable: "Nicht verfügbar"
        }
    }

    static func extract(fromText text: String) async throws -> ExtractedBooking {
        // Prüfen ob on-device Model verfügbar ist
        let model = SystemLanguageModel.default
        switch model.availability {
        case .available:
            break
        case .unavailable(.appleIntelligenceNotEnabled):
            throw ExtractorError.appleIntelligenceUnavailable(
                "Aktiviere Apple Intelligence in den Einstellungen → Apple Intelligence & Siri."
            )
        case .unavailable(.deviceNotEligible):
            throw ExtractorError.appleIntelligenceUnavailable(
                "Dein iPhone unterstützt das on-device Apple-Intelligence-Modell nicht (benötigt iPhone 15 Pro oder neuer)."
            )
        case .unavailable(.modelNotReady):
            throw ExtractorError.appleIntelligenceUnavailable(
                "Das Modell wird gerade geladen. Bitte gleich noch einmal versuchen."
            )
        case .unavailable(let other):
            throw ExtractorError.appleIntelligenceUnavailable("\(other)")
        }

        let session = LanguageModelSession(instructions: """
            You parse travel booking confirmation emails and PDFs. Extract \
            structured information into the requested format. Use ISO 8601 \
            (YYYY-MM-DD) for all dates. Recognize confirmations in German and \
            English. If a field is not mentioned in the text, leave it empty.
            """)

        do {
            let response = try await session.respond(
                to: """
                Extract the booking details from the following confirmation text. \
                Determine whether it is a hotel, flight, train, car rental, or bus \
                booking. Use the explicit dates from the document, not today's date.

                Confirmation text:
                ---
                \(text.prefix(8000))
                ---
                """,
                generating: ExtractedBooking.self
            )
            return response.content
        } catch {
            throw ExtractorError.llmFailed("\(error.localizedDescription)")
        }
    }
}

// MARK: - Booking Apply Logic

enum BookingApplier {
    /// Versucht, eine passende existierende Reise zu finden — basierend auf
    /// Datums-Nähe (±21 Tage) und Stadt-Match mit irgendeinem Segment.
    enum TripMatch: Equatable {
        /// Reise gefunden, die zeitlich (und idealerweise räumlich) zur Buchung passt.
        case matched(Trip, reason: MatchReason)
        /// Es gibt Reisen, aber keine passt zum Buchungs-Datum (±21 Tage)
        /// oder zur Buchungs-Stadt.
        case noMatch
        /// Der User hat noch keine einzige Reise angelegt.
        case noTrips

        enum MatchReason: Equatable {
            case cityAndDate, dateOnly
        }
    }

    /// Liefert ein explizites Match-Ergebnis. Wird vom Import-Sheet verwendet,
    /// um zwischen „passende Reise gefunden", „kein Match" und „keine Reisen"
    /// zu unterscheiden. Für API-Kompatibilität liefert `findMatchingTrip`
    /// weiter den heuristischen Best-Match (oder die erste Reise).
    static func matchTrip(in trips: [Trip], for booking: ExtractedBooking) -> TripMatch {
        guard !trips.isEmpty else { return .noTrips }
        guard let bookingDate = booking.parsedStartDate else { return .noMatch }

        let cities = [booking.fromLocation, booking.toLocation].compactMap { $0?.lowercased() }

        // 1. Stadt + Datum (±21 Tage)
        for trip in trips {
            for seg in trip.segments {
                let segCities = [seg.from, seg.to].map { $0.lowercased() }
                let cityHit = cities.contains { city in
                    segCities.contains { !$0.isEmpty && (city.contains($0) || $0.contains(city)) }
                }
                if cityHit, let segDate = seg.date,
                   abs(segDate.timeIntervalSince(bookingDate)) < 86400 * 21 {
                    return .matched(trip, reason: .cityAndDate)
                }
            }
        }

        // 2. Buchungs-Datum liegt innerhalb [tripStart-7d, tripEnd+7d] einer Reise
        for trip in trips {
            guard let ts = trip.startDate, let te = trip.endDate else { continue }
            if bookingDate >= ts.addingTimeInterval(-86400 * 7),
               bookingDate <= te.addingTimeInterval(86400 * 7) {
                return .matched(trip, reason: .dateOnly)
            }
        }

        return .noMatch
    }

    static func findMatchingTrip(in trips: [Trip], for booking: ExtractedBooking) -> Trip? {
        switch matchTrip(in: trips, for: booking) {
        case .matched(let trip, _): return trip
        case .noMatch, .noTrips: return trips.first
        }
    }

    // MARK: - Duplikat-Erkennung

    struct DuplicateMatch: Equatable {
        let trip: Trip
        let segmentID: UUID
        let candidateID: UUID?      // nil ⇒ Transport-Segment, gesetzt ⇒ Hotel-Kandidat
        let reason: Reason

        enum Reason {
            case bookingReference
            case sameNameAndDate
        }

        static func == (lhs: DuplicateMatch, rhs: DuplicateMatch) -> Bool {
            lhs.trip.id == rhs.trip.id &&
            lhs.segmentID == rhs.segmentID &&
            lhs.candidateID == rhs.candidateID &&
            lhs.reason == rhs.reason
        }
    }

    /// Sucht nach einem bereits importierten Eintrag, der zur Buchung passt.
    /// Reihenfolge: erst exakte Buchungs-Referenz, danach Typ + Datum (gleicher
    /// Tag) + Name. Nil wenn nichts gefunden.
    static func findDuplicate(in trips: [Trip], for booking: ExtractedBooking) -> DuplicateMatch? {
        // 1) Buchungs-Referenz wiederfinden
        if let ref = booking.bookingReference?.trimmingCharacters(in: .whitespaces),
           !ref.isEmpty {
            let refLow = ref.lowercased()
            for trip in trips {
                for seg in trip.segments {
                    if let hit = seg.hotelCandidates.first(where: {
                        $0.bookingReference?.lowercased() == refLow
                    }) {
                        return .init(trip: trip, segmentID: seg.id,
                                     candidateID: hit.id, reason: .bookingReference)
                    }
                    // Transport: Buchungs-Referenz landet als „Buchung: <ref>" im note
                    if seg.note.lowercased().contains("buchung: \(refLow)") {
                        return .init(trip: trip, segmentID: seg.id,
                                     candidateID: nil, reason: .bookingReference)
                    }
                }
            }
        }

        // 2) Typ + Datum (gleicher Kalendertag) + Name
        guard let type = booking.transportType,
              let bookingDate = booking.parsedStartDate else { return nil }
        let nameLow = booking.name
            .trimmingCharacters(in: .whitespaces).lowercased()
        guard !nameLow.isEmpty else { return nil }
        let cal = Calendar.current

        for trip in trips {
            for seg in trip.segments where seg.type == type {
                guard let d = seg.date, cal.isDate(d, inSameDayAs: bookingDate) else { continue }
                if type == .hotel {
                    if let hit = seg.hotelCandidates.first(where: {
                        $0.name.lowercased() == nameLow
                    }) {
                        return .init(trip: trip, segmentID: seg.id,
                                     candidateID: hit.id, reason: .sameNameAndDate)
                    }
                } else {
                    if seg.note.lowercased().contains(nameLow) {
                        return .init(trip: trip, segmentID: seg.id,
                                     candidateID: nil, reason: .sameNameAndDate)
                    }
                }
            }
        }
        return nil
    }

    /// Wendet die Buchung auf eine Reise an: für Hotels wird die Hotel-Etappe
    /// um einen HotelCandidate ergänzt, für Flug/Zug/Auto/Bus wird ein
    /// passendes Segment ergänzt oder ein neues erstellt.
    static func apply(_ booking: ExtractedBooking, to trip: Trip) -> ApplyResult {
        guard let type = booking.transportType else {
            return .failed("Unbekannter Buchungstyp: \(booking.bookingType)")
        }

        if type == .hotel {
            return applyHotel(booking, to: trip)
        } else {
            return applyTransport(booking, type: type, to: trip)
        }
    }

    enum ApplyResult: Equatable {
        case addedHotelCandidate(segmentID: UUID, candidateID: UUID)
        case updatedSegment(segmentID: UUID)
        case createdSegment(segmentID: UUID)
        case failed(String)
    }

    private static func applyHotel(_ booking: ExtractedBooking, to trip: Trip) -> ApplyResult {
        let cityHint = booking.toLocation ?? booking.fromLocation ?? ""

        // Existierende Hotel-Etappe mit gleicher Stadt finden
        let hotelSegmentIdx = trip.segments.firstIndex { seg in
            seg.type == .hotel &&
            (seg.to.lowercased().contains(cityHint.lowercased()) ||
             cityHint.lowercased().contains(seg.to.lowercased()))
        }

        // Oder Hotel-Etappe mit ähnlichem Datum
        let dateMatchIdx: Int? = {
            guard hotelSegmentIdx == nil, let bookingDate = booking.parsedStartDate else { return nil }
            return trip.segments.firstIndex { seg in
                seg.type == .hotel &&
                seg.date.map { abs($0.timeIntervalSince(bookingDate)) < 86400 * 5 } == true
            }
        }()

        let targetIdx = hotelSegmentIdx ?? dateMatchIdx

        let candidate = makeHotelCandidate(from: booking)

        if let idx = targetIdx {
            trip.segments[idx].hotelCandidates.append(candidate)
            return .addedHotelCandidate(segmentID: trip.segments[idx].id, candidateID: candidate.id)
        }

        // Neue Hotel-Etappe anlegen
        var newSeg = TripSegment(
            type: .hotel,
            from: "",
            to: cityHint,
            date: booking.parsedStartDate,
            note: bookingNote(from: booking),
            hotelCandidates: [candidate]
        )
        _ = newSeg.id  // silence
        trip.segments.append(newSeg)
        return .createdSegment(segmentID: newSeg.id)
    }

    private static func applyTransport(
        _ booking: ExtractedBooking,
        type: TransportType,
        to trip: Trip
    ) -> ApplyResult {
        // Passende Etappe per Typ + (Strecke ODER Datum)
        let from = booking.fromLocation?.lowercased() ?? ""
        let to = booking.toLocation?.lowercased() ?? ""

        let idx = trip.segments.firstIndex { seg in
            guard seg.type == type else { return false }
            let segFrom = seg.from.lowercased()
            let segTo = seg.to.lowercased()
            let fromHit = !from.isEmpty && (segFrom.contains(from) || from.contains(segFrom))
            let toHit = !to.isEmpty && (segTo.contains(to) || to.contains(segTo))
            if fromHit && toHit { return true }
            if let d = seg.date, let bd = booking.parsedStartDate,
               abs(d.timeIntervalSince(bd)) < 86400 * 2 {
                return fromHit || toHit
            }
            return false
        }

        if let idx {
            // Existing segment ergänzen
            var seg = trip.segments[idx]
            if let d = booking.parsedStartDate { seg.date = d }
            if seg.from.isEmpty, let f = booking.fromLocation { seg.from = f }
            if seg.to.isEmpty, let t = booking.toLocation { seg.to = t }
            seg.note = mergeNotes(existing: seg.note, new: bookingNote(from: booking))
            trip.segments[idx] = seg
            return .updatedSegment(segmentID: seg.id)
        }

        // Neues Segment anlegen
        let newSeg = TripSegment(
            type: type,
            from: booking.fromLocation ?? "",
            to: booking.toLocation ?? "",
            date: booking.parsedStartDate,
            note: bookingNote(from: booking)
        )
        trip.segments.append(newSeg)
        return .createdSegment(segmentID: newSeg.id)
    }

    private static func makeHotelCandidate(from booking: ExtractedBooking) -> HotelCandidate {
        var c = HotelCandidate(name: booking.name)
        c.status = .booked
        c.bookingReference = booking.bookingReference
        if let price = booking.totalPrice {
            // Wenn end-start date bekannt, durch Nächte teilen für Preis/Nacht
            if let s = booking.parsedStartDate, let e = booking.parsedEndDate {
                let nights = max(1, Calendar.current.dateComponents([.day], from: s, to: e).day ?? 1)
                c.pricePerNight = price / Double(nights)
            } else {
                c.pricePerNight = price
            }
        }
        c.notes = bookingNote(from: booking)
        return c
    }

    private static func bookingNote(from booking: ExtractedBooking) -> String {
        var parts: [String] = []
        if let ref = booking.bookingReference, !ref.isEmpty {
            parts.append("Buchung: \(ref)")
        }
        if let price = booking.totalPrice {
            let cur = booking.currency ?? ""
            parts.append("Preis: \(Int(price)) \(cur)".trimmingCharacters(in: .whitespaces))
        }
        if let a = booking.adults {
            var travelers = "\(a) Erw."
            if let c = booking.children, c > 0 { travelers += " + \(c) Kind\(c > 1 ? "er" : "")" }
            parts.append(travelers)
        }
        return parts.joined(separator: " · ")
    }

    private static func mergeNotes(existing: String, new: String) -> String {
        if existing.isEmpty { return new }
        if new.isEmpty { return existing }
        if existing.contains(new) { return existing }
        return "\(existing)\n\(new)"
    }
}

// MARK: - Booking Import Sheet

struct BookingImportSheet: View {
    /// Initial preselected trip — `nil` when invoked from the global
    /// overview / share extension and no trip exists yet. The sheet then
    /// guides the user to create one before applying the booking.
    let trip: Trip?
    let store: TripsStore
    /// When supplied (e.g. via the Share Extension), the file-picker step is
    /// skipped and processing starts immediately. The caller is responsible
    /// for cleaning up the file after the sheet is dismissed.
    let preloadedPDF: URL?
    @Environment(\.dismiss) private var dismiss

    @State private var step: Step
    @State private var pdfURL: URL?
    @State private var rawText: String = ""
    @State private var extracted: ExtractedBooking?
    @State private var targetTrip: Trip?
    @State private var errorMessage: String?
    @State private var showFileImporter: Bool
    @State private var applyResult: BookingApplier.ApplyResult?

    // Editierbare Felder (von extracted vorausgefüllt)
    @State private var editType: TransportType = .hotel
    @State private var editName: String = ""
    @State private var editFrom: String = ""
    @State private var editTo: String = ""
    @State private var editStartDate: Date = Date()
    @State private var editEndDate: Date = Date()
    @State private var editHasEndDate: Bool = false
    @State private var editReference: String = ""
    @State private var editPrice: String = ""
    @State private var editCurrency: String = "EUR"

    // Match-Status für die Zielreise (von fillEditFields berechnet)
    @State private var matchResult: BookingApplier.TripMatch = .noTrips
    @State private var newTripNameDraft: String = ""

    // Duplikat-Hinweis: gesetzt, wenn dieselbe Buchung bereits in einer
    // Reise gefunden wurde (per Buchungs-Referenz oder Name+Datum).
    @State private var duplicateMatch: BookingApplier.DuplicateMatch?
    @State private var showDuplicateConfirm = false

    init(trip: Trip?, store: TripsStore, preloadedPDF: URL? = nil) {
        self.trip = trip
        self.store = store
        self.preloadedPDF = preloadedPDF
        self._targetTrip = State(initialValue: trip)
        self._pdfURL = State(initialValue: preloadedPDF)
        self._showFileImporter = State(initialValue: preloadedPDF == nil)
        self._step = State(initialValue: preloadedPDF == nil ? .picking : .processing)
    }

    enum Step {
        case picking, processing, review, done
    }

    var body: some View {
        NavigationStack {
            Group {
                switch step {
                case .picking:    pickingView
                case .processing: processingView
                case .review:     reviewView
                case .done:       doneView
                }
            }
            .navigationTitle("Buchung importieren")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") { dismiss() }
                }
                if step == .review {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Übernehmen") {
                            if duplicateMatch != nil {
                                showDuplicateConfirm = true
                            } else {
                                applyAndDismiss()
                            }
                        }
                        .disabled(
                            editName.trimmingCharacters(in: .whitespaces).isEmpty ||
                            targetTrip == nil
                        )
                    }
                }
            }
        }
        .confirmationDialog(
            duplicateMatch.map { "Buchung ist bereits in „\($0.trip.name)“ importiert." }
                ?? "Buchung bereits importiert",
            isPresented: $showDuplicateConfirm,
            titleVisibility: .visible
        ) {
            Button("Trotzdem hinzufügen", role: .destructive) { applyAndDismiss() }
            Button("Abbrechen", role: .cancel) {}
        } message: {
            Text("Möchtest du diese Buchung wirklich noch einmal speichern? Sie wird dann doppelt in der Reise erscheinen.")
        }
        .fileImporter(
            isPresented: $showFileImporter,
            allowedContentTypes: [.pdf],
            allowsMultipleSelection: false
        ) { result in
            handleFileImport(result)
        }
        .task(id: preloadedPDF) {
            if let url = preloadedPDF, extracted == nil, errorMessage == nil {
                await processPDF(at: url)
            }
        }
    }

    private var pickingView: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 48))
                .foregroundStyle(AppTheme.accent)
            Text("PDF einer Buchungsbestätigung wählen")
                .font(.headline)
            Text("Die App liest den Text mit Apple Intelligence aus und ergänzt deine Reise — du kannst alles vor dem Speichern bearbeiten.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            if let errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            Button {
                showFileImporter = true
            } label: {
                Label("PDF auswählen", systemImage: "doc.badge.plus")
                    .padding(.horizontal, 8)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var processingView: some View {
        VStack(spacing: 16) {
            ProgressView().scaleEffect(1.5)
                .padding(.bottom, 8)
            Text("Apple Intelligence liest die Bestätigung…")
                .font(.headline)
            Text("Das passiert komplett auf deinem iPhone — keine Daten verlassen das Gerät.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var reviewView: some View {
        Form {
            if let dup = duplicateMatch {
                duplicateBanner(for: dup)
            }
            Section("Typ") {
                Picker("Buchungstyp", selection: $editType) {
                    ForEach(TransportType.allCases) { t in
                        Label(t.label, systemImage: t.systemImage).tag(t)
                    }
                }
                .pickerStyle(.menu)
            }

            Section(editType == .hotel ? "Hotel" : "Strecke") {
                TextField(editType == .hotel ? "Hotel-Name" : "Flugnummer / Zug / Anbieter", text: $editName)
                if editType != .hotel {
                    TextField("Von", text: $editFrom)
                }
                TextField(editType == .hotel ? "Ort" : "Nach", text: $editTo)
            }

            Section("Datum") {
                DatePicker(editType == .hotel ? "Check-in" : "Abfahrt", selection: $editStartDate, displayedComponents: .date)
                Toggle(editType == .hotel ? "Check-out angeben" : "Ankunft angeben", isOn: $editHasEndDate)
                if editHasEndDate {
                    DatePicker(editType == .hotel ? "Check-out" : "Ankunft", selection: $editEndDate, displayedComponents: .date)
                }
            }

            Section("Details") {
                TextField("Buchungs-Referenz", text: $editReference)
                HStack {
                    Text("Preis gesamt")
                    Spacer()
                    TextField("0", text: $editPrice).keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing).frame(width: 100)
                    TextField("EUR", text: $editCurrency).frame(width: 50)
                        .multilineTextAlignment(.trailing)
                        .textInputAutocapitalization(.characters)
                }
            }

            tripMatchSection

            Section {
                Text("Mit 'Übernehmen' wird die Buchung in der gewählten Reise gespeichert. Hotels landen als Vorschlag mit Status 'Gebucht', andere Buchungen ergänzen ein passendes Segment oder werden neu angelegt.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    @ViewBuilder
    private func duplicateBanner(for dup: BookingApplier.DuplicateMatch) -> some View {
        Section {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "exclamationmark.octagon.fill")
                    .foregroundStyle(.red)
                VStack(alignment: .leading, spacing: 4) {
                    Text("Diese Buchung ist bereits importiert")
                        .font(.subheadline.weight(.semibold))
                    Text(dup.reason == .bookingReference
                         ? "Eine Buchung mit derselben Referenz liegt schon in „\(dup.trip.name)“."
                         : "Eine gleichnamige Buchung am selben Tag liegt schon in „\(dup.trip.name)“.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    @ViewBuilder
    private var tripMatchSection: some View {
        switch matchResult {
        case .matched(let trip, let reason):
            Section {
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundStyle(.green)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Passt zu „\(trip.name)“")
                            .font(.subheadline.weight(.semibold))
                        Text(reason == .cityAndDate
                             ? "Übereinstimmung in Stadt und Datum."
                             : "Übereinstimmung im Reise-Zeitraum.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                Picker("Zielreise", selection: $targetTrip) {
                    ForEach(store.trips) { t in
                        Text(t.name).tag(Optional(t))
                    }
                }
                .pickerStyle(.menu)
            } header: {
                Text("Zielreise")
            } footer: {
                Text("Du kannst über das Auswahlmenü auch eine andere Reise wählen, falls der Vorschlag nicht stimmt.")
            }

        case .noMatch:
            Section {
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Keine passende Reise gefunden")
                            .font(.subheadline.weight(.semibold))
                        Text("Das Buchungs-Datum liegt außerhalb deiner bestehenden Reisen (±21 Tage). Lege eine neue Reise an oder wähle manuell eine bestehende.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                TextField("Name für die neue Reise", text: $newTripNameDraft)
                Button {
                    createNewTripFromDraft()
                } label: {
                    Label("Neue Reise anlegen", systemImage: "plus.circle.fill")
                }
                Divider().padding(.vertical, 4)
                Picker("Stattdessen vorhandene Reise wählen", selection: $targetTrip) {
                    ForEach(store.trips) { t in
                        Text(t.name).tag(Optional(t))
                    }
                }
                .pickerStyle(.menu)
            } header: {
                Text("Zielreise")
            }

        case .noTrips:
            Section {
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "suitcase.fill")
                        .foregroundStyle(AppTheme.accent)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Du hast noch keine Reise angelegt")
                            .font(.subheadline.weight(.semibold))
                        Text("Lege jetzt eine Reise für diese Buchung an.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                TextField("Name der Reise", text: $newTripNameDraft)
                Button {
                    createNewTripFromDraft()
                } label: {
                    Label("Reise anlegen", systemImage: "plus.circle.fill")
                }
                .buttonStyle(.borderedProminent)
            } header: {
                Text("Zielreise")
            }
        }
    }

    private var doneView: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 56))
                .foregroundStyle(.green)
            Text("Buchung übernommen")
                .font(.headline)
            if let r = applyResult {
                Text(describe(result: r))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            Button("Fertig") { dismiss() }
                .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func describe(result: BookingApplier.ApplyResult) -> String {
        switch result {
        case .addedHotelCandidate: "Hotel wurde der passenden Etappe als gebuchter Vorschlag hinzugefügt."
        case .updatedSegment: "Bestehende Etappe wurde mit Buchungs-Details ergänzt."
        case .createdSegment: "Neue Etappe wurde angelegt."
        case .failed(let msg): "Fehler: \(msg)"
        }
    }

    // MARK: Handlers

    private func handleFileImport(_ result: Result<[URL], Error>) {
        switch result {
        case .failure(let error):
            errorMessage = "PDF konnte nicht geladen werden: \(error.localizedDescription)"
        case .success(let urls):
            guard let url = urls.first else { return }
            pdfURL = url
            step = .processing
            Task { await processPDF(at: url) }
        }
    }

    private func processPDF(at url: URL) async {
        let scoped = url.startAccessingSecurityScopedResource()
        defer { if scoped { url.stopAccessingSecurityScopedResource() } }

        guard let text = await BookingPDFExtractor.extractText(from: url) else {
            await MainActor.run {
                errorMessage = "Konnte aus dem PDF keinen Text lesen."
                step = .picking
            }
            return
        }
        rawText = text

        do {
            let result = try await BookingExtractor.extract(fromText: text)
            await MainActor.run {
                extracted = result
                fillEditFields(from: result)
                step = .review
            }
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
                step = .picking
            }
        }
    }

    private func fillEditFields(from booking: ExtractedBooking) {
        editType = booking.transportType ?? .hotel
        editName = booking.name
        editFrom = booking.fromLocation ?? ""
        editTo = booking.toLocation ?? ""
        editStartDate = booking.parsedStartDate ?? Date()
        if let end = booking.parsedEndDate {
            editEndDate = end
            editHasEndDate = true
        } else {
            editEndDate = editStartDate
            editHasEndDate = false
        }
        editReference = booking.bookingReference ?? ""
        editPrice = booking.totalPrice.map { String(format: "%.2f", $0) } ?? ""
        editCurrency = booking.currency ?? "EUR"

        // Trip-Matching: explizit „matched / noMatch / noTrips" auswerten
        let result = BookingApplier.matchTrip(in: store.trips, for: booking)
        matchResult = result
        if case let .matched(trip, _) = result {
            targetTrip = trip
        }
        // Default-Name für eine neue Reise: Zielstadt + Jahr der Buchung
        newTripNameDraft = suggestedNewTripName(from: booking)
        // Duplikat-Check: gleiche Buchungs-Referenz oder Name+Datum bereits drin?
        duplicateMatch = BookingApplier.findDuplicate(in: store.trips, for: booking)
    }

    private func suggestedNewTripName(from booking: ExtractedBooking) -> String {
        let city = booking.toLocation?.trimmingCharacters(in: .whitespaces)
            ?? booking.fromLocation?.trimmingCharacters(in: .whitespaces)
            ?? ""
        let year: String = {
            guard let d = booking.parsedStartDate else { return "" }
            return " \(Calendar.current.component(.year, from: d))"
        }()
        let base = city.isEmpty ? "Neue Reise" : city
        return "\(base)\(year)"
    }

    private func createNewTripFromDraft() {
        let trimmed = newTripNameDraft.trimmingCharacters(in: .whitespaces)
        let name = trimmed.isEmpty ? "Neue Reise" : trimmed
        let newTrip = store.add(named: name)
        targetTrip = newTrip
        matchResult = .matched(newTrip, reason: .cityAndDate)
    }

    private func applyAndDismiss() {
        let edited = ExtractedBooking(
            bookingType: editType.rawValue,
            name: editName.trimmingCharacters(in: .whitespaces),
            fromLocation: editFrom.isEmpty ? nil : editFrom,
            toLocation: editTo.isEmpty ? nil : editTo,
            startDate: isoString(editStartDate),
            endDate: editHasEndDate ? isoString(editEndDate) : nil,
            bookingReference: editReference.isEmpty ? nil : editReference,
            totalPrice: Double(editPrice.replacingOccurrences(of: ",", with: ".")),
            currency: editCurrency.isEmpty ? nil : editCurrency,
            adults: nil,
            children: nil
        )
        guard let trip = targetTrip else {
            // Sollte nicht passieren — der Übernehmen-Button ist disabled
            // wenn keine Reise gewählt ist. Defensiv abbrechen.
            return
        }
        let result = BookingApplier.apply(edited, to: trip)
        applyResult = result
        store.save()
        step = .done
    }

    private func isoString(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.locale = Locale(identifier: "en_US_POSIX")
        return f.string(from: date)
    }
}

// MARK: - Splash

struct SplashView: View {
    @Binding var isPresented: Bool
    @State private var animateCards = false
    @State private var animateLogo = false
    @State private var fadeOut = false

    private struct Destination {
        let emoji: String
        let city: String
        let angle: Double
    }

    private let destinations: [Destination] = [
        Destination(emoji: "🗼", city: "Paris",     angle: -160),
        Destination(emoji: "🌉", city: "London",    angle: -110),
        Destination(emoji: "🏛️", city: "Rom",       angle: -55),
        Destination(emoji: "🗽", city: "New York",  angle: 5),
        Destination(emoji: "⛩️", city: "Tokyo",     angle: 60),
        Destination(emoji: "🕌", city: "Istanbul",  angle: 110),
        Destination(emoji: "🏰", city: "Bayern",    angle: 160),
        Destination(emoji: "🗿", city: "Rapa Nui",  angle: -200),
    ]

    var body: some View {
        ZStack {
            AppTheme.bgGradient
            .ignoresSafeArea()

            Circle()
                .fill(AppTheme.accent.opacity(0.10))
                .frame(width: 380, height: 380)
                .blur(radius: 90)
                .offset(x: 110, y: -180)

            Circle()
                .fill(Color(hex: 0xEC4899).opacity(0.06))
                .frame(width: 280, height: 280)
                .blur(radius: 80)
                .offset(x: -120, y: 220)

            ForEach(Array(destinations.enumerated()), id: \.offset) { idx, dest in
                postcard(for: dest, index: idx)
            }

            VStack(spacing: 14) {
                Image("LogoMark")
                    .resizable()
                    .frame(width: 110, height: 110)
                    .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                    .shadow(color: .black.opacity(0.55), radius: 30, y: 12)

                HStack(spacing: 0) {
                    Text("My").font(.system(.largeTitle, design: .serif).weight(.bold))
                        .foregroundStyle(.white)
                    Text("Voyage").font(.system(.largeTitle, design: .serif).weight(.bold))
                        .foregroundStyle(AppTheme.accent)
                }

                Text("INDIVIDUELLE REISEPLANUNG")
                    .font(.system(size: 10, weight: .medium))
                    .tracking(3)
                    .foregroundStyle(.white.opacity(0.45))
            }
            .scaleEffect(animateLogo ? 1.0 : 0.55)
            .opacity(animateLogo ? 1.0 : 0)
        }
        .opacity(fadeOut ? 0 : 1)
        .onAppear { runIntro() }
    }

    private func postcard(for dest: Destination, index: Int) -> some View {
        let radius: CGFloat = 155
        let angleRad = Angle.degrees(dest.angle).radians
        let target = CGSize(width: cos(angleRad) * radius, height: sin(angleRad) * radius)
        let start = CGSize(width: target.width * 5, height: target.height * 5)
        let tilt: Double = (index % 2 == 0) ? -10 : 10

        return VStack(spacing: 4) {
            Text(dest.emoji).font(.system(size: 38))
            Text(dest.city)
                .font(.system(size: 11, weight: .medium, design: .serif))
                .foregroundStyle(.black.opacity(0.7))
        }
        .frame(width: 92, height: 108)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(hex: 0xF5F1E8))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(.black.opacity(0.08), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.45), radius: 14, x: 4, y: 8)
        .offset(animateCards ? target : start)
        .rotationEffect(animateCards ? .degrees(tilt) : .degrees(tilt * 4))
        .opacity(animateCards ? 1 : 0)
        .animation(
            .spring(response: 1.0, dampingFraction: 0.72)
                .delay(0.06 * Double(index)),
            value: animateCards
        )
    }

    private func runIntro() {
        animateCards = true
        withAnimation(.spring(response: 0.55, dampingFraction: 0.7).delay(0.15)) {
            animateLogo = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.6) {
            withAnimation(.easeInOut(duration: 0.45)) { fadeOut = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
                isPresented = false
            }
        }
    }
}

#Preview("List") {
    ContentView()
}

#Preview("Splash") {
    SplashView(isPresented: .constant(true))
}
