import SwiftUI
import WidgetKit
import AppIntents
import CozyCore

/// Điểm vào chung: vẽ widget theo family + nội dung trong cấu hình.
struct CozyWidgetView: View {
    var data: CozyWidgetData
    /// Truyền tường minh để App (Xưởng Widget) dùng lại đúng view này cho Live Preview.
    var family: WidgetFamily

    var body: some View {
        Group {
            switch family {
            case .accessoryInline:
                InlineAccessory(data: data)
            case .accessoryCircular:
                CircularAccessory(data: data)
            case .accessoryRectangular:
                RectangularAccessory(data: data)
            default:
                HomeWidget(data: data, family: family)
            }
        }
        .containerBackground(for: .widget) {
            if family.isAccessory {
                Color.clear
            } else {
                ZStack {
                    data.theme.background.opacity(data.config.backgroundOpacity)
                    data.theme.wash(accent: data.config.accent.color)
                    // Vệt sáng pastel nhẹ góc trên giúp widget bắt mắt hơn
                    Circle()
                        .fill(data.config.accent.color.opacity(0.16))
                        .frame(width: 140, height: 140)
                        .blur(radius: 36)
                        .offset(x: 68, y: -56)
                }
            }
        }
    }
}

extension WidgetFamily {
    var isAccessory: Bool {
        switch self {
        case .accessoryInline, .accessoryCircular, .accessoryRectangular: return true
        default: return false
        }
    }
}

// MARK: - Home Screen

private struct HomeWidget: View {
    var data: CozyWidgetData
    var family: WidgetFamily

    var ink: Color { data.theme.ink }
    var sub: Color { data.theme.secondaryInk }
    var accent: Color { data.config.accent.color }
    var font: WidgetFontStyle { data.config.font }

    var body: some View {
        content
            .foregroundStyle(ink)
            .overlay { border }
    }

    @ViewBuilder
    private var content: some View {
        switch data.config.content {
        case .vocab: VocabHome(data: data, family: family)
        case .moodFood: MoodFoodHome(data: data, family: family)
        case .couple: CoupleHome(data: data, family: family)
        case .squad: SquadHome(data: data, family: family)
        case .event: EventHome(data: data, family: family)
        case .weather: WeatherHome(data: data, family: family)
        case .streak: StreakHome(data: data, family: family)
        case .mascot: MascotHome(data: data, family: family)
        case .combo: ComboHome(data: data, family: family)
        }
    }

    @ViewBuilder
    private var border: some View {
        let shape = ContainerRelativeShape()
        switch data.config.border {
        case .none: EmptyView()
        case .hairline: shape.strokeBorder(Color.cardBorder.opacity(0.85), lineWidth: 1).padding(-14)
        case .dashed: shape.strokeBorder(accent.opacity(0.6), style: StrokeStyle(lineWidth: 1.5, dash: [5, 4])).padding(-8)
        case .stitched: shape.strokeBorder(accent.opacity(0.55), style: StrokeStyle(lineWidth: 2, dash: [2, 3])).padding(-6)
        }
    }
}

private struct WidgetHeader: View {
    var title: String
    var symbol: String
    var data: CozyWidgetData
    var trailing: String? = nil

    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: symbol)
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 18, height: 18)
                .background(Circle().fill(data.config.accent.color))
            Text(title)
                .font(data.config.font.font(size: 11, weight: .bold))
                .foregroundStyle(data.config.accent.color)
            Spacer(minLength: 0)
            if let trailing {
                Text(trailing)
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundStyle(data.theme.secondaryInk)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Capsule().fill(data.config.accent.color.opacity(0.14)))
            } else if let h = data.holiday {
                Text(h.emoji).font(.system(size: 12))
            }
        }
        .lineLimit(1)
    }
}

private struct WidgetSoftSurface<Content: View>: View {
    var tint: Color
    var isDark: Bool
    @ViewBuilder var content: () -> Content

    var body: some View {
        content()
            .padding(.horizontal, 9)
            .padding(.vertical, 6)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(isDark ? Color.white.opacity(0.08) : Color.white.opacity(0.65))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(tint.opacity(0.10))
                    )
            )
    }
}

// MARK: Vocab

private struct VocabHome: View {
    var data: CozyWidgetData
    var family: WidgetFamily

