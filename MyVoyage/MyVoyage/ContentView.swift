import SwiftUI

// MARK: - Theme

enum AppTheme {
    static let bg = Color(hex: 0x0A0A0F)
    static let surface = Color.white.opacity(0.03)
    static let border = Color.white.opacity(0.07)
    static let text = Color(hex: 0xE8E4D9)
    static let textSubtle = Color(hex: 0xE8E4D9).opacity(0.35)
    static let textMuted = Color(hex: 0xE8E4D9).opacity(0.55)
    static let accent = Color(hex: 0x3B82F6)
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
    var id: UUID = UUID()
    var type: TransportType = .flight
    var from: String = ""
    var to: String = ""
    var date: Date? = nil
    var note: String = ""
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
        ("new york", "🗽"),
        ("tokio", "⛩️"),
        ("tokyo", "⛩️"),
        ("kyoto", "🏯"),
        ("istanbul", "🕌"),
        ("barcelona", "🏝️"),
        ("madrid", "💃"),
        ("valencia", "🍊"),
        ("münchen", "🍺"),
        ("munich", "🍺"),
        ("berlin", "🐻"),
        ("amsterdam", "🌷"),
        ("rio", "🏖️"),
        ("vegas", "🎰"),
        ("san francisco", "🌉"),
        ("dubai", "🏙️"),
        ("bangkok", "🛕"),
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
    static let fileURL: URL = {
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return dir.appendingPathComponent("trips.json")
    }()

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
        guard let data = try? Data(contentsOf: fileURL),
              let trips = try? decoder.decode([Trip].self, from: data) else {
            return nil
        }
        return trips
    }

    static func save(_ trips: [Trip]) {
        do {
            let data = try encoder.encode(trips)
            try data.write(to: fileURL, options: .atomic)
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

    var body: some View {
        NavigationStack {
            TripsListView(store: store)
                .navigationDestination(for: Trip.self) { trip in
                    TripDetailView(trip: trip, store: store)
                }
        }
        .tint(AppTheme.accent)
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase != .active { store.save() }
        }
    }
}

// MARK: - Trips List (Übersicht)

struct TripsListView: View {
    let store: TripsStore

    @State private var pushNewTrip: Trip? = nil
    @State private var showWizard = false
    @State private var showResetConfirm = false
    @State private var showDeleteAllConfirm = false
    @State private var deletionTarget: Trip? = nil

    private let columns = [GridItem(.adaptive(minimum: 160, maximum: 220), spacing: 14)]

