import Foundation

/// Ngày âm lịch Việt Nam.
public struct LunarDate: Codable, Hashable, Sendable, CustomStringConvertible {
    public var day: Int
    public var month: Int
    public var year: Int
    public var isLeapMonth: Bool

    public init(day: Int, month: Int, year: Int, isLeapMonth: Bool = false) {
        self.day = day
        self.month = month
        self.year = year
        self.isLeapMonth = isLeapMonth
    }

    /// Ví dụ: "15/8" hoặc "3/4 nhuận".
    public var shortText: String { "\(day)/\(month)\(isLeapMonth ? " nhuận" : "")" }

    public var description: String { "\(shortText)/\(year)" }

    /// Nhãn gọn cho ô lịch: "1/8" vào mùng 1, "Rằm" vào ngày 15, còn lại chỉ số ngày.
    public var cellLabel: String {
        if day == 1 { return "1/\(month)" }
        if day == 15 { return "Rằm" }
        return "\(day)"
    }

    public var yearName: String { VietnameseLunarCalendar.canChi(year: year) }
}

/// Bộ chuyển đổi Dương lịch ↔ Âm lịch Việt Nam (múi giờ UTC+7),
/// dựa trên thuật toán thiên văn của Hồ Ngọc Đức.
public enum VietnameseLunarCalendar {
    public static let vietnamTimeZone: Double = 7

    // MARK: - Public API

    public static func lunarDate(from date: Date, calendar: Calendar = .cozy) -> LunarDate {
        let c = calendar.dateComponents([.year, .month, .day], from: date)
        return solarToLunar(day: c.day!, month: c.month!, year: c.year!)
    }

    public static func solarToLunar(day: Int, month: Int, year: Int, timeZone tz: Double = vietnamTimeZone) -> LunarDate {
        let dayNumber = jdFromDate(day, month, year)
        let k = floorInt((Double(dayNumber) - 2415021.076998695) / 29.530588853)
        var monthStart = newMoonDay(k + 1, tz)
        if monthStart > dayNumber { monthStart = newMoonDay(k, tz) }
        var a11 = lunarMonth11(year, tz)
        var b11 = a11
        var lunarYear: Int
        if a11 >= monthStart {
            lunarYear = year
            a11 = lunarMonth11(year - 1, tz)
        } else {
            lunarYear = year + 1
            b11 = lunarMonth11(year + 1, tz)
        }
        let lunarDay = dayNumber - monthStart + 1
        let diff = floorInt(Double(monthStart - a11) / 29)
        var isLeap = false
        var lunarMonth = diff + 11
        if b11 - a11 > 365 {
            let leapMonthDiff = leapMonthOffset(a11, tz)
            if diff >= leapMonthDiff {
                lunarMonth = diff + 10
                if diff == leapMonthDiff { isLeap = true }
            }
        }
        if lunarMonth > 12 { lunarMonth -= 12 }
        if lunarMonth >= 11 && diff < 4 { lunarYear -= 1 }
        return LunarDate(day: lunarDay, month: lunarMonth, year: lunarYear, isLeapMonth: isLeap)
    }

    /// Trả về (ngày, tháng, năm) dương lịch, hoặc nil nếu tháng nhuận không tồn tại.
    public static func lunarToSolar(_ lunar: LunarDate, timeZone tz: Double = vietnamTimeZone) -> DateComponents? {
        let a11: Int
        let b11: Int
        if lunar.month < 11 {
            a11 = lunarMonth11(lunar.year - 1, tz)
            b11 = lunarMonth11(lunar.year, tz)
        } else {
            a11 = lunarMonth11(lunar.year, tz)
            b11 = lunarMonth11(lunar.year + 1, tz)
        }
        let k = floorInt(0.5 + (Double(a11) - 2415021.076998695) / 29.530588853)
        var off = lunar.month - 11
        if off < 0 { off += 12 }
        if b11 - a11 > 365 {
            let leapOff = leapMonthOffset(a11, tz)
            var leapMonth = leapOff - 2
            if leapMonth < 0 { leapMonth += 12 }
            if lunar.isLeapMonth && lunar.month != leapMonth {
                return nil
            } else if lunar.isLeapMonth || off >= leapOff {
                off += 1
            }
        } else if lunar.isLeapMonth {
            return nil
        }
        let monthStart = newMoonDay(k + off, tz)
        let (d, m, y) = jdToDate(monthStart + lunar.day - 1)
        return DateComponents(year: y, month: m, day: d)
    }