    var body: some View {
        if let w = data.word {
            VStack(alignment: .leading, spacing: family == .systemSmall ? 4 : 6) {
                WidgetHeader(
                    title: "Từ vựng hôm nay",
                    symbol: "character.book.closed.fill",
                    data: data,
                    trailing: family == .systemSmall ? nil : "🔥 \(data.streak)n"
                )
                HStack(alignment: .center, spacing: 8) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(w.word)
                            .font(data.config.font.font(size: family == .systemSmall ? 20 : 25, weight: .bold))
                            .minimumScaleFactor(0.6)
                            .lineLimit(2)
                        if !w.phonetic.isEmpty {
                            Text(w.phonetic)
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundStyle(data.theme.secondaryInk)
                                .lineLimit(1)
                        }
                    }
                    .cozySwap(w.id)
                    .invalidatableContent()
                    Spacer(minLength: 0)
                    if data.config.showMascot && family != .systemSmall {
                        WidgetMascot(state: data.mascot, size: 50)
                    }
                }
                WidgetSoftSurface(tint: Color.accentSage, isDark: data.theme == .night) {
                    Text(w.meaning)
                        .font(.system(size: 12.5, weight: .semibold, design: .rounded))
                        .lineLimit(family == .systemLarge ? 3 : 2)
                        .cozySwap(w.id)
                        .invalidatableContent()
                }
                if family == .systemLarge {
                    if !w.example.isEmpty {
                        Text("“\(w.example)”")
                            .font(.system(size: 13, design: .serif).italic())
                            .foregroundStyle(data.theme.secondaryInk)
                            .padding(.top, 2)
                    }
                    Spacer(minLength: 4)
                    HStack(spacing: 8) {
                        Label("\(data.streak) ngày", systemImage: "flame.fill").cozyNumeric(data.streak)
                        Spacer()
                        Label("\(data.learnedToday) từ hôm nay", systemImage: "sparkles").cozyNumeric(data.learnedToday)
                        Spacer()
                        Label("\(data.dueCount) cần ôn", systemImage: "arrow.triangle.2.circlepath").cozyNumeric(data.dueCount)
                    }
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundStyle(data.theme.secondaryInk)
                }
                Spacer(minLength: 0)
                HStack(spacing: 6) {
                    Button(intent: MarkWordLearnedIntent()) {
                        Label(family == .systemSmall ? "Thuộc" : "Đã thuộc", systemImage: "checkmark")
                    }
                    .buttonStyle(WidgetPillStyle(tint: Color.accentSage, filled: true))
                    Button(intent: NextVocabIntent()) {
                        Label(family == .systemSmall ? "Đổi" : "Đổi từ", systemImage: "shuffle")
                    }
                    .buttonStyle(WidgetPillStyle(tint: Color.accentSage, filled: false))
                }
            }
        } else {
            EmptyState(text: "Chọn kho từ vựng trong app nhé", symbol: "character.book.closed")
        }
    }
}

struct WidgetPillStyle: ButtonStyle {
    @Environment(\.widgetRenderingMode) private var renderingMode
    var tint: Color
    var filled: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 11.5, weight: .bold, design: .rounded))
            .labelStyle(.titleAndIcon)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .frame(maxWidth: .infinity)
            .foregroundStyle(renderingMode == .fullColor ? (filled ? Color.white : tint) : Color.primary)
            .background(Capsule().fill(renderingMode == .fullColor ? (filled ? tint : tint.opacity(0.16)) : Color.primary.opacity(filled ? 0.28 : 0.12)))
            .opacity(configuration.isPressed ? 0.72 : 1)
    }
}

// MARK: Mood + Food

private struct MoodFoodHome: View {
    var data: CozyWidgetData
    var family: WidgetFamily

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            WidgetHeader(
                title: "Hôm nay thế nào?",
                symbol: "face.smiling",
                data: data,
                trailing: data.checkIn.map { $0.date.formatted(date: .omitted, time: .shortened) }
            )
            HStack(alignment: .center, spacing: 10) {
                WidgetMascot(state: data.mascot, size: family == .systemSmall ? 54 : 64)
                VStack(alignment: .leading, spacing: 3) {
                    Text(data.checkIn.map { "\($0.mood.emoji) \($0.mood.displayName)" } ?? "Chạm check-in nha")
                        .font(data.config.font.font(size: 15, weight: .bold))
                        .lineLimit(1)
                    if let foods = data.checkIn?.foods, !foods.isEmpty {
                        HStack(spacing: 3) {
                            ForEach(foods.prefix(4)) { CozyAssetImage(asset: $0.asset, size: 19) }
                        }
                    } else {
                        Text(data.mascot.caption)
                            .font(.system(size: 10.5, weight: .medium, design: .rounded))
                            .foregroundStyle(data.theme.secondaryInk)
                            .lineLimit(2)
                    }
                }
                .cozySwap(data.checkIn?.id)
                .invalidatableContent()
            }
            if let c = data.checkIn {
                BatteryBar(value: c.socialBattery, tint: data.config.accent.color)
                if family != .systemSmall, !c.note.isEmpty {
                    Text("“\(c.note)”")
                        .font(data.config.font.font(size: 12.5, weight: .regular))
                        .foregroundStyle(data.theme.secondaryInk)
                        .lineLimit(1)
                }
            }
            Spacer(minLength: 0)
            if family != .systemSmall {
                HStack(spacing: 6) {
                    ForEach([MoodOption.happy, .chill, .tired, .missing], id: \.self) { m in
                        Button(intent: QuickCheckInIntent(mood: m)) { CozyAssetImage(asset: m.mood.asset, size: 20) }
                            .buttonStyle(.plain)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 5)
                            .background(Capsule().fill(data.config.accent.color.opacity(0.16)))
                    }
                }
            }
            if family == .systemLarge {
                HStack(spacing: 6) {
                    ForEach([FoodOption.pho, .comTam, .banhMi, .milkTea, .coffee], id: \.self) { f in
                        Button(intent: QuickCheckInIntent(food: f)) { CozyAssetImage(asset: f.food.asset, size: 22) }
                            .buttonStyle(.plain)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 5)
                            .background(Capsule().fill(Color.accentHoney.opacity(0.20)))
                    }
                }
            }
        }
    }
}

