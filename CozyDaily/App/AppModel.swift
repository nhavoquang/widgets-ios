import SwiftUI
import UIKit
import Observation
import CozyCore
import WidgetKit

/// Trạng thái toàn app. Mọi thay đổi đi qua `CozyRepository` (ghi App Group ngay),
/// rồi reload widget để Lock/Home Screen phản hồi tức thì.
@MainActor
@Observable
final class AppModel {
    let repository: CozyRepository
    private(set) var snapshot: CozySnapshot
    private(set) var currentWord: VocabWord?
    var now = Date()

    let weather: CozyWeatherService
    let speech = SpeechService()
    let calendarImport = CalendarImportService()
    private let syncTrigger = CloudSyncTrigger()
    private(set) var cloudError: String?

    init(repository: CozyRepository = CozyShared.repository) {
        self.repository = repository
        self.snapshot = repository.snapshot(reload: true)
        self.weather = CozyWeatherService(repository: repository)
        repository.syncEngine = syncTrigger
        self.currentWord = repository.currentWord()
    }

    // MARK: - Refresh

    func refresh() {
        now = Date()
        snapshot = repository.snapshot(reload: true)
        currentWord = repository.currentWord(now: now)
    }

    private func commit() {
        withAnimation(CozyMotion.spring) { refresh() }
        CozyShared.didChange()
    }

    func onForeground() async {
        refresh()
        UIDevice.current.isBatteryMonitoringEnabled = true
        let level = UIDevice.current.batteryLevel
        repository.updateMyProfile(deviceBattery: level >= 0 ? Double(level) : nil)
        await weather.refreshIfNeeded()
        await syncCloud()
        commit()
    }

    func syncCloud() async {
        do {
            try await CloudSync.shared.sync()
            cloudError = nil
        } catch {
            cloudError = error.localizedDescription
        }
        refresh()
    }

    func prepareInvitation(_ kind: SpaceKind) async -> ShareInvitation? {
        do {
            let (share, container) = try await CloudSync.shared.prepareShare(kind: kind)
            cloudError = nil
            commit()
            return ShareInvitation(share: share, container: container)
        } catch {
            cloudError = error.localizedDescription
            return nil
        }
    }

    func leave(_ space: SharedSpace) async {
        do {
            try await CloudSync.shared.leave(spaceID: space.id)
        } catch {
            cloudError = error.localizedDescription
        }
        commit()
    }

    func removeDemoData() {
        repository.removeDemoData()
        commit()
    }

    // MARK: - Derived

    var settings: UserSettings { snapshot.settings }
    var latestCheckInToday: CheckIn? { repository.latestCheckIn(on: now) }
    var streak: Int { CozyRepository.streak(log: snapshot.learnedLog, now: now, calendar: repository.calendar) }
    var dueCount: Int { SpacedRepetition(calendar: repository.calendar).dueWords(states: snapshot.reviewStates, now: now).count }
    var learnedToday: Int { snapshot.learnedLog[repository.calendar.dayKey(for: now)] ?? 0 }
    var couple: SharedSpace? { snapshot.spaces.preferred(.couple) }
    var squad: SharedSpace? { snapshot.spaces.preferred(.squad) }
    var lunarToday: LunarDate { VietnameseLunarCalendar.lunarDate(from: now, calendar: repository.calendar) }

    var mascot: MascotState {
        MascotEngine.resolve(species: settings.species, mood: latestCheckInToday?.mood, weather: snapshot.weather, date: now, calendar: repository.calendar)
    }

    func upcomingEvents(limit: Int = 4) -> [CozyEvent] {
        repository.upcomingEvents(now: now, limit: limit)
    }

    func status(of event: CozyEvent) -> EventStatus {
        EventCounter(calendar: repository.calendar).status(of: event, now: now)
    }

    func reviewState(for word: VocabWord) -> ReviewState? { snapshot.reviewStates[word.id] }

    // MARK: - Vocab

    func markLearned() {
        repository.markCurrentWordLearned(now: Date())
        Haptics.success()
        commit()
    }

    func skipWord() {
        repository.skipCurrentWord(now: Date())
        Haptics.tap()
        commit()
    }

    func forgotWord() {
        repository.markCurrentWordForgot(now: Date())
        commit()
    }

    func speak(_ word: VocabWord) { speech.speak(word.word) }

    func addCustomWord(_ word: VocabWord) {
        repository.addCustomWord(word)
        commit()
    }

    func setDeck(_ deck: VocabDeck, active: Bool) {
        repository.updateSettings { s in
            if active { s.activeDecks.insert(deck) } else if s.activeDecks.count > 1 { s.activeDecks.remove(deck) }
        }
        commit()
    }

    // MARK: - Check-in

    func checkIn(mood: Mood, foods: [FoodSticker], battery: Int, note: String) {
        repository.checkIn(mood: mood, foods: foods, socialBattery: battery, note: note, now: Date())
        commit()
    }

    // MARK: - Events

    func save(_ event: CozyEvent, sharedWith spaceIDs: Set<UUID>) {
        repository.upsertEvent(event, sharedWith: spaceIDs)
        commit()
    }

    func deleteEvent(_ id: UUID) {
        repository.deleteEvent(id: id)
        commit()
    }

    func importAppleCalendar() async {
        let imported = await calendarImport.upcomingEvents(days: 30)
        for e in imported { repository.upsertEvent(e) }
        repository.updateSettings { $0.syncAppleCalendar = true }
        commit()
    }

    // MARK: - Spaces

    func sendPing(_ ping: QuickPing) {
        guard let c = couple else { return }
        repository.send(.ping(ping), in: c.id, to: c.partner(of: DemoData.meID)?.id)
        Haptics.ping()
        commit()
    }

    func react(_ sticker: String, in space: SharedSpace) {
        repository.send(.sticker(sticker), in: space.id)
        Haptics.tap()
        commit()
    }

    func setAnniversary(_ date: Date) {
        guard var c = couple else { return }
        c.anniversary = date
        c.modifiedAt = Date()
        repository.upsertSpace(c)
        commit()
    }

    // MARK: - Widgets & Settings

    func save(_ config: WidgetConfig) {
        repository.upsertWidgetConfig(config)
        commit()
    }

    func deleteConfig(_ id: UUID) {
        repository.deleteWidgetConfig(id: id)
        commit()
    }

    func updateSettings(_ body: (inout UserSettings) -> Void) {
        repository.updateSettings(body)
        repository.updateMyProfile()
        commit()
    }

    func widgetData(for config: WidgetConfig) -> CozyWidgetData {
        CozyWidgetData.make(config: config, date: now, repository: repository)
    }
}
