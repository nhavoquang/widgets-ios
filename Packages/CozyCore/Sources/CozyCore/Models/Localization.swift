import Foundation

/// 15 ngôn ngữ phổ biến nhất trên App Store toàn cầu (+ `.system` tự động nhận theo ngôn ngữ iPhone).
public enum AppLanguage: String, Codable, CaseIterable, Sendable, Identifiable {
    case system = "system"
    case en = "en"
    case vi = "vi"
    case ja = "ja"
    case ko = "ko"
    case zhHans = "zh-Hans"
    case zhHant = "zh-Hant"
    case es = "es"
    case fr = "fr"
    case de = "de"
    case ptBR = "pt-BR"
    case th = "th"
    case id = "id"
    case ru = "ru"
    case it = "it"
    case ar = "ar"

    public var id: String { rawValue }

    /// Danh sách 15 ngôn ngữ cụ thể (dùng cho `project.yml` / App Store `knownRegions`).
    public static let storeLocaleCodes: [String] = [
        "en", "vi", "ja", "ko", "zh-Hans", "zh-Hant", "es", "fr", "de", "pt-BR", "th", "id", "ru", "it", "ar"
    ]

    /// Tên bản địa kèm cờ để người dùng ở bất kỳ quốc gia nào cũng nhận ra ngay.
    public var nativeDisplayName: String {
        switch self {
        case .system: return "🌐 Auto (iOS)"
        case .en: return "🇺🇸 English"
        case .vi: return "🇻🇳 Tiếng Việt"
        case .ja: return "🇯🇵 日本語"
        case .ko: return "🇰🇷 한국어"
        case .zhHans: return "🇨🇳 简体中文"
        case .zhHant: return "🇹🇼 繁體中文"
        case .es: return "🇪🇸 Español"
        case .fr: return "🇫🇷 Français"
        case .de: return "🇩🇪 Deutsch"
        case .ptBR: return "🇧🇷 Português"
        case .th: return "🇹🇭 ไทย"
        case .id: return "🇮🇩 Bahasa Indonesia"
        case .ru: return "🇷🇺 Русский"
        case .it: return "🇮🇹 Italiano"
        case .ar: return "🇸🇦 العربية"
        }
    }

    /// Ngôn ngữ thực tế đang áp dụng (nếu `.system` thì tự ánh xạ từ `Locale.preferredLanguages` của thiết bị).
    public var resolved: AppLanguage {
        if self != .system { return self }
        let preferred = Locale.preferredLanguages.first ?? Locale.current.identifier
        return Self.matchSystemLocale(preferred)
    }

    public static func matchSystemLocale(_ identifier: String) -> AppLanguage {
        let lower = identifier.lowercased().replacingOccurrences(of: "_", with: "-")
        if lower.hasPrefix("vi") { return .vi }
        if lower.hasPrefix("ja") { return .ja }
        if lower.hasPrefix("ko") { return .ko }
        if lower.hasPrefix("zh-hant") || lower.hasPrefix("zh-tw") || lower.hasPrefix("zh-hk") || lower.hasPrefix("zh-mo") {
            return .zhHant
        }
        if lower.hasPrefix("zh") { return .zhHans }
        if lower.hasPrefix("es") { return .es }
        if lower.hasPrefix("fr") { return .fr }
        if lower.hasPrefix("de") { return .de }
        if lower.hasPrefix("pt") { return .ptBR }
        if lower.hasPrefix("th") { return .th }
        if lower.hasPrefix("id") || lower.hasPrefix("in") { return .id }
        if lower.hasPrefix("ru") { return .ru }
        if lower.hasPrefix("it") { return .it }
        if lower.hasPrefix("ar") { return .ar }
        return .en
    }

    public var locale: Locale {
        Locale(identifier: resolved.rawValue)
    }

    public var isVietnamese: Bool {
        resolved == .vi
    }
}

/// Bộ định vị ngôn ngữ đồng bộ tức thì cho Main App, Lock Wallpaper Studio, AppIntents và WidgetKit.
/// Cho phép đổi ngôn ngữ ngay trong Cài đặt mà không cần khởi động lại máy, đồng thời tự theo ngôn ngữ iPhone khi cài mới ở nước ngoài.
public enum CozyL10n {
    private static let languageDefaultsKey = "cozy.activeLanguage.v1"

    public static var current: AppLanguage {
        get {
            if let group = SnapshotStore.activeAppGroupID,
               let d = UserDefaults(suiteName: group),
               let raw = d.string(forKey: languageDefaultsKey),
               let lang = AppLanguage(rawValue: raw) {
                return lang
            }
            if let raw = UserDefaults.standard.string(forKey: languageDefaultsKey),
               let lang = AppLanguage(rawValue: raw) {
                return lang
            }
            return .system
        }
        set {
            if let group = SnapshotStore.activeAppGroupID,
               let d = UserDefaults(suiteName: group) {
                d.set(newValue.rawValue, forKey: languageDefaultsKey)
            }
            UserDefaults.standard.set(newValue.rawValue, forKey: languageDefaultsKey)
        }
    }

    public static var effective: AppLanguage { current.resolved }
    public static var locale: Locale { effective.locale }