struct BatteryBar: View {
    var value: Int
    var tint: Color

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: batterySymbol).font(.system(size: 11, weight: .bold)).foregroundStyle(tint)
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(tint.opacity(0.18))
                    Capsule()
                        .fill(LinearGradient(colors: [tint.opacity(0.82), tint], startPoint: .leading, endPoint: .trailing))
                        .frame(width: geo.size.width * CGFloat(value) / 100)
                }
            }
            .frame(height: 6)
            Text("\(value)%").font(.system(size: 10, weight: .bold, design: .rounded)).monospacedDigit().cozyNumeric(value)
        }
        .accessibilityLabel("Pin xã hội \(value) phần trăm")
    }

    var batterySymbol: String {
        switch value {
        case ..<20: return "battery.0percent"
        case ..<45: return "battery.25percent"
        case ..<70: return "battery.50percent"
        case ..<90: return "battery.75percent"
        default: return "battery.100percent"
        }
    }
}

// MARK: Couple

private struct CoupleHome: View {
    var data: CozyWidgetData
    var family: WidgetFamily

    var body: some View {
        if let me = data.me, let partner = data.partner {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    WidgetHeader(title: data.couple?.name ?? "Couple", symbol: "heart.fill", data: data)
                    if let a = data.couple?.anniversary {
                        let days = EventCounter().status(of: CozyEvent(title: "", kind: .countUp(since: a)), now: data.date).days
                        Text("\(days) ngày 💞")
                            .font(.system(size: 10.5, weight: .heavy, design: .rounded))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Capsule().fill(Color.accentPeach))
                            .cozyNumeric(days)
                    }
                }
                HStack(spacing: 8) {
                    MemberColumn(member: me, data: data, compact: family == .systemSmall)
                    if family != .systemSmall {
                        Image(systemName: "heart.fill")
                            .foregroundStyle(Color.accentPeach)
                            .font(.system(size: 15))
                    }
                    MemberColumn(member: partner, data: data, compact: family == .systemSmall)
                }
                Spacer(minLength: 0)
                if family != .systemSmall {
                    HStack(spacing: 6) {
                        ForEach([PingOption.ateYet, .missYou, .craveMilkTea], id: \.self) { p in
                            Button(intent: SendPingIntent(ping: p)) {
                                Text("\(p.ping.emoji) \(p.ping.text)").lineLimit(1).minimumScaleFactor(0.7)
                            }
                            .buttonStyle(WidgetPillStyle(tint: Color.accentPeach, filled: p == .missYou))
                        }
                    }
                }
            }
        } else {
            EmptyState(text: "Mời người yêu vào Couple Space trong app", symbol: "heart")
        }
    }
}

private struct MemberColumn: View {
    var member: MemberStatus
    var data: CozyWidgetData
    var compact: Bool

