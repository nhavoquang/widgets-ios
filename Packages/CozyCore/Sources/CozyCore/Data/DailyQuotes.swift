import Foundation

/// Ngày bắt đầu tuần trên Lịch tuần & Lịch tháng (Thứ Hai chuẩn Âu/Việt hoặc Chủ Nhật chuẩn Mỹ/Nhật/Hàn).
public enum WeekStartDay: String, Codable, CaseIterable, Sendable, Identifiable {
    case monday
    case sunday

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .monday: return CozyL10n.t("weekStart.monday")
        case .sunday: return CozyL10n.t("weekStart.sunday")
        }
    }
}

/// Bộ câu nói truyền cảm hứng (Daily Quotes / Focus Affirmations) dịch chuẩn sang 15 ngôn ngữ cho thị trường toàn cầu.
public struct DailyQuote: Sendable, Hashable {
    public let id: Int
    public let text: String
    public let author: String
}

public enum DailyQuotesCatalog {
    public static func quoteOfTheDay(on date: Date = Date(), calendar: Calendar = .cozy, lang: AppLanguage = CozyL10n.effective) -> DailyQuote {
        let dayOfYear = calendar.ordinality(of: .day, in: .year, for: date) ?? 1
        let idx = abs(dayOfYear - 1) % entries.count
        let entry = entries[idx]
        let code = lang.resolved
        let localized = entry.translations[code] ?? entry.translations[.en]!
        return DailyQuote(id: idx, text: localized, author: entry.author)
    }

    private struct Entry {
        let author: String
        let translations: [AppLanguage: String]
    }

