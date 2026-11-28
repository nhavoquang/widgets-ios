import Foundation

/// Điểm móc đồng bộ ngầm (CloudKit ở giai đoạn 2). Mặc định không làm gì.
public protocol SyncEngine: AnyObject, Sendable {
    func snapshotDidChange(_ snapshot: CozySnapshot, changes: Set<CozyRepository.Change>)
}

/// Kho dữ liệu local-first dùng chung giữa App, Widget và AppIntents.
/// Mọi thao tác ghi vào App Group ngay lập tức, sau đó báo cho `SyncEngine`.
public final class CozyRepository: @unchecked Sendable {
    public enum Change: String, Hashable, Sendable {
        case settings, vocab, checkIn, events, spaces, widgets, weather
        /// Thay đổi đến từ iCloud (không cần đẩy ngược lên).
        case remote
    }

    public let store: SnapshotStore
    public var calendar: Calendar
    public weak var syncEngine: SyncEngine?
    private let lock = NSRecursiveLock()
    private var cached: CozySnapshot?
    private let srs: SpacedRepetition
    private let counter: EventCounter

    public init(store: SnapshotStore, calendar: Calendar = .cozy) {
        self.store = store
        self.calendar = calendar
        self.srs = SpacedRepetition(calendar: calendar)
        self.counter = EventCounter(calendar: calendar)
    }

    public static func shared() -> CozyRepository { CozyRepository(store: .shared()) }

    // MARK: - Snapshot

    /// Đọc snapshot. `reload = true` để đọc lại từ đĩa (vd. Widget/App vừa ghi).
    public func snapshot(reload: Bool = false) -> CozySnapshot {
        lock.lock(); defer { lock.unlock() }
        if reload || cached == nil {
            cached = loadOrCreate()
        }
        return cached!
    }

    /// Lần chạy đầu tiên: tạo dữ liệu thật sạch sẽ (không tạo người yêu/thời tiết/sự kiện giả).
    private func loadOrCreate() -> CozySnapshot {
        if let s = store.load() { return s }
        if let c = cached { return c }
        let fresh = CozySnapshot.freshReal(now: Date())
        try? store.save(fresh)
        return fresh
    }

    @discardableResult
    public func mutate<T>(_ changes: Set<Change>, _ body: (inout CozySnapshot) -> T) -> T {
        lock.lock(); defer { lock.unlock() }
        var snap = loadOrCreate()
        let result = body(&snap)
        snap.updatedAt = Date()
        cached = snap
        try? store.save(snap)
        syncEngine?.snapshotDidChange(snap, changes: changes)
        return result
    }

    public func reset(to snapshot: CozySnapshot) {
        mutate(Set([.settings, .vocab, .checkIn, .events, .spaces, .widgets, .weather])) { $0 = snapshot }
    }

    // MARK: - Settings

    public func updateSettings(_ body: (inout UserSettings) -> Void) {
        mutate([.settings]) { body(&$0.settings) }
    }

    // MARK: - Vocab

    public func allWords(in snap: CozySnapshot? = nil) -> [VocabWord] {
        VocabSeed.all + (snap ?? snapshot()).customWords
    }

    public func word(id: String) -> VocabWord? {
        allWords().first { $0.id == id }
    }

    /// Từ của hôm nay. Tự chọn từ mới nếu sang ngày mới.
    @discardableResult
    public func currentWord(now: Date = Date()) -> VocabWord? {
        let key = calendar.dayKey(for: now)
        let snap = snapshot(reload: true)
        let words = allWords(in: snap)
        if let p = snap.todayWord, p.dayKey == key, let w = words.first(where: { $0.id == p.wordID }) {
            return w
        }
        return mutate([.vocab]) { s in
            let next = srs.nextWord(words: words, states: s.reviewStates, decks: s.settings.activeDecks, now: now)
            if let next { s.todayWord = TodayWordPointer(wordID: next.id, dayKey: key) }
            return next
        }
    }