    var body: some View {
        VStack(spacing: 3) {
            WidgetMascot(
                state: MascotEngine.resolve(species: member.species, mood: member.mood, weather: member.id == DemoData.meID ? data.weather : nil, date: data.date),
                size: compact ? 42 : 52
            )
            Text(member.displayName).font(data.config.font.font(size: 12, weight: .bold)).lineLimit(1)
            Text(member.mood.map { "\($0.emoji) \($0.displayName)" } ?? "–")
                .font(.system(size: 10, weight: .semibold, design: .rounded))
                .foregroundStyle(data.theme.secondaryInk)
                .lineLimit(1)
            if !compact {
                HStack(spacing: 4) {
                    if let b = member.deviceBattery {
                        Label("\(Int(b * 100))%", systemImage: "battery.75percent")
                    }
                    if let f = member.foods.first { Text(f.emoji) }
                }
                .font(.system(size: 9, weight: .semibold))
                .foregroundStyle(data.theme.secondaryInk)
                if let w = member.weatherLine {
                    Text(w).font(.system(size: 9)).foregroundStyle(data.theme.secondaryInk).lineLimit(1)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 5)
        .padding(.horizontal, 4)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(data.theme == .night ? Color.white.opacity(0.06) : Color.white.opacity(0.55))
        )
    }
}

// MARK: Squad

private struct SquadHome: View {
    var data: CozyWidgetData
    var family: WidgetFamily

    var body: some View {
        if let squad = data.squad {
            VStack(alignment: .leading, spacing: 6) {
                WidgetHeader(title: squad.name, symbol: "person.3.fill", data: data, trailing: "\(squad.members.count) bạn")
                let columns = family == .systemSmall ? 2 : 4
                let members = Array(squad.members.prefix(family == .systemLarge ? 8 : 4))
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: columns), spacing: 6) {
                    ForEach(members) { m in
                        VStack(spacing: 2) {
                            WidgetMascot(
                                state: MascotEngine.resolve(species: m.species, mood: m.mood, weather: nil, date: data.date),
                                size: family == .systemSmall ? 34 : 40
                            )
                            Text(m.displayName).font(data.config.font.font(size: 10, weight: .bold)).lineLimit(1)
                            if family != .systemSmall, let s = m.socialBattery {
                                Text("🔋\(s)%").font(.system(size: 9, weight: .semibold)).foregroundStyle(data.theme.secondaryInk)
                            }
                        }
                    }
                }
                Spacer(minLength: 0)
                if family != .systemSmall, let last = squad.interactions.max(by: { $0.sentAt < $1.sentAt }) {
                    let who = squad.members.first { $0.id == last.fromMemberID }?.displayName ?? "Ai đó"
                    WidgetSoftSurface(tint: Color.accentHoney, isDark: data.theme == .night) {
                        Text("\(who): \(last.displayText)")
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                            .lineLimit(1)
                    }
                }
            }
        } else {
            EmptyState(text: "Tạo Squad Board trong tab Kết nối", symbol: "person.3")
        }
    }
}

// MARK: Event

private struct EventHome: View {
    var data: CozyWidgetData
    var family: WidgetFamily

    var body: some View {
        if let e = data.event, let s = data.eventStatus {
            VStack(alignment: .leading, spacing: 4) {
                WidgetHeader(title: e.kind.modeName, symbol: e.kind.symbolName, data: data, trailing: "\(data.lunar.shortText) ÂL")
                Spacer(minLength: 0)
                HStack(alignment: .center) {
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(alignment: .lastTextBaseline, spacing: 4) {
                            Text(s.headline)
                                .font(.system(size: family == .systemSmall ? 42 : 50, weight: .heavy, design: .rounded))
                                .foregroundStyle(s.direction == .overdue ? Color.accentPeach : data.theme.ink)
                                .minimumScaleFactor(0.5)
                                .cozyNumeric(s.days)
                            Text(s.caption)
                                .font(.system(size: 12, weight: .bold, design: .rounded))
                                .foregroundStyle(data.theme.secondaryInk)
                        }
                        Text("\(e.emoji) \(e.title)")
                            .font(data.config.font.font(size: 15, weight: .bold))
                            .lineLimit(2)
                    }
                    Spacer(minLength: 0)
                    if data.config.showMascot && family != .systemSmall {
                        WidgetMascot(state: data.mascot, size: 58)
                    }
                }
                if let d = s.referenceDate, family != .systemSmall {
                    Text(d, format: .dateTime.weekday(.wide).day().month().locale(Locale(identifier: "vi_VN")))
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(data.theme.secondaryInk)
                }
                if family == .systemLarge {
                    Divider().padding(.vertical, 6)
                    Text("Âm lịch hôm nay: \(data.lunar.shortText) · năm \(data.lunar.yearName)")
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundStyle(data.theme.secondaryInk)
                    ForEach(Array(data.tomorrowEvents.prefix(3))) { item in
                        Text("Mai: \(item.event.emoji) \(item.event.title)").font(.system(size: 12, weight: .medium))
                    }
                }
            }
        } else {
            EmptyState(text: "Thêm sự kiện trong tab Lịch", symbol: "calendar.badge.plus")
        }
    }
}

