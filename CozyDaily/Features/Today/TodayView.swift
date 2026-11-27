import SwiftUI
import CozyCore

/// Tab 1 — Hôm nay (Today Hub).
struct TodayView: View {
    @Environment(AppModel.self) private var model
    @State private var showCheckIn = false
    @State private var showDecks = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    HeroHeader()
                    VocabCard(showDecks: $showDecks)
                    CheckInBar(showCheckIn: $showCheckIn)
                    WeatherCard()
                    UpcomingEventsCard()
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 24)
            }
            .background(Color.bgCream.ignoresSafeArea())
            .refreshable {
                await model.weather.refreshIfNeeded(force: true)
                model.refresh()
            }
            .toolbar(.hidden, for: .navigationBar)
            .sheet(isPresented: $showCheckIn) {
                CheckInSheet().presentationDetents([.large]).presentationCornerRadius(28)
            }
            .sheet(isPresented: $showDecks) {
                DeckPickerSheet().presentationDetents([.medium, .large])
            }
        }
    }
}

// MARK: - Hero

private struct HeroHeader: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        HStack(alignment: .center, spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
                Text(DayPart(date: model.now).greeting + ",")
                    .font(CozyFont.body(15, weight: .medium))
                    .foregroundStyle(Color.inkTaupe)
                Text(model.settings.displayName)
                    .font(CozyFont.title(30, weight: .heavy))
                    .foregroundStyle(Color.inkCoffee)
                Text(dateLine)
                    .font(CozyFont.body(13))
                    .foregroundStyle(Color.inkTaupe)
                Text(model.mascot.caption)
                    .font(CozyFont.body(13, weight: .medium))
                    .foregroundStyle(Color.inkCoffee)
                    .padding(.top, 2)
            }
            Spacer()
            MascotView(state: model.mascot, size: 96)
        }
        .padding(.top, 12)
    }

    var dateLine: String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "vi_VN")
        f.dateFormat = "EEEE, d MMMM"
        let lunar = model.lunarToday
        return "\(f.string(from: model.now).capitalized) · \(lunar.shortText) ÂL \(lunar.yearName)"
    }
}

// MARK: - Vocab

private struct VocabCard: View {
    @Environment(AppModel.self) private var model
    @Binding var showDecks: Bool
    @State private var revealed = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            CozySectionHeader(
                title: "Từ vựng hôm nay",
                symbol: "character.book.closed.fill",
                accent: .accentSage,
                trailing: "🔥 \(model.streak) ngày · \(model.dueCount) cần ôn"
            )
            if let w = model.currentWord {
                HStack(alignment: .firstTextBaseline) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(w.word)
                            .font(.system(size: 30, weight: .bold, design: .serif))
                            .foregroundStyle(Color.inkCoffee)
                        Text(w.phonetic)
                            .font(.system(size: 14, design: .monospaced))
                            .foregroundStyle(Color.inkTaupe)
                    }
                    Spacer()
                    Button { model.speak(w) } label: {
                        Image(systemName: "speaker.wave.2.fill")
                            .font(.system(size: 16, weight: .semibold))
                            .frame(width: 40, height: 40)
                            .background(Circle().fill(Color.accentSage.opacity(0.15)))
                            .foregroundStyle(Color.accentSage)
                    }
                    .accessibilityLabel("Phát âm")
                }

                Button {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) { revealed.toggle() }
                } label: {
                    VStack(alignment: .leading, spacing: 6) {
                        if revealed {
                            Text(w.meaning)
                                .font(CozyFont.title(18, weight: .semibold))
                                .foregroundStyle(Color.inkCoffee)
                            Text("“\(w.example)”")
                                .font(.system(size: 14, design: .serif).italic())
                                .foregroundStyle(Color.inkTaupe)
                        } else {
                            Label("Chạm để xem nghĩa — thử đoán trước nhé!", systemImage: "eye.slash")
                                .font(CozyFont.body(14, weight: .medium))
                                .foregroundStyle(Color.inkTaupe)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(12)
                    .background(RoundedRectangle(cornerRadius: 16).fill(Color.accentSage.opacity(0.08)))
                }
                .buttonStyle(.plain)

                HStack(spacing: 8) {
                    Button { revealed = false; model.markLearned() } label: { Label("Đã thuộc", systemImage: "checkmark") }
                        .buttonStyle(CozyPillButtonStyle(tint: .accentSage))
                    Button { revealed = false; model.skipWord() } label: { Label("Đổi từ", systemImage: "shuffle") }
                        .buttonStyle(CozyPillButtonStyle(tint: .accentSage, filled: false))
                    Button { revealed = false; model.forgotWord() } label: { Text("Quên rồi") }
                        .buttonStyle(CozyPillButtonStyle(tint: .inkTaupe, filled: false))
                    Spacer()
                    Button { showDecks = true } label: { Image(systemName: "slider.horizontal.3") }
                        .foregroundStyle(Color.inkTaupe)
                        .accessibilityLabel("Chọn kho từ")
                }

                if let s = model.reviewState(for: w) {
                    StageDots(stage: s.stage)
                }
            } else {
                Text("Chưa có từ nào trong kho đã chọn.")
                    .foregroundStyle(Color.inkTaupe)
                Button("Chọn kho từ vựng") { showDecks = true }
                    .buttonStyle(CozyPillButtonStyle(tint: .accentSage))
            }
        }
        .cozyCard(accent: .accentSage)
    }
}

