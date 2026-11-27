import XCTest
@testable import CozyCore

final class SpacedRepetitionTests: XCTestCase {
    let srs = SpacedRepetition(calendar: TestCal.vn)

    func testIntervalsOneThreeSevenThirty() {
        let cal = TestCal.vn
        var now = TestCal.date(2026, 1, 1)
        var state: ReviewState?
        var gaps: [Int] = []
        for _ in 0..<4 {
            let next = srs.markLearned(state, wordID: "w", now: now)
            gaps.append(cal.dateComponents([.day], from: cal.startOfDay(for: now), to: next.dueDate).day!)
            state = next
            now = next.dueDate.addingTimeInterval(9 * 3600)
        }
        XCTAssertEqual(gaps, [1, 3, 7, 30])
        XCTAssertTrue(state!.isMastered)
    }

    func testForgotResetsToTomorrow() {
        let now = TestCal.date(2026, 1, 1)
        let learned = srs.markLearned(nil, wordID: "w", now: now)
        let forgot = srs.markForgot(learned, wordID: "w", now: now)
        XCTAssertEqual(forgot.stage, 0)
        XCTAssertEqual(TestCal.vn.dateComponents([.day], from: TestCal.vn.startOfDay(for: now), to: forgot.dueDate).day, 1)
    }

    func testDueWordsComeBeforeNewWords() {
        let now = TestCal.date(2026, 1, 10)
        let words = VocabSeed.daily
        let due = ReviewState(wordID: words[5].id, stage: 1, dueDate: TestCal.date(2026, 1, 9))
        let picked = srs.nextWord(words: words, states: [due.wordID: due], decks: [.daily], now: now)
        XCTAssertEqual(picked?.id, words[5].id)
        let fresh = srs.nextWord(words: words, states: [due.wordID: due], decks: [.daily], now: now, excluding: [due.wordID])
        XCTAssertEqual(fresh?.id, words[0].id)
    }
}

final class EventCounterTests: XCTestCase {
    let counter = EventCounter(calendar: TestCal.vn)

    func testCountUpStartsAtDayOne() {
        let e = CozyEvent(title: "Yêu", kind: .countUp(since: TestCal.date(2026, 1, 1)))
        XCTAssertEqual(counter.status(of: e, now: TestCal.date(2026, 1, 1, 22)).days, 1)
        XCTAssertEqual(counter.status(of: e, now: TestCal.date(2026, 1, 11)).headline, "11")
    }

    func testCountdownAndYearly() {
        let trip = CozyEvent(title: "Trip", kind: .countdown(date: TestCal.date(2026, 2, 1), repeatsYearly: false))
        XCTAssertEqual(counter.status(of: trip, now: TestCal.date(2026, 1, 20)).sentence, "Còn 12 ngày")
        let bday = CozyEvent(title: "SN", kind: .countdown(date: TestCal.date(2000, 1, 5), repeatsYearly: true))
        let s = counter.status(of: bday, now: TestCal.date(2026, 1, 6))
        XCTAssertEqual(s.direction, .upcoming)
        XCTAssertEqual(s.days, 364)
        XCTAssertEqual(counter.status(of: bday, now: TestCal.date(2026, 1, 5, 20)).direction, .today)
    }

    func testWeeklyNextSession() {
        // 27/11/2026 là Thứ Sáu. Lớp T3 & T5 lúc 19:30 → T3 1/12.
        let e = CozyEvent(title: "Lớp", kind: .weekly(weekdays: [3, 5], hour: 19, minute: 30))
        let next = counter.nextOccurrence(of: e, now: TestCal.date(2026, 11, 27, 10))!
        let c = TestCal.vn.dateComponents([.month, .day, .hour, .minute], from: next)
        XCTAssertEqual([c.month, c.day, c.hour, c.minute], [12, 1, 19, 30])
    }