// MARK: Weather

private struct WeatherHome: View {
    var data: CozyWidgetData
    var family: WidgetFamily

    var body: some View {
        if let w = data.weather {
            VStack(alignment: .leading, spacing: 5) {
                WidgetHeader(
                    title: w.placeName,
                    symbol: "location.fill",
                    data: data,
                    trailing: "C:\(Int(w.highC))° T:\(Int(w.lowC))°"
                )
                HStack(alignment: .center) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(w.temperatureText)
                            .font(.system(size: family == .systemSmall ? 38 : 44, weight: .heavy, design: .rounded))
                            .cozyNumeric(Int(w.temperatureC.rounded()))
                        Label(w.condition.displayName, systemImage: w.condition.symbolName)
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .symbolRenderingMode(.multicolor)
                            .lineLimit(1)
                    }
                    Spacer(minLength: 0)
                    if data.config.showMascot {
                        WidgetMascot(state: data.mascot, size: family == .systemSmall ? 54 : 68)
                    }
                }
                Spacer(minLength: 0)
                if family == .systemSmall {
                    Text(WeatherSuggestion.foods(for: w).prefix(2).map { "\($0.emoji) \($0.displayName)" }.joined(separator: " · "))
                        .font(.system(size: 10.5, weight: .semibold, design: .rounded))
                        .foregroundStyle(data.theme.secondaryInk)
                        .lineLimit(1)
                } else {
                    WidgetSoftSurface(tint: Color.accentSky, isDark: data.theme == .night) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(WeatherSuggestion.outfit(for: w))
                                .font(data.config.font.font(size: 11.5, weight: .semibold))
                                .lineLimit(1)
                            Text("Gợi ý: " + WeatherSuggestion.foods(for: w).map { "\($0.emoji) \($0.displayName)" }.joined(separator: " · "))
                                .font(.system(size: 10.5, weight: .medium, design: .rounded))
                                .foregroundStyle(data.theme.secondaryInk)
                                .lineLimit(1)
                        }
                    }
                }
            }
        } else {
            EmptyState(text: "Mở app để cập nhật thời tiết thật", symbol: "cloud.sun")
        }
    }
}

// MARK: Streak / Mascot / Combo

private struct StreakHome: View {
    var data: CozyWidgetData
    var family: WidgetFamily

    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                Circle().stroke(Color.accentSage.opacity(0.2), lineWidth: 11)
                Circle()
                    .trim(from: 0, to: min(1, CGFloat(max(data.streak, 1)) / 30))
                    .stroke(
                        AngularGradient(colors: [Color.accentSage, Color.accentHoney, Color.accentSage], center: .center),
                        style: StrokeStyle(lineWidth: 11, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                VStack(spacing: 0) {
                    Text("\(data.streak)").font(.system(size: 30, weight: .heavy, design: .rounded)).cozyNumeric(data.streak)
                    Text("ngày 🔥").font(.system(size: 11, weight: .bold, design: .rounded))
                }
            }
            .padding(4)
            if family != .systemSmall {
                Text("\(data.learnedToday) từ hôm nay · \(data.dueCount) cần ôn")
                    .cozyNumeric(data.dueCount)
                    .font(.system(size: 11.5, weight: .semibold, design: .rounded))
                    .foregroundStyle(data.theme.secondaryInk)
            }
        }
    }
}

private struct MascotHome: View {
    var data: CozyWidgetData
    var family: WidgetFamily

