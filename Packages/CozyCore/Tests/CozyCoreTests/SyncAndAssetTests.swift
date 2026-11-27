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
}