    var body: some View {
        ZStack {
            AppTheme.bg.ignoresSafeArea()

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
            .frame(maxWidth: .infinity)
            .frame(height: 200)
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
                .frame(height: 110)
                .clipped()

                LinearGradient(
                    colors: [Color.clear, Color.black.opacity(0.55)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 110)
                .allowsHitTesting(false)

                Text(trip.coverEmoji)
                    .font(.system(size: 36))
                    .padding(.top, 8)
                    .padding(.trailing, 10)
                    .shadow(color: .black.opacity(0.5), radius: 8)
            }
            .frame(height: 110)

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
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(height: 200)
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
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            AppTheme.bg.ignoresSafeArea()

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
                        if let url = portal.urlBuilder(segment, travelers) {
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
                        if let url = portal.urlBuilder(segment, trip.travelers) {
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
    let urlBuilder: (TripSegment, Travelers) -> URL?
}

enum BookingPortals {
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

    static func portals(for type: TransportType) -> [BookingPortal] {
        switch type {
        case .flight:
            return [
                BookingPortal(name: "Skyscanner") { seg, tr in
                    let d = dateString(seg.date).replacingOccurrences(of: "-", with: "")
                    let urlStr = "https://www.skyscanner.de/transport/flights/\(encode(seg.from))/\(encode(seg.to))/\(d)/?adults=\(tr.adults)&children=\(tr.children.count)"
                    return URL(string: urlStr)
                },
                BookingPortal(name: "Google Flights") { seg, tr in
                    let q = "Flights from \(seg.from) to \(seg.to) on \(dateString(seg.date))"
                    let urlStr = "https://www.google.com/travel/flights?q=\(encode(q))&adults=\(tr.adults)&children=\(tr.children.count)"
                    return URL(string: urlStr)
                },
                BookingPortal(name: "Expedia") { seg, tr in
                    let urlStr = "https://www.expedia.de/Flights-Search?trip=oneway&leg1=from:\(encode(seg.from)),to:\(encode(seg.to)),departure:\(dateString(seg.date))&passengers=adults:\(tr.adults)"
                    return URL(string: urlStr)
                },
            ]
        case .train:
            return [
                BookingPortal(name: "DB Bahn") { seg, _ in
                    let urlStr = "https://www.bahn.de/buchung/fahrplan/suche#sts=true&so=\(encode(seg.from))&zo=\(encode(seg.to))"
                    return URL(string: urlStr)
                },
                BookingPortal(name: "Omio") { seg, tr in
                    let urlStr = "https://www.omio.de/trains/\(encode(seg.from))-\(encode(seg.to))?date=\(dateString(seg.date))&adults=\(tr.adults)&children=\(tr.children.count)"
                    return URL(string: urlStr)
                },
            ]
        case .car:
            return [
                BookingPortal(name: "Rentalcars") { seg, _ in
                    let urlStr = "https://www.rentalcars.com/de/search/?pickUpPlace=\(encode(seg.from))&puDay=\(dateString(seg.date))"
                    return URL(string: urlStr)
                },
                BookingPortal(name: "Booking.com") { seg, _ in
                    let urlStr = "https://www.booking.com/cars/search.de.html?pickup_location=\(encode(seg.from))&pickup_date=\(dateString(seg.date))"
                    return URL(string: urlStr)
                },
            ]
        case .bus:
            return [
                BookingPortal(name: "FlixBus") { seg, tr in
                    let urlStr = "https://global.flixbus.com/bus-tickets/\(encode(seg.from))-\(encode(seg.to))?departureDate=\(dateString(seg.date))&adult=\(tr.adults)&children=\(tr.children.count)"
                    return URL(string: urlStr)
                },
                BookingPortal(name: "Omio") { seg, tr in
                    let urlStr = "https://www.omio.de/buses/\(encode(seg.from))-\(encode(seg.to))?date=\(dateString(seg.date))&adults=\(tr.adults)&children=\(tr.children.count)"
                    return URL(string: urlStr)
                },
            ]
        case .hotel:
            return [
                BookingPortal(name: "Booking.com") { seg, tr in
                    let urlStr = "https://www.booking.com/searchresults.de.html?ss=\(encode(seg.to))&checkin=\(dateString(seg.date))&group_adults=\(tr.adults)&group_children=\(tr.children.count)"
                    return URL(string: urlStr)
                },
                BookingPortal(name: "Hotels.com") { seg, tr in
                    let urlStr = "https://de.hotels.com/search.do?q-destination=\(encode(seg.to))&q-check-in=\(dateString(seg.date))&q-rooms=1&q-room-0-adults=\(tr.adults)&q-room-0-children=\(tr.children.count)"
                    return URL(string: urlStr)
                },
                BookingPortal(name: "Expedia") { seg, tr in
                    let urlStr = "https://www.expedia.de/Hotel-Search?destination=\(encode(seg.to))&startDate=\(dateString(seg.date))&adults=\(tr.adults)&children=\(tr.children.count)"
                    return URL(string: urlStr)
                },
            ]
        }
    }
}

// MARK: - Destination Image Service

struct DestinationImage: Equatable {
    let url: URL
    let attribution: String  // "Wikipedia / <author>"
}

@MainActor
@Observable
final class DestinationImageService {
    static let shared = DestinationImageService()

    private var cache: [String: DestinationImage?] = [:]
    private var inflight: [String: Task<DestinationImage?, Never>] = [:]

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
        if result != nil { cache[key] = result }
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
        Group {
            if let image {
                AsyncImage(url: image.url, transaction: Transaction(animation: .easeInOut(duration: 0.35))) { phase in
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
        .task(id: destination) {
            guard !destination.isEmpty else { image = nil; return }
            image = await DestinationImageService.shared.image(for: destination)
        }
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
        GeometryReader { geo in
            ZStack {
                backdrop.ignoresSafeArea()
                VStack(spacing: 0) {
                    headerBar.frame(maxWidth: .infinity)
                    content.frame(maxWidth: .infinity)
                    footerBar.frame(maxWidth: .infinity)
                }
                .frame(width: geo.size.width, height: geo.size.height)
            }
        }
        .preferredColorScheme(.dark)
    }

    private var backdrop: some View {
        ZStack {
            AppTheme.bg
            Circle()
                .fill(currentStep.accent.opacity(0.18))
                .frame(width: 460, height: 460)
                .blur(radius: 110)
                .offset(x: -100, y: -260)
                .animation(.easeInOut(duration: 0.6), value: currentStep)
            Circle()
                .fill(currentStep.accent.opacity(0.10))
                .frame(width: 360, height: 360)
                .blur(radius: 100)
                .offset(x: 140, y: 280)
                .animation(.easeInOut(duration: 0.6), value: currentStep)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .clipped()
    }

    private var headerBar: some View {
        VStack(spacing: 12) {
            HStack {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(AppTheme.text)
                        .frame(width: 32, height: 32)
                        .background(Color.white.opacity(0.06), in: Circle())
                }
                Spacer()
                Text("Neue Reise · \(currentIndex + 1)/\(visibleSteps.count)")
                    .font(.system(size: 11, weight: .medium))
                    .tracking(1.5)
                    .foregroundStyle(AppTheme.textMuted)
                Spacer()
                Color.clear.frame(width: 32, height: 32)
            }

            HStack(spacing: 4) {
                ForEach(0..<visibleSteps.count, id: \.self) { i in
                    Capsule()
                        .fill(i <= currentIndex ? currentStep.accent : AppTheme.border)
                        .frame(height: 3)
                        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: currentIndex)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 6)
        .padding(.bottom, 12)
    }

    @ViewBuilder
    private var content: some View {
        ScrollView {
            VStack {
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
                .transition(.opacity.combined(with: .scale(scale: 0.96)))
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 24)
        }
        .frame(maxWidth: .infinity)
    }

    private var footerBar: some View {
        HStack(spacing: 12) {
            if currentIndex > 0 {
                Button {
                    goingForward = false
                    withAnimation(.spring(response: 0.45, dampingFraction: 0.82)) {
                        currentIndex -= 1
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "chevron.left").font(.system(size: 12, weight: .semibold))
                        Text("Zurück").font(.system(size: 14, weight: .medium))
                    }
                    .foregroundStyle(AppTheme.text)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color.white.opacity(0.06), in: Capsule())
                }
            }
            Spacer()
            Button {
                advance()
            } label: {
                HStack(spacing: 6) {
                    Text(currentStep == .summary ? "Reise erstellen" : "Weiter")
                        .font(.system(size: 14, weight: .semibold))
                    Image(systemName: currentStep == .summary ? "sparkles" : "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 22)
                .padding(.vertical, 13)
                .background(
                    LinearGradient(
                        colors: [currentStep.accent, currentStep.accent.opacity(0.75)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    in: Capsule()
                )
                .shadow(color: currentStep.accent.opacity(0.4), radius: 14, y: 6)
                .opacity(data.canContinue(from: currentStep) ? 1 : 0.45)
            }
            .disabled(!data.canContinue(from: currentStep))
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 18)
        .padding(.top, 10)
        .background(.ultraThinMaterial)
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

            TextField("", text: Binding(
                get: { data.destinations.first ?? "" },
                set: {
                    if data.destinations.isEmpty { data.destinations = [$0] }
                    else { data.destinations[0] = $0 }
                }
            ), prompt: Text("z.B. Barcelona").foregroundStyle(AppTheme.text.opacity(0.25)))
                .font(.system(.title3, design: .serif))
                .foregroundStyle(AppTheme.text)
                .submitLabel(.done)
                .padding(.horizontal, 14)
                .padding(.vertical, 14)
                .background(Color.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 12))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(WizardStep.where_.accent.opacity(0.45), lineWidth: 1))

            VStack(alignment: .leading, spacing: 8) {
                Text("BELIEBTE ZIELE")
                    .font(.system(size: 10, weight: .medium)).tracking(1.5)
                    .foregroundStyle(AppTheme.textSubtle)
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
        let dests = data.validDestinations
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

        let primary = dests.first ?? "Neue Reise"
        let f = DateFormatter()
        f.locale = Locale(identifier: "de_DE")
        f.dateFormat = "MMMM yyyy"
        let monthLabel = data.startDate.map { f.string(from: $0) } ?? ""
        let name = monthLabel.isEmpty ? primary : "\(primary) \(monthLabel)"

        return Trip(name: name, travelers: data.travelers, segments: segments)
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
            LinearGradient(
                colors: [Color(hex: 0x0A0A0F), Color(hex: 0x101A33), Color(hex: 0x0A0A0F)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
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