    /// "Đã thuộc" → lên bậc SRS, ghi log streak, chuyển sang từ kế tiếp.
    @discardableResult
    public func markCurrentWordLearned(now: Date = Date()) -> VocabWord? {
        guard let current = currentWord(now: now) else { return nil }
        let key = calendar.dayKey(for: now)
        return mutate([.vocab]) { s in
            s.reviewStates[current.id] = srs.markLearned(s.reviewStates[current.id], wordID: current.id, now: now)
            s.learnedLog[key, default: 0] += 1
            let next = srs.nextWord(words: allWords(in: s), states: s.reviewStates, decks: s.settings.activeDecks, now: now, excluding: [current.id])
            if let next { s.todayWord = TodayWordPointer(wordID: next.id, dayKey: key) }
            return next
        }
    }

    /// "Đổi từ" → bỏ qua tạm thời, không ảnh hưởng SRS.
    @discardableResult
    public func skipCurrentWord(now: Date = Date()) -> VocabWord? {
        guard let current = currentWord(now: now) else { return nil }
        let key = calendar.dayKey(for: now)
        return mutate([.vocab]) { s in
            var skipped = Set(s.todayWord?.skipped ?? [])
            skipped.insert(current.id)
            var next = srs.nextWord(words: allWords(in: s), states: s.reviewStates, decks: s.settings.activeDecks, now: now, excluding: skipped)
            if next == nil {
                // Đã bỏ qua hết: làm lại vòng mới.
                skipped = [current.id]
                next = srs.nextWord(words: allWords(in: s), states: s.reviewStates, decks: s.settings.activeDecks, now: now, excluding: skipped)
            }
            if let next { s.todayWord = TodayWordPointer(wordID: next.id, dayKey: key, skipped: Array(skipped).sorted()) }
            return next
        }
    }

    public func markCurrentWordForgot(now: Date = Date()) {
        guard let current = currentWord(now: now) else { return }
        mutate([.vocab]) { s in
            s.reviewStates[current.id] = srs.markForgot(s.reviewStates[current.id], wordID: current.id, now: now)
        }
    }

    public func addCustomWord(_ word: VocabWord) {
        var w = word
        w.deck = .custom
        mutate([.vocab]) { s in
            s.customWords.removeAll { $0.id == w.id }
            s.customWords.append(w)
            s.settings.activeDecks.insert(.custom)
        }
    }

    public func dueReviewCount(now: Date = Date()) -> Int {
        srs.dueWords(states: snapshot().reviewStates, now: now).count
    }

    public func masteredCount() -> Int {
        snapshot().reviewStates.values.filter(\.isMastered).count
    }

    /// Chuỗi ngày liên tiếp có học từ (tính tới hôm nay; nếu hôm nay chưa học thì tính tới hôm qua).
    public func vocabStreak(now: Date = Date()) -> Int {
        Self.streak(log: snapshot().learnedLog, now: now, calendar: calendar)
    }

    public static func streak(log: [String: Int], now: Date, calendar: Calendar) -> Int {
        var day = calendar.startOfDay(for: now)
        if (log[calendar.dayKey(for: day)] ?? 0) == 0 {
            day = calendar.date(byAdding: .day, value: -1, to: day)!
        }
        var count = 0
        while (log[calendar.dayKey(for: day)] ?? 0) > 0 {
            count += 1
            day = calendar.date(byAdding: .day, value: -1, to: day)!
        }
        return count
    }

    // MARK: - Check-in

    @discardableResult
    public func checkIn(mood: Mood, foods: [FoodSticker], socialBattery: Int, note: String, source: CheckIn.Source = .manual, now: Date = Date()) -> CheckIn {
        let entry = CheckIn(date: now, mood: mood, foods: foods, socialBattery: socialBattery, note: note, source: source)
        mutate([.checkIn, .spaces]) { s in
            s.checkIns.append(entry)
            // Cập nhật trạng thái "me" trong mọi không gian chia sẻ.
            for i in s.spaces.indices {
                if let m = s.spaces[i].members.firstIndex(where: { $0.id == DemoData.meID }) {
                    s.spaces[i].members[m].mood = mood
                    s.spaces[i].members[m].foods = foods
                    s.spaces[i].members[m].socialBattery = entry.socialBattery
                    s.spaces[i].members[m].note = entry.note
                    s.spaces[i].members[m].updatedAt = now
                }
            }
        }
        return entry
    }

