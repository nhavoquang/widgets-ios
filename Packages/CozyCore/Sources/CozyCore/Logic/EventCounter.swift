import Foundation

/// Kết quả tính toán hiển thị cho một sự kiện.
public struct EventStatus: Hashable, Sendable {
    public enum Direction: Hashable, Sendable { case upcoming, today, elapsed, overdue }

    public var direction: Direction
    /// Số ngày (luôn >= 0).
    public var days: Int
    /// Mốc thời điểm liên quan (lần xảy ra kế tiếp, hoặc ngày bắt đầu với đếm tiến).
    public var referenceDate: Date?
    /// Chữ số lớn hiển thị trên widget, vd. "12".
    public var headline: String
    /// Dòng mô tả, vd. "ngày nữa", "ngày bên nhau".
    public var caption: String
    /// Câu đầy đủ, vd. "Còn 12 ngày".
    public var sentence: String
}

public struct EventCounter: Sendable {
    public var calendar: Calendar

    public init(calendar: Calendar = .cozy) {
        self.calendar = calendar
    }

    /// Lần xảy ra kế tiếp kể từ `now` (tính cả hôm nay). Với đếm tiến trả về ngày bắt đầu.
    public func nextOccurrence(of event: CozyEvent, now: Date) -> Date? {
        let today = calendar.startOfDay(for: now)
        switch event.kind {
        case let .countdown(date, repeatsYearly):
            guard repeatsYearly else { return date }
            return nextYearly(date, onOrAfter: today)
        case let .countUp(since):
            return since
        case let .lunar(day, month):
            return VietnameseLunarCalendar.nextOccurrence(lunarDay: day, lunarMonth: month, onOrAfter: now, calendar: calendar)
        case let .weekly(weekdays, hour, minute):
            return nextWeekly(weekdays: weekdays, hour: hour, minute: minute, after: now)
        case let .deadline(due):
            return due
        }
    }

    public func status(of event: CozyEvent, now: Date) -> EventStatus {
        let today = calendar.startOfDay(for: now)
        switch event.kind {
        case let .countUp(since):
            let days = max(0, dayDiff(from: calendar.startOfDay(for: since), to: today))
            // Ngày đầu tiên tính là ngày 1 (thói quen "đếm ngày yêu").
            let count = days + 1
            return EventStatus(
                direction: .elapsed, days: count, referenceDate: since,
                headline: "\(count)", caption: "ngày", sentence: "Đã \(count) ngày"
            )
        case let .deadline(due):
            let diff = dayDiff(from: today, to: calendar.startOfDay(for: due))
            if due < now {
                let late = max(0, -diff)
                return EventStatus(
                    direction: .overdue, days: late, referenceDate: due,
                    headline: late == 0 ? "!" : "\(late)",
                    caption: late == 0 ? "quá hạn" : "ngày trễ",
                    sentence: late == 0 ? "Đã quá hạn hôm nay" : "Trễ \(late) ngày"
                )
            }
            if diff == 0 {
                let hours = max(0, Int(due.timeIntervalSince(now) / 3600))
                return EventStatus(
                    direction: .today, days: 0, referenceDate: due,
                    headline: hours > 0 ? "\(hours)h" : "<1h", caption: "còn lại",
                    sentence: hours > 0 ? "Hạn chót hôm nay, còn \(hours) giờ" : "Hạn chót sắp tới!"
                )
            }
            return upcoming(days: diff, date: due)
        default:
            guard let next = nextOccurrence(of: event, now: now) else {
                return EventStatus(direction: .elapsed, days: 0, referenceDate: nil, headline: "–", caption: "", sentence: "Không xác định")
            }
            let diff = dayDiff(from: today, to: calendar.startOfDay(for: next))
            if diff == 0 {
                return EventStatus(direction: .today, days: 0, referenceDate: next, headline: "🎉", caption: "hôm nay", sentence: "Là hôm nay!")
            }
            if diff < 0 {
                let ago = -diff
                return EventStatus(direction: .elapsed, days: ago, referenceDate: next, headline: "\(ago)", caption: "ngày trước", sentence: "Đã qua \(ago) ngày")
            }
            return upcoming(days: diff, date: next)
        }
    }

    /// Sắp xếp sự kiện theo độ "gần": hôm nay → sắp tới → đếm tiến/đã qua.
    public func sortedByUrgency(_ events: [CozyEvent], now: Date) -> [CozyEvent] {
        func rank(_ e: CozyEvent) -> (Int, Int) {
            let s = status(of: e, now: now)
            switch s.direction {
            case .today: return (0, 0)
            case .overdue: return (1, s.days)
            case .upcoming: return (2, s.days)
            case .elapsed: return (3, s.days)
            }
        }
        return events.sorted { rank($0) < rank($1) }
    }

    // MARK: - Helpers

    func upcoming(days: Int, date: Date) -> EventStatus {
        EventStatus(
            direction: .upcoming, days: days, referenceDate: date,
            headline: "\(days)", caption: days == 1 ? "ngày nữa (mai)" : "ngày nữa",
            sentence: days == 1 ? "Ngày mai" : "Còn \(days) ngày"
        )
    }

    public func dayDiff(from a: Date, to b: Date) -> Int {
        calendar.dateComponents([.day], from: calendar.startOfDay(for: a), to: calendar.startOfDay(for: b)).day ?? 0
    }

    func nextYearly(_ date: Date, onOrAfter day: Date) -> Date? {
        let c = calendar.dateComponents([.month, .day], from: date)
        let year = calendar.component(.year, from: day)
        for y in year...(year + 4) {
            var comps = DateComponents(year: y, month: c.month, day: c.day)
            // 29/2 vào năm không nhuận → 28/2.
            if c.month == 2, c.day == 29, !isLeapYear(y) { comps.day = 28 }
            if let d = calendar.date(from: comps), d >= day { return d }
        }
        return nil
    }

    func nextWeekly(weekdays: [Int], hour: Int, minute: Int, after now: Date) -> Date? {
        guard !weekdays.isEmpty else { return nil }
        let today = calendar.startOfDay(for: now)
        for offset in 0..<8 {
            guard let day = calendar.date(byAdding: .day, value: offset, to: today) else { continue }
            let wd = calendar.component(.weekday, from: day)
            guard weekdays.contains(wd) else { continue }
            guard let at = calendar.date(bySettingHour: hour, minute: minute, second: 0, of: day) else { continue }
            // Buổi hôm nay đã qua thì xét tuần sau.
            if offset == 0 && at < now { continue }
            return at
        }
        return nil
    }

    func isLeapYear(_ y: Int) -> Bool { (y % 4 == 0 && y % 100 != 0) || y % 400 == 0 }
}

public enum WeekdayName {
    /// 1 = Chủ nhật ... 7 = Thứ bảy.
    public static func short(_ weekday: Int) -> String {
        switch weekday {
        case 1: return "CN"
        case 2: return "T2"
        case 3: return "T3"
        case 4: return "T4"
        case 5: return "T5"
        case 6: return "T6"
        case 7: return "T7"
        default: return "?"
        }
    }

    /// Thứ tự hiển thị tuần bắt đầu Thứ Hai.
    public static let mondayFirst: [Int] = [2, 3, 4, 5, 6, 7, 1]
}