    var body: some View {
        VStack(spacing: 6) {
            WidgetMascot(state: data.mascot, size: family == .systemSmall ? 88 : 114)
            Text(data.mascot.caption)
                .font(data.config.font.font(size: 11.5, weight: .semibold))
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Capsule().fill(data.config.accent.color.opacity(0.14)))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

private struct ComboHome: View {
    var data: CozyWidgetData
    var family: WidgetFamily

    var body: some View {
        if family == .systemSmall {
            VStack(alignment: .leading, spacing: 5) {
                HStack(alignment: .top) {
                    WidgetMascot(state: data.mascot, size: 54)
                    Spacer(minLength: 0)
                    if let w = data.weather {
                        VStack(alignment: .trailing, spacing: 1) {
                            Text(w.temperatureText)
                                .font(.system(size: 24, weight: .heavy, design: .rounded))
                                .cozyNumeric(Int(w.temperatureC.rounded()))
                            Image(systemName: w.condition.symbolName)
                                .symbolRenderingMode(.multicolor)
                                .font(.system(size: 14))
                            Text(w.placeName)
                                .font(.system(size: 9, weight: .semibold, design: .rounded))
                                .foregroundStyle(data.theme.secondaryInk)
                                .lineLimit(1)
                        }
                    }
                }
                Spacer(minLength: 0)
                WidgetSoftSurface(tint: data.config.accent.color, isDark: data.theme == .night) {
                    VStack(alignment: .leading, spacing: 1) {
                        if let w = data.word {
                            Text(w.word).font(data.config.font.font(size: 14.5, weight: .bold)).lineLimit(1)
                            Text(w.meaning).font(.system(size: 10.5, weight: .medium)).foregroundStyle(data.theme.secondaryInk).lineLimit(1)
                        } else {
                            Text("\(data.lunar.shortText) ÂL · 🔥 \(data.streak)n")
                                .font(.system(size: 11, weight: .bold, design: .rounded))
                        }
                    }
                }
            }
        } else {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 5) {
                    Text(DayPart(date: data.date).greeting)
                        .font(data.config.font.font(size: 13.5, weight: .bold))
                        .lineLimit(1)
                    Text("\(data.lunar.shortText) ÂL · \(data.lunar.yearName)")
                        .font(.system(size: 10.5, weight: .semibold, design: .rounded))
                        .foregroundStyle(data.theme.secondaryInk)
                    Spacer(minLength: 0)
                    HStack(spacing: 6) {
                        WidgetMascot(state: data.mascot, size: family == .systemLarge ? 78 : 62)
                        if let c = data.checkIn {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(c.mood.emoji).font(.system(size: 20))
                                if !c.foods.isEmpty {
                                    Text(c.foods.prefix(2).map(\.emoji).joined()).font(.system(size: 14))
                                }
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                VStack(alignment: .leading, spacing: 6) {
                    if let w = data.weather {
                        WidgetSoftSurface(tint: Color.accentSky, isDark: data.theme == .night) {
                            HStack(spacing: 6) {
                                Image(systemName: w.condition.symbolName)
                                    .symbolRenderingMode(.multicolor)
                                    .font(.system(size: 16))
                                VStack(alignment: .leading, spacing: 0) {
                                    Text("\(w.temperatureText) \(w.condition.displayName)")
                                        .font(.system(size: 12, weight: .bold, design: .rounded))
                                        .lineLimit(1)
                                    Text(w.placeName)
                                        .font(.system(size: 10, weight: .medium))
                                        .foregroundStyle(data.theme.secondaryInk)
                                        .lineLimit(1)
                                }
                            }
                        }
                    }
                    if let w = data.word {
                        WidgetSoftSurface(tint: Color.accentSage, isDark: data.theme == .night) {
                            VStack(alignment: .leading, spacing: 1) {
                                Text("✨ \(w.word)")
                                    .font(data.config.font.font(size: 13, weight: .bold))
                                    .lineLimit(1)
                                Text(w.meaning)
                                    .font(.system(size: 10.5, weight: .medium))
                                    .foregroundStyle(data.theme.secondaryInk)
                                    .lineLimit(1)
                            }
                        }
                    }
                    if let e = data.event, let s = data.eventStatus {
                        WidgetSoftSurface(tint: Color.accentPeach, isDark: data.theme == .night) {
                            Text("\(e.emoji) \(e.title): \(s.sentence)")
                                .font(.system(size: 11, weight: .semibold, design: .rounded))
                                .lineLimit(1)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
}

private struct EmptyState: View {
    var text: String
    var symbol: String

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: symbol).font(.system(size: 22))
            Text(text).font(.system(size: 12, weight: .medium, design: .rounded)).multilineTextAlignment(.center)
        }
        .foregroundStyle(Color.inkTaupe)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Lock Screen (100% Real Data, siêu sắc nét & bắt mắt)

private struct InlineAccessory: View {
    var data: CozyWidgetData

    var body: some View {
        // Inline chỉ nhận 1 ảnh + 1 dòng chữ, hệ thống tự tô màu.
        switch data.config.content {
        case .vocab:
            Label(
                data.word.map { "\($0.word) · 🔥\(data.streak)" } ?? "CozyDaily",
                systemImage: "character.book.closed.fill"
            )
        case .couple:
            Label(
                data.partner.map { "\($0.displayName): \($0.mood?.displayName ?? "đang online")" } ?? "Couple",
                systemImage: data.partner?.mood?.monochromeSymbolName ?? "heart.fill"
            )
        case .event:
            Label(
                data.eventStatus.map { "\(data.event?.title ?? ""): \($0.sentence)" } ?? "Sự kiện",
                systemImage: data.event?.kind.symbolName ?? "calendar"
            )
            .contentTransition(.numericText())
        case .weather:
            Label(
                data.weather.map { "\($0.temperatureText) \($0.condition.displayName) · \($0.placeName)" } ?? "Thời tiết",
                systemImage: data.weather?.condition.asset.monochromeSymbolName ?? "cloud.sun.fill"
            )
            .contentTransition(.numericText())
        case .combo:
            if let w = data.weather {
                Label(
                    "\(w.temperatureText) \(w.placeName) · \(data.lunar.shortText) ÂL",
                    systemImage: w.condition.asset.monochromeSymbolName
                )
                .contentTransition(.numericText())
            } else {
                Label("\(data.lunar.shortText) ÂL · 🔥\(data.streak) ngày", systemImage: "pawprint.fill")
            }
        default:
            Label(
                "\(data.lunar.shortText) ÂL · \(data.streak) ngày",
                systemImage: data.checkIn?.mood.monochromeSymbolName ?? "pawprint.fill"
            )
            .contentTransition(.numericText())
        }
    }
}

private struct CircularAccessory: View {
    var data: CozyWidgetData

    var body: some View {
        switch data.config.content {
        case .streak, .vocab:
            Gauge(value: Double(min(data.streak, 30)), in: 0...30) {
                Image(systemName: "flame.fill")
            } currentValueLabel: {
                Text("\(data.streak)").cozyNumeric(data.streak)
            }
            .gaugeStyle(.accessoryCircularCapacity)
            .widgetAccentable()
        case .event:
            ZStack {
                AccessoryWidgetBackground()
                VStack(spacing: -1) {
                    Text(data.eventStatus.map { $0.direction == .today ? "0" : $0.headline } ?? "–")
                        .font(.system(size: 20, weight: .heavy, design: .rounded)).minimumScaleFactor(0.5)
                        .cozyNumeric(data.eventStatus?.days ?? 0)
                    Image(systemName: data.event?.kind.symbolName ?? "calendar").font(.system(size: 10, weight: .bold)).widgetAccentable()
                }
            }
        case .couple:
            ZStack {
                AccessoryWidgetBackground()
                VStack(spacing: -1) {
                    Image(systemName: "heart.fill").font(.system(size: 10)).widgetAccentable()
                    Text(anniversaryDays.map(String.init) ?? "–")
                        .font(.system(size: 16, weight: .heavy, design: .rounded)).minimumScaleFactor(0.5)
                        .cozyNumeric(anniversaryDays ?? 0)
                }
            }
        case .weather, .combo:
            ZStack {
                AccessoryWidgetBackground()
                if let w = data.weather {
                    VStack(spacing: 0) {
                        Image(systemName: w.condition.asset.monochromeSymbolName)
                            .font(.system(size: 14, weight: .bold))
                            .widgetAccentable()
                        Text(w.temperatureText)
                            .font(.system(size: 16, weight: .heavy, design: .rounded))
                            .cozyNumeric(Int(w.temperatureC.rounded()))
                    }
                } else {
                    MascotGlyph(state: data.mascot)
                }
            }
        default:
            ZStack {
                AccessoryWidgetBackground()
                if let mood = data.checkIn?.mood, data.config.content == .moodFood {
                    CozyAssetImage(asset: mood.asset, size: 30)
                } else {
                    MascotGlyph(state: data.mascot)
                }
            }
            .cozySwap(data.checkIn?.id)
        }
    }

    var anniversaryDays: Int? {
        guard let a = data.couple?.anniversary else { return nil }
        return EventCounter().status(of: CozyEvent(title: "", kind: .countUp(since: a)), now: data.date).days
    }
}

private struct RectangularAccessory: View {
    @Environment(\.isLuminanceReduced) private var isLuminanceReduced
    var data: CozyWidgetData

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            switch data.config.content {
            case .vocab:
                if let w = data.word {
                    HStack(spacing: 4) {
                        Image(systemName: "character.book.closed.fill").font(.system(size: 11, weight: .bold)).widgetAccentable()
                        Text(w.word).font(data.config.font.font(size: 15, weight: .bold)).lineLimit(1).widgetAccentable()
                    }
                    if !w.phonetic.isEmpty {
                        Text(w.phonetic).font(.system(size: 10.5, design: .monospaced)).opacity(0.8).lineLimit(1)
                    }
                    // Chế độ ẩn nghĩa để luyện phản xạ: nghĩa chỉ hiện khi máy đã mở khóa.
                    if data.config.hideMeaningOnLockScreen {
                        Text(w.meaning).font(.system(size: 12, weight: .medium)).lineLimit(1).privacySensitive()
                    } else {
                        Text(w.meaning).font(.system(size: 12, weight: .medium)).lineLimit(1)
                    }
                }
            case .weather:
                if let w = data.weather {
                    HStack(spacing: 4) {
                        Image(systemName: w.condition.asset.monochromeSymbolName).font(.system(size: 12, weight: .bold)).widgetAccentable()
                        Text("\(w.temperatureText) \(w.condition.displayName)")
                            .font(.system(size: 15, weight: .heavy, design: .rounded))
                            .cozyNumeric(Int(w.temperatureC.rounded()))
                            .widgetAccentable()
                    }
                    Text("\(w.placeName) · C:\(Int(w.highC))° T:\(Int(w.lowC))°")
                        .font(.system(size: 11.5, weight: .semibold, design: .rounded))
                        .lineLimit(1)
                    Text(data.mascot.caption)
                        .font(.system(size: 11))
                        .opacity(0.85)
                        .lineLimit(1)
                } else {
                    Label("Mở app lấy thời tiết thật", systemImage: "cloud.sun.fill").font(.system(size: 12, weight: .semibold))
                }
            case .couple:
                HStack(spacing: 4) {
                    Image(systemName: data.partner?.mood?.monochromeSymbolName ?? "heart.fill").widgetAccentable()
                    Text(data.partner?.displayName ?? "Couple").font(.system(size: 14, weight: .bold)).lineLimit(1)
                    if let b = data.partner?.deviceBattery {
                        Spacer(minLength: 2)
                        Text("\(Int(b * 100))%").font(.system(size: 10, weight: .bold, design: .rounded)).opacity(0.8)
                    }
                }
                Text(data.partner?.note.isEmpty == false ? "“\(data.partner!.note)”" : (data.partner?.mood?.displayName ?? "Đang kết nối"))
                    .font(.system(size: 12, weight: .medium))
                    .lineLimit(1)
                Text(data.partner?.weatherLine ?? "\(data.lunar.shortText) ÂL")
                    .font(.system(size: 11))
                    .opacity(0.8)
                    .lineLimit(1)
            case .event:
                Label(data.event?.title ?? "Sự kiện", systemImage: data.event?.kind.symbolName ?? "calendar")
                    .font(.system(size: 12.5, weight: .bold)).lineLimit(1).widgetAccentable()
                Text(data.eventStatus?.sentence ?? "")
                    .font(.system(size: 17, weight: .heavy, design: .rounded))
                    .lineLimit(1)
                    .cozyNumeric(data.eventStatus?.days ?? 0)
                Text("\(data.lunar.shortText) ÂL · \(data.lunar.yearName)")
                    .font(.system(size: 10.5))
                    .opacity(0.8)
                    .lineLimit(1)
            case .moodFood, .mascot:
                HStack(spacing: 4) {
                    Image(systemName: data.checkIn?.mood.monochromeSymbolName ?? "pawprint.fill").widgetAccentable()
                    Text(data.checkIn?.mood.displayName ?? data.mascot.species.displayName)
                        .font(.system(size: 14, weight: .bold)).widgetAccentable()
                }
                Text(
                    data.checkIn?.foods.isEmpty == false
                        ? data.checkIn!.foods.map(\.displayName).joined(separator: ", ")
                        : data.mascot.caption
                )
                .font(.system(size: 11.5))
                .lineLimit(1)
                if let s = data.checkIn?.socialBattery {
                    Gauge(value: Double(s), in: 0...100) { Text("Pin") }.gaugeStyle(.accessoryLinearCapacity)
                }
            default:
                // Combo 2-in-1 real-data Lock Screen: thời tiết thật + từ vựng + sự kiện/âm lịch
                if let w = data.weather {
                    HStack(spacing: 4) {
                        Image(systemName: w.condition.asset.monochromeSymbolName).font(.system(size: 11, weight: .bold)).widgetAccentable()
                        Text("\(w.temperatureText) \(w.condition.displayName) · \(w.placeName)")
                            .font(.system(size: 12.5, weight: .bold, design: .rounded))
                            .lineLimit(1)
                            .widgetAccentable()
                            .cozyNumeric(Int(w.temperatureC.rounded()))
                    }
                }
                if let word = data.word {
                    Text("✨ \(word.word) — \(word.meaning)")
                        .font(.system(size: 11.5, weight: .medium))
                        .lineLimit(1)
                }
                if let e = data.event, let s = data.eventStatus {
                    Text("\(e.emoji) \(e.title): \(s.sentence)")
                        .font(.system(size: 11))
                        .opacity(0.85)
                        .lineLimit(1)
                } else {
                    Text("\(data.lunar.shortText) ÂL · 🔥 \(data.streak) ngày")
                        .font(.system(size: 11))
                        .opacity(0.85)
                        .lineLimit(1)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
