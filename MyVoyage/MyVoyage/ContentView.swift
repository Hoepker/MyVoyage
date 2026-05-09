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

struct TripSegment: Identifiable, Equatable {
    let id = UUID()
    var type: TransportType = .flight
    var from: String = ""
    var to: String = ""
    var date: Date? = nil
    var note: String = ""
}

struct Travelers: Equatable {
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
final class Trip: Identifiable, Hashable {
    let id = UUID()
    var name: String
    var travelers: Travelers
    var segments: [TripSegment]
    var accentHex: UInt32

    init(
        name: String,
        travelers: Travelers = Travelers(),
        segments: [TripSegment] = [],
        accentHex: UInt32 = 0x3B82F6
    ) {
        self.name = name
        self.travelers = travelers
        self.segments = segments
        self.accentHex = accentHex
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

// MARK: - Trips Store

@Observable
final class TripsStore {
    var trips: [Trip] = []

    init() { seedDemo() }

    func add(named name: String = "Neue Reise") -> Trip {
        let trip = Trip(name: name, accentHex: nextAccent())
        trips.append(trip)
        return trip
    }

    func remove(_ trip: Trip) {
        trips.removeAll { $0.id == trip.id }
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

    var body: some View {
        NavigationStack {
            TripsListView(store: store)
                .navigationDestination(for: Trip.self) { trip in
                    TripDetailView(trip: trip, store: store)
                }
        }
        .tint(AppTheme.accent)
    }
}

// MARK: - Trips List (Übersicht)

struct TripsListView: View {
    let store: TripsStore

    @State private var pushNewTrip: Trip? = nil

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
        .navigationDestination(item: $pushNewTrip) { trip in
            TripDetailView(trip: trip, store: store)
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
            }
            newTripCard
        }
    }

    private var newTripCard: some View {
        Button {
            pushNewTrip = store.add()
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
                LinearGradient(
                    colors: [trip.accent.opacity(0.85), trip.accent.opacity(0.35), Color.black.opacity(0.6)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                Text(trip.coverEmoji)
                    .font(.system(size: 60))
                    .padding(.top, 14)
                    .padding(.trailing, 14)
                    .shadow(color: .black.opacity(0.4), radius: 12)
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
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(trip.coverEmoji).font(.system(size: 40))
                    Text(trip.dateRangeLabel)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(AppTheme.textMuted)
                }
                Spacer()
                travelersButton
            }

            TextField("", text: $trip.name, prompt: Text("Name deiner Reise...").foregroundStyle(AppTheme.text.opacity(0.25)))
                .font(.system(.title2, design: .serif))
                .foregroundStyle(AppTheme.text)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(Color.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 8))
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(AppTheme.border, lineWidth: 1))
                .submitLabel(.done)
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
