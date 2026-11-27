import Foundation

/// Các kho từ vựng (mục 3.1).
public enum VocabDeck: String, Codable, CaseIterable, Sendable, Identifiable {
    case daily, idioms, exam, healing, custom

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .daily: return "Giao tiếp đời thường"
        case .idioms: return "Idioms & Slang"
        case .exam: return "IELTS/TOEIC"
        case .healing: return "Từ vựng chữa lành"
        case .custom: return "Bộ từ của tôi"
        }
    }

    public var emoji: String {
        switch self {
        case .daily: return "💬"
        case .idioms: return "🎭"
        case .exam: return "📝"
        case .healing: return "🌿"
        case .custom: return "✍️"
        }
    }
}

public struct VocabWord: Codable, Hashable, Sendable, Identifiable {
    public var id: String
    public var word: String
    public var phonetic: String
    public var meaning: String
    public var example: String
    public var deck: VocabDeck

    public init(id: String? = nil, word: String, phonetic: String, meaning: String, example: String, deck: VocabDeck) {
        self.id = id ?? "\(deck.rawValue):\(word.lowercased())"
        self.word = word
        self.phonetic = phonetic
        self.meaning = meaning
        self.example = example
        self.deck = deck
    }
}

/// Trạng thái ôn tập của một từ theo Spaced Repetition.
public struct ReviewState: Codable, Hashable, Sendable {
    public var wordID: String
    /// 0 = mới học; mỗi lần "Đã thuộc" tăng 1 bậc. Bậc cuối = đã thành thạo.
    public var stage: Int
    public var dueDate: Date
    public var lastReviewed: Date?
    public var timesSeen: Int

    public init(wordID: String, stage: Int = 0, dueDate: Date, lastReviewed: Date? = nil, timesSeen: Int = 0) {
        self.wordID = wordID
        self.stage = stage
        self.dueDate = dueDate
        self.lastReviewed = lastReviewed
        self.timesSeen = timesSeen
    }

    public var isMastered: Bool { stage >= SpacedRepetition.intervals.count }
}
