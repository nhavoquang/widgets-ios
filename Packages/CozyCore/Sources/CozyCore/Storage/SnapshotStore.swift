import Foundation

/// Lưu/đọc `CozySnapshot` dưới dạng JSON, ghi nguyên tử.
/// App và Widget Extension cùng trỏ vào thư mục App Group nên đọc được dữ liệu của nhau tức thì.
public final class SnapshotStore: @unchecked Sendable {
    public static let appGroupID = "group.com.cozydaily.shared"
    public static let fileName = "cozy-snapshot.json"

    public let fileURL: URL
    private let lock = NSLock()
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    public init(directory: URL) {
        self.fileURL = directory.appendingPathComponent(Self.fileName)
        let e = JSONEncoder()
        e.dateEncodingStrategy = .iso8601
        e.outputFormatting = [.sortedKeys]
        self.encoder = e
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        self.decoder = d
    }

    /// Store dùng thư mục App Group (iOS/macOS). Rơi về Application Support nếu chưa cấu hình entitlement.
    public static func shared() -> SnapshotStore {
        #if canImport(Darwin)
        if let url = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupID) {
            return SnapshotStore(directory: url)
        }
        #endif
        let fallback = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        try? FileManager.default.createDirectory(at: fallback, withIntermediateDirectories: true)
        return SnapshotStore(directory: fallback)
    }

    public func load() -> CozySnapshot? {
        lock.lock(); defer { lock.unlock() }
        guard let data = try? Data(contentsOf: fileURL) else { return nil }
        return try? decoder.decode(CozySnapshot.self, from: data)
    }

    public func save(_ snapshot: CozySnapshot) throws {
        lock.lock(); defer { lock.unlock() }
        try FileManager.default.createDirectory(at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        let data = try encoder.encode(snapshot)
        try data.write(to: fileURL, options: [.atomic])
    }

    public func delete() {
        lock.lock(); defer { lock.unlock() }
        try? FileManager.default.removeItem(at: fileURL)
    }
}
