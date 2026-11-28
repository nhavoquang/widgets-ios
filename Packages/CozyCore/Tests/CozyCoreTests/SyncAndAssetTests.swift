import XCTest
@testable import CozyCore

final class AssetRegistryTests: XCTestCase {
    func testAssetNamesAreUniqueAndFilled() {
        let all = MascotAssetManager.allAssets
        XCTAssertEqual(Set(all.map(\.staticFullColorImageName)).count, all.count)
        XCTAssertTrue(all.allSatisfy { !$0.monochromeSymbolName.isEmpty && !$0.fallbackEmoji.isEmpty })
        XCTAssertEqual(Mood.happy.asset.animationResourceName, "anim_mood_happy")
        XCTAssertEqual(FoodSticker.pho.asset.staticFullColorImageName, "img_food_pho")
        XCTAssertEqual(WeatherCondition.rain.asset.monochromeSymbolName, "cloud.rain.fill")
    }

    func testAppGroupCandidatesPreferSideloadRewrite() {
        let ids = SnapshotStore.appGroupCandidates(info: ["ALTAppGroups": ["group.x.TEAM"], "CozyAppGroup": SnapshotStore.defaultAppGroupID])
        XCTAssertEqual(ids, ["group.x.TEAM", SnapshotStore.defaultAppGroupID])
    }
}

final class SharedWidgetStoreTests: XCTestCase {
    func testQuickStateAndThemeConfig() {
        let repo = CozyRepository(store: TestCal.tempStore(), calendar: TestCal.vn)
        let now = TestCal.date(2026, 11, 27)
        repo.reset(to: DemoData.makeInitialSnapshot(now: now, calendar: TestCal.vn))
        let suite = "cozy-tests-\(UUID().uuidString)"
        let store = SharedWidgetStore(repository: repo, defaults: UserDefaults(suiteName: suite))
        let state = store.publishQuickState(now: now)
        XCTAssertEqual(store.quickState()?.vocabulary?.wordID, state.vocabulary?.wordID)
        XCTAssertEqual(state.partner?.displayName, "Gấu")

        var theme = store.themeConfig(id: DemoData.id(21))!
        theme.accent = .accentHoney
        theme.showMascot = false
        store.saveThemeConfig(theme, id: DemoData.id(21))
        XCTAssertEqual(repo.widgetConfig(id: DemoData.id(21))?.accent, .accentHoney)
        XCTAssertEqual(repo.widgetConfig(id: DemoData.id(21))?.showMascot, false)
        UserDefaults.standard.removePersistentDomain(forName: suite)
    }
}

final class SpaceMergeTests: XCTestCase {
    let t0 = TestCal.date(2026, 11, 1)
    let t1 = TestCal.date(2026, 11, 2)

    func makeLocal(events: [UUID] = [], synced: [UUID] = [], interactions: [Interaction] = []) -> SharedSpace {
        var s = SharedSpace(kind: .couple, name: "Đôi", members: [MemberStatus(id: "me", displayName: "A", species: .cat, mood: .happy, updatedAt: t1)], interactions: interactions, sharedEventIDs: events)
        s.cloud = CloudSpaceInfo(zoneName: "z", ownerName: "o", isOwner: true, syncedEventIDs: synced)
        return s
    }

    func testMyStatusAndPingsAreUploadedWithCloudID() {
        let ping = Interaction(from: "me", payload: .ping(.missYou), sentAt: t1)
        let partner = MemberStatus(id: "_partner", displayName: "B", species: .bear, updatedAt: t0)
        let theirs = Interaction(from: "_partner", to: "_me", payload: .ping(.ateYet), sentAt: t0)
        var events: [CozyEvent] = []
        let r = SpaceMerge.merge(local: makeLocal(interactions: [ping]), events: &events, remote: RemoteSpace(members: [partner], interactions: [theirs]), myUserID: "_me")
        XCTAssertEqual(r.upload.member?.id, "_me")
        XCTAssertEqual(r.upload.interactions.map(\.fromMemberID), ["_me"])
        XCTAssertEqual(r.space.members.map(\.id), ["me", "_partner"])
        XCTAssertEqual(r.space.interactions.map(\.toMemberID), ["me", nil])
        XCTAssertNotNil(r.upload.meta, "Máy chủ chưa có thông tin thì phải đẩy lên")
    }

