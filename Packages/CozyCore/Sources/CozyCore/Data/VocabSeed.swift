import Foundation

/// Kho từ vựng mẫu đi kèm app (offline). Có thể mở rộng bằng file JSON ở giai đoạn sau.
public enum VocabSeed {
    public static let all: [VocabWord] = daily + idioms + exam + healing

    public static let daily: [VocabWord] = [
        VocabWord(word: "grab a bite", phonetic: "/ɡræb ə baɪt/", meaning: "ăn nhanh một chút", example: "Let's grab a bite before the movie.", deck: .daily),
        VocabWord(word: "run late", phonetic: "/rʌn leɪt/", meaning: "bị trễ giờ", example: "Sorry, I'm running a bit late!", deck: .daily),
        VocabWord(word: "catch up", phonetic: "/kætʃ ʌp/", meaning: "hàn huyên, cập nhật tình hình", example: "We should catch up this weekend.", deck: .daily),
        VocabWord(word: "hang out", phonetic: "/hæŋ aʊt/", meaning: "đi chơi, tụ tập", example: "Do you want to hang out later?", deck: .daily),
        VocabWord(word: "take a rain check", phonetic: "/teɪk ə reɪn tʃek/", meaning: "hẹn dịp khác", example: "Can I take a rain check on dinner?", deck: .daily),
        VocabWord(word: "errand", phonetic: "/ˈer.ənd/", meaning: "việc vặt", example: "I have a few errands to run.", deck: .daily),
        VocabWord(word: "leftovers", phonetic: "/ˈleftˌoʊ.vɚz/", meaning: "đồ ăn thừa", example: "We'll have leftovers for lunch.", deck: .daily),
        VocabWord(word: "commute", phonetic: "/kəˈmjuːt/", meaning: "quãng đường đi làm hằng ngày", example: "My commute takes 30 minutes.", deck: .daily),
        VocabWord(word: "doze off", phonetic: "/doʊz ɔːf/", meaning: "ngủ gật", example: "I dozed off on the bus.", deck: .daily),
        VocabWord(word: "treat yourself", phonetic: "/triːt jɔːrˈself/", meaning: "tự thưởng cho bản thân", example: "You worked hard — treat yourself!", deck: .daily),
    ]

    public static let idioms: [VocabWord] = [
        VocabWord(word: "a piece of cake", phonetic: "/ə piːs əv keɪk/", meaning: "dễ như ăn bánh", example: "The test was a piece of cake.", deck: .idioms),
        VocabWord(word: "under the weather", phonetic: "/ˈʌn.dɚ ðə ˈweð.ɚ/", meaning: "hơi mệt, không khỏe", example: "I'm feeling a bit under the weather.", deck: .idioms),
        VocabWord(word: "spill the tea", phonetic: "/spɪl ðə tiː/", meaning: "kể chuyện 'hot', buôn dưa lê", example: "Come on, spill the tea!", deck: .idioms),
        VocabWord(word: "hit the sack", phonetic: "/hɪt ðə sæk/", meaning: "đi ngủ", example: "I'm exhausted, time to hit the sack.", deck: .idioms),
        VocabWord(word: "vibe check", phonetic: "/vaɪb tʃek/", meaning: "kiểm tra 'năng lượng'/tâm trạng", example: "Quick vibe check: how's everyone?", deck: .idioms),
        VocabWord(word: "once in a blue moon", phonetic: "/wʌns ɪn ə bluː muːn/", meaning: "hiếm khi, năm thì mười họa", example: "We eat out once in a blue moon.", deck: .idioms),
        VocabWord(word: "break the ice", phonetic: "/breɪk ði aɪs/", meaning: "phá vỡ sự ngại ngùng", example: "A joke helped break the ice.", deck: .idioms),
        VocabWord(word: "low-key", phonetic: "/ˌloʊˈkiː/", meaning: "kín đáo; 'thật ra là'", example: "I low-key want bubble tea.", deck: .idioms),
        VocabWord(word: "on cloud nine", phonetic: "/ɑːn klaʊd naɪn/", meaning: "vui sướng tột độ", example: "She's been on cloud nine all week.", deck: .idioms),
        VocabWord(word: "call it a day", phonetic: "/kɔːl ɪt ə deɪ/", meaning: "nghỉ tay, kết thúc công việc", example: "Let's call it a day.", deck: .idioms),
    ]