    private static let entries: [Entry] = [
        Entry(author: "Marcus Aurelius", translations: [
            .en: "Focus on what is within your control, and let the rest go.",
            .vi: "Tập trung vào điều bạn kiểm soát được, và buông nhẹ phần còn lại.",
            .ja: "自分がコントロールできることに集中し、残りは手放そう。",
            .ko: "통제할 수 있는 것에 집중하고 나머지는 내려놓아라.",
            .zhHans: "专注于你能掌控的事，其余顺其自然。",
            .zhHant: "專注於你能掌控的事，其餘順其自然。",
            .es: "Concéntrate en lo que puedes controlar y deja ir el resto.",
            .fr: "Concentrez-vous sur ce que vous contrôlez, laissez aller le reste.",
            .de: "Konzentriere dich auf das, was du steuern kannst.",
            .ptBR: "Foque no que está sob seu controle e desapegue do resto.",
            .th: "โฟกัสในสิ่งที่คุณควบคุมได้ และปล่อยวางส่วนที่เหลือ",
            .id: "Fokus pada apa yang bisa kamu kendalikan, lepaskan sisanya.",
            .ru: "Сосредоточьтесь на том, что в вашей власти.",
            .it: "Concentrati su ciò che puoi controllare e lascia andare il resto.",
            .ar: "ركّز على ما يمكنك التحكم به، ودع الباقي يمضي."
        ]),
        Entry(author: "James Clear", translations: [
            .en: "Every small action today is a vote for the person you wish to become.",
            .vi: "Mỗi hành động nhỏ hôm nay là một phiếu bầu cho phiên bản bạn muốn trở thành.",
            .ja: "今日の小さな行動一つひとつが、なりたい自分への一票になる。",
            .ko: "오늘의 작은 행동 하나하나가 내가 되고 싶은 사람을 향한 투표다.",
            .zhHans: "今天的每一个微小行动，都是在为理想中的自己投票。",
            .zhHant: "今天的每一個微小行動，都是在為理想中的自己投票。",
            .es: "Cada pequeña acción hoy es un voto por quien deseas llegar a ser.",
            .fr: "Chaque petite action est un vote pour la personne que vous voulez devenir.",
            .de: "Jede kleine Tat heute formt den Menschen, der du sein willst.",
            .ptBR: "Cada pequena ação hoje constrói quem você deseja se tornar.",
            .th: "ทุกการกระทำเล็กๆ วันนี้ คือคะแนนเสียงให้ตัวคุณในอนาคต",
            .id: "Setiap langkah kecil hari ini membentuk dirimu di masa depan.",
            .ru: "Каждое малое действие сегодня создаёт вас будущего.",
            .it: "Ogni piccola azione oggi è un voto per chi desideri diventare.",
            .ar: "كل خطوة صغيرة اليوم تبني الشخص الذي تطمح أن تكونه."
        ]),
        Entry(author: "Seneca", translations: [
            .en: "Begin at once to live, and count each separate day as a separate life.",
            .vi: "Hãy sống trọn ngay lúc này, và trân trọng mỗi ngày như một cuộc đời riêng.",
            .ja: "今すぐ生き始めよ。一日一日をひとつの人生として数えよ。",
            .ko: "지금 당장 삶을 시작하고, 하루하루를 하나의 인생으로 여겨라.",
            .zhHans: "立刻开始生活，把每一天都当作独立的一生来珍惜。",
            .zhHant: "立刻開始生活，把每一天都當作獨立的一生來珍惜。",
            .es: "Empieza a vivir ahora y cuenta cada día como una vida entera.",
            .fr: "Commencez à vivre dès maintenant ; chaque jour est une vie.",
            .de: "Beginne sofort zu leben und zähle jeden Tag als eigenes Leben.",
            .ptBR: "Comece a viver agora e conte cada dia como uma vida única.",
            .th: "จงเริ่มใช้ชีวิตเดี๋ยวนี้ และนับแต่ละวันดั่งหนึ่งชีวิตที่มีค่า",
            .id: "Mulailah hidup hari ini, hargai setiap hari sebagai satu kehidupan.",
            .ru: "Начните жить прямо сейчас, цените каждый отдельный день.",
            .it: "Inizia subito a vivere e considera ogni singolo giorno come una vita.",
            .ar: "ابدأ الحياة الآن، واعتبر كل يوم جديد حياةً كاملة."
        ]),
        Entry(author: "Cal Newport", translations: [
            .en: "Clarity about what matters provides clarity about what does not.",
            .vi: "Rõ ràng về điều quan trọng sẽ giúp bạn dứt khoát bỏ qua điều xao nhãng.",
            .ja: "大切なものが明確になれば、不要なものも自然と明確になる。",
            .ko: "중요한 것이 명확해지면 중요하지 않은 것도 명확해진다.",
            .zhHans: "看清真正重要的事，自然就能放下无关紧要的事。",
            .zhHant: "看清真正重要的事，自然就能放下無關緊要的事。",
            .es: "Tener claro lo que importa aclara también lo que no importa.",
            .fr: "Savoir ce qui compte éclaire aussitôt ce qui ne compte pas.",
            .de: "Klarheit über das Wichtige schafft Klarheit über das Unwichtige.",
            .ptBR: "Clareza sobre o que importa traz clareza sobre o que não importa.",
            .th: "เมื่อชัดเจนในสิ่งสำคัญ คุณจะรู้ทันทีว่าสิ่งใดควรตัดทิ้ง",
            .id: "Kejelasan tentang hal penting membantumu mengabaikan gangguan.",
            .ru: "Ясность в главном даёт ясность в том, что не имеет значения.",
            .it: "La chiarezza su ciò che conta rivela ciò che è superfluo.",
            .ar: "الوضوح بشأن ما يهم يمنحك وضوحاً بشأن ما لا يهم."
        ]),
        Entry(author: "Naval Ravikant", translations: [
            .en: "Consistency beats intensity. Calmness is a superpower.",
            .vi: "Sự đều đặn thắng sự bốc đồng. Bình tĩnh chính là một siêu năng lực.",
            .ja: "継続は一時的な熱量に勝る。穏やかさは最強の武器だ。",
            .ko: "꾸준함이 강렬함을 이긴다. 평온함은 최고의 초능력이다.",
            .zhHans: "持之以恒胜过一时猛冲，内心平静是一种超能力。",
            .zhHant: "持之以恆勝過一時猛衝，內心平靜是一種超能力。",
            .es: "La constancia supera a la intensidad. La calma es un superpoder.",
            .fr: "La régularité bat l’intensité. Le calme est un super-pouvoir.",
            .de: "Beständigkeit schlägt Intensität. Ruhe ist eine Superkraft.",
            .ptBR: "Consistência vence intensidade. A calma é um superpoder.",
            .th: "ความสม่ำเสมอชนะความเร่งรีบ ความสงบคือพลังพิเศษ",
            .id: "Konsistensi mengalahkan intensitas. Ketenangan adalah kekuatan.",
            .ru: "Постоянство важнее рывков. Спокойствие — это суперсила.",
            .it: "La costanza batte l’intensità. La calma è un superpotere.",
            .ar: "الاستمرارية تغلب الاندفاع، والهدوء قوة خارقة."
        ]),
        Entry(author: "Leonardo da Vinci", translations: [
            .en: "Simplicity is the ultimate sophistication.",
            .vi: "Sự tối giản chính là đỉnh cao của sự tinh tế.",
            .ja: "シンプルさこそ、究極の洗練である。",
            .ko: "단순함이야말로 궁극의 정교함이다.",
            .zhHans: "至繁归于至简，简约是极致的优雅。",
            .zhHant: "至繁歸於至簡，簡約是極致的優雅。",
            .es: "La simplicidad es la máxima sofisticación.",
            .fr: "La simplicité est la sophistication suprême.",
            .de: "Einfachheit ist die höchste Stufe der Vollendung.",
            .ptBR: "A simplicidade é o último grau de sofisticação.",
            .th: "ความเรียบง่ายคือความประณีตขั้นสูงสุด",
            .id: "Kesederhanaan adalah kecanggihan tertinggi.",
            .ru: "Простота — это высшая степень утончённости.",
            .it: "La semplicità è l’ultima sofisticazione.",
            .ar: "البساطة هي قمة الرقي."
        ]),
        Entry(author: "Lao Tzu", translations: [
            .en: "Nature does not hurry, yet everything is accomplished.",
            .vi: "Tự nhiên chẳng hề vội vã, nhưng vạn vật đều hoàn thành trọn vẹn.",
            .ja: "自然は急がない。それでもすべては成し遂げられる。",
            .ko: "자연은 서두르지 않지만 모든 것을 이루어낸다.",
            .zhHans: "大自然从不匆忙，却万物皆成。",
            .zhHant: "大自然從不匆忙，卻萬物皆成。",
            .es: "La naturaleza no se apresura y, sin embargo, todo se logra.",
            .fr: "La nature ne se presse pas, pourtant tout s’accomplit.",
            .de: "Die Natur eilt nicht, und doch wird alles vollbracht.",
            .ptBR: "A natureza não tem pressa e, ainda assim, tudo se realiza.",
            .th: "ธรรมชาติไม่เคยเร่งรีบ แต่ทุกสิ่งล้วนสำเร็จงดงาม",
            .id: "Alam tidak pernah tergesa-gesa, namun segalanya terselesaikan.",
            .ru: "Природа не спешит, но всё успевает.",
            .it: "La natura non ha fretta, eppure tutto si compie.",
            .ar: "الطبيعة لا تتعجل، ومع ذلك يُنجز كل شيء."
        ])
    ]
}