    func testSecondSyncUploadsNothing() {
        var events: [CozyEvent] = []
        let first = SpaceMerge.merge(local: makeLocal(), events: &events, remote: RemoteSpace(), myUserID: "_me")
        let server = RemoteSpace(meta: first.upload.meta, members: [first.upload.member!])
        let second = SpaceMerge.merge(local: first.space, events: &events, remote: server, myUserID: "_me")
        XCTAssertTrue(second.upload.isEmpty, "\(second.upload)")
    }

    func testEventAddUploadAndDeletions() {
        let mine = CozyEvent(title: "Mới", kind: .countUp(since: t0))
        let goneRemotely = CozyEvent(title: "Bị gỡ", kind: .countUp(since: t0))
        let deletedLocally = CozyEvent(title: "Đã xóa", kind: .countUp(since: t0))
        let fromPartner = CozyEvent(title: "Của người ấy", kind: .countUp(since: t0))
        var events = [mine, goneRemotely]
        let local = makeLocal(events: [mine.id, goneRemotely.id], synced: [goneRemotely.id, deletedLocally.id])
        let r = SpaceMerge.merge(local: local, events: &events, remote: RemoteSpace(events: [deletedLocally, fromPartner]), myUserID: "_me")
        XCTAssertEqual(r.upload.events.map(\.id), [mine.id])
        XCTAssertEqual(r.upload.deletedEventIDs, [deletedLocally.id])
        XCTAssertEqual(Set(events.map(\.id)), [mine.id, fromPartner.id])
        XCTAssertEqual(Set(r.space.sharedEventIDs), [mine.id, fromPartner.id])
    }

    func testPersonalMergeKeepsBothAndHonoursDeletions() {
        let repo = CozyRepository(store: TestCal.tempStore(), calendar: TestCal.vn)
        let base = DemoData.makeInitialSnapshot(now: t0, calendar: TestCal.vn)
        repo.reset(to: base)
        repo.deleteEvent(id: DemoData.id(3))
        repo.checkIn(mood: .happy, foods: [], socialBattery: 50, note: "", now: t1)
        var other = base
        other.checkIns.append(CheckIn(mood: .tired))
        let merged = PersonalMerge.merge(local: repo.snapshot(), remote: other)
        XCTAssertFalse(merged.events.contains { $0.id == DemoData.id(3) })
        XCTAssertEqual(merged.checkIns.count, base.checkIns.count + 2)
        XCTAssertEqual(merged.events.count, base.events.count - 1, "Không tạo bản trùng")
    }

    func testRemoveDemoData() {
        let repo = CozyRepository(store: TestCal.tempStore(), calendar: TestCal.vn)
        repo.reset(to: DemoData.makeInitialSnapshot(now: t0, calendar: TestCal.vn))
        repo.removeDemoData()
        XCTAssertTrue(repo.snapshot().events.isEmpty)
        XCTAssertTrue(repo.snapshot().spaces.isEmpty)
        XCTAssertTrue(repo.snapshot().checkIns.isEmpty)
    }

    func testUserSettingsBackwardCompatibleDecode() throws {
        let legacyJSON = """
        {
            "displayName": "Bông",
            "species": "bunny",
            "activeDecks": ["daily"],
            "shareWeatherWithSpaces": false,
            "shareDeviceBattery": true,
            "syncAppleCalendar": false,
            "hasOnboarded": true
        }
        """
        let decoded = try JSONDecoder().decode(UserSettings.self, from: Data(legacyJSON.utf8))
        XCTAssertEqual(decoded.displayName, "Bông")
        XCTAssertEqual(decoded.species, .bunny)
        XCTAssertEqual(decoded.appearance, .system)
        XCTAssertTrue(decoded.hapticsEnabled)
        XCTAssertEqual(decoded.weatherLocation, .autoGPS)

        var updated = decoded
        updated.appearance = .dark
        updated.hapticsEnabled = false
        updated.weatherLocation = .hanoi
        let roundTrip = try JSONDecoder().decode(UserSettings.self, from: JSONEncoder().encode(updated))
        XCTAssertEqual(roundTrip.appearance, .dark)
        XCTAssertFalse(roundTrip.hapticsEnabled)
        XCTAssertEqual(roundTrip.weatherLocation, .hanoi)
    }

