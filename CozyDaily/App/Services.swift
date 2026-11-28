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
    static var isEnabled = true

    static func tap() {
        guard isEnabled else { return }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    static func success() {
        guard isEnabled else { return }
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    /// Rung "tim đập" cho Quick Ping.
    static func ping() {
        guard isEnabled else { return }
        let g = UIImpactFeedbackGenerator(style: .soft)
        g.impactOccurred(intensity: 0.9)
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(180))
            guard isEnabled else { return }
            g.impactOccurred(intensity: 0.6)
        }
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

// MARK: - Weather (WeatherKit + Open-Meteo thật cho cả bản chưa ký)

/// Chỉ Main App gọi mạng lấy thời tiết thật. Widget đọc snapshot trong App Group tức thì.
@MainActor
final class CozyWeatherService: NSObject, CLLocationManagerDelegate {
    private let repository: CozyRepository
    private let policy = WeatherCachePolicy()
    private let manager = CLLocationManager()
    private var locationContinuation: CheckedContinuation<CLLocation?, Never>?
    private(set) var lastError: String?
    private(set) var isRefreshing = false

    init(repository: CozyRepository) {
        self.repository = repository
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyKilometer
    }

    func refreshIfNeeded(force: Bool = false) async {
        guard !isRefreshing else { return }
        isRefreshing = true
        defer { isRefreshing = false }

        let snap = repository.snapshot(reload: true)
        let preset = snap.settings.weatherLocation

        let lat: Double
        let lon: Double
        let fallbackPlace: String

        if preset == .autoGPS, let gps = await currentLocation() {
            lat = gps.coordinate.latitude
            lon = gps.coordinate.longitude
            fallbackPlace = await placeName(for: gps)
        } else {
            let effective = preset == .autoGPS ? WeatherLocationPreset.hcmc : preset
            lat = effective.coordinates.latitude
            lon = effective.coordinates.longitude
            fallbackPlace = effective.shortName
        }

        let cached = snap.weather
        let isDemoWeather = cached?.regionKey == "demo"
        let decision = policy.decide(cached: cached, latitude: lat, longitude: lon, now: Date(), force: force)
        if !isDemoWeather && !force, case .useCache = decision {
            return
        }

        await fetchRealWeather(latitude: lat, longitude: lon, placeName: fallbackPlace)
    }

    /// Ưu tiên WeatherKit (nếu có quyền Apple Developer trả phí), tự chuyển sang Open-Meteo miễn phí
    /// để thời tiết luôn là dữ liệu THẬT 100% trên cả bản sideload/miễn phí.
    private func fetchRealWeather(latitude: Double, longitude: Double, placeName: String) async {
        let region = policy.regionKey(latitude: latitude, longitude: longitude)

        #if canImport(WeatherKit)
        do {
            let loc = CLLocation(latitude: latitude, longitude: longitude)
            let w = try await WeatherKit.WeatherService.shared.weather(for: loc, including: .current, .daily)
            let current = w.0
            let today = w.1.first
            let snap = WeatherSnapshot(
                temperatureC: current.temperature.converted(to: .celsius).value,
                apparentC: current.apparentTemperature.converted(to: .celsius).value,
                condition: Self.map(current.condition),
                humidity: current.humidity,
                highC: today?.highTemperature.converted(to: .celsius).value ?? current.temperature.value,
                lowC: today?.lowTemperature.converted(to: .celsius).value ?? current.temperature.value,
                placeName: placeName,
                regionKey: region,
                fetchedAt: Date()
            )
            repository.updateWeather(snap)
            lastError = nil
            return
        } catch {
            // Rơi xuống Open-Meteo thật ở dưới.
        }
        #endif

        do {
            let snap = try await fetchOpenMeteo(latitude: latitude, longitude: longitude, placeName: placeName, regionKey: region)
            repository.updateWeather(snap)
            lastError = nil
        } catch {
            lastError = "Chưa lấy được thời tiết trực tuyến: \(error.localizedDescription)"
        }
    }

    private func fetchOpenMeteo(latitude: Double, longitude: Double, placeName: String, regionKey: String) async throws -> WeatherSnapshot {
        var comps = URLComponents(string: "https://api.open-meteo.com/v1/forecast")!
        comps.queryItems = [
            URLQueryItem(name: "latitude", value: String(format: "%.4f", latitude)),
            URLQueryItem(name: "longitude", value: String(format: "%.4f", longitude)),
            URLQueryItem(name: "current", value: "temperature_2m,relative_humidity_2m,apparent_temperature,weather_code"),
            URLQueryItem(name: "daily", value: "temperature_2m_max,temperature_2m_min"),
            URLQueryItem(name: "timezone", value: "auto"),
            URLQueryItem(name: "forecast_days", value: "1"),
        ]
        var req = URLRequest(url: comps.url!)
        req.timeoutInterval = 12
        let (data, response) = try await URLSession.shared.data(for: req)
        if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
            throw URLError(.badServerResponse)
        }
        let decoded = try JSONDecoder().decode(OpenMeteoResponse.self, from: data)
        let temp = decoded.current.temperature_2m
        let apparent = decoded.current.apparent_temperature
        let humidity = min(max(decoded.current.relative_humidity_2m / 100.0, 0), 1)
        let high = decoded.daily.temperature_2m_max.first ?? temp
        let low = decoded.daily.temperature_2m_min.first ?? temp
        let condition = WeatherCondition.fromWMOCode(decoded.current.weather_code, temperatureC: temp)

        return WeatherSnapshot(
            temperatureC: temp,
            apparentC: apparent,
            condition: condition,
            humidity: humidity,
            highC: high,
            lowC: low,
            placeName: placeName,
            regionKey: regionKey,
            fetchedAt: Date()
        )
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
            Task { @MainActor in await self.refreshIfNeeded(force: true) }
        }
    }
}

private struct OpenMeteoResponse: Decodable {
    struct Current: Decodable {
        var temperature_2m: Double
        var relative_humidity_2m: Double
        var apparent_temperature: Double
        var weather_code: Int
    }
    struct Daily: Decodable {
        var temperature_2m_max: [Double]
        var temperature_2m_min: [Double]
    }
    var current: Current
    var daily: Daily
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