    public static let exam: [VocabWord] = [
        VocabWord(word: "mitigate", phonetic: "/ˈmɪt̬.ə.ɡeɪt/", meaning: "giảm nhẹ, làm dịu", example: "Trees help mitigate urban heat.", deck: .exam),
        VocabWord(word: "substantial", phonetic: "/səbˈstæn.ʃəl/", meaning: "đáng kể", example: "There was a substantial increase in sales.", deck: .exam),
        VocabWord(word: "inevitable", phonetic: "/ɪˈnev.ə.t̬ə.bəl/", meaning: "không thể tránh khỏi", example: "Change is inevitable.", deck: .exam),
        VocabWord(word: "allocate", phonetic: "/ˈæl.ə.keɪt/", meaning: "phân bổ", example: "Allocate time for rest.", deck: .exam),
        VocabWord(word: "prominent", phonetic: "/ˈprɑː.mə.nənt/", meaning: "nổi bật, quan trọng", example: "She is a prominent researcher.", deck: .exam),
        VocabWord(word: "deteriorate", phonetic: "/dɪˈtɪr.i.ə.reɪt/", meaning: "xấu đi, suy giảm", example: "Air quality has deteriorated.", deck: .exam),
        VocabWord(word: "feasible", phonetic: "/ˈfiː.zə.bəl/", meaning: "khả thi", example: "Is the plan feasible?", deck: .exam),
        VocabWord(word: "consensus", phonetic: "/kənˈsen.səs/", meaning: "sự đồng thuận", example: "We reached a consensus.", deck: .exam),
        VocabWord(word: "commence", phonetic: "/kəˈmens/", meaning: "bắt đầu (trang trọng)", example: "The meeting will commence at 9.", deck: .exam),
        VocabWord(word: "fluctuate", phonetic: "/ˈflʌk.tʃu.eɪt/", meaning: "dao động, lên xuống", example: "Prices fluctuate daily.", deck: .exam),
    ]

    public static let healing: [VocabWord] = [
        VocabWord(word: "serene", phonetic: "/səˈriːn/", meaning: "thanh bình, tĩnh lặng", example: "A serene morning by the lake.", deck: .healing),
        VocabWord(word: "cozy", phonetic: "/ˈkoʊ.zi/", meaning: "ấm cúng", example: "This café feels so cozy.", deck: .healing),
        VocabWord(word: "resilient", phonetic: "/rɪˈzɪl.jənt/", meaning: "kiên cường, mau hồi phục", example: "You are more resilient than you think.", deck: .healing),
        VocabWord(word: "unwind", phonetic: "/ʌnˈwaɪnd/", meaning: "thư giãn, xả hơi", example: "I unwind with a cup of tea.", deck: .healing),
        VocabWord(word: "gratitude", phonetic: "/ˈɡræt̬.ə.tuːd/", meaning: "lòng biết ơn", example: "Start the day with gratitude.", deck: .healing),
        VocabWord(word: "self-compassion", phonetic: "/ˌself kəmˈpæʃ.ən/", meaning: "lòng trắc ẩn với bản thân", example: "Practice self-compassion on hard days.", deck: .healing),
        VocabWord(word: "bloom", phonetic: "/bluːm/", meaning: "nở rộ, phát triển", example: "Let yourself bloom slowly.", deck: .healing),
        VocabWord(word: "solace", phonetic: "/ˈsɑː.lɪs/", meaning: "niềm an ủi", example: "Music is my solace.", deck: .healing),
        VocabWord(word: "hygge", phonetic: "/ˈhjuː.ɡə/", meaning: "cảm giác ấm áp, thư thái (Đan Mạch)", example: "Candles and blankets — pure hygge.", deck: .healing),
        VocabWord(word: "breathe", phonetic: "/briːð/", meaning: "hít thở", example: "Just breathe. You're doing fine.", deck: .healing),
    ]
}