    func testWMOCodeMappingAndWidgetLiveReload() {
        XCTAssertEqual(WeatherCondition.fromWMOCode(0, temperatureC: 28), .clear)
        XCTAssertEqual(WeatherCondition.fromWMOCode(0, temperatureC: 37), .hot)
        XCTAssertEqual(WeatherCondition.fromWMOCode(63, temperatureC: 24), .rain)
        XCTAssertEqual(WeatherCondition.fromWMOCode(95, temperatureC: 26), .thunderstorm)

        // Demo weather với regionKey "demo" phải luôn buộc fetch dữ liệu thật.
        let demoSnap = DemoData.makeInitialSnapshot(now: t0, calendar: TestCal.vn)
        let policy = WeatherCachePolicy()
        let decision = policy.decide(cached: demoSnap.weather, latitude: 10.78, longitude: 106.70, now: t0)
        if case .useCache = decision {
            XCTFail("Demo weather không được chặn fetch thời tiết thật")
        }

        // Widget process đọc từ cùng file App Group phải thấy cấu hình mới ngay khi app ghi.
        let store = TestCal.tempStore()
        let appRepo = CozyRepository(store: store, calendar: TestCal.vn)
        let widgetRepo = CozyRepository(store: store, calendar: TestCal.vn)
        appRepo.reset(to: demoSnap)
        _ = widgetRepo.widgetConfig(id: DemoData.id(21))
        appRepo.syncWidgetSpecies(from: .cat, to: .bunny)
        XCTAssertEqual(widgetRepo.widgetConfig(id: DemoData.id(21))?.species, .bunny)
    }

    func testSpaceMergeEnforcesCoupleAndSquadMemberLimits() {
        let extraMembers = (1...10).map { i in
            MemberStatus(id: "_u\(i)", displayName: String(format: "Bạn %02d", i), species: .cat, updatedAt: t0)
        }
        var events: [CozyEvent] = []

        // Couple: tối đa 2 người (mình + 1 người yêu)
        let coupleMerged = SpaceMerge.merge(
            local: makeLocal(),
            events: &events,
            remote: RemoteSpace(members: extraMembers),
            myUserID: "_me"
        )
        XCTAssertEqual(coupleMerged.space.members.count, 2)
        XCTAssertFalse(coupleMerged.space.canAddMember)
        XCTAssertFalse(SpaceMerge.canAcceptMember(kind: .couple, existingMembers: Array(extraMembers.prefix(2)), userID: "_new"))
        XCTAssertTrue(SpaceMerge.canAcceptMember(kind: .couple, existingMembers: Array(extraMembers.prefix(2)), userID: "_u1"))

        // Squad: tối đa 8 người (mình + 7 bạn)
        var squadLocal = makeLocal()
        squadLocal.kind = .squad
        let squadMerged = SpaceMerge.merge(
            local: squadLocal,
            events: &events,
            remote: RemoteSpace(members: extraMembers),
            myUserID: "_me"
        )
        XCTAssertEqual(squadMerged.space.members.count, 8)
        XCTAssertFalse(squadMerged.space.canAddMember)
        XCTAssertTrue(SpaceMerge.canAcceptMember(kind: .squad, existingMembers: Array(extraMembers.prefix(7)), userID: "_new"))
        XCTAssertFalse(SpaceMerge.canAcceptMember(kind: .squad, existingMembers: Array(extraMembers.prefix(8)), userID: "_new"))
    }

    func testTasksTodayScheduleAndPartnerLink() throws {
        let repo = CozyRepository(store: TestCal.tempStore(), calendar: TestCal.vn)
        let now = TestCal.date(2026, 11, 28, 9, 0)
        // Fresh repo không được chứa dữ liệu mẫu giả
        XCTAssertTrue(repo.snapshot().events.isEmpty)
        XCTAssertNil(repo.snapshot().weather)
        XCTAssertTrue(repo.snapshot().spaces.isEmpty)

        // Thêm công việc & sự kiện hôm nay
        let task = repo.addTask(title: "Gửi báo cáo", timeText: "14:00", day: now)!
        repo.upsertEvent(CozyEvent(title: "Họp nhóm", kind: .deadline(due: TestCal.date(2026, 11, 28, 10, 30))))
        let schedule = repo.todaySchedule(now: now)
        XCTAssertEqual(schedule.map(\.title), ["Họp nhóm", "Gửi báo cáo"])
        repo.toggleTask(id: task.id)
        XCTAssertTrue(repo.tasks(on: now).first?.isDone == true)

        // PartnerStatusLink encode/decode thật qua cozydaily://partner?...
        let url = try XCTUnwrap(PartnerStatusLink.makeURL(
            name: "Minh", species: .dog, mood: .happy, note: "Nhớ bạn nè",
            weatherLine: "26° Hà Nội", deviceBattery: 0.78, at: now
        ))
        let parsed = try XCTUnwrap(PartnerStatusLink.parse(url))
        XCTAssertEqual(parsed.name, "Minh")
        XCTAssertEqual(parsed.mood, .happy)
        XCTAssertEqual(parsed.note, "Nhớ bạn nè")
        repo.applyIncomingPartner(parsed)
        XCTAssertEqual(repo.space(kind: .couple)?.partner(of: DemoData.meID)?.displayName, "Minh")
    }

