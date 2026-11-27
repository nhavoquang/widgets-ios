import Foundation
import AVFoundation
import CoreLocation
import EventKit
import UIKit
import CozyCore
#if canImport(WeatherKit)
import WeatherKit
#endif

// MARK: - Haptics

@MainActor
enum Haptics {
    static func tap() { UIImpactFeedbackGenerator(style: .light).impactOccurred() }
    static func success() { UINotificationFeedbackGenerator().notificationOccurred(.success) }
    /// Rung "tim đập" cho Quick Ping.
    static func ping() {
        let g = UIImpactFeedbackGenerator(style: .soft)
        g.impactOccurred(intensity: 0.9)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) { g.impactOccurred(intensity: 0.6) }
    }
}

// MARK: - Phát âm offline

@MainActor
final class SpeechService {
    private let synth = AVSpeechSynthesizer()

    func speak(_ text: String, slow: Bool = false) {
        if synth.isSpeaking { synth.stopSpeaking(at: .immediate) }
        let u = AVSpeechUtterance(string: text)
        u.voice = AVSpeechSynthesisVoice(language: "en-US")
        u.rate = slow ? 0.35 : AVSpeechUtteranceDefaultSpeechRate
        synth.speak(u)
    }
}

// MARK: - WeatherKit + cache theo vùng

/// Chỉ Main App gọi WeatherKit. Widget đọc snapshot trong App Group.
@MainActor
final class CozyWeatherService: NSObject, CLLocationManagerDelegate {
    private let repository: CozyRepository
    private let policy = WeatherCachePolicy()
    private let manager = CLLocationManager()
    private var locationContinuation: CheckedContinuation<CLLocation?, Never>?
    private(set) var lastError: String?

    init(repository: CozyRepository) {
        self.repository = repository
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyKilometer
    }

    func refreshIfNeeded(force: Bool = false) async {
        guard let location = await currentLocation() else { return }
        let cached = repository.snapshot().weather
        let decision = policy.decide(cached: cached, latitude: location.coordinate.latitude, longitude: location.coordinate.longitude, now: Date(), force: force)
        guard case .fetch = decision else { return }
        await fetch(location: location)
    }

    private func fetch(location: CLLocation) async {
        #if canImport(WeatherKit)
        do {
            let w = try await WeatherKit.WeatherService.shared.weather(for: location, including: .current, .daily)
            let current = w.0
            let today = w.1.first
            let place = await placeName(for: location)
            let snap = WeatherSnapshot(
                temperatureC: current.temperature.converted(to: .celsius).value,
                apparentC: current.apparentTemperature.converted(to: .celsius).value,
                condition: Self.map(current.condition),
                humidity: current.humidity,
                highC: today?.highTemperature.converted(to: .celsius).value ?? current.temperature.value,
                lowC: today?.lowTemperature.converted(to: .celsius).value ?? current.temperature.value,
                placeName: place,
                regionKey: policy.regionKey(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude),
                fetchedAt: Date()
            )
            repository.updateWeather(snap)
            lastError = nil
        } catch {
            lastError = error.localizedDescription
        }
        #endif
    }

    #if canImport(WeatherKit)
    static func map(_ c: WeatherKit.WeatherCondition) -> CozyCore.WeatherCondition {
        switch c {
        case .clear, .mostlyClear: return .clear
        case .partlyCloudy: return .partlyCloudy
        case .cloudy, .mostlyCloudy: return .cloudy
        case .rain, .heavyRain, .sunShowers: return .rain
        case .drizzle, .freezingDrizzle: return .drizzle
        case .thunderstorms, .isolatedThunderstorms, .scatteredThunderstorms, .strongStorms, .tropicalStorm, .hurricane: return .thunderstorm
        case .foggy, .haze, .smoky: return .fog
        case .snow, .heavySnow, .flurries, .sleet, .blizzard, .blowingSnow, .freezingRain, .hail, .wintryMix, .sunFlurries: return .snow
        case .windy, .breezy, .blowingDust: return .windy
        case .hot: return .hot
        case .frigid: return .snow
        @unknown default: return .cloudy
        }
    }
    #endif

    private func placeName(for location: CLLocation) async -> String {
        let marks = try? await CLGeocoder().reverseGeocodeLocation(location, preferredLocale: Locale(identifier: "vi_VN"))
        return marks?.first?.locality ?? marks?.first?.administrativeArea ?? "Quanh đây"
    }

    private func currentLocation() async -> CLLocation? {
        switch manager.authorizationStatus {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
            return nil
        case .denied, .restricted:
            return nil
        default:
            if let l = manager.location, Date().timeIntervalSince(l.timestamp) < 30 * 60 { return l }
            guard locationContinuation == nil else { return manager.location }
            return await withCheckedContinuation { cont in
                locationContinuation = cont
                manager.requestLocation()
            }
        }
    }

    private func finishLocation(_ location: CLLocation?) {
        locationContinuation?.resume(returning: location)
        locationContinuation = nil
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let last = locations.last
        Task { @MainActor in self.finishLocation(last) }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in self.finishLocation(nil) }
    }

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        if status == .authorizedWhenInUse || status == .authorizedAlways {
            Task { @MainActor in await self.refreshIfNeeded() }
        }
    }
}

// MARK: - Apple Calendar (EventKit)

@MainActor
final class CalendarImportService {
    private let store = EKEventStore()

    func upcomingEvents(days: Int) async -> [CozyEvent] {
        guard (try? await store.requestFullAccessToEvents()) == true else { return [] }
        let start = Date()
        let end = Calendar.cozy.date(byAdding: .day, value: days, to: start)!
        let predicate = store.predicateForEvents(withStart: start, end: end, calendars: nil)
        return store.events(matching: predicate).prefix(30).map { ek in
            CozyEvent(
                id: UUID(uuidString: Self.stableUUID(ek.eventIdentifier ?? ek.title)) ?? UUID(),
                title: ek.title ?? "Sự kiện",
                emoji: "🗓️",
                kind: ek.isAllDay ? .countdown(date: ek.startDate, repeatsYearly: false) : .deadline(due: ek.startDate),
                accent: .accentSky,
                externalIdentifier: ek.eventIdentifier
            )
        }
    }

    /// UUID ổn định từ ID EventKit để import lại không bị trùng.
    static func stableUUID(_ s: String) -> String {
        var h1: UInt64 = 1469598103934665603
        var h2: UInt64 = 1099511628211
        for b in s.utf8 {
            h1 = (h1 ^ UInt64(b)) &* 1099511628211
            h2 = (h2 &+ UInt64(b)) &* 6364136223846793005
        }
        let hex = String(format: "%016llx%016llx", h1, h2)
        let c = Array(hex)
        return "\(String(c[0..<8]))-\(String(c[8..<12]))-\(String(c[12..<16]))-\(String(c[16..<20]))-\(String(c[20..<32]))"
    }
}
