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
        case .hairline: shape.strokeBorder(Color.cardBorder.opacity(0.9), lineWidth: 1).padding(-14)
        case .dashed: shape.strokeBorder(accent.opacity(0.6), style: StrokeStyle(lineWidth: 1.5, dash: [5, 4])).padding(-8)
        case .stitched: shape.strokeBorder(accent.opacity(0.5), style: StrokeStyle(lineWidth: 2, dash: [2, 3])).padding(-6)
        }
    }
}

private struct WidgetHeader: View {
    var title: String
    var symbol: String
    var data: CozyWidgetData

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: symbol).font(.system(size: 10, weight: .bold))
            Text(title).font(data.config.font.font(size: 11, weight: .bold))
            Spacer(minLength: 0)
            if let h = data.holiday { Text(h.emoji).font(.system(size: 11)) }
        }
        .foregroundStyle(data.config.accent.color)
        .lineLimit(1)
    }
}

// MARK: Vocab

private struct VocabHome: View {
    var data: CozyWidgetData
    var family: WidgetFamily

    var body: some View {
        if let w = data.word {
            VStack(alignment: .leading, spacing: family == .systemSmall ? 4 : 6) {
                WidgetHeader(title: "Từ vựng hôm nay", symbol: "character.book.closed.fill", data: data)
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(w.word)
                            .font(data.config.font.font(size: family == .systemSmall ? 20 : 24, weight: .bold))
                            .minimumScaleFactor(0.6)
                            .lineLimit(2)
                        Text(w.phonetic).font(.system(size: 11, design: .monospaced)).foregroundStyle(data.theme.secondaryInk)
                    }
                    Spacer(minLength: 0)
                    if data.config.showMascot && family != .systemSmall {
                        MascotView(state: data.mascot, size: 46, animated: false)
                    }
                }
                Text(w.meaning)
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .lineLimit(2)
                if family == .systemLarge {
                    Text("“\(w.example)”")
                        .font(.system(size: 13, design: .serif).italic())
                        .foregroundStyle(data.theme.secondaryInk)
                        .padding(.top, 4)
                    Spacer()
                    HStack {
                        Label("\(data.streak) ngày", systemImage: "flame.fill")
                        Spacer()
                        Label("\(data.dueCount) từ cần ôn", systemImage: "arrow.triangle.2.circlepath")
                    }
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(data.theme.secondaryInk)
                }
                Spacer(minLength: 0)
                HStack(spacing: 6) {
                    Button(intent: MarkWordLearnedIntent()) {
                        Label(family == .systemSmall ? "Thuộc" : "Đã thuộc", systemImage: "checkmark")
                    }
                    .buttonStyle(WidgetPillStyle(tint: Color.accentSage, filled: true))
                    Button(intent: SkipWordIntent()) {
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
    var tint: Color
    var filled: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 12, weight: .bold, design: .rounded))
            .labelStyle(.titleAndIcon)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .frame(maxWidth: .infinity)
            .foregroundStyle(filled ? .white : tint)
            .background(Capsule().fill(filled ? tint : tint.opacity(0.15)))
            .opacity(configuration.isPressed ? 0.7 : 1)
    }
}

// MARK: Mood + Food

