import Foundation

/// Chế độ xem của Monthly Sticker Grid (mục 3.5, Tab 3).
public enum GridLens: String, Codable, CaseIterable, Sendable, Identifiable {
    case mood, food, vocab

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .mood: return "Mood"
        case .food: return "Món ăn"
        case .vocab: return "Vocab"
        }
    }
}

public struct MonthGridCell: Hashable, Sendable, Identifiable {
    public var id: String { date.map { "\($0.timeIntervalSince1970)" } ?? "pad-\(index)" }
    public var index: Int
    /// nil = ô đệm trước ngày 1.
    public var date: Date?
    public var day: Int
    public var lunar: LunarDate?
    public var isToday: Bool
    public var sticker: String?
    /// 0...1 dùng tô đậm nhạt (vd. số từ học).
    public var intensity: Double
    public var hasEvent: Bool
}

public struct MonthGrid: Sendable {
    public var year: Int
    public var month: Int
    public var cells: [MonthGridCell]

    public var title: String { "Tháng \(month), \(year)" }

    /// Dựng lưới tháng, tuần bắt đầu Thứ Hai.
    public static func build(
        year: Int,
        month: Int,
        lens: GridLens,
        snapshot: CozySnapshot,
        now: Date,
        calendar: Calendar = .cozy
    ) -> MonthGrid {
        guard let first = calendar.date(from: DateComponents(year: year, month: month, day: 1)),
              let range = calendar.range(of: .day, in: .month, for: first) else {
            return MonthGrid(year: year, month: month, cells: [])
        }
        let weekday = calendar.component(.weekday, from: first) // 1 = CN
        let leading = (weekday + 5) % 7 // số ô đệm khi tuần bắt đầu T2

        var cells: [MonthGridCell] = (0..<leading).map {
            MonthGridCell(index: $0, date: nil, day: 0, lunar: nil, isToday: false, sticker: nil, intensity: 0, hasEvent: false)
        }

        // Gom check-in mới nhất mỗi ngày.
        var latestByDay: [String: CheckIn] = [:]
        for c in snapshot.checkIns {
            let k = calendar.dayKey(for: c.date)
            if let existing = latestByDay[k], existing.date > c.date { continue }
            latestByDay[k] = c
        }
        let maxLearned = max(1, snapshot.learnedLog.values.max() ?? 1)
        let counter = EventCounter(calendar: calendar)
        var eventDays = Set<String>()
        for e in snapshot.events {
            if let d = counter.nextOccurrence(of: e, now: first) { eventDays.insert(calendar.dayKey(for: d)) }
        }

        for day in range {
            guard let date = calendar.date(from: DateComponents(year: year, month: month, day: day)) else { continue }
            let key = calendar.dayKey(for: date)
            let checkIn = latestByDay[key]
            var sticker: String?
            var intensity = 0.0
            switch lens {
            case .mood:
                sticker = checkIn?.mood.emoji
                intensity = checkIn == nil ? 0 : 1
            case .food:
                sticker = checkIn?.foods.first?.emoji
                intensity = checkIn?.foods.isEmpty == false ? 1 : 0
            case .vocab:
                let n = snapshot.learnedLog[key] ?? 0
                sticker = n > 0 ? (n >= 5 ? "🌳" : n >= 3 ? "🌿" : "🌱") : nil
                intensity = Double(n) / Double(maxLearned)
            }
            cells.append(MonthGridCell(
                index: cells.count,
                date: date,
                day: day,
                lunar: VietnameseLunarCalendar.lunarDate(from: date, calendar: calendar),
                isToday: calendar.isDate(date, inSameDayAs: now),
                sticker: sticker,
                intensity: intensity,
                hasEvent: eventDays.contains(key)
            ))
        }
        return MonthGrid(year: year, month: month, cells: cells)
    }

    /// Thống kê nhanh cho phần tổng kết dưới lưới.
    public static func summary(year: Int, month: Int, snapshot: CozySnapshot, calendar: Calendar = .cozy) -> (topMood: Mood?, topFood: FoodSticker?, wordsLearned: Int, checkInDays: Int) {
        let inMonth = snapshot.checkIns.filter {
            let c = calendar.dateComponents([.year, .month], from: $0.date)
            return c.year == year && c.month == month
        }
        var moodCount: [Mood: Int] = [:]
        var foodCount: [FoodSticker: Int] = [:]
        for c in inMonth {
            moodCount[c.mood, default: 0] += 1
            for f in c.foods { foodCount[f, default: 0] += 1 }
        }
        let prefix = String(format: "%04d-%02d-", year, month)
        let words = snapshot.learnedLog.filter { $0.key.hasPrefix(prefix) }.values.reduce(0, +)
        let days = Set(inMonth.map { calendar.dayKey(for: $0.date) }).count
        return (
            moodCount.max { ($0.value, $0.key.rawValue) < ($1.value, $1.key.rawValue) }?.key,
            foodCount.max { ($0.value, $0.key.rawValue) < ($1.value, $1.key.rawValue) }?.key,
            words,
            days
        )
    }
}