    /// 7 nhãn cột lịch tuần chuẩn cho 15 ngôn ngữ (tùy chọn bắt đầu từ Thứ Hai hoặc Chủ Nhật).
    public static func weekdayShortLabels(for lang: AppLanguage = effective, startDay: WeekStartDay = .monday) -> [String] {
        let monFirst: [String]
        switch lang.resolved {
        case .vi: monFirst = ["T2", "T3", "T4", "T5", "T6", "T7", "CN"]
        case .ja: monFirst = ["月", "火", "水", "木", "金", "土", "日"]
        case .ko: monFirst = ["월", "화", "수", "목", "금", "토", "일"]
        case .zhHans, .zhHant: monFirst = ["一", "二", "三", "四", "五", "六", "日"]
        case .es: monFirst = ["L", "M", "X", "J", "V", "S", "D"]
        case .fr: monFirst = ["L", "M", "M", "J", "V", "S", "D"]
        case .de: monFirst = ["Mo", "Di", "Mi", "Do", "Fr", "Sa", "So"]
        case .ptBR: monFirst = ["Seg", "Ter", "Qua", "Qui", "Sex", "Sáb", "Dom"]
        case .th: monFirst = ["จ.", "อ.", "พ.", "พฤ.", "ศ.", "ส.", "อา."]
        case .id: monFirst = ["Sen", "Sel", "Rab", "Kam", "Jum", "Sab", "Min"]
        case .ru: monFirst = ["Пн", "Вт", "Ср", "Чт", "Пт", "Сб", "Вс"]
        case .it: monFirst = ["L", "M", "M", "G", "V", "S", "D"]
        case .ar: monFirst = ["إث", "ثل", "أر", "خم", "جم", "سب", "أح"]
        default: monFirst = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
        }
        if startDay == .sunday, let sun = monFirst.last {
            return [sun] + Array(monFirst.dropLast())
        }
        return monFirst
    }

    /// Định dạng tiêu đề ngày trên Màn hình khóa chuẩn từng quốc gia.
    public static func formatLockDate(_ date: Date, lang: AppLanguage = effective) -> String {
        let f = DateFormatter()
        let resolved = lang.resolved
        f.locale = resolved.locale
        switch resolved {
        case .vi:
            f.dateFormat = "EEEE, d 'tháng' M"
        case .ja, .zhHans, .zhHant:
            f.dateFormat = "M月d日 EEEE"
        case .ko:
            f.dateFormat = "M월 d일 EEEE"
        default:
            f.setLocalizedDateFormatFromTemplate("EEEEMMMd")
        }
        return f.string(from: date)
    }

    /// Tra cứu bản dịch cho khóa chữ trên 15 ngôn ngữ (tự fallback sang Tiếng Anh chuẩn quốc tế).
    public static func t(_ key: String, lang: AppLanguage = effective) -> String {
        let code = lang.resolved
        if let dict = table[key] {
            if let val = dict[code] { return val }
            if let enVal = dict[.en] { return enVal }
        }
        return key
    }

    // MARK: - 15-Language Dictionary for Core UI, Lock Studio, Widgets & Settings