private struct StageDots: View {
    var stage: Int

    var body: some View {
        HStack(spacing: 6) {
            ForEach(Array(SpacedRepetition.intervals.enumerated()), id: \.offset) { i, days in
                VStack(spacing: 2) {
                    Circle()
                        .fill(i < stage ? Color.accentSage : Color.accentSage.opacity(0.2))
                        .frame(width: 10, height: 10)
                    Text("\(days)n").font(.system(size: 9, weight: .medium)).foregroundStyle(Color.inkTaupe)
                }
            }
            Text("Chu kỳ ôn tập").font(.system(size: 11)).foregroundStyle(Color.inkTaupe)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Đã qua \(stage) trên \(SpacedRepetition.intervals.count) chu kỳ ôn")
    }
}

private struct DeckPickerSheet: View {
    @Environment(AppModel.self) private var model
    @State private var newWord = ""
    @State private var newMeaning = ""
    @State private var newPhonetic = ""
    @State private var newExample = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Kho từ vựng") {
                    ForEach(VocabDeck.allCases) { deck in
                        Toggle(isOn: Binding(
                            get: { model.settings.activeDecks.contains(deck) },
                            set: { model.setDeck(deck, active: $0) }
                        )) {
                            Label(deck.displayName, systemImage: "book").labelStyle(DeckLabel(emoji: deck.emoji))
                        }
                    }
                }
                Section("Thêm từ của bạn") {
                    TextField("Từ / cụm từ tiếng Anh", text: $newWord).textInputAutocapitalization(.never)
                    TextField("Phiên âm (tùy chọn)", text: $newPhonetic)
                    TextField("Nghĩa tiếng Việt", text: $newMeaning)
                    TextField("Câu ví dụ (tùy chọn)", text: $newExample)
                    Button("Thêm vào “Bộ từ của tôi”") {
                        model.addCustomWord(VocabWord(word: newWord, phonetic: newPhonetic, meaning: newMeaning, example: newExample, deck: .custom))
                        newWord = ""; newMeaning = ""; newPhonetic = ""; newExample = ""
                    }
                    .disabled(newWord.trimmingCharacters(in: .whitespaces).isEmpty || newMeaning.isEmpty)
                }
                if !model.snapshot.customWords.isEmpty {
                    Section("Bộ từ của tôi (\(model.snapshot.customWords.count))") {
                        ForEach(model.snapshot.customWords) { w in
                            VStack(alignment: .leading) {
                                Text(w.word).font(.headline)
                                Text(w.meaning).font(.subheadline).foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Từ vựng")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

private struct DeckLabel: LabelStyle {
    var emoji: String
    func makeBody(configuration: Configuration) -> some View {
        HStack { Text(emoji); configuration.title }
    }
}

// MARK: - Check-in bar

private struct CheckInBar: View {
    @Environment(AppModel.self) private var model
    @Binding var showCheckIn: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            CozySectionHeader(title: "Mood & Món ăn", symbol: "face.smiling", accent: .accentPeach, trailing: model.latestCheckInToday.map { timeString($0.date) })
            if let c = model.latestCheckInToday {
                HStack(spacing: 12) {
                    Text(c.mood.emoji).font(.system(size: 40))
                    VStack(alignment: .leading, spacing: 4) {
                        Text(c.mood.displayName).font(CozyFont.title(18)).foregroundStyle(Color.inkCoffee)
                        if !c.foods.isEmpty {
                            Text(c.foods.map { "\($0.emoji) \($0.displayName)" }.joined(separator: " · "))
                                .font(CozyFont.body(13)).foregroundStyle(Color.inkTaupe)
                        }
                        if !c.note.isEmpty {
                            Text("“\(c.note)”").font(CozyFont.body(13).italic()).foregroundStyle(Color.inkCoffee)
                        }
                    }
                }
                BatteryBar(value: c.socialBattery, tint: .accentPeach)
            }
            // Check-in 1 chạm: chạm emoji để ghi nhanh, giữ món ăn & pin lần trước.
            HStack(spacing: 6) {
                ForEach(Mood.allCases) { mood in
                    Button {
                        let last = model.latestCheckInToday
                        model.checkIn(mood: mood, foods: last?.foods ?? [], battery: last?.socialBattery ?? 60, note: last?.note ?? "")
                    } label: {
                        Text(mood.emoji)
                            .font(.system(size: 24))
                            .frame(maxWidth: .infinity, minHeight: 42)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(model.latestCheckInToday?.mood == mood ? Color.accentPeach.opacity(0.3) : Color.accentPeach.opacity(0.08))
                            )
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(mood.displayName)
                }
            }
            Button { showCheckIn = true } label: {
                Label("Check-in đầy đủ (món ăn, pin xã hội, note)", systemImage: "square.and.pencil")
            }
            .buttonStyle(CozyPillButtonStyle(tint: .accentPeach, filled: false))
        }
        .cozyCard(accent: .accentPeach)
    }

    func timeString(_ d: Date) -> String {
        d.formatted(date: .omitted, time: .shortened)
    }
}

struct CheckInSheet: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    @State private var mood: Mood = .chill
    @State private var foods: Set<FoodSticker> = []
    @State private var battery: Double = 60
    @State private var note = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Bạn thấy thế nào?").font(CozyFont.title(18))
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 10) {
                        ForEach(Mood.allCases) { m in
                            Button { mood = m } label: {
                                VStack(spacing: 4) {
                                    Text(m.emoji).font(.system(size: 30))
                                    Text(m.displayName).font(.system(size: 11, weight: .medium))
                                }
                                .frame(maxWidth: .infinity, minHeight: 72)
                                .background(RoundedRectangle(cornerRadius: 16).fill(mood == m ? Color.accentPeach.opacity(0.3) : Color.cardIvory))
                                .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(Color.cardBorder))
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    Text("Hôm nay ăn gì?").font(CozyFont.title(18))
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 10) {
                        ForEach(FoodSticker.allCases) { f in
                            Button {
                                if foods.contains(f) { foods.remove(f) } else { foods.insert(f) }
                            } label: {
                                VStack(spacing: 4) {
                                    Text(f.emoji).font(.system(size: 28))
                                    Text(f.displayName).font(.system(size: 11, weight: .medium)).lineLimit(1)
                                }
                                .frame(maxWidth: .infinity, minHeight: 68)
                                .background(RoundedRectangle(cornerRadius: 16).fill(foods.contains(f) ? Color.accentHoney.opacity(0.35) : Color.cardIvory))
                                .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(Color.cardBorder))
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    VStack(alignment: .leading) {
                        Text("Pin xã hội: \(Int(battery))%").font(CozyFont.title(18))
                        Slider(value: $battery, in: 0...100, step: 5).tint(Color.accentPeach)
                        Text(battery < 30 ? "Cần sạc pin một mình 🔌" : battery > 75 ? "Sẵn sàng quẩy! 🎉" : "Vừa đủ để gặp bạn thân ☕️")
                            .font(.caption).foregroundStyle(Color.inkTaupe)
                    }

                    VStack(alignment: .leading) {
                        Text("Note ngắn").font(CozyFont.title(18))
                        TextField("Tối đa 30 ký tự", text: $note)
                            .padding(12)
                            .background(RoundedRectangle(cornerRadius: 14).fill(Color.cardIvory))
                            .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Color.cardBorder))
                            .onChange(of: note) { _, v in if v.count > CozyMetrics.noteMaxLength { note = String(v.prefix(CozyMetrics.noteMaxLength)) } }
                        Text("\(note.count)/\(CozyMetrics.noteMaxLength)").font(.caption2).foregroundStyle(Color.inkTaupe)
                    }
                }
                .padding(20)
            }
            .background(Color.bgCream)
            .navigationTitle("Check-in")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Đóng") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Lưu") {
                        model.checkIn(mood: mood, foods: FoodSticker.allCases.filter(foods.contains), battery: Int(battery), note: note)
                        dismiss()
                    }
                    .bold()
                }
            }
            .onAppear {
                if let c = model.latestCheckInToday {
                    mood = c.mood
                    foods = Set(c.foods)
                    battery = Double(c.socialBattery)
                    note = c.note
                }
            }
        }
    }
}

