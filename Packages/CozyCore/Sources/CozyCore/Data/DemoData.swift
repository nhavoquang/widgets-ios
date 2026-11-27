import Foundation

/// Dữ liệu khởi tạo cho lần mở app đầu tiên và cho Preview/Widget placeholder.
public enum DemoData {
    public static let meID = "me"

    /// ID cố định cho dữ liệu mẫu: hai thiết bị không tạo bản trùng khi đồng bộ.
    public static func id(_ n: Int) -> UUID {
        UUID(uuidString: String(format: "C0C0C0C0-0000-4000-8000-%012d", n))!
    }

    public static func isDemo(_ id: UUID) -> Bool { id.uuidString.hasPrefix("C0C0C0C0-0000-4000-8000-") }

    public static func makeInitialSnapshot(now: Date, calendar: Calendar = .cozy) -> CozySnapshot {
        let today = calendar.startOfDay(for: now)
        func days(_ n: Int) -> Date { calendar.date(byAdding: .day, value: n, to: today)! }

        let year = calendar.component(.year, from: now)
        let tet = CozyEvent(id: id(1), title: "Tết Nguyên Đán", emoji: "🧧", kind: .lunar(day: 1, month: 1), accent: .accentPeach)
        let ram = CozyEvent(id: id(2), title: "Rằm hằng tháng", emoji: "🌕", kind: .lunar(day: 15, month: nil), accent: .accentHoney)
        let trip = CozyEvent(id: id(3), title: "Đi Đà Lạt", emoji: "🏕️", kind: .countdown(date: days(23), repeatsYearly: false), accent: .accentSky, isShared: true)
        let love = CozyEvent(id: id(4), title: "Ngày yêu nhau", emoji: "💞", kind: .countUp(since: days(-412)), accent: .accentPeach, isShared: true)
        let english = CozyEvent(id: id(5), title: "Lớp tiếng Anh", emoji: "📚", kind: .weekly(weekdays: [3, 5], hour: 19, minute: 30), accent: .accentSage)
        let report = CozyEvent(id: id(6), title: "Nộp báo cáo", emoji: "📝", kind: .deadline(due: calendar.date(bySettingHour: 17, minute: 0, second: 0, of: days(3))!), accent: .accentSky)
        let birthday = CozyEvent(
            id: id(7), title: "Sinh nhật Mây", emoji: "🎂",
            kind: .countdown(date: calendar.date(from: DateComponents(year: year, month: 12, day: 20))!, repeatsYearly: true),
            accent: .accentHoney, isShared: true
        )

        let me = MemberStatus(id: meID, displayName: "Mình", species: .cat, mood: .chill, foods: [.milkTea], socialBattery: 70, deviceBattery: 0.82, note: "Đang chill nè")
        let partner = MemberStatus(
            id: "partner", displayName: "Gấu", species: .bear, mood: .missing, foods: [.pho],
            socialBattery: 55, deviceBattery: 0.46, weatherLine: "Mưa 24° ở Hà Nội", note: "Nhớ quá à",
            updatedAt: now.addingTimeInterval(-25 * 60)
        )
        let couple = SharedSpace(
            kind: .couple, name: "Mình & Gấu", members: [me, partner], anniversary: days(-412),
            interactions: [
                Interaction(from: "partner", to: meID, payload: .ping(.ateYet), sentAt: now.addingTimeInterval(-50 * 60)),
                Interaction(from: meID, to: "partner", payload: .ping(.craveMilkTea), sentAt: now.addingTimeInterval(-40 * 60)),
            ],
            sharedEventIDs: [trip.id, love.id]
        )
        let squad = SharedSpace(
            kind: .squad, name: "Hội Bánh Tráng", members: [
                me,
                MemberStatus(id: "m1", displayName: "Mây", species: .bunny, mood: .excited, foods: [.banhMi], socialBattery: 90, note: "Cuối tuần đi đâu?"),
                MemberStatus(id: "m2", displayName: "Tùng", species: .dog, mood: .busy, foods: [.coffee], socialBattery: 20, note: "Deadline dí 😵"),
                MemberStatus(id: "m3", displayName: "Linh", species: .cat, mood: .sleepy, foods: [.comTam], socialBattery: 40, note: ""),
            ],
            interactions: [
                Interaction(from: "m1", payload: .sticker("🔥"), sentAt: now.addingTimeInterval(-3 * 3600)),
                Interaction(from: "m2", payload: .text("Ai đi cà phê không?"), sentAt: now.addingTimeInterval(-2 * 3600)),
            ],
            sharedEventIDs: [trip.id, birthday.id]
        )

        var learned: [String: Int] = [:]
        for i in 1...4 { learned[calendar.dayKey(for: days(-i))] = [2, 3, 1, 4][i - 1] }

        let checkIns: [CheckIn] = [
            CheckIn(id: id(11), date: days(-1).addingTimeInterval(12 * 3600), mood: .happy, foods: [.bunBo], socialBattery: 80, note: "Ăn bún bò ngon"),
            CheckIn(id: id(12), date: days(-2).addingTimeInterval(13 * 3600), mood: .tired, foods: [.comTam], socialBattery: 30, note: "Họp cả ngày"),
            CheckIn(id: id(13), date: days(-3).addingTimeInterval(9 * 3600), mood: .chill, foods: [.coffee, .banhMi], socialBattery: 65, note: ""),
            CheckIn(id: id(14), date: days(-5).addingTimeInterval(19 * 3600), mood: .excited, foods: [.hotpot], socialBattery: 95, note: "Lẩu với hội bạn"),
        ]

        let configs: [WidgetConfig] = [
            WidgetConfig(id: id(21), name: "Từ vựng hôm nay", content: .vocab),
            WidgetConfig(id: id(22), name: "Mood & Món ăn", content: .moodFood),
            WidgetConfig(id: id(23), name: "Người yêu", content: .couple, species: .bear),
            WidgetConfig(id: id(24), name: "Đi Đà Lạt", content: .event, eventID: trip.id),
            WidgetConfig(id: id(25), name: "Combo sáng", content: .combo, secondaryContent: .weather, accent: .accentHoney),
        ]

        return CozySnapshot(
            settings: UserSettings(),
            checkIns: checkIns,
            learnedLog: learned,
            events: [tet, ram, trip, love, english, report, birthday],
            spaces: [couple, squad],
            activeSpaceID: couple.id,
            widgetConfigs: configs,
            weather: WeatherSnapshot(
                temperatureC: 27, apparentC: 29, condition: .partlyCloudy, humidity: 0.72,
                highC: 31, lowC: 24, placeName: "TP.HCM", regionKey: "10.78,106.70",
                fetchedAt: now.addingTimeInterval(-10 * 60)
            ),
            updatedAt: now
        )
    }

    /// Snapshot dùng cho Xcode Preview & widget placeholder (không đọc đĩa).
    public static var preview: CozySnapshot { makeInitialSnapshot(now: Date()) }
}