    public static func date(from lunar: LunarDate, calendar: Calendar = .cozy) -> Date? {
        guard let comps = lunarToSolar(lunar) else { return nil }
        return calendar.date(from: comps)
    }

    /// Số ngày của một tháng âm (29 hoặc 30).
    public static func daysInMonth(month: Int, year: Int, isLeap: Bool = false) -> Int {
        guard let start = lunarToSolar(LunarDate(day: 1, month: month, year: year, isLeapMonth: isLeap)) else { return 29 }
        let jdStart = jdFromDate(start.day!, start.month!, start.year!)
        let day30 = jdToDate(jdStart + 29)
        let back = solarToLunar(day: day30.0, month: day30.1, year: day30.2)
        return back.day == 30 ? 30 : 29
    }

    /// Ngày dương lịch sớm nhất >= đầu ngày `from` rơi vào ngày âm `lunarDay/lunarMonth`.
    /// - Parameter lunarMonth: nil = lặp hằng tháng (vd. Mùng 1, Rằm).
    /// Nếu tháng chỉ có 29 ngày mà sự kiện là ngày 30, dùng ngày 29 (tục lệ giỗ chạp).
    public static func nextOccurrence(lunarDay: Int, lunarMonth: Int?, onOrAfter from: Date, calendar: Calendar = .cozy) -> Date? {
        let startOfFrom = calendar.startOfDay(for: from)
        let today = lunarDate(from: from, calendar: calendar)
        var candidates: [LunarDate] = []
        if let lunarMonth {
            for y in today.year...(today.year + 2) {
                let dim = daysInMonth(month: lunarMonth, year: y)
                candidates.append(LunarDate(day: min(lunarDay, dim), month: lunarMonth, year: y))
            }
        } else {
            // Duyệt khoảng 15 tháng âm tới (gồm cả tháng nhuận nếu có).
            var y = today.year
            var m = today.month
            for _ in 0..<15 {
                let dim = daysInMonth(month: m, year: y)
                candidates.append(LunarDate(day: min(lunarDay, dim), month: m, year: y))
                if lunarToSolar(LunarDate(day: 1, month: m, year: y, isLeapMonth: true)) != nil {
                    let dimLeap = daysInMonth(month: m, year: y, isLeap: true)
                    candidates.append(LunarDate(day: min(lunarDay, dimLeap), month: m, year: y, isLeapMonth: true))
                }
                m += 1
                if m > 12 { m = 1; y += 1 }
            }
        }
        return candidates
            .compactMap { date(from: $0, calendar: calendar) }
            .filter { $0 >= startOfFrom }
            .min()
    }

    public static func canChi(year: Int) -> String {
        let can = ["Giáp", "Ất", "Bính", "Đinh", "Mậu", "Kỷ", "Canh", "Tân", "Nhâm", "Quý"]
        let chi = ["Tý", "Sửu", "Dần", "Mão", "Thìn", "Tỵ", "Ngọ", "Mùi", "Thân", "Dậu", "Tuất", "Hợi"]
        return "\(can[mod(year + 6, 10)]) \(chi[mod(year + 8, 12)])"
    }

    // MARK: - Thuật toán thiên văn

    static func mod(_ a: Int, _ n: Int) -> Int { ((a % n) + n) % n }
    static func floorInt(_ x: Double) -> Int { Int(x.rounded(.down)) }

    static func jdFromDate(_ dd: Int, _ mm: Int, _ yy: Int) -> Int {
        let a = (14 - mm) / 12
        let y = yy + 4800 - a
        let m = mm + 12 * a - 3
        var jd = dd + (153 * m + 2) / 5 + 365 * y + y / 4 - y / 100 + y / 400 - 32045
        if jd < 2299161 {
            jd = dd + (153 * m + 2) / 5 + 365 * y + y / 4 - 32083
        }
        return jd
    }

    static func jdToDate(_ jd: Int) -> (Int, Int, Int) {
        let b: Int
        let c: Int
        if jd > 2299160 {
            let a = jd + 32044
            b = (4 * a + 3) / 146097
            c = a - (b * 146097) / 4
        } else {
            b = 0
            c = jd + 32082
        }
        let d = (4 * c + 3) / 1461
        let e = c - (1461 * d) / 4
        let m = (5 * e + 2) / 153
        let day = e - (153 * m + 2) / 5 + 1
        let month = m + 3 - 12 * (m / 10)
        let year = b * 100 + d - 4800 + m / 10
        return (day, month, year)
    }

