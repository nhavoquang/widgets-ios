import XCTest
@testable import CozyCore

final class LunarCalendarTests: XCTestCase {
    func testTetDates() {
        XCTAssertEqual(VietnameseLunarCalendar.solarToLunar(day: 10, month: 2, year: 2024), LunarDate(day: 1, month: 1, year: 2024))
        XCTAssertEqual(VietnameseLunarCalendar.solarToLunar(day: 29, month: 1, year: 2025), LunarDate(day: 1, month: 1, year: 2025))
        XCTAssertEqual(VietnameseLunarCalendar.solarToLunar(day: 17, month: 2, year: 2026), LunarDate(day: 1, month: 1, year: 2026))
    }

    func testMidAutumnAndLastDayOfYear() {
        // Trung Thu 2025: 6/10/2025
        XCTAssertEqual(VietnameseLunarCalendar.solarToLunar(day: 6, month: 10, year: 2025), LunarDate(day: 15, month: 8, year: 2025))
        // 16/2/2026 là 30 Tết Ất Tỵ
        XCTAssertEqual(VietnameseLunarCalendar.solarToLunar(day: 16, month: 2, year: 2026), LunarDate(day: 29, month: 12, year: 2025))
    }

    func testLeapMonth2025() {
        // Năm Ất Tỵ 2025 có tháng 6 nhuận, mùng 1 nhuận = 25/7/2025.
        let l = VietnameseLunarCalendar.solarToLunar(day: 25, month: 7, year: 2025)
        XCTAssertEqual(l, LunarDate(day: 1, month: 6, year: 2025, isLeapMonth: true))
        let back = VietnameseLunarCalendar.lunarToSolar(LunarDate(day: 1, month: 6, year: 2025, isLeapMonth: true))
        XCTAssertEqual(back?.day, 25)
        XCTAssertEqual(back?.month, 7)
        XCTAssertNil(VietnameseLunarCalendar.lunarToSolar(LunarDate(day: 1, month: 5, year: 2025, isLeapMonth: true)))
    }

    func testRoundTripAcrossThreeYears() {
        var jd = VietnameseLunarCalendar.jdFromDate(1, 1, 2024)
        let end = VietnameseLunarCalendar.jdFromDate(31, 12, 2027)
        while jd <= end {
            let (d, m, y) = VietnameseLunarCalendar.jdToDate(jd)
            let lunar = VietnameseLunarCalendar.solarToLunar(day: d, month: m, year: y)
            let back = VietnameseLunarCalendar.lunarToSolar(lunar)
            XCTAssertEqual(back?.day, d, "\(d)/\(m)/\(y) -> \(lunar)")
            XCTAssertEqual(back?.month, m)
            XCTAssertEqual(back?.year, y)
            jd += 1
        }
    }

    func testCanChi() {
        XCTAssertEqual(VietnameseLunarCalendar.canChi(year: 2024), "Giáp Thìn")
        XCTAssertEqual(VietnameseLunarCalendar.canChi(year: 2025), "Ất Tỵ")
        XCTAssertEqual(VietnameseLunarCalendar.canChi(year: 2026), "Bính Ngọ")
    }

    func testNextTetFromDecember() {
        let cal = TestCal.vn
        let next = VietnameseLunarCalendar.nextOccurrence(lunarDay: 1, lunarMonth: 1, onOrAfter: TestCal.date(2025, 12, 1), calendar: cal)
        let c = cal.dateComponents([.year, .month, .day], from: next!)
        XCTAssertEqual([c.year, c.month, c.day], [2026, 2, 17])
    }

    func testMonthlyFullMoon() {
        let cal = TestCal.vn
        // Sau Trung Thu 2025 (6/10), Rằm kế tiếp là 15/9 âm = 4/11/2025 (tháng 9 âm bắt đầu 21/10).
        let next = VietnameseLunarCalendar.nextOccurrence(lunarDay: 15, lunarMonth: nil, onOrAfter: TestCal.date(2025, 10, 7), calendar: cal)
        let c = cal.dateComponents([.year, .month, .day], from: next!)
        XCTAssertEqual([c.year, c.month, c.day], [2025, 11, 4])
    }
}
