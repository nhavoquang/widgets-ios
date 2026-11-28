import Foundation

/// Dữ liệu một không gian chia sẻ trên máy chủ (đã giải mã từ các CKRecord).
public struct RemoteSpace: Codable, Hashable, Sendable {
    public var meta: SpaceMeta?
    /// `id` của mỗi thành viên là iCloud user record name.
    public var members: [MemberStatus]
    public var interactions: [Interaction]
    public var events: [CozyEvent]

    public init(meta: SpaceMeta? = nil, members: [MemberStatus] = [], interactions: [Interaction] = [], events: [CozyEvent] = []) {
        self.meta = meta
        self.members = members
        self.interactions = interactions
        self.events = events
    }
}

public struct SpaceMeta: Codable, Hashable, Sendable {
    public var id: UUID
    public var kind: SpaceKind
    public var name: String
    public var anniversary: Date?
    public var modifiedAt: Date

    public init(id: UUID, kind: SpaceKind, name: String, anniversary: Date?, modifiedAt: Date) {
        self.id = id
        self.kind = kind
        self.name = name
        self.anniversary = anniversary
        self.modifiedAt = modifiedAt
    }
}

/// Những gì cần đẩy lên iCloud sau khi hợp nhất.
public struct SpaceUpload: Hashable, Sendable {
    public var meta: SpaceMeta?
    public var member: MemberStatus?
    public var interactions: [Interaction] = []
    public var events: [CozyEvent] = []
    public var deletedEventIDs: [UUID] = []

    public var isEmpty: Bool {
        meta == nil && member == nil && interactions.isEmpty && events.isEmpty && deletedEventIDs.isEmpty
    }
}

/// Logic hợp nhất thuần (không phụ thuộc CloudKit) để kiểm thử được.
/// Trên máy, thành viên "mình" có id `me`; trên máy chủ là iCloud user record name.
public enum SpaceMerge {
    public static let interactionLimit = 200

    /// Hợp nhất một không gian. `events` là kho sự kiện cục bộ và được cập nhật tại chỗ.
    public static func merge(
        local: SharedSpace,
        events: inout [CozyEvent],
        remote: RemoteSpace,
        myUserID: String,
        otherSharedIDs: Set<UUID> = []
    ) -> (space: SharedSpace, upload: SpaceUpload) {
        var space = local
        var upload = SpaceUpload()
        var cloud = local.cloud ?? CloudSpaceInfo(zoneName: "", ownerName: "", isOwner: false)

        // 1. Thông tin chung: bản mới hơn thắng.
        let localModified = local.modifiedAt ?? .distantPast
        if let meta = remote.meta, meta.modifiedAt >= localModified {
            space.name = meta.name
            space.anniversary = meta.anniversary
            space.modifiedAt = meta.modifiedAt
        } else {
            upload.meta = SpaceMeta(id: local.id, kind: local.kind, name: local.name, anniversary: local.anniversary, modifiedAt: local.modifiedAt ?? Date(timeIntervalSince1970: 0))
        }

        // 2. Thành viên: mỗi người chỉ ghi bản ghi của chính mình.
        let remoteMe = remote.members.first { $0.id == myUserID }
        var localMe = local.members.first { $0.id == DemoData.meID }
        if let mine = localMe {
            if let remoteMe, remoteMe.updatedAt > mine.updatedAt {
                var m = remoteMe
                m.id = DemoData.meID
                localMe = m
            } else if remoteMe.map({ !sameContent($0, mine) }) ?? true {
                var m = mine
                m.id = myUserID
                upload.member = m
            }
        } else if var m = remoteMe {
            m.id = DemoData.meID
            localMe = m
        }
        let maxOthers = max(0, space.kind.memberLimit.upperBound - (localMe == nil ? 0 : 1))
        let others = Array(
            remote.members
                .filter { $0.id != myUserID }
                .sorted { ($0.displayName, $0.id) < ($1.displayName, $1.id) }
                .prefix(maxOthers)
        )
        space.members = (localMe.map { [$0] } ?? []) + others

        // 3. Tương tác: chỉ thêm, hợp theo id.
        func toLocal(_ i: Interaction) -> Interaction {
            var x = i
            if x.fromMemberID == myUserID { x.fromMemberID = DemoData.meID }
            if x.toMemberID == myUserID { x.toMemberID = DemoData.meID }
            return x
        }
        let remoteIDs = Set(remote.interactions.map(\.id))
        upload.interactions = local.interactions
            .filter { $0.fromMemberID == DemoData.meID && !remoteIDs.contains($0.id) }
            .map { i in
                var x = i
                x.fromMemberID = myUserID
                return x
            }
        var byID: [UUID: Interaction] = [:]
        for i in local.interactions { byID[i.id] = i }
        for i in remote.interactions { byID[i.id] = toLocal(i) }
        space.interactions = Array(
            byID.values.sorted { ($0.sentAt, $0.id.uuidString) < ($1.sentAt, $1.id.uuidString) }.suffix(interactionLimit)
        )

        // 4. Sự kiện chung: `syncedEventIDs` phân biệt "mới tạo" với "đã bị xóa".
        let synced = Set(cloud.syncedEventIDs)
        let shared = Set(local.sharedEventIDs)
        let remoteByID = Dictionary(remote.events.map { ($0.id, $0) }, uniquingKeysWith: { a, _ in a })
        var finalIDs: [UUID] = []

        for id in Set(remoteByID.keys).union(shared) {
            let localEvent = shared.contains(id) ? events.first { $0.id == id } : nil
            switch (localEvent, remoteByID[id]) {
            case let (l?, r?):
                if (l.modifiedAt ?? .distantPast) > (r.modifiedAt ?? .distantPast) {
                    upload.events.append(l)
                } else if let i = events.firstIndex(where: { $0.id == id }) {
                    events[i] = r
                }
                finalIDs.append(id)
            case let (l?, nil):
                if synced.contains(id) {
                    // Người khác đã gỡ khỏi không gian (giữ lại nếu còn chia sẻ ở nơi khác).
                    if !otherSharedIDs.contains(id) { events.removeAll { $0.id == id } }
                } else {
                    upload.events.append(l)
                    finalIDs.append(id)
                }
            case let (nil, r?):
                if synced.contains(id) {
                    // Mình đã gỡ/xóa trên máy này.
                    upload.deletedEventIDs.append(id)
                } else {
                    events.removeAll { $0.id == id }
                    events.append(r)
                    finalIDs.append(id)
                }
            case (nil, nil):
                break
            }
        }
        upload.events.sort { $0.id.uuidString < $1.id.uuidString }
        space.sharedEventIDs = finalIDs.sorted { $0.uuidString < $1.uuidString }
        cloud.syncedEventIDs = space.sharedEventIDs
        space.cloud = cloud
        return (space, upload)
    }