// MARK: - Weather

private struct WeatherCard: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            CozySectionHeader(title: "Thời tiết & Gợi ý", symbol: "cloud.sun.fill", accent: .accentSky, trailing: model.snapshot.weather.map { "cập nhật \($0.fetchedAt.formatted(date: .omitted, time: .shortened))" })
            if let w = model.snapshot.weather {
                HStack(alignment: .center) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(w.temperatureText).font(CozyFont.number(44)).foregroundStyle(Color.inkCoffee)
                        Label(w.condition.displayName, systemImage: w.condition.symbolName)
                            .symbolRenderingMode(.multicolor)
                            .font(CozyFont.body(14, weight: .semibold))
                        Text("\(w.placeName) · cảm giác \(Int(w.apparentC))° · C:\(Int(w.highC))° T:\(Int(w.lowC))°")
                            .font(CozyFont.body(12)).foregroundStyle(Color.inkTaupe)
                    }
                    Spacer()
                }
                Text(WeatherSuggestion.outfit(for: w)).font(CozyFont.body(14, weight: .medium)).foregroundStyle(Color.inkCoffee)
                HStack(spacing: 8) {
                    ForEach(WeatherSuggestion.foods(for: w)) { f in
                        Text("\(f.emoji) \(f.displayName)")
                            .font(CozyFont.body(13, weight: .medium))
                            .padding(.horizontal, 10).padding(.vertical, 6)
                            .background(Capsule().fill(Color.accentHoney.opacity(0.18)))
                    }
                }
                if model.settings.shareWeatherWithSpaces {
                    Label("Đang chia sẻ thời tiết với người yêu & nhóm bạn", systemImage: "person.2.wave.2")
                        .font(.caption).foregroundStyle(Color.inkTaupe)
                }
            } else {
                Text("Cho phép vị trí để xem thời tiết và gợi ý món ăn theo trời nhé.")
                    .font(CozyFont.body(14)).foregroundStyle(Color.inkTaupe)
            }
        }
        .cozyCard(accent: .accentSky)
    }
}