    func testDeadlineOverdue() {
        let e = CozyEvent(title: "Báo cáo", kind: .deadline(due: TestCal.date(2026, 1, 1, 17)))
        XCTAssertEqual(counter.status(of: e, now: TestCal.date(2026, 1, 3, 9)).direction, .overdue)
        XCTAssertEqual(counter.status(of: e, now: TestCal.date(2026, 1, 3, 9)).days, 2)
        XCTAssertEqual(counter.status(of: e, now: TestCal.date(2026, 1, 1, 12)).direction, .today)
    }

    func testLunarEventUsesLunarCalendar() {
        let e = CozyEvent(title: "Tết", kind: .lunar(day: 1, month: 1))
        let s = counter.status(of: e, now: TestCal.date(2026, 2, 7))
        XCTAssertEqual(s.days, 10)
    }
}

final class WeatherPolicyTests: XCTestCase {
    let policy = WeatherCachePolicy()

    func testRegionKeyRoundsToAboutOneKm() {
        XCTAssertEqual(policy.regionKey(latitude: 10.7769, longitude: 106.7009), "10.78,106.70")
        XCTAssertEqual(policy.regionKey(latitude: 10.7801, longitude: 106.6998), "10.78,106.70")
    }

    func testDecisions() {
        let now = TestCal.date(2026, 1, 1, 12)
        let snap = WeatherSnapshot(temperatureC: 28, apparentC: 30, condition: .clear, highC: 32, lowC: 24, placeName: "HCM", regionKey: "10.78,106.70", fetchedAt: now.addingTimeInterval(-10 * 60))
        XCTAssertEqual(policy.decide(cached: nil, latitude: 10.78, longitude: 106.7, now: now), .fetch(reason: "chưa có cache"))
        XCTAssertEqual(policy.decide(cached: snap, latitude: 10.78, longitude: 106.7, now: now), .useCache)
        XCTAssertEqual(policy.decide(cached: snap, latitude: 10.78, longitude: 106.7, now: now, force: true), .useCache)
        XCTAssertEqual(policy.decide(cached: snap, latitude: 21.03, longitude: 105.85, now: now), .fetch(reason: "đổi khu vực"))
        XCTAssertEqual(policy.decide(cached: snap, latitude: 10.78, longitude: 106.7, now: now.addingTimeInterval(40 * 60)), .fetch(reason: "cache hết hạn"))
    }

    func testQuotaEstimateStaysUnder500k() {
        // ~500 người dùng mở app 10 lần/ngày → 150k calls/tháng.
        XCTAssertLessThan(policy.estimatedMonthlyCalls(activeUsers: 500, opensPerDay: 10), 500_000)
    }
}

final class MascotTests: XCTestCase {
    func testLateNightAlwaysSleeps() {
        let s = MascotEngine.resolve(species: .cat, mood: .excited, weather: nil, date: TestCal.date(2026, 1, 1, 22, 45), calendar: TestCal.vn)
        XCTAssertEqual(s.pose, .sleeping)
        XCTAssertEqual(s.accessories, [.blanket])
    }

    func testRainyMorning() {
        let rain = WeatherSnapshot(temperatureC: 24, apparentC: 24, condition: .rain, highC: 26, lowC: 22, placeName: "HN", regionKey: "x", fetchedAt: Date())
        let s = MascotEngine.resolve(species: .bear, mood: .happy, weather: rain, date: TestCal.date(2026, 1, 1, 7), calendar: TestCal.vn)
        XCTAssertEqual(s.accessories, [.umbrella, .coffee])
        XCTAssertEqual(s.pose, .bouncing)
    }

    func testColdGetsScarf() {
        let cold = WeatherSnapshot(temperatureC: 12, apparentC: 10, condition: .cloudy, highC: 14, lowC: 9, placeName: "SP", regionKey: "x", fetchedAt: Date())
        let s = MascotEngine.resolve(species: .bunny, mood: nil, weather: cold, date: TestCal.date(2026, 1, 1, 12), calendar: TestCal.vn)
        XCTAssertTrue(s.accessories.contains(.scarf))
    }
}

