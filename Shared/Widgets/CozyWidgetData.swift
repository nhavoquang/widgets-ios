import WidgetKit
import CozyCore
import Foundation

/// Một sự kiện kèm trạng thái đếm đã tính.
struct EventItem: Identifiable {
    var event: CozyEvent
    var status: EventStatus
    var id: UUID { event.id }
}

/// Dữ liệu đã tính sẵn cho một lần vẽ widget.
struct CozyWidgetData {
    var date: Date
    var config: WidgetConfig
    var theme: WidgetTheme
    var word: VocabWord?
    var streak: Int
    var learnedToday: Int
    var dueCount: Int
    var checkIn: CheckIn?
    var weather: WeatherSnapshot?
    var mascot: MascotState
    var couple: SharedSpace?
    var squad: SharedSpace?
    var event: CozyEvent?
    var eventStatus: EventStatus?
    var tomorrowEvents: [EventItem]
    var lunar: LunarDate
    var holiday: HolidayDetector.Holiday?

    var me: MemberStatus? { couple?.members.first { $0.id == DemoData.meID } }
    var partner: MemberStatus? { couple?.partner(of: DemoData.meID) }

    static func make(config: WidgetConfig?, date: Date, repository: CozyRepository, fallbackContent: WidgetContentKind = .combo) -> CozyWidgetData {
        let snap = repository.snapshot(reload: true)
        let cfg = config ?? WidgetConfig(name: "CozyDaily", content: fallbackContent, species: snap.settings.species)
        let cal = repository.calendar
        let counter = EventCounter(calendar: cal)

        let word: VocabWord? = {
            if let p = snap.todayWord, p.dayKey == cal.dayKey(for: date) {
                return repository.word(id: p.wordID)
            }
            // Widget chỉ đọc; nếu sang ngày mới thì để repository chọn từ.
            return repository.currentWord(now: date)
        }()

        let latest = snap.checkIns.filter { cal.isDate($0.date, inSameDayAs: date) }.max { $0.date < $1.date }
            ?? snap.checkIns.max { $0.date < $1.date }

        let event: CozyEvent? = {
            if let id = cfg.eventID, let e = snap.events.first(where: { $0.id == id }) { return e }
            return counter.sortedByUrgency(snap.events.filter { if case .countUp = $0.kind { return false }; return true }, now: date).first
        }()

        let tomorrow = cal.date(byAdding: .day, value: 1, to: cal.startOfDay(for: date))!
        let tomorrowEvents = snap.events.compactMap { e -> EventItem? in
            guard let next = counter.nextOccurrence(of: e, now: tomorrow), cal.isDate(next, inSameDayAs: tomorrow) else { return nil }
            return EventItem(event: e, status: counter.status(of: e, now: tomorrow))
        }

        return CozyWidgetData(
            date: date,
            config: cfg,
            theme: cfg.effectiveTheme(at: date, calendar: cal),
            word: word,
            streak: CozyRepository.streak(log: snap.learnedLog, now: date, calendar: cal),
            learnedToday: snap.learnedLog[cal.dayKey(for: date)] ?? 0,
            dueCount: SpacedRepetition(calendar: cal).dueWords(states: snap.reviewStates, now: date).count,
            checkIn: latest,
            weather: snap.weather,
            mascot: MascotEngine.resolve(species: cfg.species, mood: latest?.mood, weather: snap.weather, date: date, calendar: cal),
            couple: snap.spaces.preferred(.couple),
            squad: snap.spaces.preferred(.squad),
            event: event,
            eventStatus: event.map { counter.status(of: $0, now: date) },
            tomorrowEvents: tomorrowEvents,
            lunar: VietnameseLunarCalendar.lunarDate(from: date, calendar: cal),
            holiday: HolidayDetector.holiday(on: date, calendar: cal)
        )
    }

    static var placeholder: CozyWidgetData {
        let repo = CozyRepository(store: SnapshotStore(directory: FileManager.default.temporaryDirectory.appendingPathComponent("cozy-placeholder")))
        return make(config: nil, date: Date(), repository: repo)
    }
}

struct CozyEntry: TimelineEntry {
    var date: Date
    var data: CozyWidgetData
}

enum CozyTimeline {
    /// Mỗi 30 phút một entry trong 6 giờ tới để linh vật đổi tư thế theo khung giờ,
    /// không tốn quota WeatherKit vì chỉ đọc cache trong App Group.
    static func entries(config: WidgetConfig?, fallback: WidgetContentKind, now: Date = Date()) -> Timeline<CozyEntry> {
        let repo = CozyShared.repository
        var entries: [CozyEntry] = []
        for step in 0..<12 {
            let d = now.addingTimeInterval(Double(step) * 30 * 60)
            entries.append(CozyEntry(date: d, data: .make(config: config, date: d, repository: repo, fallbackContent: fallback)))
        }
        return Timeline(entries: entries, policy: .after(now.addingTimeInterval(6 * 3600)))
    }
}