    private static let table: [String: [AppLanguage: String]] = [
        "tab.today": [
            .en: "Today", .vi: "Hôm nay", .ja: "今日", .ko: "오늘", .zhHans: "今天", .zhHant: "今天",
            .es: "Hoy", .fr: "Aujourd’hui", .de: "Heute", .ptBR: "Hoje", .th: "วันนี้",
            .id: "Hari Ini", .ru: "Сегодня", .it: "Oggi", .ar: "اليوم"
        ],
        "tab.connect": [
            .en: "Connect", .vi: "Kết nối", .ja: "つながり", .ko: "연결", .zhHans: "连接", .zhHant: "連結",
            .es: "Conectar", .fr: "Lien", .de: "Verbinden", .ptBR: "Conexão", .th: "เชื่อมต่อ",
            .id: "Terhubung", .ru: "Связь", .it: "Connetti", .ar: "تواصل"
        ],
        "tab.calendar": [
            .en: "Calendar", .vi: "Lịch & Lưới", .ja: "カレンダー", .ko: "캘린더", .zhHans: "日历", .zhHant: "日曆",
            .es: "Calendario", .fr: "Calendrier", .de: "Kalender", .ptBR: "Calendário", .th: "ปฏิทิน",
            .id: "Kalender", .ru: "Календарь", .it: "Calendario", .ar: "التقويم"
        ],
        "tab.studio": [
            .en: "Lock Studio", .vi: "Lock Studio", .ja: "ロック画面", .ko: "잠금 스튜디오", .zhHans: "锁屏工坊", .zhHant: "鎖屏工坊",
            .es: "Lock Studio", .fr: "Lock Studio", .de: "Lock Studio", .ptBR: "Lock Studio", .th: "สตูดิโอ",
            .id: "Lock Studio", .ru: "Экран", .it: "Lock Studio", .ar: "الاستوديو"
        ],
        "settings.title": [
            .en: "Settings", .vi: "Cài đặt", .ja: "設定", .ko: "설정", .zhHans: "设置", .zhHant: "設定",
            .es: "Ajustes", .fr: "Réglages", .de: "Einstellungen", .ptBR: "Ajustes", .th: "การตั้งค่า",
            .id: "Pengaturan", .ru: "Настройки", .it: "Impostazioni", .ar: "الإعدادات"
        ],
        "settings.language": [
            .en: "Language", .vi: "Ngôn ngữ", .ja: "言語", .ko: "언어", .zhHans: "语言", .zhHant: "語言",
            .es: "Idioma", .fr: "Langue", .de: "Sprache", .ptBR: "Idioma", .th: "ภาษา",
            .id: "Bahasa", .ru: "Язык", .it: "Lingua", .ar: "اللغة"
        ],
        "common.done": [
            .en: "Done", .vi: "Xong", .ja: "完了", .ko: "완료", .zhHans: "完成", .zhHant: "完成",
            .es: "Listo", .fr: "OK", .de: "Fertig", .ptBR: "Concluído", .th: "เสร็จสิ้น",
            .id: "Selesai", .ru: "Готово", .it: "Fine", .ar: "تم"
        ],
        "common.close": [
            .en: "Close", .vi: "Đóng", .ja: "閉じる", .ko: "닫기", .zhHans: "关闭", .zhHant: "關閉",
            .es: "Cerrar", .fr: "Fermer", .de: "Schließen", .ptBR: "Fechar", .th: "ปิด",
            .id: "Tutup", .ru: "Закрыть", .it: "Chiudi", .ar: "إغلاق"
        ],
        "common.update": [
            .en: "Refresh", .vi: "Cập nhật", .ja: "更新", .ko: "새로고침", .zhHans: "刷新", .zhHant: "重新整理",
            .es: "Actualizar", .fr: "Actualiser", .de: "Aktualisieren", .ptBR: "Atualizar", .th: "อัปเดต",
            .id: "Perbarui", .ru: "Обновить", .it: "Aggiorna", .ar: "تحديث"
        ],
        "appearance.title": [
            .en: "Appearance", .vi: "Giao diện", .ja: "外観モード", .ko: "화면 테마", .zhHans: "外观", .zhHant: "外觀",
            .es: "Apariencia", .fr: "Apparence", .de: "Erscheinungsbild", .ptBR: "Aparência", .th: "รูปลักษณ์",
            .id: "Tampilan", .ru: "Оформление", .it: "Aspetto", .ar: "المظهر"
        ],
        "appearance.system": [
            .en: "Auto", .vi: "Theo máy", .ja: "自動", .ko: "시스템", .zhHans: "跟随系统", .zhHant: "跟隨系統",
            .es: "Auto", .fr: "Auto", .de: "System", .ptBR: "Auto", .th: "อัตโนมัติ",
            .id: "Sistem", .ru: "Авто", .it: "Auto", .ar: "تلقائي"
        ],
        "appearance.light": [
            .en: "Light", .vi: "Sáng", .ja: "ライト", .ko: "라이트", .zhHans: "浅色", .zhHant: "淺色",
            .es: "Claro", .fr: "Clair", .de: "Hell", .ptBR: "Claro", .th: "สว่าง",
            .id: "Terang", .ru: "Светлая", .it: "Chiaro", .ar: "فاتح"
        ],
        "appearance.dark": [
            .en: "Dark", .vi: "Tối", .ja: "ダーク", .ko: "다크", .zhHans: "深色", .zhHant: "深色",
            .es: "Oscuro", .fr: "Sombre", .de: "Dunkel", .ptBR: "Escuro", .th: "มืด",
            .id: "Gelap", .ru: "Тёмная", .it: "Scuro", .ar: "داكن"
        ],
        "settings.displayName": [
            .en: "Display Name", .vi: "Tên hiển thị", .ja: "表示名", .ko: "표시 이름", .zhHans: "显示名称", .zhHant: "顯示名稱",
            .es: "Nombre", .fr: "Nom affiché", .de: "Anzeigename", .ptBR: "Nome", .th: "ชื่อที่แสดง",
            .id: "Nama Tampilan", .ru: "Имя", .it: "Nome", .ar: "الاسم"
        ],
        "settings.haptics": [
            .en: "Haptic Feedback", .vi: "Rung phản hồi", .ja: "触覚フィードバック", .ko: "햅틱 반응", .zhHans: "触感反馈", .zhHant: "觸覺回饋",
            .es: "Vibración", .fr: "Retour haptique", .de: "Haptik", .ptBR: "Vibração", .th: "การสั่นตอบสนอง",
            .id: "Getaran Haptik", .ru: "Виброотклик", .it: "Feedback aptico", .ar: "اهتزاز لمسي"
        ],
        // Weather conditions
        "weather.title": [
            .en: "Weather", .vi: "Thời tiết", .ja: "天気", .ko: "날씨", .zhHans: "天气", .zhHant: "天氣",
            .es: "Clima", .fr: "Météo", .de: "Wetter", .ptBR: "Clima", .th: "สภาพอากาศ",
            .id: "Cuaca", .ru: "Погода", .it: "Meteo", .ar: "الطقس"
        ],
        "weather.clear": [
            .en: "Clear", .vi: "Trời quang", .ja: "快晴", .ko: "맑음", .zhHans: "晴朗", .zhHant: "晴朗",
            .es: "Despejado", .fr: "Dégagé", .de: "Klar", .ptBR: "Limpo", .th: "แจ่มใส",
            .id: "Cerah", .ru: "Ясно", .it: "Sereno", .ar: "صافي"
        ],
        "weather.partlyCloudy": [
            .en: "Partly Cloudy", .vi: "Ít mây", .ja: "晴れ時々曇り", .ko: "구름 조금", .zhHans: "多云", .zhHant: "多雲",
            .es: "Algo nublado", .fr: "éclaircies", .de: "Teils bewölkt", .ptBR: "Parc. nublado", .th: "มีเมฆบางส่วน",
            .id: "Berawan", .ru: "Малооблачно", .it: "Poco nuvoloso", .ar: "غائم جزئياً"
        ],
        "weather.cloudy": [
            .en: "Cloudy", .vi: "Nhiều mây", .ja: "曇り", .ko: "흐림", .zhHans: "阴天", .zhHant: "陰天",
            .es: "Nublado", .fr: "Nuageux", .de: "Bewölkt", .ptBR: "Nublado", .th: "มีเมฆมาก",
            .id: "Mendung", .ru: "Облачно", .it: "Nuvoloso", .ar: "غائم"
        ],
        "weather.rain": [
            .en: "Rain", .vi: "Mưa", .ja: "雨", .ko: "비", .zhHans: "雨", .zhHant: "雨",
            .es: "Lluvia", .fr: "Pluie", .de: "Regen", .ptBR: "Chuva", .th: "ฝนตก",
            .id: "Hujan", .ru: "Дождь", .it: "Pioggia", .ar: "مطر"
        ],
        "weather.thunderstorm": [
            .en: "Storm", .vi: "Dông", .ja: "雷雨", .ko: "뇌우", .zhHans: "雷阵雨", .zhHant: "雷陣雨",
            .es: "Tormenta", .fr: "Orage", .de: "Gewitter", .ptBR: "Tempestade", .th: "พายุฝน",
            .id: "Badai Petir", .ru: "Гроза", .it: "Temporale", .ar: "عاصفة"
        ],
        "weather.drizzle": [
            .en: "Drizzle", .vi: "Mưa phùn", .ja: "霧雨", .ko: "이슬비", .zhHans: "毛毛雨", .zhHant: "毛毛雨",
            .es: "Llovizna", .fr: "Bruine", .de: "Nieselregen", .ptBR: "Garoa", .th: "ฝนปรอย",
            .id: "Gerimis", .ru: "Морось", .it: "Pioggerella", .ar: "رذاذ"
        ],
        "weather.fog": [
            .en: "Fog", .vi: "Sương mù", .ja: "霧", .ko: "안개", .zhHans: "雾", .zhHant: "霧",
            .es: "Niebla", .fr: "Brouillard", .de: "Nebel", .ptBR: "Neblina", .th: "หมอก",
            .id: "Kabut", .ru: "Туман", .it: "Nebbia", .ar: "ضباب"
        ],
        "weather.snow": [
            .en: "Snow", .vi: "Tuyết", .ja: "雪", .ko: "눈", .zhHans: "雪", .zhHant: "雪",
            .es: "Nieve", .fr: "Neige", .de: "Schnee", .ptBR: "Neve", .th: "หิมะ",
            .id: "Salju", .ru: "Снег", .it: "Neve", .ar: "ثلج"
        ],
        "weather.windy": [
            .en: "Windy", .vi: "Gió mạnh", .ja: "強風", .ko: "강풍", .zhHans: "大风", .zhHant: "強風",
            .es: "Ventoso", .fr: "Venteux", .de: "Windig", .ptBR: "Ventania", .th: "ลมแรง",
            .id: "Berangin", .ru: "Ветрено", .it: "Ventoso", .ar: "عاصف"
        ],
        "weather.hot": [
            .en: "Hot", .vi: "Nắng nóng", .ja: "猛暑", .ko: "폭염", .zhHans: "炎热", .zhHant: "炎熱",
            .es: "Caluroso", .fr: "Chaud", .de: "Heiß", .ptBR: "Quente", .th: "ร้อนจัด",
            .id: "Panas", .ru: "Жарко", .it: "Caldo", .ar: "حار"
        ],
        "weather.feelsLike": [
            .en: "Feels", .vi: "Cảm giác", .ja: "体感", .ko: "체감", .zhHans: "体感", .zhHant: "體感",
            .es: "Sensación", .fr: "Ressenti", .de: "Gefühlt", .ptBR: "Sensação", .th: "รู้สึกเหมือน",
            .id: "Terasa", .ru: "Ощущ.", .it: "Percepita", .ar: "المحسوسة"
        ],
        "weather.humidity": [
            .en: "Hum", .vi: "Ẩm", .ja: "湿度", .ko: "습도", .zhHans: "湿度", .zhHant: "濕度",
            .es: "Hum", .fr: "Hum", .de: "Feuchte", .ptBR: "Umid", .th: "ชื้น",
            .id: "Lembap", .ru: "Влажн.", .it: "Umid", .ar: "رطوبة"
        ],
        // Moods
        "mood.happy": [
            .en: "Happy", .vi: "Vui vẻ", .ja: "ハッピー", .ko: "행복해", .zhHans: "开心", .zhHant: "開心",
            .es: "Feliz", .fr: "Heureux", .de: "Glücklich", .ptBR: "Feliz", .th: "มีความสุข",
            .id: "Senang", .ru: "Радость", .it: "Felice", .ar: "سعيد"
        ],
        "mood.chill": [
            .en: "Chill", .vi: "Chill", .ja: "リラックス", .ko: "평온해", .zhHans: "惬意", .zhHant: "愜意",
            .es: "Relax", .fr: "Détendu", .de: "Entspannt", .ptBR: "De boa", .th: "ชิลล์",
            .id: "Santai", .ru: "Спокойно", .it: "Relax", .ar: "مرتاح"
        ],
        "mood.sleepy": [
            .en: "Sleepy", .vi: "Buồn ngủ", .ja: "眠い", .ko: "졸려", .zhHans: "犯困", .zhHant: "想睡",
            .es: "Con sueño", .fr: "Somnolent", .de: "Müde", .ptBR: "Com sono", .th: "ง่วงนอน",
            .id: "Mengantuk", .ru: "Сонно", .it: "Assonnato", .ar: "نعسان"
        ],
        "mood.excited": [
            .en: "Excited", .vi: "Háo hức", .ja: "ワクワク", .ko: "신나", .zhHans: "兴奋", .zhHant: "興奮",
            .es: "Emocionado", .fr: "Enthousiaste", .de: "Aufgeregt", .ptBR: "Animado", .th: "ตื่นเต้น",
            .id: "Bersemangat", .ru: "Восторг", .it: "Carico", .ar: "متحمس"
        ],
        "mood.tired": [
            .en: "Tired", .vi: "Mệt mỏi", .ja: "お疲れ", .ko: "피곤해", .zhHans: "疲惫", .zhHant: "疲憊",
            .es: "Cansado", .fr: "Fatigué", .de: "Erschöpft", .ptBR: "Cansado", .th: "เหนื่อย",
            .id: "Lelah", .ru: "Усталость", .it: "Stanco", .ar: "متعب"
        ],
        "mood.missing": [
            .en: "Miss you", .vi: "Nhớ nhung", .ja: "会いたい", .ko: "보고 싶어", .zhHans: "想你", .zhHant: "想你",
            .es: "Te extraño", .fr: "Tu me manques", .de: "Vermisse dich", .ptBR: "Saudade", .th: "คิดถึง",
            .id: "Kangen", .ru: "Скучаю", .it: "Mi manchi", .ar: "مشتاق"
        ],
        "mood.busy": [
            .en: "Busy", .vi: "Bận rộn", .ja: "集中・多忙", .ko: "바쁨", .zhHans: "忙碌", .zhHant: "忙碌",
            .es: "Ocupado", .fr: "Occupé", .de: "Beschäftigt", .ptBR: "Ocupado", .th: "ยุ่งอยู่",
            .id: "Sibuk", .ru: "Занят", .it: "Impegnato", .ar: "مشغول"
        ],
        // Lock Studio Tabs & Blocks
        "studio.tab.templates": [
            .en: "Templates", .vi: "16 Mẫu", .ja: "テンプレート", .ko: "템플릿", .zhHans: "模板", .zhHant: "模板",
            .es: "Plantillas", .fr: "Modèles", .de: "Vorlagen", .ptBR: "Modelos", .th: "เทมเพลต",
            .id: "Templat", .ru: "Шаблоны", .it: "Modelli", .ar: "القوالب"
        ],
        "studio.tab.layout": [
            .en: "Grid & Drag", .vi: "Bố cục & Cột", .ja: "配置・列", .ko: "배치·열", .zhHans: "布局与列", .zhHant: "佈局與欄",
            .es: "Diseño", .fr: "Grille", .de: "Raster", .ptBR: "Grade", .th: "เลย์เอาต์",
            .id: "Tata Letak", .ru: "Сетка", .it: "Griglia", .ar: "التخطيط"
        ],
        "studio.tab.style": [
            .en: "Style", .vi: "Viền & Chữ", .ja: "スタイル", .ko: "스타일", .zhHans: "样式", .zhHant: "樣式",
            .es: "Estilo", .fr: "Style", .de: "Stil", .ptBR: "Estilo", .th: "สไตล์",
            .id: "Gaya", .ru: "Стиль", .it: "Stile", .ar: "النمط"
        ],
        "studio.tab.bg": [
            .en: "Wallpaper", .vi: "Nền", .ja: "背景", .ko: "배경", .zhHans: "背景", .zhHant: "背景",
            .es: "Fondo", .fr: "Fond", .de: "Hintergrund", .ptBR: "Fundo", .th: "พื้นหลัง",
            .id: "Latar", .ru: "Фон", .it: "Sfondo", .ar: "الخلفية"
        ],
        "block.weekStrip": [
            .en: "Week Calendar", .vi: "Lịch tuần", .ja: "週間カレンダー", .ko: "주간 캘린더", .zhHans: "周历", .zhHant: "週曆",
            .es: "Semana", .fr: "Semaine", .de: "Woche", .ptBR: "Semana", .th: "ปฏิทินสัปดาห์",
            .id: "Mingguan", .ru: "Неделя", .it: "Settimana", .ar: "أسبوعي"
        ],
        "block.todaySchedule": [
            .en: "Today’s Schedule", .vi: "Lịch trình hôm nay", .ja: "今日の予定", .ko: "오늘 일정", .zhHans: "今日日程", .zhHant: "今日行程",
            .es: "Agenda de hoy", .fr: "Agenda du jour", .de: "Heutiger Plan", .ptBR: "Agenda de hoje", .th: "กำหนดการวันนี้",
            .id: "Agenda Hari Ini", .ru: "План на день", .it: "Impegni di oggi", .ar: "جدول اليوم"
        ],
        "block.weather": [
            .en: "Live Weather", .vi: "Thời tiết thật", .ja: "リアルタイム天気", .ko: "실시간 날씨", .zhHans: "实时天气", .zhHant: "即時天氣",
            .es: "Clima en vivo", .fr: "Météo en direct", .de: "Live-Wetter", .ptBR: "Clima ao vivo", .th: "สภาพอากาศสด",
            .id: "Cuaca Langsung", .ru: "Погода", .it: "Meteo live", .ar: "الطقس المباشر"
        ],
        "block.vocab": [
            .en: "Daily Word", .vi: "Từ vựng hôm nay", .ja: "今日の単語", .ko: "오늘의 단어", .zhHans: "每日词汇", .zhHant: "每日單字",
            .es: "Palabra del día", .fr: "Mot du jour", .de: "Wort des Tages", .ptBR: "Palavra do dia", .th: "ศัพท์วันนี้",
            .id: "Kosakata", .ru: "Слово дня", .it: "Parola del giorno", .ar: "كلمة اليوم"
        ],
        "block.partner": [
            .en: "Partner Mood", .vi: "Người kết nối", .ja: "パートナー", .ko: "파트너 기분", .zhHans: "伴侣状态", .zhHant: "伴侶狀態",
            .es: "Pareja", .fr: "Partenaire", .de: "Partner", .ptBR: "Parceiro(a)", .th: "คนรู้ใจ",
            .id: "Pasangan", .ru: "Партнёр", .it: "Partner", .ar: "الشريك"
        ],
        "block.monthGrid": [
            .en: "Month Calendar", .vi: "Lịch tháng", .ja: "月間カレンダー", .ko: "월간 캘린더", .zhHans: "月历", .zhHant: "月曆",
            .es: "Mes", .fr: "Mois", .de: "Monat", .ptBR: "Mês", .th: "ปฏิทินเดือน",
            .id: "Bulanan", .ru: "Месяц", .it: "Mese", .ar: "شهري"
        ],
        "block.eventCountdown": [
            .en: "Countdown", .vi: "Đếm ngày sự kiện", .ja: "カウントダウン", .ko: "디데이", .zhHans: "倒数日", .zhHant: "倒數日",
            .es: "Cuenta atrás", .fr: "Compte à rebours", .de: "Countdown", .ptBR: "Contagem", .th: "นับถอยหลัง",
            .id: "Hitung Mundur", .ru: "Отсчёт", .it: "Conto alla rovescia", .ar: "عد تنازلي"
        ],
        "block.yearProgress": [
            .en: "Year Progress", .vi: "Tiến độ năm %", .ja: "今年の進捗 %", .ko: "올해 진행률 %", .zhHans: "年度进度 %", .zhHant: "年度進度 %",
            .es: "Progreso anual", .fr: "Année %", .de: "Jahresfortschritt", .ptBR: "Ano %", .th: "ความคืบหน้าปี",
            .id: "Progres Tahun", .ru: "Прогресс года", .it: "Anno %", .ar: "تقدم السنة"
        ],
        "block.habitStreak": [
            .en: "7-Day Streak", .vi: "Chuỗi học 7 ngày", .ja: "7日間ストリーク", .ko: "7일 연속 기록", .zhHans: "7天打卡", .zhHant: "7天連續",
            .es: "Racha 7 días", .fr: "Série 7 jours", .de: "7-Tage-Serie", .ptBR: "Ofensiva 7d", .th: "สถิติ 7 วัน",
            .id: "Runtunan 7h", .ru: "Серия 7 дней", .it: "Serie 7 giorni", .ar: "سلسلة ٧ أيام"
        ],
        "block.lunarCard": [
            .en: "Lunar Date", .vi: "Âm lịch hôm nay", .ja: "旧暦", .ko: "음력", .zhHans: "农历", .zhHant: "農曆",
            .es: "Calendario lunar", .fr: "Date lunaire", .de: "Mondkalender", .ptBR: "Data lunar", .th: "จันทรคติ",
            .id: "Kalender Lunar", .ru: "Лунный день", .it: "Data lunare", .ar: "التقويم القمري"
        ],
        "block.stickyNote": [
            .en: "Sticky Note", .vi: "Ghi chú ghim", .ja: "付箋メモ", .ko: "메모", .zhHans: "便签", .zhHant: "便條貼",
            .es: "Nota rápida", .fr: "Note épinglée", .de: "Notiz", .ptBR: "Nota fixa", .th: "โน้ตติดหน้าจอ",
            .id: "Catatan Tempel", .ru: "Заметка", .it: "Nota", .ar: "ملاحظة"
        ],
        "block.batteryCard": [
            .en: "Battery", .vi: "Pin thiết bị", .ja: "バッテリー", .ko: "배터리", .zhHans: "设备电量", .zhHant: "裝置電量",
            .es: "Batería", .fr: "Batterie", .de: "Batterie", .ptBR: "Bateria", .th: "แบตเตอรี่",
            .id: "Baterai", .ru: "Заряд", .it: "Batteria", .ar: "البطارية"
        ],
        "schedule.noEvents": [
            .en: "No events today", .vi: "Không có sự kiện hôm nay", .ja: "今日の予定はありません", .ko: "오늘 일정 없음", .zhHans: "今天没有日程", .zhHant: "今天沒有行程",
            .es: "Sin eventos hoy", .fr: "Aucun événement", .de: "Heute keine Termine", .ptBR: "Sem eventos hoje", .th: "ไม่มีกิจกรรมวันนี้",
            .id: "Tidak ada acara", .ru: "Событий нет", .it: "Nessun impegno", .ar: "لا توجد أحداث اليوم"
        ],
        "partner.empty": [
            .en: "Not connected yet", .vi: "Chưa kết nối", .ja: "未接続", .ko: "아직 연결 안 됨", .zhHans: "尚未连接", .zhHant: "尚未連結",
            .es: "Sin conectar", .fr: "Non connecté", .de: "Nicht verbunden", .ptBR: "Não conectado", .th: "ยังไม่ได้เชื่อมต่อ",
            .id: "Belum terhubung", .ru: "Не подключено", .it: "Non connesso", .ar: "غير متصل بعد"
        ],
        "studio.addComponent": [
            .en: "Add Widget Block", .vi: "Thêm ô thành phần", .ja: "ブロックを追加", .ko: "구성 요소 추가", .zhHans: "添加组件块", .zhHant: "新增組件塊",
            .es: "Añadir bloque", .fr: "Ajouter un bloc", .de: "Block hinzufügen", .ptBR: "Adicionar bloco", .th: "เพิ่มบล็อกวิดเจ็ต",
            .id: "Tambah Blok", .ru: "Добавить блок", .it: "Aggiungi blocco", .ar: "إضافة عنصر"
        ],
        "studio.dragHint": [
            .en: "Long-press & drag tiles to reorder · Tap 1col / 1/2 / 1/3 / 1/4 to resize:",
            .vi: "Nhấn giữ & kéo thả ô để đổi vị trí · Chạm 1 cột / 1/2 / 1/3 / 1/4 để chia cột:",
            .ja: "長押し＆ドラッグで並べ替え・ボタンで1〜4列に変更：",
            .ko: "길게 눌러 드래그하여 순서 변경 · 버튼으로 1~4열 조절:",
            .zhHans: "长按拖动调整顺序 · 点击切换 1/2/3/4 列宽：",
            .zhHant: "長按拖曳調整順序 · 點擊切換 1/2/3/4 欄寬：",
            .es: "Mantén pulsado y arrastra · Toca para dividir en 1–4 columnas:",
            .fr: "Maintenez et glissez pour réorganiser · 1 à 4 colonnes :",
            .de: "Gedrückt halten & ziehen · Tippen für 1–4 Spalten:",
            .ptBR: "Segure e arraste para mover · Toque para 1–4 colunas:",
            .th: "แตะค้างแล้วลากเพื่อย้าย · แตะเพื่อแบ่ง 1–4 คอลัมน์:",
            .id: "Tekan lama & geser · Ketuk untuk bagi 1–4 kolom:",
            .ru: "Удерживайте и перетаскивайте · 1–4 колонки:",
            .it: "Tieni premuto e trascina · Tocca per 1–4 colonne:",
            .ar: "اضغط مطولاً واسحب للترتيب · اختر من ١ إلى ٤ أعمدة:"
        ],
        "studio.installShortcutFirst": [
            .en: "First Time: Install Auto Shortcut (1 Tap)",
            .vi: "Lần đầu: Cài Shortcut tự động (1 chạm)",
            .ja: "初回のみ：自動ショートカットを追加（1タップ）",
            .ko: "최초 1회: 자동 단축어 설치 (원탭)",
            .zhHans: "首次使用：一键安装自动快捷指令",
            .zhHant: "首次使用：一鍵安裝自動捷徑",
            .es: "Primera vez: Instalar Atajo automático (1 toque)",
            .fr: "1re fois : Installer le Raccourci auto (1 geste)",
            .de: "Einmalig: Auto-Kurzbefehl installieren",
            .ptBR: "1ª vez: Instalar Atalho automático (1 toque)",
            .th: "ครั้งแรก: ติดตั้งคำสั่งลัดอัตโนมัติ (แตะครั้งเดียว)",
            .id: "Pertama Kali: Pasang Pintasan Otomatis",
            .ru: "Первый раз: Установить быструю команду",
            .it: "Prima volta: Installa Comando rapido",
            .ar: "لأول مرة: تثبيت الاختصار التلقائي"
        ],
        "style.none": [
            .en: "Plain", .vi: "Không nền", .ja: "背景なし", .ko: "배경 없음", .zhHans: "无背景", .zhHant: "無背景",
            .es: "Sin fondo", .fr: "Sans fond", .de: "Ohne", .ptBR: "Sem fundo", .th: "ไม่มีพื้นหลัง",
            .id: "Polos", .ru: "Без фона", .it: "Senza sfondo", .ar: "بدون خلفية"
        ],
        "style.frostedGlass": [
            .en: "Frosted", .vi: "Kính mờ", .ja: "すりガラス", .ko: "블러 글래스", .zhHans: "毛玻璃", .zhHant: "毛玻璃",
            .es: "Cristal", .fr: "Verre dépoli", .de: "Milchglas", .ptBR: "Vidro fosco", .th: "กระจกฝ้า",
            .id: "Kaca Buram", .ru: "Стекло", .it: "Vetro", .ar: "زجاج ضبابي"
        ],
        "style.solidSoft": [
            .en: "Soft Card", .vi: "Bo mềm", .ja: "ソフトカード", .ko: "소프트 카드", .zhHans: "柔和卡片", .zhHant: "柔和卡片",
            .es: "Suave", .fr: "Carte douce", .de: "Weich", .ptBR: "Suave", .th: "การ์ดนุ่ม",
            .id: "Lembut", .ru: "Мягкая", .it: "Morbido", .ar: "بطاقة ناعمة"
        ],
        "style.glowingBorder": [
            .en: "Neon Rim", .vi: "Viền sáng", .ja: "ネオン枠", .ko: "네온 테두리", .zhHans: "发光边框", .zhHant: "發光邊框",
            .es: "Borde neón", .fr: "Contour néon", .de: "Neonrand", .ptBR: "Borda neon", .th: "ขอบเรืองแสง",
            .id: "Tepi Neon", .ru: "Неон", .it: "Bordo neon", .ar: "إطار مضيء"
        ],
        "style.hairlineOutline": [
            .en: "Outline", .vi: "Viền mảnh", .ja: "細枠", .ko: "얇은 선", .zhHans: "细线框", .zhHant: "細線框",
            .es: "Contorno", .fr: "Contour fin", .de: "Kontur", .ptBR: "Contorno", .th: "เส้นขอบบาง",
            .id: "Garis Tipis", .ru: "Контур", .it: "Contorno", .ar: "خط رفيع"
        ],
        "style.dashedOutline": [
            .en: "Dashed", .vi: "Nét đứt", .ja: "破線", .ko: "점선", .zhHans: "虚线", .zhHant: "虛線",
            .es: "Punteado", .fr: "Pointillés", .de: "Gestrichelt", .ptBR: "Tracejado", .th: "เส้นประ",
            .id: "Putus-putus", .ru: "Пунктир", .it: "Tratteggio", .ar: "متقطع"
        ],
        "style.cornerRadius": [
            .en: "Corner Radius", .vi: "Độ bo góc", .ja: "角の丸み", .ko: "모서리 둥글기", .zhHans: "圆角半径", .zhHant: "圓角半徑",
            .es: "Esquinas", .fr: "Arrondi", .de: "Eckenradius", .ptBR: "Arredondamento", .th: "ความโค้งมุม",
            .id: "Sudut Lengkung", .ru: "Скругление", .it: "Raggio angoli", .ar: "انحناء الزوايا"
        ],
        "style.gridSpacing": [
            .en: "Grid Spacing", .vi: "Khoảng cách ô", .ja: "ブロック間隔", .ko: "블록 간격", .zhHans: "组件间距", .zhHant: "組件間距",
            .es: "Espaciado", .fr: "Espacement", .de: "Abstand", .ptBR: "Espaçamento", .th: "ระยะห่าง",
            .id: "Jarak Kotak", .ru: "Отступы", .it: "Spaziatura", .ar: "المسافة"
        ],
        "style.fontScale": [
            .en: "Text Size", .vi: "Cỡ chữ", .ja: "文字サイズ", .ko: "글자 크기", .zhHans: "字体大小", .zhHant: "字體大小",
            .es: "Tamaño texto", .fr: "Taille texte", .de: "Textgröße", .ptBR: "Tamanho texto", .th: "ขนาดตัวอักษร",
            .id: "Ukuran Teks", .ru: "Размер текста", .it: "Dimensione testo", .ar: "حجم النص"
        ],
        "style.cardOpacity": [
            .en: "Card Opacity", .vi: "Độ đậm nền thẻ", .ja: "カードの濃さ", .ko: "카드 불투명도", .zhHans: "卡片不透明度", .zhHant: "卡片不透明度",
            .es: "Opacidad", .fr: "Opacité", .de: "Deckkraft", .ptBR: "Opacidade", .th: "ความทึบการ์ด",
            .id: "Opasitas Kartu", .ru: "Прозрачность", .it: "Opacità", .ar: "شفافية البطاقة"
        ],
        "style.verticalOffset": [
            .en: "Vertical Offset", .vi: "Vị trí dọc", .ja: "縦の位置", .ko: "세로 위치", .zhHans: "垂直位置", .zhHant: "垂直位置",
            .es: "Posición vertical", .fr: "Position verticale", .de: "Vertikale Position", .ptBR: "Posição vertical", .th: "ตำแหน่งแนวตั้ง",
            .id: "Posisi Vertikal", .ru: "Позиция по верт.", .it: "Posizione verticale", .ar: "الموضع الرأسي"
        ],
        "bg.choosePhoto": [
            .en: "Choose Photo from Library", .vi: "Chọn ảnh nền từ Thư viện", .ja: "写真ライブラリから選択", .ko: "사진 보관함에서 선택",
            .zhHans: "从相册选择背景图", .zhHant: "從相簿選擇背景圖", .es: "Elegir foto de la galería", .fr: "Choisir une photo",
            .de: "Foto aus Mediathek wählen", .ptBR: "Escolher foto da galeria", .th: "เลือกรูปภาพจากคลัง",
            .id: "Pilih Foto dari Galeri", .ru: "Выбрать фото из галереи", .it: "Scegli foto dalla libreria", .ar: "اختر صورة من المكتبة"
        ],
        "block.yearDots": [
            .en: "365 Year Dots", .vi: "Lưới 365 chấm Năm", .ja: "365日ドット進捗", .ko: "365일 도트 그리드",
            .zhHans: "365天圆点进度", .zhHant: "365天圓點進度", .es: "365 puntos del año", .fr: "Grille 365 jours",
            .de: "365-Tage-Punkte", .ptBR: "365 pontos do ano", .th: "ตาราง 365 จุด",
            .id: "365 Titik Tahun", .ru: "365 точек года", .it: "365 punti dell’anno", .ar: "شبكة ٣٦٥ يوماً"
        ],
        "block.dailyQuote": [
            .en: "Daily Quote", .vi: "Câu nói hôm nay", .ja: "今日の名言", .ko: "오늘의 명언",
            .zhHans: "每日一言", .zhHant: "每日一言", .es: "Frase del día", .fr: "Citation du jour",
            .de: "Zitat des Tages", .ptBR: "Frase do dia", .th: "คำคมวันนี้",
            .id: "Kutipan Hari Ini", .ru: "Цитата дня", .it: "Citazione del giorno", .ar: "حكمة اليوم"
        ],
        "block.multiCountdown": [
            .en: "Multi-Countdowns", .vi: "Thanh đếm sự kiện", .ja: "複数カウントダウン", .ko: "멀티 디데이 바",
            .zhHans: "多事件进度条", .zhHant: "多事件進度條", .es: "Barras de cuenta atrás", .fr: "Comptes à rebours",
            .de: "Multi-Countdowns", .ptBR: "Múltiplas contagens", .th: "แถบนับถอยหลัง",
            .id: "Multi Hitung Mundur", .ru: "Шкала событий", .it: "Conti alla rovescia", .ar: "شريط العد التنازلي"
        ],
        "weekStart.title": [
            .en: "Start Week On", .vi: "Bắt đầu tuần", .ja: "週の始まり", .ko: "주 시작 요일",
            .zhHans: "每周起始日", .zhHant: "每週起始日", .es: "Inicio de semana", .fr: "Début de semaine",
            .de: "Wochenbeginn", .ptBR: "Início da semana", .th: "เริ่มต้นสัปดาห์",
            .id: "Awal Minggu", .ru: "Начало недели", .it: "Inizio settimana", .ar: "بداية الأسبوع"
        ],
        "weekStart.monday": [
            .en: "Monday", .vi: "Thứ Hai", .ja: "月曜日", .ko: "월요일",
            .zhHans: "周一", .zhHant: "週一", .es: "Lunes", .fr: "Lundi",
            .de: "Montag", .ptBR: "Segunda", .th: "วันจันทร์",
            .id: "Senin", .ru: "Понедельник", .it: "Lunedì", .ar: "الاثنين"
        ],
        "weekStart.sunday": [
            .en: "Sunday", .vi: "Chủ Nhật", .ja: "日曜日", .ko: "일요일",
            .zhHans: "周日", .zhHant: "週日", .es: "Domingo", .fr: "Dimanche",
            .de: "Sonntag", .ptBR: "Domingo", .th: "วันอาทิตย์",
            .id: "Minggu", .ru: "Воскресенье", .it: "Domenica", .ar: "الأحد"
        ],
        "bg.photoDim": [
            .en: "Photo Dimming", .vi: "Độ tối ảnh nền", .ja: "背景の暗さ", .ko: "배경 어둡기",
            .zhHans: "背景暗度", .zhHant: "背景暗度", .es: "Oscurecer foto", .fr: "Assombrir",
            .de: "Abdunkeln", .ptBR: "Escurecer foto", .th: "ความมืดพื้นหลัง",
            .id: "Redup Foto", .ru: "Затемнение фото", .it: "Oscura foto", .ar: "تعتيم الصورة"
        ],
        "bg.photoBlur": [
            .en: "Photo Blur", .vi: "Độ mờ ảnh nền", .ja: "背景ぼかし", .ko: "배경 흐림",
            .zhHans: "背景模糊", .zhHant: "背景模糊", .es: "Desenfoque", .fr: "Flou",
            .de: "Unschärfe", .ptBR: "Desfoque", .th: "ความเบลอพื้นหลัง",
            .id: "Blur Foto", .ru: "Размытие фото", .it: "Sfocatura", .ar: "ضبابية الصورة"
        ],
        "settings.syncReminders": [
            .en: "Sync Apple Reminders", .vi: "Đồng bộ Lời nhắc (Reminders)", .ja: "Appleリマインダー同期", .ko: "미리 알림 동기화",
            .zhHans: "同步苹果提醒事项", .zhHant: "同步提醒事項", .es: "Sincronizar Recordatorios", .fr: "Synchroniser Rappels",
            .de: "Erinnerungen synchr.", .ptBR: "Sincronizar Lembretes", .th: "ซิงค์เตือนความจำ",
            .id: "Sinkron Pengingat", .ru: "Синхр. Напоминания", .it: "Sincronizza Promemoria", .ar: "مزامنة التذكيرات"
        ]
    ]
}