final class RepositoryTests: XCTestCase {
    func testVocabFlowAndStreak() {
        let repo = CozyRepository(store: TestCal.tempStore(), calendar: TestCal.vn)
        let now = TestCal.date(2026, 11, 27)
        repo.reset(to: CozySnapshot(settings: UserSettings(activeDecks: [.daily])))
        let first = repo.currentWord(now: now)
        XCTAssertNotNil(first)
        XCTAssertEqual(repo.currentWord(now: now)?.id, first?.id, "Cùng ngày phải giữ nguyên từ")
        let next = repo.markCurrentWordLearned(now: now)
        XCTAssertNotEqual(next?.id, first?.id)
        XCTAssertEqual(repo.snapshot().reviewStates[first!.id]?.stage, 1)
        XCTAssertEqual(repo.vocabStreak(now: now), 1)
        let skipped = repo.skipCurrentWord(now: now)
        XCTAssertNotEqual(skipped?.id, next?.id)
    }

    func testPersistenceIsSharedBetweenInstances() {
        let store = TestCal.tempStore()
        let a = CozyRepository(store: store, calendar: TestCal.vn)
        a.reset(to: CozySnapshot())
        a.checkIn(mood: .happy, foods: [.pho], socialBattery: 150, note: String(repeating: "a", count: 50))
        let b = CozyRepository(store: store, calendar: TestCal.vn)
        let c = b.latestCheckIn()
        XCTAssertEqual(c?.mood, .happy)
        XCTAssertEqual(c?.socialBattery, 100)
        XCTAssertEqual(c?.note.count, 30)
    }

    func testStreakSkipsTodayIfNotYetLearned() {
        let cal = TestCal.vn
        let now = TestCal.date(2026, 11, 27)
        var log: [String: Int] = [:]
        for i in 1...3 { log[cal.dayKey(for: cal.date(byAdding: .day, value: -i, to: now)!)] = 1 }
        XCTAssertEqual(CozyRepository.streak(log: log, now: now, calendar: cal), 3)
        log[cal.dayKey(for: now)] = 2
        XCTAssertEqual(CozyRepository.streak(log: log, now: now, calendar: cal), 4)
    }

    func testDemoDataEncodesRoundTrip() throws {
        let snap = DemoData.makeInitialSnapshot(now: TestCal.date(2026, 11, 27), calendar: TestCal.vn)
        let store = TestCal.tempStore()
        try store.save(snap)
        let loaded = store.load()
        XCTAssertEqual(loaded?.events.count, snap.events.count)
        XCTAssertEqual(loaded?.spaces.first?.members.count, 2)
    }
}

final class MonthGridTests: XCTestCase {
    func testNovember2026StartsOnSunday() {
        let snap = DemoData.makeInitialSnapshot(now: TestCal.date(2026, 11, 27), calendar: TestCal.vn)
        let grid = MonthGrid.build(year: 2026, month: 11, lens: .mood, snapshot: snap, now: TestCal.date(2026, 11, 27), calendar: TestCal.vn)
        // 1/11/2026 là Chủ nhật → 6 ô đệm (T2..T7).
        XCTAssertEqual(grid.cells.prefix(while: { $0.date == nil }).count, 6)
        XCTAssertEqual(grid.cells.filter { $0.date != nil }.count, 30)
        XCTAssertEqual(grid.cells.first(where: \.isToday)?.day, 27)
        XCTAssertEqual(grid.cells.first(where: { $0.day == 26 })?.sticker, Mood.happy.emoji)
    }

    func testAutoThemeHoliday() {
        let cfg = WidgetConfig(name: "x", content: .vocab, autoTheme: .both)
        XCTAssertEqual(cfg.effectiveTheme(at: TestCal.date(2026, 2, 17, 10), calendar: TestCal.vn), .festive)
        XCTAssertEqual(cfg.effectiveTheme(at: TestCal.date(2026, 3, 10, 23), calendar: TestCal.vn), .night)
        XCTAssertEqual(cfg.effectiveTheme(at: TestCal.date(2026, 3, 11, 10), calendar: TestCal.vn), .paper)
    }
}
