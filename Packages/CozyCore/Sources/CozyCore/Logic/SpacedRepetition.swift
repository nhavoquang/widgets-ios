import Foundation

/// Lặp lại ngắt quãng với chu kỳ 1 - 3 - 7 - 30 ngày.
public struct SpacedRepetition: Sendable {
    public static let intervals: [Int] = [1, 3, 7, 30]

    public var calendar: Calendar

    public init(calendar: Calendar = .cozy) {
        self.calendar = calendar
    }

    /// Người dùng bấm "Đã thuộc": lên bậc và hẹn ngày ôn kế tiếp.
    public func markLearned(_ state: ReviewState?, wordID: String, now: Date) -> ReviewState {
        var s = state ?? ReviewState(wordID: wordID, dueDate: now)
        let index = min(s.stage, Self.intervals.count - 1)
        let days = Self.intervals[index]
        s.stage = min(s.stage + 1, Self.intervals.count)
        s.lastReviewed = now
        s.timesSeen += 1
        s.dueDate = calendar.date(byAdding: .day, value: days, to: calendar.startOfDay(for: now)) ?? now
        return s
    }

    /// Người dùng quên: quay về bậc 0, ôn lại vào ngày mai.
    public func markForgot(_ state: ReviewState?, wordID: String, now: Date) -> ReviewState {
        var s = state ?? ReviewState(wordID: wordID, dueDate: now)
        s.stage = 0
        s.lastReviewed = now
        s.timesSeen += 1
        s.dueDate = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: now)) ?? now
        return s
    }

    /// Các từ đến hạn ôn (chưa thành thạo, dueDate <= cuối ngày hôm nay), sắp theo hạn sớm nhất.
    public func dueWords(states: [String: ReviewState], now: Date) -> [ReviewState] {
        let endOfToday = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: now)) ?? now
        return states.values
            .filter { !$0.isMastered && $0.dueDate < endOfToday }
            .sorted { ($0.dueDate, $0.wordID) < ($1.dueDate, $1.wordID) }
    }

    /// Chọn từ tiếp theo: ưu tiên từ đến hạn ôn, sau đó tới từ mới trong kho đang chọn.
    /// - Parameter excluding: các từ vừa bị "Đổi từ" để không lặp lại ngay.
    public func nextWord(
        words: [VocabWord],
        states: [String: ReviewState],
        decks: Set<VocabDeck>,
        now: Date,
        excluding: Set<String> = []
    ) -> VocabWord? {
        let pool = words.filter { decks.isEmpty || decks.contains($0.deck) }
        let byID = Dictionary(pool.map { ($0.id, $0) }, uniquingKeysWith: { a, _ in a })
        for due in dueWords(states: states, now: now) where !excluding.contains(due.wordID) {
            if let w = byID[due.wordID] { return w }
        }
        if let fresh = pool.first(where: { states[$0.id] == nil && !excluding.contains($0.id) }) {
            return fresh
        }
        // Hết từ mới: lấy từ chưa thành thạo có hạn gần nhất.
        let upcoming = pool
            .compactMap { w -> (VocabWord, Date)? in
                guard let s = states[w.id], !s.isMastered, !excluding.contains(w.id) else { return nil }
                return (w, s.dueDate)
            }
            .min { $0.1 < $1.1 }
        return upcoming?.0 ?? pool.first(where: { !excluding.contains($0.id) })
    }
}

public extension Calendar {
    /// Lịch Gregorian, múi giờ hiện tại, tuần bắt đầu Thứ Hai (thói quen người Việt).
    static var cozy: Calendar {
        var c = Calendar(identifier: .gregorian)
        c.firstWeekday = 2
        c.locale = Locale(identifier: "vi_VN")
        return c
    }

    /// Khóa ngày dạng `yyyy-MM-dd` theo lịch này.
    func dayKey(for date: Date) -> String {
        let c = dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", c.year ?? 0, c.month ?? 0, c.day ?? 0)
    }
}