// MARK: - Events

private struct UpcomingEventsCard: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            CozySectionHeader(title: "Sắp tới", symbol: "calendar", accent: .accentSky, trailing: nil)
            ForEach(model.upcomingEvents()) { e in
                EventRow(event: e, status: model.status(of: e))
            }
        }
        .cozyCard()
    }
}

struct EventRow: View {
    var event: CozyEvent
    var status: EventStatus

    var body: some View {
        HStack(spacing: 12) {
            Text(event.emoji)
                .font(.system(size: 22))
                .frame(width: 44, height: 44)
                .background(RoundedRectangle(cornerRadius: 14).fill(event.accent.color.opacity(0.18)))
            VStack(alignment: .leading, spacing: 2) {
                Text(event.title).font(CozyFont.body(15, weight: .semibold)).foregroundStyle(Color.inkCoffee)
                HStack(spacing: 4) {
                    Image(systemName: event.kind.symbolName)
                    Text(event.kind.modeName)
                    if event.isShared { Image(systemName: "person.2.fill") }
                }
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(Color.inkTaupe)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 0) {
                Text(status.headline).font(CozyFont.number(22)).foregroundStyle(status.direction == .overdue ? Color.accentPeach : Color.inkCoffee)
                Text(status.caption).font(.system(size: 10, weight: .medium)).foregroundStyle(Color.inkTaupe)
            }
        }
        .accessibilityElement(children: .combine)
    }
}