    /// Cập nhật nhanh chỉ mood (từ Shortcut/Focus/Widget), giữ món ăn & pin của lần trước trong ngày.
    @discardableResult
    public func quickMood(_ mood: Mood, source: CheckIn.Source, now: Date = Date()) -> CheckIn {
        let last = latestCheckIn(on: now)
        return checkIn(mood: mood, foods: last?.foods ?? [], socialBattery: last?.socialBattery ?? 60, note: last?.note ?? "", source: source, now: now)
    }

    /// Check-in nhanh từ widget/Shortcut: giá trị nil giữ nguyên theo lần trước trong ngày.
    @discardableResult
    public func quickCheckIn(mood: Mood?, food: FoodSticker?, source: CheckIn.Source, now: Date = Date()) -> CheckIn {
        let last = latestCheckIn(on: now)
        return checkIn(
            mood: mood ?? last?.mood ?? .chill,
            foods: food.map { [$0] } ?? last?.foods ?? [],
            socialBattery: last?.socialBattery ?? 60,
            note: last?.note ?? "", source: source, now: now
        )
    }

    public func latestCheckIn(on day: Date) -> CheckIn? {
        snapshot().checkIns.filter { calendar.isDate($0.date, inSameDayAs: day) }.max { $0.date < $1.date }
    }

    public func latestCheckIn() -> CheckIn? {
        snapshot().checkIns.max { $0.date < $1.date }
    }

    // MARK: - Events

    /// - Parameter spaceIDs: nếu khác nil, đặt lại danh sách không gian được chia sẻ sự kiện này.
    public func upsertEvent(_ event: CozyEvent, sharedWith spaceIDs: Set<UUID>? = nil, now: Date = Date()) {
        mutate([.events, .spaces]) { s in
            var e = event
            e.modifiedAt = now
            if let spaceIDs {
                e.isShared = !spaceIDs.isEmpty
                for i in s.spaces.indices {
                    s.spaces[i].sharedEventIDs.removeAll { $0 == e.id }
                    if spaceIDs.contains(s.spaces[i].id) { s.spaces[i].sharedEventIDs.append(e.id) }
                }
            }
            s.deletedIDs?[e.id.uuidString] = nil
            if let i = s.events.firstIndex(where: { $0.id == e.id }) { s.events[i] = e } else { s.events.append(e) }
        }
    }

    public func deleteEvent(id: UUID) {
        mutate([.events]) { s in
            s.events.removeAll { $0.id == id }
            s.deletedIDs = (s.deletedIDs ?? [:]).merging([id.uuidString: Date()]) { _, new in new }
            for i in s.spaces.indices { s.spaces[i].sharedEventIDs.removeAll { $0 == id } }
        }
    }

    public func upcomingEvents(now: Date = Date(), limit: Int = 5) -> [CozyEvent] {
        Array(counter.sortedByUrgency(snapshot().events, now: now).prefix(limit))
    }

    public func event(id: UUID) -> CozyEvent? { snapshot().events.first { $0.id == id } }

    // MARK: - Spaces

    public func activeSpace() -> SharedSpace? {
        let s = snapshot()
        return s.spaces.first { $0.id == s.activeSpaceID } ?? s.spaces.first
    }

    public func space(kind: SpaceKind) -> SharedSpace? {
        snapshot().spaces.preferred(kind)
    }

    public func setActiveSpace(_ id: UUID) {
        mutate([.spaces]) { $0.activeSpaceID = id }
    }

    public func send(_ payload: Interaction.Payload, in spaceID: UUID, to memberID: String? = nil, now: Date = Date()) {
        mutate([.spaces]) { s in
            guard let i = s.spaces.firstIndex(where: { $0.id == spaceID }) else { return }
            s.spaces[i].interactions.append(Interaction(from: DemoData.meID, to: memberID, payload: payload, sentAt: now))
            // Giữ tối đa 200 tương tác gần nhất.
            if s.spaces[i].interactions.count > 200 {
                s.spaces[i].interactions.removeFirst(s.spaces[i].interactions.count - 200)
            }
        }
    }

    public func upsertSpace(_ space: SharedSpace) {
        mutate([.spaces]) { s in
            if let i = s.spaces.firstIndex(where: { $0.id == space.id }) { s.spaces[i] = space } else { s.spaces.append(space) }
        }
    }