    func testFifteenLanguagesAndLegacySettingsDecode() throws {
        // Đảm bảo đủ 15 ngôn ngữ App Store + chế độ .system
        XCTAssertEqual(AppLanguage.storeLocaleCodes.count, 15)
        XCTAssertEqual(AppLanguage.allCases.count, 16)

        // Kiểm tra ánh xạ mã vùng hệ thống
        XCTAssertEqual(AppLanguage.matchSystemLocale("vi-VN"), .vi)
        XCTAssertEqual(AppLanguage.matchSystemLocale("ja_JP"), .ja)
        XCTAssertEqual(AppLanguage.matchSystemLocale("zh-Hant-TW"), .zhHant)
        XCTAssertEqual(AppLanguage.matchSystemLocale("zh-Hans-CN"), .zhHans)
        XCTAssertEqual(AppLanguage.matchSystemLocale("pt-BR"), .ptBR)
        XCTAssertEqual(AppLanguage.matchSystemLocale("fr-FR"), .fr)
        XCTAssertEqual(AppLanguage.matchSystemLocale("unknown-XX"), .en)

        // Kiểm tra đủ 7 ngày trong tuần và bản dịch khác rỗng cho cả 15 ngôn ngữ
        for lang in AppLanguage.allCases where lang != .system {
            XCTAssertEqual(CozyL10n.weekdayShortLabels(for: lang).count, 7)
            XCTAssertFalse(CozyL10n.t("tab.today", lang: lang).isEmpty)
            XCTAssertFalse(CozyL10n.t("block.weather", lang: lang).isEmpty)
            XCTAssertFalse(CozyL10n.t("weather.rain", lang: lang).isEmpty)
        }

        // Giải mã JSON UserSettings cũ chưa có trường `language`, `weekStartDay`, `syncAppleReminders`
        let legacyJSON = #"{"displayName":"An","species":"cat"}"#.data(using: .utf8)!
        let decoded = try JSONDecoder().decode(UserSettings.self, from: legacyJSON)
        XCTAssertEqual(decoded.language, .system)
        XCTAssertEqual(decoded.weekStartDay, .monday)
        XCTAssertFalse(decoded.syncAppleReminders)

        // Kiểm tra Chủ Nhật đứng đầu tuần cho Mỹ/Nhật/Hàn khi bật `.sunday`
        XCTAssertEqual(CozyL10n.weekdayShortLabels(for: .en, startDay: .sunday).first, "Sun")
        XCTAssertEqual(CozyL10n.weekdayShortLabels(for: .ja, startDay: .sunday).first, "日")
        XCTAssertEqual(CozyL10n.weekdayShortLabels(for: .vi, startDay: .monday).first, "T2")

        // Kiểm tra Daily Quotes đủ 15 ngôn ngữ và Từ vựng quốc tế không lộ nghĩa tiếng Việt
        for lang in AppLanguage.allCases where lang != .system {
            let quote = DailyQuotesCatalog.quoteOfTheDay(on: t0, lang: lang)
            XCTAssertFalse(quote.text.isEmpty)
        }
        let sampleWord = VocabSeed.daily.first! // "grab a bite"
        XCTAssertEqual(sampleWord.localizedMeaning(for: .vi), "ăn nhanh một chút")
        XCTAssertEqual(sampleWord.localizedMeaning(for: .en), "get something quick to eat")
        XCTAssertEqual(sampleWord.localizedMeaning(for: .ja), "get something quick to eat")
    }
}