    /// Kiểm tra xem một người dùng mới có còn chỗ tham gia không gian theo giới hạn (2 cho cặp đôi, 8 cho nhóm) hay không.
    public static func canAcceptMember(kind: SpaceKind, existingMembers: [MemberStatus], userID: String) -> Bool {
        if existingMembers.contains(where: { $0.id == userID }) { return true }
        return existingMembers.count < kind.memberLimit.upperBound
    }

    static func sameContent(_ a: MemberStatus, _ b: MemberStatus) -> Bool {
        a.displayName == b.displayName && a.species == b.species && a.mood == b.mood && a.foods == b.foods
            && a.socialBattery == b.socialBattery && a.deviceBattery == b.deviceBattery
            && a.weatherLine == b.weatherLine && a.note == b.note
    }
}

/// Hợp nhất dữ liệu cá nhân giữa các thiết bị của cùng một người (Private DB).
public enum PersonalMerge {
    public static func merge(local: CozySnapshot, remote: CozySnapshot) -> CozySnapshot {
        var out = local
        var deleted = local.deletedIDs ?? [:]
        for (k, v) in remote.deletedIDs ?? [:] { deleted[k] = max(v, deleted[k] ?? .distantPast) }
        out.deletedIDs = deleted.isEmpty ? nil : deleted

        var checkIns: [UUID: CheckIn] = [:]
        for c in remote.checkIns + local.checkIns { checkIns[c.id] = c }
        out.checkIns = checkIns.values.sorted { ($0.date, $0.id.uuidString) < ($1.date, $1.id.uuidString) }

        for (id, r) in remote.reviewStates {
            if let l = out.reviewStates[id], (l.lastReviewed ?? .distantPast) >= (r.lastReviewed ?? .distantPast) { continue }
            out.reviewStates[id] = r
        }
        for (day, n) in remote.learnedLog { out.learnedLog[day] = max(n, out.learnedLog[day] ?? 0) }

        for w in remote.customWords where !out.customWords.contains(where: { $0.id == w.id }) { out.customWords.append(w) }

        for e in remote.events {
            if let i = out.events.firstIndex(where: { $0.id == e.id }) {
                if (e.modifiedAt ?? .distantPast) > (out.events[i].modifiedAt ?? .distantPast) { out.events[i] = e }
            } else {
                out.events.append(e)
            }
        }
        out.events.removeAll { deleted[$0.id.uuidString] != nil }

        for c in remote.widgetConfigs where !out.widgetConfigs.contains(where: { $0.id == c.id }) { out.widgetConfigs.append(c) }
        out.widgetConfigs.removeAll { deleted[$0.id.uuidString] != nil }

        // Cài đặt: lấy bản của snapshot mới hơn.
        if remote.updatedAt > local.updatedAt || local.settings == UserSettings() { out.settings = remote.settings }
        return out
    }
}
