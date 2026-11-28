import Foundation
import CloudKit
import CozyCore

extension Notification.Name {
    /// Dữ liệu cục bộ vừa được cập nhật từ iCloud.
    static let cozyRemoteDidChange = Notification.Name("cozyRemoteDidChange")
}

enum CloudConfig {
    /// Chỉ bật khi app được ký kèm entitlement iCloud. Gọi CloudKit khi thiếu entitlement sẽ làm app crash.
    static var isEnabled: Bool {
        (Bundle.main.object(forInfoDictionaryKey: "CozyCloudEnabled") as? String) == "YES"
    }

    static var containerID: String {
        (Bundle.main.object(forInfoDictionaryKey: "CozyCloudContainer") as? String) ?? "iCloud.com.cozydaily"
    }
}

enum CloudSyncError: LocalizedError {
    case disabled
    case spaceFull(SpaceKind)

    var errorDescription: String? {
        switch self {
        case .disabled:
            return "Bản cài này chưa bật iCloud. Cần build đã ký bằng tài khoản Apple Developer trả phí."
        case .spaceFull(let kind):
            return "\(kind.displayName) đã đủ tối đa \(kind.memberLimit.upperBound) người nên không thể tham gia thêm."
        }
    }
}

/// Đồng bộ CloudKit:
/// - Private DB, zone `CozyZone`: bản sao dữ liệu cá nhân giữa các thiết bị của bạn.
/// - Mỗi không gian Cặp đôi/Nhóm là một zone `Space-<uuid>` chia sẻ bằng zone-wide `CKShare`;
///   người được mời đọc/ghi qua Shared DB.
actor CloudSync {
    static let shared = CloudSync(repository: CozyShared.repository)

    private static let personalZone = "CozyZone"
    private static let spacePrefix = "Space-"
    private static let payloadKey = "payload"

    private enum RecordType {
        static let personal = "CozyPersonal"
        static let space = "CozySpace"
        static let member = "CozyMember"
        static let interaction = "CozyInteraction"
        static let event = "CozyEventRecord"
    }

    private let repository: CozyRepository
    private var running: Task<Void, Error>?
    private var rerunRequested = false
    private var debounce: Task<Void, Never>?

    init(repository: CozyRepository) {
        self.repository = repository
    }

    private var container: CKContainer { CKContainer(identifier: CloudConfig.containerID) }
    private var privateDB: CKDatabase { container.privateCloudDatabase }
    private var sharedDB: CKDatabase { container.sharedCloudDatabase }

    // MARK: - Entry points

    /// Gom nhiều thay đổi liên tiếp thành một lần đồng bộ.
    func scheduleSync() {
        guard CloudConfig.isEnabled else { return }
        debounce?.cancel()
        debounce = Task {
            try? await Task.sleep(for: .seconds(1.5))
            guard !Task.isCancelled else { return }
            try? await self.sync()
        }
    }

    func sync() async throws {
        guard CloudConfig.isEnabled else { return }
        if let running {
            rerunRequested = true
            return try await running.value
        }
        let task = Task {
            repeat {
                rerunRequested = false
                try await performSync()
            } while rerunRequested
        }
        running = task
        defer { running = nil }
        try await task.value
    }

    /// Đăng ký Silent Push cho mọi thay đổi ở cả hai database.
    func registerSubscriptions() async {
        guard CloudConfig.isEnabled else { return }
        for (db, id) in [(privateDB, "cozy-private-changes"), (sharedDB, "cozy-shared-changes")] {
            let subscription = CKDatabaseSubscription(subscriptionID: id)
            let info = CKSubscription.NotificationInfo()
            info.shouldSendContentAvailable = true
            subscription.notificationInfo = info
            _ = try? await db.save(subscription)
        }
    }

    // MARK: - Chia sẻ

    /// Trả về `CKShare` của không gian loại `kind`, tạo không gian mới nếu chưa có.
    func prepareShare(kind: SpaceKind) async throws -> (CKShare, CKContainer) {
        guard CloudConfig.isEnabled else { throw CloudSyncError.disabled }
        let existing = repository.snapshot(reload: true).spaces.first { $0.kind == kind && $0.cloud != nil }
        let info: CloudSpaceInfo
        let name: String
        if let existing, let cloud = existing.cloud {
            info = cloud
            name = existing.name
        } else {
            let id = UUID()
            let zoneID = CKRecordZone.ID(zoneName: Self.spacePrefix + id.uuidString, ownerName: CKCurrentUserDefaultName)
            _ = try await privateDB.modifyRecordZones(saving: [CKRecordZone(zoneID: zoneID)], deleting: [])
            info = CloudSpaceInfo(zoneName: zoneID.zoneName, ownerName: zoneID.ownerName, isOwner: true)
            let settings = repository.snapshot().settings
            name = kind == .couple ? "Hai đứa mình" : "Hội của mình"
            let me = MemberStatus(id: DemoData.meID, displayName: settings.displayName, species: settings.species)
            var space = SharedSpace(id: id, kind: kind, name: name, members: [me])
            space.cloud = info
            space.modifiedAt = Date()
            let newSpace = space
            repository.mutate([.spaces]) { s in
                s.spaces.removeAll { $0.kind == kind && $0.cloud == nil }
                s.spaces.append(newSpace)
                s.activeSpaceID = newSpace.id
            }
        }

        let zoneID = CKRecordZone.ID(zoneName: info.zoneName, ownerName: info.ownerName)
        let db = info.isOwner ? privateDB : sharedDB
        let shareID = CKRecord.ID(recordName: CKRecordNameZoneWideShare, zoneID: zoneID)
        let share: CKShare
        if let found = try? await db.record(for: shareID) as? CKShare {
            share = found
        } else {
            let new = CKShare(recordZoneID: zoneID)
            new[CKShare.SystemFieldKey.title] = name as CKRecordValue
            new.publicPermission = .none
            let result = try await db.modifyRecords(saving: [new], deleting: [])
            share = (try result.saveResults[new.recordID]?.get() as? CKShare) ?? new
        }
        let shareURL = share.url
        if let shareURL {
            repository.mutate([.spaces]) { s in
                if let i = s.spaces.firstIndex(where: { $0.cloud?.zoneName == info.zoneName }) {
                    s.spaces[i].shareURL = shareURL
                }
            }
        }
        try await sync()
        return (share, container)
    }

    func accept(_ metadata: CKShare.Metadata) async throws {
        guard CloudConfig.isEnabled else { return }
        _ = try await CKContainer(identifier: metadata.containerIdentifier).accept(metadata)
        let myUserID = try await container.userRecordID().recordName
        // Kiểm tra giới hạn thành viên (2 cho Couple, 8 cho Squad) trước khi giữ kết nối.
        let joinedZones = try await sharedDB.allRecordZones().filter { $0.zoneID.zoneName.hasPrefix(Self.spacePrefix) }
        for zone in joinedZones {
            let remote = try await fetchSpace(zoneID: zone.zoneID, database: sharedDB)
            if let meta = remote.meta, !SpaceMerge.canAcceptMember(kind: meta.kind, existingMembers: remote.members, userID: myUserID) {
                _ = try? await sharedDB.modifyRecordZones(saving: [], deleting: [zone.zoneID])
                throw CloudSyncError.spaceFull(meta.kind)
            }
        }
        try await sync()
    }

    /// Chủ không gian: xóa zone. Người được mời: rời khỏi zone.
    func leave(spaceID: UUID) async throws {
        guard CloudConfig.isEnabled,
              let space = repository.snapshot().spaces.first(where: { $0.id == spaceID }),
              let cloud = space.cloud else { return }
        let zoneID = CKRecordZone.ID(zoneName: cloud.zoneName, ownerName: cloud.ownerName)
        _ = try await (cloud.isOwner ? privateDB : sharedDB).modifyRecordZones(saving: [], deleting: [zoneID])
        repository.mutate([.spaces, .remote]) { s in s.spaces.removeAll { $0.id == spaceID } }
        NotificationCenter.default.post(name: .cozyRemoteDidChange, object: nil)
    }

    // MARK: - Đồng bộ

    private func performSync() async throws {
        let myUserID = try await container.userRecordID().recordName
        try await syncPersonal()

        let owned = try await privateDB.allRecordZones().filter { $0.zoneID.zoneName.hasPrefix(Self.spacePrefix) }
        let joined = try await sharedDB.allRecordZones().filter { $0.zoneID.zoneName.hasPrefix(Self.spacePrefix) }

        for (zones, db, isOwner) in [(owned, privateDB, true), (joined, sharedDB, false)] {
            for zone in zones {
                try await syncSpace(zoneID: zone.zoneID, database: db, isOwner: isOwner, myUserID: myUserID)
            }
        }

        // Không gian bị chủ xóa hoặc mình bị gỡ.
        let alive = Set((owned + joined).map(\.zoneID.zoneName))
        let hasStale = repository.snapshot().spaces.contains { $0.cloud.map { !alive.contains($0.zoneName) } ?? false }
        if hasStale {
            repository.mutate([.spaces, .remote]) { s in
                s.spaces.removeAll { $0.cloud.map { !alive.contains($0.zoneName) } ?? false }
            }
        }
        NotificationCenter.default.post(name: .cozyRemoteDidChange, object: nil)
    }

    private func syncPersonal() async throws {
        let zoneID = CKRecordZone.ID(zoneName: Self.personalZone, ownerName: CKCurrentUserDefaultName)
        _ = try await privateDB.modifyRecordZones(saving: [CKRecordZone(zoneID: zoneID)], deleting: [])
        let recordID = CKRecord.ID(recordName: "personal-snapshot", zoneID: zoneID)

        var record: CKRecord
        var remote: CozySnapshot?
        do {
            record = try await privateDB.record(for: recordID)
            if let data = record[Self.payloadKey] as? Data { remote = try? Self.decode(CozySnapshot.self, data) }
        } catch let error as CKError where error.code == .unknownItem {
            record = CKRecord(recordType: RecordType.personal, recordID: recordID)
        }

        if let remote {
            let local = repository.snapshot(reload: true)
            if PersonalMerge.merge(local: local, remote: remote) != local {
                repository.mutate([.remote]) { s in s = PersonalMerge.merge(local: s, remote: remote) }
            }
        }

        // Không gian chia sẻ và thời tiết không nằm trong bản sao cá nhân.
        var upload = repository.snapshot()
        upload.spaces = []
        upload.activeSpaceID = nil
        upload.weather = nil
        upload.todayWord = nil
        if var previous = remote {
            previous.updatedAt = upload.updatedAt
            if previous == upload { return }
        }
        record[Self.payloadKey] = try Self.encode(upload) as CKRecordValue
        _ = try await privateDB.modifyRecords(saving: [record], deleting: [], savePolicy: .allKeys)
    }

    private func syncSpace(zoneID: CKRecordZone.ID, database: CKDatabase, isOwner: Bool, myUserID: String) async throws {
        let remote = try await fetchSpace(zoneID: zoneID, database: database)

        let upload: SpaceUpload? = repository.mutate([.spaces, .events, .remote]) { s in
            var index = s.spaces.firstIndex { $0.cloud?.zoneName == zoneID.zoneName }
            if index == nil {
                // Vừa được mời (hoặc thiết bị mới): dựng không gian từ máy chủ.
                guard let meta = remote.meta else { return nil }
                var space = SharedSpace(id: meta.id, kind: meta.kind, name: meta.name, members: [], anniversary: meta.anniversary)
                space.modifiedAt = meta.modifiedAt
                space.cloud = CloudSpaceInfo(zoneName: zoneID.zoneName, ownerName: zoneID.ownerName, isOwner: isOwner)
                if !remote.members.contains(where: { $0.id == myUserID }) {
                    space.members = [MemberStatus(id: DemoData.meID, displayName: s.settings.displayName, species: s.settings.species)]
                }
                s.spaces.removeAll { $0.kind == meta.kind && $0.cloud == nil }
                s.spaces.append(space)
                s.activeSpaceID = space.id
                index = s.spaces.count - 1
            }
            guard let i = index else { return nil }

            let before = Set(s.spaces[i].sharedEventIDs)
            let others = Set(s.spaces.enumerated().filter { $0.offset != i }.flatMap { $0.element.sharedEventIDs })
            let result = SpaceMerge.merge(local: s.spaces[i], events: &s.events, remote: remote, myUserID: myUserID, otherSharedIDs: others)
            var space = result.space
            // Chỉ đánh dấu "đã đồng bộ" sau khi đẩy lên thành công.
            if var cloud = space.cloud {
                let pending = Set(result.upload.events.map(\.id))
                cloud.syncedEventIDs.removeAll { pending.contains($0) }
                cloud.syncedEventIDs += result.upload.deletedEventIDs
                space.cloud = cloud
            }
            s.spaces[i] = space
            for id in before where !s.events.contains(where: { $0.id == id }) {
                s.deletedIDs = (s.deletedIDs ?? [:]).merging([id.uuidString: Date()]) { _, new in new }
            }
            return result.upload
        }

        guard let upload, !upload.isEmpty else { return }
        try await push(upload, zoneID: zoneID, database: database)

        repository.mutate([.spaces, .remote]) { s in
            guard let i = s.spaces.firstIndex(where: { $0.cloud?.zoneName == zoneID.zoneName }), var cloud = s.spaces[i].cloud else { return }
            let deleted = Set(upload.deletedEventIDs)
            cloud.syncedEventIDs.removeAll { deleted.contains($0) }
            cloud.syncedEventIDs += upload.events.map(\.id)
            s.spaces[i].cloud = cloud
        }
    }

    private func fetchSpace(zoneID: CKRecordZone.ID, database: CKDatabase) async throws -> RemoteSpace {
        var remote = RemoteSpace()
        var token: CKServerChangeToken?
        var more = true
        // Dữ liệu một không gian nhỏ (≤ 8 người), tải toàn bộ cho đơn giản và chắc chắn.
        while more {
            let changes = try await database.recordZoneChanges(inZoneWith: zoneID, since: token)
            for (_, result) in changes.modificationResultsByID {
                let record = try result.get().record
                guard let data = record[Self.payloadKey] as? Data else { continue }
                switch record.recordType {
                case RecordType.space: remote.meta = try? Self.decode(SpaceMeta.self, data)
                case RecordType.member: if let v = try? Self.decode(MemberStatus.self, data) { remote.members.append(v) }
                case RecordType.interaction: if let v = try? Self.decode(Interaction.self, data) { remote.interactions.append(v) }
                case RecordType.event: if let v = try? Self.decode(CozyEvent.self, data) { remote.events.append(v) }
                default: break
                }
            }
            token = changes.changeToken
            more = changes.moreComing
        }
        return remote
    }

    private func push(_ upload: SpaceUpload, zoneID: CKRecordZone.ID, database: CKDatabase) async throws {
        func record<T: Encodable>(_ type: String, _ name: String, _ value: T) throws -> CKRecord {
            let r = CKRecord(recordType: type, recordID: CKRecord.ID(recordName: name, zoneID: zoneID))
            r[Self.payloadKey] = try Self.encode(value) as CKRecordValue
            return r
        }
        var saving: [CKRecord] = []
        if let meta = upload.meta { saving.append(try record(RecordType.space, "space-meta", meta)) }
        if let m = upload.member { saving.append(try record(RecordType.member, "member-\(m.id)", m)) }
        for i in upload.interactions { saving.append(try record(RecordType.interaction, "msg-\(i.id.uuidString)", i)) }
        for e in upload.events { saving.append(try record(RecordType.event, "event-\(e.id.uuidString)", e)) }
        let deleting = upload.deletedEventIDs.map { CKRecord.ID(recordName: "event-\($0.uuidString)", zoneID: zoneID) }

        // CloudKit giới hạn 400 bản ghi mỗi lần.
        var start = 0
        repeat {
            let batch = Array(saving[start..<min(start + 300, saving.count)])
            let result = try await database.modifyRecords(saving: batch, deleting: start == 0 ? deleting : [], savePolicy: .allKeys, atomically: false)
            for (_, r) in result.saveResults { _ = try r.get() }
            start += 300
        } while start < saving.count
    }

    // MARK: - Codec

    private static func encode<T: Encodable>(_ value: T) throws -> Data {
        let e = JSONEncoder()
        e.dateEncodingStrategy = .iso8601
        return try e.encode(value)
    }

    private static func decode<T: Decodable>(_ type: T.Type, _ data: Data) throws -> T {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return try d.decode(type, from: data)
    }
}

/// Nhận thông báo thay đổi từ repository và lên lịch đồng bộ.
final class CloudSyncTrigger: SyncEngine {
    func snapshotDidChange(_ snapshot: CozySnapshot, changes: Set<CozyRepository.Change>) {
        guard !changes.contains(.remote) else { return }
        Task { await CloudSync.shared.scheduleSync() }
    }
}