private struct MoodFoodHome: View {
    var data: CozyWidgetData
    var family: WidgetFamily

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            WidgetHeader(title: "Hôm nay thế nào?", symbol: "face.smiling", data: data)
            HStack(alignment: .center, spacing: 10) {
                MascotView(state: data.mascot, size: family == .systemSmall ? 54 : 64, animated: false)
                VStack(alignment: .leading, spacing: 3) {
                    Text(data.checkIn.map { "\($0.mood.emoji) \($0.mood.displayName)" } ?? "Chưa check-in")
                        .font(data.config.font.font(size: 16, weight: .bold))
                    if let foods = data.checkIn?.foods, !foods.isEmpty {
                        Text(foods.map(\.emoji).joined(separator: " ")).font(.system(size: 18))
                    }
                }
            }
            if let c = data.checkIn {
                BatteryBar(value: c.socialBattery, tint: data.config.accent.color)
                if family != .systemSmall, !c.note.isEmpty {
                    Text("“\(c.note)”").font(data.config.font.font(size: 13, weight: .regular)).foregroundStyle(data.theme.secondaryInk)
                }
            }
            Spacer(minLength: 0)
            if family != .systemSmall {
                HStack(spacing: 6) {
                    ForEach([MoodOption.happy, .chill, .tired, .missing], id: \.self) { m in
                        Button(intent: quickMood(m)) { Text(m.mood.emoji).font(.system(size: 18)) }
                            .buttonStyle(.plain)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 4)
                            .background(Capsule().fill(data.config.accent.color.opacity(0.14)))
                    }
                }
            }
        }
    }

    func quickMood(_ m: MoodOption) -> LogMoodIntent {
        var i = LogMoodIntent()
        i.mood = m
        i.source = .widget
        return i
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
                    Capsule().fill(tint).frame(width: geo.size.width * CGFloat(value) / 100)
                }
            }
            .frame(height: 6)
            Text("\(value)%").font(.system(size: 10, weight: .bold, design: .rounded)).monospacedDigit()
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
                        Text("\(EventCounter().status(of: CozyEvent(title: "", kind: .countUp(since: a)), now: data.date).days) ngày 💞")
                            .font(.system(size: 11, weight: .heavy, design: .rounded))
                            .foregroundStyle(Color.accentPeach)
                    }
                }
                HStack(spacing: 8) {
                    MemberColumn(member: me, data: data, compact: family == .systemSmall)
                    if family != .systemSmall {
                        Image(systemName: "heart.fill").foregroundStyle(Color.accentPeach).font(.system(size: 14))
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
                            .buttonStyle(WidgetPillStyle(tint: Color.accentPeach, filled: false))
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
            MascotView(
                state: MascotEngine.resolve(species: member.species, mood: member.mood, weather: member.id == DemoData.meID ? data.weather : nil, date: data.date),
                size: compact ? 40 : 50, animated: false
            )
            Text(member.displayName).font(data.config.font.font(size: 12, weight: .bold)).lineLimit(1)
            Text(member.mood.map { "\($0.emoji) \($0.displayName)" } ?? "–")
                .font(.system(size: 10, weight: .medium, design: .rounded))
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
    }
}

// MARK: Squad

private struct SquadHome: View {
    var data: CozyWidgetData
    var family: WidgetFamily

