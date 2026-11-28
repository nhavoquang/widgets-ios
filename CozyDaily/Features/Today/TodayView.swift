import SwiftUI
import CozyCore

/// Tab 1 — Hôm nay (Today Hub).
struct TodayView: View {
    @Environment(AppModel.self) private var model
    @State private var showCheckIn = false
    @State private var showDecks = false
    @State private var showSettings = false

    var body: some View {
        NavigationStack {
            ZStack {
                CozyAmbientBackground()
                ScrollView {
                    VStack(spacing: 16) {
                        HeroHeader(showSettings: $showSettings)
                        QuickStatsStrip()
                        VocabCard(showDecks: $showDecks)
                        CheckInBar(showCheckIn: $showCheckIn)
                        WeatherCard()
                        UpcomingEventsCard()
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 28)
                }
                .refreshable {
                    await model.weather.refreshIfNeeded(force: true)
                    model.refresh()
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .sheet(isPresented: $showCheckIn) {
                CheckInSheet().presentationDetents([.large]).presentationCornerRadius(28)
            }
            .sheet(isPresented: $showSettings) { SettingsSheet() }
            .sheet(isPresented: $showDecks) {
                DeckPickerSheet().presentationDetents([.medium, .large])
            }
        }
    }
}

// MARK: - Hero

private struct HeroHeader: View {
    @Environment(AppModel.self) private var model
    @Binding var showSettings: Bool
    @State private var petCount = 0
    @State private var showHearts = false

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Thanh ngày âm dương + nút Cài đặt gọn xinh
            HStack(spacing: 8) {
                CozyBadgePill(text: shortDateLine, symbol: "sparkles", tint: .accentHoney)
                Spacer(minLength: 4)
                Button {
                    Haptics.tap()
                    showSettings = true
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: "slider.horizontal.3")
                            .font(.system(size: 13, weight: .bold))
                        Text("Cài đặt")
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                    }
                    .foregroundStyle(Color.inkCoffee)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .background(Capsule().fill(Color.cardIvory))
                    .overlay(Capsule().strokeBorder(Color.cardBorder, lineWidth: 1))
                    .shadow(color: Color.inkCoffee.opacity(0.06), radius: 6, y: 2)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Mở cài đặt")
            }

            // Thẻ chào ấm áp kèm linh vật chạm được
            HStack(alignment: .center, spacing: 14) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(DayPart(date: model.now).greeting + ",")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundStyle(Color.inkTaupe)
                    Text(model.settings.displayName)
                        .font(CozyFont.title(28, weight: .heavy))
                        .foregroundStyle(Color.inkCoffee)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                    CozySpeechBubble(text: model.mascot.caption, tint: .accentPeach)
                }
                Spacer(minLength: 0)
                Button { petMascot() } label: {
                    ZStack {
                        AnimatedMascotView(
                            state: model.mascot,
                            size: 100,
                            reaction: [
                                model.latestCheckInToday?.mood.rawValue ?? "",
                                "\(petCount)"
                            ] + (model.latestCheckInToday?.foods.map(\.rawValue) ?? [])
                        )
                        if showHearts {
                            VStack(spacing: 2) {
                                Text("💕")
                                    .font(.system(size: 18))
                                    .offset(x: 10)
                                Text("✨")
                                    .font(.system(size: 13))
                                    .offset(x: -14)
                            }
                            .offset(y: -48)
                            .transition(.scale(scale: 0.4).combined(with: .opacity))
                        }
                    }
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Nựng \(model.settings.species.displayName)")
            }
            .cozyCard(accent: .accentPeach, padding: 16)
        }
        .padding(.top, 8)
    }

    private func petMascot() {
        petCount += 1
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) { showHearts = true }
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(900))
            withAnimation(.easeOut(duration: 0.3)) { showHearts = false }
        }
    }

    private var shortDateLine: String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "vi_VN")
        f.dateFormat = "EEE, d/M"
        let lunar = model.lunarToday
        return "\(f.string(from: model.now).capitalized) · \(lunar.shortText) ÂL"
    }
}