    /// Cập nhật tên/linh vật/pin của "mình" trong mọi không gian.
    public func updateMyProfile(deviceBattery: Double? = nil, now: Date = Date()) {
        let snap = snapshot()
        let name = snap.settings.displayName
        let species = snap.settings.species
        let battery = snap.settings.shareDeviceBattery ? deviceBattery.map { ($0 * 20).rounded() / 20 } : nil
        let needsUpdate = snap.spaces.contains { space in
            space.members.contains { m in
                m.id == DemoData.meID && (m.displayName != name || m.species != species || (deviceBattery != nil && m.deviceBattery != battery))
            }
        }
        guard needsUpdate else { return }
        mutate([.spaces]) { s in
            for i in s.spaces.indices {
                if let m = s.spaces[i].members.firstIndex(where: { $0.id == DemoData.meID }) {
                    s.spaces[i].members[m].displayName = name
                    s.spaces[i].members[m].species = species
                    if deviceBattery != nil { s.spaces[i].members[m].deviceBattery = battery }
                    s.spaces[i].members[m].updatedAt = now
                }
            }
        }
    }

    /// Xóa toàn bộ dữ liệu mẫu (không gian mẫu, check-in, sự kiện mẫu, thời tiết mẫu).
    public func removeDemoData() {
        mutate([.checkIn, .events, .spaces, .vocab, .weather]) { s in
            s.spaces.removeAll { $0.cloud == nil }
            s.checkIns.removeAll { DemoData.isDemo($0.id) }
            s.events.removeAll { DemoData.isDemo($0.id) }
            s.learnedLog = s.learnedLog.filter { day, _ in s.reviewStates.values.contains { $0.lastReviewed.map { calendar.dayKey(for: $0) == day } ?? false } }
            if let w = s.weather, w.regionKey == "demo" || (w.placeName == "TP.HCM" && Int(w.temperatureC) == 27 && Int(w.highC) == 31 && Int(w.lowC) == 24) {
                s.weather = nil
            }
            s.activeSpaceID = s.spaces.first?.id
        }
    }

    // MARK: - Daily Tasks & Today Schedule

    @discardableResult
    public func addTask(title: String, timeText: String? = nil, day: Date? = Date(), accent: ColorToken = .accentSky) -> CozyTask? {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        let cleanTime = timeText?.trimmingCharacters(in: .whitespacesAndNewlines)
        let task = CozyTask(
            title: String(trimmed.prefix(60)),
            dayKey: day.map { calendar.dayKey(for: $0) },
            timeText: (cleanTime?.isEmpty == false) ? cleanTime : nil,
            isDone: false,
            accent: accent
        )
        mutate([.events]) { s in
            s.tasks.append(task)
        }
        return task
    }

    public func toggleTask(id: UUID) {
        mutate([.events]) { s in
            if let i = s.tasks.firstIndex(where: { $0.id == id }) {
                s.tasks[i].isDone.toggle()
            }
        }
    }

    public func deleteTask(id: UUID) {
        mutate([.events]) { s in
            s.tasks.removeAll { $0.id == id }
        }
    }

    public func tasks(on day: Date) -> [CozyTask] {
        let key = calendar.dayKey(for: day)
        return snapshot(reload: true).tasks
            .filter { $0.dayKey == nil || $0.dayKey == key }
            .sorted {
                if $0.isDone != $1.isDone { return !$0.isDone }
                return ($0.timeText ?? "99:99", $0.createdAt) < ($1.timeText ?? "99:99", $1.createdAt)
            }
    }