    var body: some View {
        if let squad = data.squad {
            VStack(alignment: .leading, spacing: 6) {
                WidgetHeader(title: squad.name, symbol: "person.3.fill", data: data)
                let columns = family == .systemSmall ? 2 : 4
                let members = Array(squad.members.prefix(family == .systemLarge ? 8 : (family == .systemSmall ? 4 : 4)))
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: columns), spacing: 6) {
                    ForEach(members) { m in
                        VStack(spacing: 2) {
                            Text("\(m.species.emoji)\(m.mood?.emoji ?? "")").font(.system(size: family == .systemSmall ? 18 : 22))
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
                    Text("\(who): \(last.displayText)").font(.system(size: 11, weight: .medium)).lineLimit(1).foregroundStyle(data.theme.secondaryInk)
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
                WidgetHeader(title: e.kind.modeName, symbol: e.kind.symbolName, data: data)
                Spacer(minLength: 0)
                HStack(alignment: .lastTextBaseline, spacing: 4) {
                    Text(s.headline)
                        .font(.system(size: family == .systemSmall ? 44 : 52, weight: .heavy, design: .rounded))
                        .minimumScaleFactor(0.5)
                        .contentTransition(.numericText())
                    Text(s.caption).font(.system(size: 12, weight: .semibold, design: .rounded)).foregroundStyle(data.theme.secondaryInk)
                }
                Text("\(e.emoji) \(e.title)").font(data.config.font.font(size: 15, weight: .bold)).lineLimit(2)
                if let d = s.referenceDate, family != .systemSmall {
                    Text(d, format: .dateTime.weekday(.wide).day().month().locale(Locale(identifier: "vi_VN")))
                        .font(.system(size: 11)).foregroundStyle(data.theme.secondaryInk)
                }
                if family == .systemLarge {
                    Divider().padding(.vertical, 6)
                    Text("Âm lịch hôm nay: \(data.lunar.shortText) · năm \(data.lunar.yearName)")
                        .font(.system(size: 12, weight: .medium)).foregroundStyle(data.theme.secondaryInk)
                    ForEach(Array(data.tomorrowEvents.prefix(3))) { item in
                        Text("Mai: \(item.event.emoji) \(item.event.title)").font(.system(size: 12))
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
            VStack(alignment: .leading, spacing: 4) {
                WidgetHeader(title: w.placeName, symbol: "location.fill", data: data)
                HStack {
                    VStack(alignment: .leading, spacing: 0) {
                        Text(w.temperatureText).font(.system(size: 40, weight: .heavy, design: .rounded))
                        Label(w.condition.displayName, systemImage: w.condition.symbolName)
                            .font(.system(size: 12, weight: .semibold))
                            .symbolRenderingMode(.multicolor)
                    }
                    Spacer(minLength: 0)
                    if data.config.showMascot { MascotView(state: data.mascot, size: family == .systemSmall ? 44 : 60, animated: false) }
                }
                Spacer(minLength: 0)
                Text("C:\(Int(w.highC))° T:\(Int(w.lowC))°").font(.system(size: 11, weight: .medium)).foregroundStyle(data.theme.secondaryInk)
                if family != .systemSmall {
                    Text(WeatherSuggestion.outfit(for: w)).font(data.config.font.font(size: 12, weight: .medium)).lineLimit(1)
                    Text("Gợi ý: " + WeatherSuggestion.foods(for: w).map { "\($0.emoji) \($0.displayName)" }.joined(separator: " · "))
                        .font(.system(size: 11)).foregroundStyle(data.theme.secondaryInk).lineLimit(1)
                }
            }
        } else {
            EmptyState(text: "Mở app để cập nhật thời tiết", symbol: "cloud.sun")
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
                Circle().stroke(Color.accentSage.opacity(0.2), lineWidth: 10)
                Circle()
                    .trim(from: 0, to: min(1, CGFloat(data.streak) / 30))
                    .stroke(Color.accentSage, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                VStack(spacing: 0) {
                    Text("\(data.streak)").font(.system(size: 30, weight: .heavy, design: .rounded))
                    Text("ngày 🔥").font(.system(size: 11, weight: .semibold))
                }
            }
            .padding(4)
            if family != .systemSmall {
                Text("\(data.dueCount) từ cần ôn hôm nay").font(.system(size: 12, weight: .medium)).foregroundStyle(data.theme.secondaryInk)
            }
        }
    }
}

private struct MascotHome: View {
    var data: CozyWidgetData
    var family: WidgetFamily

    var body: some View {
        VStack(spacing: 6) {
            MascotView(state: data.mascot, size: family == .systemSmall ? 86 : 110, animated: false)
            Text(data.mascot.caption)
                .font(data.config.font.font(size: 12, weight: .semibold))
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

private struct ComboHome: View {
    var data: CozyWidgetData
    var family: WidgetFamily

    var body: some View {
        if family == .systemSmall {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    MascotView(state: data.mascot, size: 44, animated: false)
                    Spacer()
                    if let w = data.weather {
                        VStack(alignment: .trailing) {
                            Text(w.temperatureText).font(.system(size: 22, weight: .heavy, design: .rounded))
                            Image(systemName: w.condition.symbolName).symbolRenderingMode(.multicolor)
                        }
                    }
                }
                Spacer(minLength: 0)
                if let w = data.word {
                    Text(w.word).font(data.config.font.font(size: 16, weight: .bold)).lineLimit(1)
                    Text(w.meaning).font(.system(size: 11)).foregroundStyle(data.theme.secondaryInk).lineLimit(1)
                }
            }
        } else {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(DayPart(date: data.date).greeting).font(data.config.font.font(size: 14, weight: .bold))
                    Text("\(data.lunar.shortText) ÂL · \(data.lunar.yearName)").font(.system(size: 11)).foregroundStyle(data.theme.secondaryInk)
                    MascotView(state: data.mascot, size: 58, animated: false)
                    if let c = data.checkIn {
                        Text("\(c.mood.emoji) \(c.foods.map(\.emoji).joined())").font(.system(size: 15))
                    }
                }
                Divider()
                VStack(alignment: .leading, spacing: 6) {
                    if let w = data.word {
                        Label(w.word, systemImage: "character.book.closed.fill").font(data.config.font.font(size: 15, weight: .bold)).lineLimit(1)
                        Text(w.meaning).font(.system(size: 12)).foregroundStyle(data.theme.secondaryInk).lineLimit(1)
                    }
                    if let w = data.weather {
                        Label("\(w.temperatureText) \(w.condition.displayName)", systemImage: w.condition.symbolName).font(.system(size: 12, weight: .semibold))
                    }
                    if let e = data.event, let s = data.eventStatus {
                        Label("\(e.title): \(s.sentence)", systemImage: "calendar").font(.system(size: 12, weight: .semibold)).lineLimit(1)
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

// MARK: - Lock Screen

private struct InlineAccessory: View {
    var data: CozyWidgetData

    var body: some View {
        switch data.config.content {
        case .vocab:
            Text("📖 \(data.word?.word ?? "CozyDaily")")
        case .couple:
            Text("💞 \(data.partner.map { "\($0.displayName) \($0.mood?.emoji ?? "")" } ?? "Couple")")
        case .event:
            Text("\(data.event?.emoji ?? "📅") \(data.eventStatus?.sentence ?? "")")
        case .weather:
            Text("\(data.weather?.temperatureText ?? "–") \(data.weather?.condition.displayName ?? "")")
        default:
            Text("\(data.checkIn?.mood.emoji ?? "🐾") \(data.lunar.shortText) ÂL · 🔥\(data.streak)")
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
                Text("\(data.streak)")
            }
            .gaugeStyle(.accessoryCircularCapacity)
            .widgetAccentable()
        case .event:
            ZStack {
                AccessoryWidgetBackground()
                VStack(spacing: -2) {
                    Text(data.eventStatus?.headline ?? "–").font(.system(size: 20, weight: .heavy, design: .rounded)).minimumScaleFactor(0.5)
                    Text(data.event?.emoji ?? "📅").font(.system(size: 11))
                }
            }
        case .couple:
            ZStack {
                AccessoryWidgetBackground()
                VStack(spacing: -2) {
                    Image(systemName: "heart.fill").font(.system(size: 10)).widgetAccentable()
                    Text(anniversaryDays).font(.system(size: 16, weight: .heavy, design: .rounded)).minimumScaleFactor(0.5)
                }
            }
        default:
            ZStack {
                AccessoryWidgetBackground()
                if data.config.showMascot {
                    Text(data.checkIn?.mood.emoji ?? data.mascot.species.emoji).font(.system(size: 26))
                } else {
                    MascotGlyph(state: data.mascot)
                }
            }
        }
    }

    var anniversaryDays: String {
        guard let a = data.couple?.anniversary else { return "–" }
        return "\(EventCounter().status(of: CozyEvent(title: "", kind: .countUp(since: a)), now: data.date).days)"
    }
}

private struct RectangularAccessory: View {
    @Environment(\.isLuminanceReduced) private var isLuminanceReduced
    var data: CozyWidgetData

    var body: some View {
        VStack(alignment: .leading, spacing: 1) {
            switch data.config.content {
            case .vocab:
                if let w = data.word {
                    Text(w.word).font(data.config.font.font(size: 16, weight: .bold)).widgetAccentable()
                    Text(w.phonetic).font(.system(size: 11, design: .monospaced))
                    // Chế độ ẩn nghĩa để luyện phản xạ: nghĩa chỉ hiện khi máy đã mở khóa.
                    if data.config.hideMeaningOnLockScreen {
                        Text(w.meaning).font(.system(size: 12)).privacySensitive()
                    } else {
                        Text(w.meaning).font(.system(size: 12))
                    }
                }
            case .couple:
                HStack(spacing: 4) {
                    Image(systemName: "heart.fill").widgetAccentable()
                    Text(data.partner?.displayName ?? "Couple").font(.system(size: 14, weight: .bold))
                    Text(data.partner?.mood?.emoji ?? "")
                }
                Text(data.partner?.note.isEmpty == false ? data.partner!.note : (data.partner?.mood?.displayName ?? "")).font(.system(size: 12)).lineLimit(1)
                Text(data.partner?.weatherLine ?? "").font(.system(size: 11)).lineLimit(1)
            case .event:
                Label(data.event?.title ?? "Sự kiện", systemImage: data.event?.kind.symbolName ?? "calendar")
                    .font(.system(size: 13, weight: .bold)).widgetAccentable()
                Text(data.eventStatus?.sentence ?? "").font(.system(size: 18, weight: .heavy, design: .rounded))
            case .moodFood, .mascot:
                HStack(spacing: 4) {
                    Text(data.checkIn?.mood.emoji ?? "🐾")
                    Text(data.checkIn?.mood.displayName ?? "Chưa check-in").font(.system(size: 14, weight: .bold)).widgetAccentable()
                }
                Text(data.checkIn?.foods.map { "\($0.emoji) \($0.displayName)" }.joined(separator: ", ") ?? "").font(.system(size: 12)).lineLimit(1)
                if let s = data.checkIn?.socialBattery {
                    Gauge(value: Double(s), in: 0...100) { Text("Pin") }.gaugeStyle(.accessoryLinearCapacity)
                }
            default:
                // Combo 2-in-1: từ vựng + sự kiện/thời tiết
                HStack(spacing: 4) {
                    Image(systemName: "character.book.closed.fill").widgetAccentable()
                    Text(data.word?.word ?? "–").font(.system(size: 14, weight: .bold)).lineLimit(1)
                }
                if let w = data.weather {
                    Text("\(w.temperatureText) \(w.condition.displayName)").font(.system(size: 12))
                }
                if let e = data.event, let s = data.eventStatus {
                    Text("\(e.emoji) \(s.sentence)").font(.system(size: 12)).lineLimit(1)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
