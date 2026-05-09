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

// MARK: - Store

@Observable
final class TripStore {
    var tripName: String = "Meine Traumreise"
    var travelers: Travelers = Travelers(adults: 2, children: [])
    var segments: [TripSegment] = []

    init() {
        seedDemo()
    }

    private func seedDemo() {
        let cal = Calendar.current
        let base = cal.date(from: DateComponents(year: 2026, month: 6, day: 1))!
        segments = [
            TripSegment(type: .flight, from: "Berlin", to: "Barcelona", date: base),
            TripSegment(type: .hotel, from: "", to: "Barcelona", date: base),
            TripSegment(type: .car, from: "Barcelona", to: "Valencia", date: cal.date(byAdding: .day, value: 3, to: base)),
            TripSegment(type: .train, from: "Valencia", to: "Madrid", date: cal.date(byAdding: .day, value: 6, to: base)),
        ]
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

    var uniquePlaceCount: Int {
        Set(segments.flatMap { [$0.from, $0.to] }.filter { !$0.isEmpty }).count
    }

    func count(of type: TransportType) -> Int {
        segments.filter { $0.type == type }.count
    }
}

// MARK: - Root

struct ContentView: View {
    @State private var store = TripStore()
    @State private var showTravelers = false

    var body: some View {
        ZStack(alignment: .top) {
            AppTheme.bg.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    headerSection
                    SummaryBar(store: store)
                    sectionTitle("Reiseplan")
                    Timeline(store: store)
                    addSegmentButton
                    if !store.segments.isEmpty {
                        sectionTitle("Buchungsübersicht")
                            .padding(.top, 12)
                        BookingOverview(store: store)
                    }
                    Color.clear.frame(height: 24)
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
            }
        }
        .preferredColorScheme(.dark)
        .sheet(isPresented: $showTravelers) {
            TravelersSheet(travelers: $store.travelers)
                .presentationDetents([.medium, .large])
                .presentationBackground(AppTheme.bg)
        }
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 0) {
                        Text("My").font(.system(.largeTitle, design: .serif).weight(.bold))
                        Text("Voyage").font(.system(.largeTitle, design: .serif).weight(.bold))
                            .foregroundStyle(AppTheme.accent)
                    }
                    .foregroundStyle(AppTheme.text)
                    Text("INDIVIDUELLE REISEPLANUNG")
                        .font(.system(size: 10).weight(.medium))
                        .tracking(2)
                        .foregroundStyle(AppTheme.textSubtle)
                }
                Spacer()
                travelersButton
            }
            TextField("", text: $store.tripName, prompt: Text("Name deiner Reise...").foregroundStyle(AppTheme.text.opacity(0.25)))
                .font(.system(.title3, design: .serif))
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
                Text(store.travelers.summary).font(.system(size: 13))
                Text("\(store.travelers.total)")
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
            withAnimation(.snappy) { store.addSegment() }
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
    let store: TripStore

    var body: some View {
        if store.segments.isEmpty { EmptyView() } else {
            HStack(spacing: 18) {
                stat("\(store.travelers.total)", "Reisende", accent: true)
                stat("\(store.segments.count)", "Etappen")
                stat("\(store.uniquePlaceCount)", "Orte")
                stat("\(store.count(of: .flight))", "Flüge")
                stat("\(store.count(of: .hotel))", "Hotels")
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

// MARK: - Timeline

struct Timeline: View {
    let store: TripStore

    var body: some View {
        if store.segments.isEmpty {
            VStack(spacing: 8) {
                Image(systemName: "map")
                    .font(.system(size: 36))
                    .foregroundStyle(AppTheme.textSubtle)
                Text("Noch keine Etappen — füge deine erste hinzu!")
                    .font(.system(size: 13))
                    .foregroundStyle(AppTheme.textSubtle)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 32)
        } else {
            VStack(spacing: 0) {
                ForEach(Array(store.segments.enumerated()), id: \.element.id) { index, segment in
                    HStack(alignment: .top, spacing: 12) {
                        TimelineDot(type: segment.type, isLast: index == store.segments.count - 1)
                        SegmentCard(
                            segment: segment,
                            travelers: store.travelers,
                            onChange: { store.update($0) },
                            onRemove: { store.remove(segment) }
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
    let store: TripStore

    private var validSegments: [TripSegment] {
        store.segments.filter { !$0.from.isEmpty || !$0.to.isEmpty }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: "person.2.fill").font(.system(size: 11))
                Text(store.travelers.summary).font(.system(size: 12))
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
                        if let url = portal.urlBuilder(segment, store.travelers) {
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

// MARK: - Splash

struct SplashView: View {
    @Binding var isPresented: Bool
    @State private var animateCards = false
    @State private var animateLogo = false
    @State private var fadeOut = false

    private struct Destination {
        let emoji: String
        let city: String
        let angle: Double  // degrees, 0 = right, 90 = down
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

#Preview {
    ContentView()
}

#Preview("Splash") {
    SplashView(isPresented: .constant(true))
}