    /// Gộp lịch hôm nay (Apple Calendar + sự kiện lặp tuần/deadline/countdown trong ngày) + công việc `CozyTask`.
    public func todaySchedule(now: Date = Date()) -> [TodayScheduleItem] {
        let snap = snapshot(reload: true)
        let key = calendar.dayKey(for: now)
        let todayStart = calendar.startOfDay(for: now)
        var items: [TodayScheduleItem] = []

        for e in snap.events {
            if case .countUp = e.kind { continue }
            guard let next = counter.nextOccurrence(of: e, now: todayStart),
                  calendar.isDate(next, inSameDayAs: now) else { continue }
            let timeStr: String? = {
                switch e.kind {
                case let .weekly(_, h, m):
                    return String(format: "%02d:%02d", h, m)
                case let .deadline(due):
                    let c = calendar.dateComponents([.hour, .minute], from: due)
                    return String(format: "%02d:%02d", c.hour ?? 0, c.minute ?? 0)
                default:
                    return nil
                }
            }()
            items.append(TodayScheduleItem(
                id: "event-\(e.id.uuidString)",
                title: e.title,
                timeText: timeStr,
                isTask: false,
                taskID: nil,
                isDone: false,
                accent: e.accent
            ))
        }

        for t in snap.tasks where t.dayKey == nil || t.dayKey == key {
            items.append(TodayScheduleItem(
                id: "task-\(t.id.uuidString)",
                title: t.title,
                timeText: t.timeText,
                isTask: true,
                taskID: t.id,
                isDone: t.isDone,
                accent: t.accent
            ))
        }

        return items.sorted {
            if $0.isDone != $1.isDone { return !$0.isDone }
            return ($0.timeText ?? "99:99", $0.title) < ($1.timeText ?? "99:99", $1.title)
        }
    }

    /// Cập nhật trạng thái thật của người kết nối từ link `cozydaily://partner?...` (chạy được cả khi chưa bật iCloud).
    public func applyIncomingPartner(_ update: IncomingPartnerUpdate) {
        mutate([.spaces]) { s in
            let partnerMember = MemberStatus(
                id: "linked-partner",
                displayName: update.name,
                species: update.species,
                mood: update.mood,
                foods: [],
                socialBattery: nil,
                deviceBattery: update.deviceBattery,
                weatherLine: update.weatherLine,
                note: update.note,
                updatedAt: update.updatedAt
            )
            // Xóa couple mẫu cũ nếu còn sót
            s.spaces.removeAll { $0.kind == .couple && $0.cloud == nil && $0.name == "Mình & Gấu" }
            if let i = s.spaces.firstIndex(where: { $0.kind == .couple }) {
                if let pIdx = s.spaces[i].members.firstIndex(where: { $0.id != DemoData.meID }) {
                    s.spaces[i].members[pIdx] = partnerMember
                } else {
                    s.spaces[i].members.append(partnerMember)
                }
                s.spaces[i].modifiedAt = update.updatedAt
            } else {
                let me = MemberStatus(id: DemoData.meID, displayName: s.settings.displayName, species: s.settings.species)
                let space = SharedSpace(
                    kind: .couple,
                    name: "\(s.settings.displayName) & \(update.name)",
                    members: [me, partnerMember]
                )
                s.spaces.append(space)
                s.activeSpaceID = space.id
            }
        }
    }

    // MARK: - Weather

    public func updateWeather(_ weather: WeatherSnapshot) {
        mutate([.weather, .spaces]) { s in
            s.weather = weather
            guard s.settings.shareWeatherWithSpaces else { return }
            for i in s.spaces.indices {
                if let m = s.spaces[i].members.firstIndex(where: { $0.id == DemoData.meID }) {
                    s.spaces[i].members[m].weatherLine = WeatherSuggestion.shareLine(for: weather)
                }
            }
        }
    }

    // MARK: - Widgets

    public func upsertWidgetConfig(_ config: WidgetConfig) {
        mutate([.widgets]) { s in
            if let i = s.widgetConfigs.firstIndex(where: { $0.id == config.id }) { s.widgetConfigs[i] = config } else { s.widgetConfigs.append(config) }
        }
    }

    public func deleteWidgetConfig(id: UUID) {
        mutate([.widgets]) { s in
            s.widgetConfigs.removeAll { $0.id == id }
            s.deletedIDs = (s.deletedIDs ?? [:]).merging([id.uuidString: Date()]) { _, new in new }
        }
    }

    public func widgetConfig(id: UUID?) -> WidgetConfig? {
        guard let id else { return nil }
        return snapshot(reload: true).widgetConfigs.first { $0.id == id }
    }

    /// Đồng bộ loài linh vật mới sang các mẫu widget đang dùng loài cũ để Home/Lock Screen đổi theo ngay.
    public func syncWidgetSpecies(from oldSpecies: MascotSpecies, to newSpecies: MascotSpecies) {
        guard oldSpecies != newSpecies else { return }
        mutate([.widgets]) { s in
            for i in s.widgetConfigs.indices where s.widgetConfigs[i].species == oldSpecies {
                s.widgetConfigs[i].species = newSpecies
            }
        }
    }
}