private struct QuickStatsStrip: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                CozyBadgePill(text: "🔥 Chuỗi \(model.streak) ngày", symbol: nil, tint: .accentPeach)
                CozyBadgePill(text: "✨ \(model.learnedToday) từ hôm nay", symbol: nil, tint: .accentSage)
                if model.dueCount > 0 {
                    CozyBadgePill(text: "📖 \(model.dueCount) cần ôn", symbol: nil, tint: .accentSky)
                }
                if let holiday = HolidayDetector.holiday(on: model.now) {
                    CozyBadgePill(text: "\(holiday.emoji) \(holiday.name)", symbol: nil, tint: .accentHoney)
                }
            }
        }
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
                trailing: "🔥 \(model.streak) ngày · \(model.dueCount) cần ôn",
                animatedIcon: .vocab
            )
            if let w = model.currentWord {
                HStack(alignment: .center) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(w.word)
                            .font(.system(size: 30, weight: .bold, design: .serif))
                            .foregroundStyle(Color.inkCoffee)
                            .cozySwap(w.id)
                        Text(w.phonetic)
                            .font(.system(size: 14, design: .monospaced))
                            .foregroundStyle(Color.inkTaupe)
                    }
                    Spacer()
                    Button {
                        Haptics.tap()
                        model.speak(w)
                    } label: {
                        Image(systemName: "speaker.wave.2.fill")
                            .font(.system(size: 16, weight: .semibold))
                            .frame(width: 42, height: 42)
                            .background(Circle().fill(Color.accentSage.opacity(0.16)))
                            .overlay(Circle().strokeBorder(Color.accentSage.opacity(0.3), lineWidth: 1))
                            .foregroundStyle(Color.accentSage)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Phát âm")
                }

                Button {
                    Haptics.tap()
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.78)) { revealed.toggle() }
                } label: {
                    VStack(alignment: .leading, spacing: 6) {
                        if revealed {
                            HStack(spacing: 6) {
                                Text("✨").font(.system(size: 14))
                                Text(w.meaning)
                                    .font(CozyFont.title(18, weight: .bold))
                                    .foregroundStyle(Color.inkCoffee)
                            }
                            if !w.example.isEmpty {
                                Text("“\(w.example)”")
                                    .font(.system(size: 14, design: .serif).italic())
                                    .foregroundStyle(Color.inkTaupe)
                            }
                        } else {
                            HStack(spacing: 8) {
                                Image(systemName: "sparkles")
                                    .foregroundStyle(Color.accentSage)
                                Text("Chạm để lật nghĩa — thử đoán trước nha!")
                                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                                    .foregroundStyle(Color.inkTaupe)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(14)
                    .background(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(revealed ? Color.accentSage.opacity(0.14) : Color.bgCream)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .strokeBorder(
                                Color.accentSage.opacity(revealed ? 0.35 : 0.4),
                                style: revealed ? StrokeStyle(lineWidth: 1) : StrokeStyle(lineWidth: 1.2, dash: [5, 4])
                            )
                    )
                }
                .buttonStyle(.plain)

                HStack(spacing: 8) {
                    Button { revealed = false; model.markLearned() } label: { Label("Đã thuộc", systemImage: "checkmark") }
                        .buttonStyle(CozyPillButtonStyle(tint: .accentSage))
                    Button { revealed = false; model.skipWord() } label: { Label("Đổi từ", systemImage: "shuffle") }
                        .buttonStyle(CozyPillButtonStyle(tint: .accentSage, filled: false))
                    Button { revealed = false; model.forgotWord() } label: { Text("Quên") }
                        .buttonStyle(CozyPillButtonStyle(tint: .inkTaupe, filled: false))
                    Spacer(minLength: 0)
                    Button {
                        Haptics.tap()
                        showDecks = true
                    } label: {
                        Image(systemName: "books.vertical.fill")
                            .font(.system(size: 15))
                            .frame(width: 36, height: 36)
                            .background(Circle().fill(Color.bgCream))
                            .foregroundStyle(Color.inkTaupe)
                    }
                    .buttonStyle(.plain)
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
            CozySectionHeader(
                title: "Mood & Món ăn",
                symbol: "face.smiling",
                accent: .accentPeach,
                trailing: model.latestCheckInToday.map { timeString($0.date) },
                animatedIcon: .mood
            )
            if let c = model.latestCheckInToday {
                HStack(spacing: 12) {
                    Text(c.mood.emoji)
                        .font(.system(size: 36))
                        .frame(width: 54, height: 54)
                        .background(Circle().fill(Color.accentPeach.opacity(0.16)))
                    VStack(alignment: .leading, spacing: 4) {
                        Text(c.mood.displayName)
                            .font(CozyFont.title(18))
                            .foregroundStyle(Color.inkCoffee)
                        if !c.foods.isEmpty {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 6) {
                                    ForEach(c.foods) { f in
                                        Text("\(f.emoji) \(f.displayName)")
                                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                                            .foregroundStyle(Color.inkCoffee)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 4)
                                            .background(Capsule().fill(Color.accentHoney.opacity(0.2)))
                                    }
                                }
                            }
                        }
                        if !c.note.isEmpty {
                            Text("“\(c.note)”")
                                .font(.custom("Noteworthy-Bold", size: 14, relativeTo: .body))
                                .foregroundStyle(Color.inkCoffee)
                        }
                    }
                }
                BatteryBar(value: c.socialBattery, tint: .accentPeach)
            }
            // Check-in 1 chạm: chạm emoji để ghi nhanh, giữ món ăn & pin lần trước.
            HStack(spacing: 6) {
                ForEach(Mood.allCases) { mood in
                    let isSelected = model.latestCheckInToday?.mood == mood
                    Button {
                        let last = model.latestCheckInToday
                        model.checkIn(mood: mood, foods: last?.foods ?? [], battery: last?.socialBattery ?? 60, note: last?.note ?? "")
                        Haptics.tap()
                    } label: {
                        Text(mood.emoji)
                            .font(.system(size: isSelected ? 26 : 23))
                            .frame(maxWidth: .infinity, minHeight: 44)
                            .background(
                                RoundedRectangle(cornerRadius: 15, style: .continuous)
                                    .fill(isSelected ? Color.accentPeach.opacity(0.28) : Color.bgCream)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 15, style: .continuous)
                                    .strokeBorder(isSelected ? Color.accentPeach : Color.cardBorder.opacity(0.8), lineWidth: isSelected ? 1.8 : 1)
                            )
                            .scaleEffect(isSelected ? 1.05 : 1)
                    }
                    .buttonStyle(.plain)
                    .animation(.spring(response: 0.28, dampingFraction: 0.65), value: isSelected)
                    .accessibilityLabel(mood.displayName)
                }
            }
            Button {
                Haptics.tap()
                showCheckIn = true
            } label: {
                Label("Check-in đầy đủ (món ăn, pin xã hội, note)", systemImage: "square.and.pencil")
                    .frame(maxWidth: .infinity)
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
            ZStack {
                CozyAmbientBackground()
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        Text("Bạn thấy thế nào?").font(CozyFont.title(18)).foregroundStyle(Color.inkCoffee)
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 10) {
                            ForEach(Mood.allCases) { m in
                                Button {
                                    mood = m
                                    Haptics.tap()
                                } label: {
                                    VStack(spacing: 4) {
                                        Text(m.emoji).font(.system(size: 30))
                                        Text(m.displayName).font(.system(size: 11, weight: .semibold, design: .rounded))
                                    }
                                    .frame(maxWidth: .infinity, minHeight: 74)
                                    .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(mood == m ? Color.accentPeach.opacity(0.28) : Color.cardIvory))
                                    .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).strokeBorder(mood == m ? Color.accentPeach : Color.cardBorder, lineWidth: mood == m ? 1.8 : 1))
                                }
                                .buttonStyle(.plain)
                            }
                        }

                        Text("Hôm nay ăn gì?").font(CozyFont.title(18)).foregroundStyle(Color.inkCoffee)
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 10) {
                            ForEach(FoodSticker.allCases) { f in
                                Button {
                                    if foods.contains(f) { foods.remove(f) } else { foods.insert(f) }
                                    Haptics.tap()
                                } label: {
                                    VStack(spacing: 4) {
                                        Text(f.emoji).font(.system(size: 28))
                                        Text(f.displayName).font(.system(size: 11, weight: .semibold, design: .rounded)).lineLimit(1)
                                    }
                                    .frame(maxWidth: .infinity, minHeight: 70)
                                    .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(foods.contains(f) ? Color.accentHoney.opacity(0.32) : Color.cardIvory))
                                    .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).strokeBorder(foods.contains(f) ? Color.accentHoney : Color.cardBorder, lineWidth: foods.contains(f) ? 1.8 : 1))
                                }
                                .buttonStyle(.plain)
                            }
                        }

                        VStack(alignment: .leading, spacing: 6) {
                            Text("Pin xã hội: \(Int(battery))%").font(CozyFont.title(18)).foregroundStyle(Color.inkCoffee)
                            Slider(value: $battery, in: 0...100, step: 5).tint(Color.accentPeach)
                            Text(battery < 30 ? "Cần sạc pin một mình 🔌" : battery > 75 ? "Sẵn sàng quẩy! 🎉" : "Vừa đủ để gặp bạn thân ☕️")
                                .font(.caption).foregroundStyle(Color.inkTaupe)
                        }
                        .cozyCard(padding: 14)

                        VStack(alignment: .leading, spacing: 6) {
                            Text("Note ngắn").font(CozyFont.title(18)).foregroundStyle(Color.inkCoffee)
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
            }
            .navigationTitle("Check-in")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Đóng") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Lưu") {
                        model.checkIn(mood: mood, foods: FoodSticker.allCases.filter(foods.contains), battery: Int(battery), note: note)
                        Haptics.success()
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
            CozySectionHeader(
                title: "Thời tiết & Gợi ý",
                symbol: "cloud.sun.fill",
                accent: .accentSky,
                trailing: model.snapshot.weather.map { "cập nhật \($0.fetchedAt.formatted(date: .omitted, time: .shortened))" },
                animatedIcon: .weather
            )
            if let w = model.snapshot.weather {
                HStack(alignment: .center, spacing: 14) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(w.temperatureText)
                            .font(CozyFont.number(44))
                            .foregroundStyle(Color.inkCoffee)
                            .cozyNumeric(Int(w.temperatureC.rounded()))
                        Label(w.condition.displayName, systemImage: w.condition.symbolName)
                            .symbolRenderingMode(.multicolor)
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                        Text("\(w.placeName) · cảm giác \(Int(w.apparentC))° · C:\(Int(w.highC))° T:\(Int(w.lowC))°")
                            .font(CozyFont.body(12))
                            .foregroundStyle(Color.inkTaupe)
                    }
                    Spacer()
                    Image(systemName: w.condition.symbolName)
                        .symbolRenderingMode(.multicolor)
                        .font(.system(size: 40))
                        .frame(width: 64, height: 64)
                        .background(Circle().fill(Color.accentSky.opacity(0.14)))
                }

                HStack(spacing: 8) {
                    Image(systemName: "tshirt.fill")
                        .font(.system(size: 13))
                        .foregroundStyle(Color.accentSky)
                    Text(WeatherSuggestion.outfit(for: w))
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundStyle(Color.inkCoffee)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 9)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Color.accentSky.opacity(0.10)))

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(WeatherSuggestion.foods(for: w)) { f in
                            Text("\(f.emoji) \(f.displayName)")
                                .font(.system(size: 13, weight: .semibold, design: .rounded))
                                .foregroundStyle(Color.inkCoffee)
                                .padding(.horizontal, 11)
                                .padding(.vertical, 6)
                                .background(Capsule().fill(Color.accentHoney.opacity(0.22)))
                        }
                    }
                }
                if model.settings.shareWeatherWithSpaces {
                    Label("Đang chia sẻ thời tiết với người yêu & nhóm bạn", systemImage: "person.2.wave.2")
                        .font(.caption)
                        .foregroundStyle(Color.inkTaupe)
                }
            } else {
                Text("Cho phép vị trí để xem thời tiết và gợi ý món ăn theo trời nhé.")
                    .font(CozyFont.body(14))
                    .foregroundStyle(Color.inkTaupe)
            }
        }
        .cozyCard(accent: .accentSky)
    }
}

// MARK: - Events

private struct UpcomingEventsCard: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        let events = model.upcomingEvents()
        VStack(alignment: .leading, spacing: 12) {
            CozySectionHeader(
                title: "Sắp tới",
                symbol: "calendar",
                accent: .accentSky,
                trailing: events.isEmpty ? nil : "\(events.count) sự kiện",
                animatedIcon: .calendar
            )
            if events.isEmpty {
                Text("Chưa có sự kiện nào — sang tab Lịch thêm ngày đặc biệt của bạn nhé 🌸")
                    .font(CozyFont.body(13))
                    .foregroundStyle(Color.inkTaupe)
            } else {
                ForEach(events) { e in
                    EventRow(event: e, status: model.status(of: e))
                }
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
                .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(event.accent.color.opacity(0.18)))
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
