import Foundation
@testable import CozyCore

enum TestCal {
    static var vn: Calendar {
        var c = Calendar.cozy
        c.timeZone = TimeZone(secondsFromGMT: 7 * 3600)!
        return c
    }

    static func date(_ y: Int, _ m: Int, _ d: Int, _ h: Int = 9, _ min: Int = 0) -> Date {
        vn.date(from: DateComponents(year: y, month: m, day: d, hour: h, minute: min))!
    }

    static func tempStore() -> SnapshotStore {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent("cozy-tests-\(UUID().uuidString)")
        return SnapshotStore(directory: dir)
    }
}