    static func newMoon(_ k: Int) -> Double {
        let kd = Double(k)
        let t = kd / 1236.85
        let t2 = t * t
        let t3 = t2 * t
        let dr = Double.pi / 180
        var jd1 = 2415020.75933 + 29.53058868 * kd + 0.0001178 * t2 - 0.000000155 * t3
        jd1 += 0.00033 * sin((166.56 + 132.87 * t - 0.009173 * t2) * dr)
        let m = 359.2242 + 29.10535608 * kd - 0.0000333 * t2 - 0.00000347 * t3
        let mpr = 306.0253 + 385.81691806 * kd + 0.0107306 * t2 + 0.00001236 * t3
        let f = 21.2964 + 390.67050646 * kd - 0.0016528 * t2 - 0.00000239 * t3
        var c1 = (0.1734 - 0.000393 * t) * sin(m * dr) + 0.0021 * sin(2 * dr * m)
        c1 = c1 - 0.4068 * sin(mpr * dr) + 0.0161 * sin(dr * 2 * mpr)
        c1 = c1 - 0.0004 * sin(dr * 3 * mpr)
        c1 = c1 + 0.0104 * sin(dr * 2 * f) - 0.0051 * sin(dr * (m + mpr))
        c1 = c1 - 0.0074 * sin(dr * (m - mpr)) + 0.0004 * sin(dr * (2 * f + m))
        c1 = c1 - 0.0004 * sin(dr * (2 * f - m)) - 0.0006 * sin(dr * (2 * f + mpr))
        c1 = c1 + 0.0010 * sin(dr * (2 * f - mpr)) + 0.0005 * sin(dr * (2 * mpr + m))
        let deltat: Double
        if t < -11 {
            deltat = 0.001 + 0.000839 * t + 0.0002261 * t2 - 0.00000845 * t3 - 0.000000081 * t * t3
        } else {
            deltat = -0.000278 + 0.000265 * t + 0.000262 * t2
        }
        return jd1 + c1 - deltat
    }

    static func newMoonDay(_ k: Int, _ tz: Double) -> Int {
        floorInt(newMoon(k) + 0.5 + tz / 24)
    }

    static func sunLongitude(_ jdn: Double) -> Double {
        let t = (jdn - 2451545.0) / 36525
        let t2 = t * t
        let dr = Double.pi / 180
        let m = 357.52910 + 35999.05030 * t - 0.0001559 * t2 - 0.00000048 * t * t2
        let l0 = 280.46645 + 36000.76983 * t + 0.0003032 * t2
        var dl = (1.914600 - 0.004817 * t - 0.000014 * t2) * sin(dr * m)
        dl += (0.019993 - 0.000101 * t) * sin(dr * 2 * m) + 0.000290 * sin(dr * 3 * m)
        var l = (l0 + dl) * dr
        l -= Double.pi * 2 * Double(floorInt(l / (Double.pi * 2)))
        return l
    }

    static func sunLongitudeSector(_ dayNumber: Int, _ tz: Double) -> Int {
        floorInt(sunLongitude(Double(dayNumber) - 0.5 - tz / 24) / Double.pi * 6)
    }

    static func lunarMonth11(_ yy: Int, _ tz: Double) -> Int {
        let off = Double(jdFromDate(31, 12, yy)) - 2415021
        let k = floorInt(off / 29.530588853)
        var nm = newMoonDay(k, tz)
        if sunLongitudeSector(nm, tz) >= 9 {
            nm = newMoonDay(k - 1, tz)
        }
        return nm
    }

    static func leapMonthOffset(_ a11: Int, _ tz: Double) -> Int {
        let k = floorInt((Double(a11) - 2415021.076998695) / 29.530588853 + 0.5)
        var last: Int
        var i = 1
        var arc = sunLongitudeSector(newMoonDay(k + i, tz), tz)
        repeat {
            last = arc
            i += 1
            arc = sunLongitudeSector(newMoonDay(k + i, tz), tz)
        } while arc != last && i < 14
        return i - 1
    }
}
