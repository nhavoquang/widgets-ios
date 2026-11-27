import Foundation

/// Lưu/đọc `CozySnapshot` dưới dạng JSON, ghi nguyên tử.
/// App và Widget Extension cùng trỏ vào thư mục App Group nên đọc được dữ liệu của nhau tức thì.
public final class SnapshotStore: @unchecked Sendable {
    public static let defaultAppGroupID = "group.com.cozydaily.shared"

    /// Các App Group có thể dùng, theo thứ tự ưu tiên:
    /// 1. `ALTAppGroups`: AltStore/SideStore ghi ID mới vào Info.plist khi ký lại IPA.
    /// 2. `CozyAppGroup`: cấu hình lúc build.
    /// 3. ID mặc định.
    public static func appGroupCandidates(info: [String: Any]?) -> [String] {
        var ids = (info?["ALTAppGroups"] as? [String]) ?? []
        if let configured = info?["CozyAppGroup"] as? String, !configured.isEmpty { ids.append(configured) }
        ids.append(defaultAppGroupID)
        var seen = Set<String>()
        return ids.filter { seen.insert($0).inserted }
    }

    /// App Group đầu tiên mà tiến trình hiện tại thực sự truy cập được.
    public static var activeAppGroupID: String? {
        #if canImport(Darwin)
        return appGroupCandidates(info: Bundle.main.infoDictionary).first {
            FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: $0) != nil
        }
        #else
        return nil
        #endif
    }
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
        if let id = activeAppGroupID,
           let url = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: id) {
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
