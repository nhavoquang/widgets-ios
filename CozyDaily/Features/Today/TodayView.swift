import SwiftUI
import CozyCore

/// Tab 1 — Hôm nay: Điều khiển trực tiếp, cực đơn giản cho đúng 4 Widget Lock Screen thật:
/// 1. Lịch & Công việc hôm nay · 2. Từ vựng · 3. Thời tiết thật · 4. Cảm xúc & Người kết nối.
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
                    VStack(spacing: 14) {
                        TopHeaderBar(showSettings: $showSettings)

                        if let toast = model.incomingPartnerToast {
                            HStack(spacing: 8) {
                                Image(systemName: "checkmark.circle.fill").foregroundStyle(Color.accentSage)
                                Text(toast).font(.system(size: 13, weight: .semibold, design: .rounded)).foregroundStyle(Color.inkCoffee)
                                Spacer()
                                Button { model.incomingPartnerToast = nil } label: {
                                    Image(systemName: "xmark").font(.caption.bold()).foregroundStyle(Color.inkTaupe)
                                }
                            }
                            .padding(12)
                            .background(RoundedRectangle(cornerRadius: 16).fill(Color.accentSage.opacity(0.16)))
                        }

                        if model.hasDemoData {
                            DemoCleanupBanner()
                        }

                        WidgetSetupGuideButton()

                        // 1. Lịch & Công việc hôm nay (ra Lock Screen ngay)
                        TodayScheduleCard()

                        // 2. Từ vựng học hôm nay (ra Lock Screen ngay)
                        VocabCard(showDecks: $showDecks)

                        // 3. Thời tiết thật (ra Lock Screen ngay)
                        WeatherCard()

                        // 4. Cảm xúc của bạn & Người kết nối (ra Lock Screen ngay)
                        MoodAndPartnerCard(showCheckIn: $showCheckIn)
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 28)
                }
                .scrollDismissesKeyboard(.interactively)
                .refreshable {
                    await model.refreshWeatherNow()
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

// MARK: - Top Bar & Demo Cleanup

private struct TopHeaderBar: View {
    @Environment(AppModel.self) private var model
    @Binding var showSettings: Bool

    var body: some View {
        HStack(alignment: .center, spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                Text(dateLine)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color.inkTaupe)
                Text("Chào \(model.settings.displayName)")
                    .font(CozyFont.title(26, weight: .heavy))
                    .foregroundStyle(Color.inkCoffee)
                    .lineLimit(1)
            }
            Spacer()
            Button {
                Haptics.tap()
                showSettings = true
            } label: {
                HStack(spacing: 5) {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 13, weight: .bold))
                    Text("Cài đặt")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                }
                .foregroundStyle(Color.inkCoffee)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Capsule().fill(Color.cardIvory))
                .overlay(Capsule().strokeBorder(Color.cardBorder, lineWidth: 1))
                .shadow(color: Color.inkCoffee.opacity(0.06), radius: 6, y: 2)
            }
            .buttonStyle(.plain)
        }
        .padding(.top, 8)
    }

    private var dateLine: String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "vi_VN")
        f.dateFormat = "EEEE, d/M"
        return "\(f.string(from: model.now).capitalized) · \(model.lunarToday.shortText) ÂL"
    }
}

private struct DemoCleanupBanner: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "sparkles")
                .foregroundStyle(Color.accentPeach)
            VStack(alignment: .leading, spacing: 1) {
                Text("Đang còn dữ liệu mẫu cũ")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.inkCoffee)
                Text("Xóa đi để app & Lock Screen chỉ hiện 100% data thật của bạn.")
                    .font(.system(size: 11.5))
                    .foregroundStyle(Color.inkTaupe)
            }
            Spacer(minLength: 4)
            Button("Xóa sạch") {
                model.removeDemoData()
                Task { await model.refreshWeatherNow() }
            }
            .buttonStyle(CozyPillButtonStyle(tint: .accentPeach, filled: true))
        }
        .cozyCard(accent: .accentPeach, padding: 12)
    }
}

// MARK: - 1. Lịch & Công việc hôm nay

private struct TodayScheduleCard: View {
    @Environment(AppModel.self) private var model
    @State private var newTitle = ""
    @State private var newTime = ""
    @State private var syncingCal = false

    private var items: [TodayScheduleItem] { model.todaySchedule }
    private var doneCount: Int { items.filter { $0.isTask && $0.isDone }.count }
    private var totalTasks: Int { items.filter(\.isTask).count }

    var body: some View {
        VStack(alignment: .leading, spacing: 11) {
            CozySectionHeader(
                title: "Lịch & Việc hôm nay",
                symbol: "checklist",
                accent: .accentSky,
                trailing: totalTasks > 0 ? "\(doneCount)/\(totalTasks) xong" : "Lock Screen",
                animatedIcon: .calendar
            )

            // Thêm việc nhanh 1 dòng (gõ xong Enter là lên Lock Screen luôn)
            HStack(spacing: 6) {
                TextField("Giờ", text: $newTime)
                    .font(.system(size: 13, weight: .semibold, design: .monospaced))
                    .multilineTextAlignment(.center)
                    .frame(width: 56)
                    .padding(.vertical, 9)
                    .background(RoundedRectangle(cornerRadius: 12).fill(Color.bgCream))
                    .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Color.cardBorder))
                TextField("Thêm việc hôm nay…", text: $newTitle)
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .padding(.horizontal, 11)
                    .padding(.vertical, 9)
                    .background(RoundedRectangle(cornerRadius: 12).fill(Color.bgCream))
                    .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Color.cardBorder))
                    .submitLabel(.done)
                    .onSubmit { addQuickTask() }
                Button { addQuickTask() } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 36, height: 36)
                        .background(Circle().fill(newTitle.trimmingCharacters(in: .whitespaces).isEmpty ? Color.inkTaupe.opacity(0.3) : Color.accentSky))
                }
                .buttonStyle(.plain)
                .disabled(newTitle.trimmingCharacters(in: .whitespaces).isEmpty)
            }

            if items.isEmpty {
                Text("Chưa có lịch hay công việc nào hôm nay. Thêm việc ở trên hoặc đồng bộ Apple Calendar để hiện lên màn hình khóa.")
                    .font(CozyFont.body(12.5))
                    .foregroundStyle(Color.inkTaupe)
            } else {
                VStack(spacing: 8) {
                    ForEach(items) { item in
                        HStack(spacing: 10) {
                            if item.isTask, let taskID = item.taskID {
                                Button { model.toggleTask(taskID) } label: {
                                    Image(systemName: item.isDone ? "checkmark.circle.fill" : "circle")
                                        .font(.system(size: 20, weight: .semibold))
                                        .foregroundStyle(item.isDone ? Color.accentSage : Color.accentSky)
                                }
                                .buttonStyle(.plain)
                            } else {
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(item.accent.color)
                                    .frame(width: 4, height: 22)
                            }
                            if let time = item.timeText {
                                Text(time)
                                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                                    .foregroundStyle(Color.accentSky)
                            }
                            Text(item.title)
                                .font(.system(size: 14.5, weight: .semibold, design: .rounded))
                                .foregroundStyle(Color.inkCoffee)
                                .strikethrough(item.isDone)
                                .opacity(item.isDone ? 0.5 : 1)
                            Spacer()
                            if item.isTask, let taskID = item.taskID {
                                Button { model.deleteTask(taskID) } label: {
                                    Image(systemName: "xmark")
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundStyle(Color.inkTaupe.opacity(0.6))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 8)
                        .background(RoundedRectangle(cornerRadius: 13).fill(Color.bgCream))
                    }
                }
            }

            Button {
                syncingCal = true
                Task {
                    await model.importAppleCalendar()
                    syncingCal = false
                }
            } label: {
                Label(
                    syncingCal ? "Đang lấy lịch iPhone…" : (model.settings.syncAppleCalendar ? "Cập nhật lại từ Apple Calendar" : "Đồng bộ lịch từ Apple Calendar"),
                    systemImage: "calendar.badge.plus"
                )
            }
            .buttonStyle(CozyPillButtonStyle(tint: .accentSky, filled: false))
            .disabled(syncingCal)
        }
        .cozyCard(accent: .accentSky)
    }

    private func addQuickTask() {
        let title = newTitle
        let time = newTime
        newTitle = ""
        newTime = ""
        model.addTask(title: title, timeText: time)
    }
}

// MARK: - 2. Từ vựng học hôm nay

private struct VocabCard: View {
    @Environment(AppModel.self) private var model
    @Binding var showDecks: Bool
    @State private var revealed = false

    var body: some View {
        VStack(alignment: .leading, spacing: 11) {
            CozySectionHeader(
                title: "Từ vựng hôm nay",
                symbol: "character.book.closed.fill",
                accent: .accentSage,
                trailing: "🔥 \(model.streak) ngày · \(model.dueCount) ôn",
                animatedIcon: .vocab
            )
            if let w = model.currentWord {
                HStack(alignment: .center) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(w.word)
                            .font(.system(size: 26, weight: .bold, design: .rounded))
                            .foregroundStyle(Color.inkCoffee)
                            .cozySwap(w.id)
                        if !w.phonetic.isEmpty {
                            Text(w.phonetic)
                                .font(.system(size: 13, design: .monospaced))
                                .foregroundStyle(Color.inkTaupe)
                        }
                    }
                    Spacer()
                    Button {
                        Haptics.tap()
                        model.speak(w)
                    } label: {
                        Image(systemName: "speaker.wave.2.fill")
                            .font(.system(size: 15, weight: .semibold))
                            .frame(width: 38, height: 38)
                            .background(Circle().fill(Color.accentSage.opacity(0.16)))
                            .foregroundStyle(Color.accentSage)
                    }
                    .buttonStyle(.plain)
                }

                Button {
                    Haptics.tap()
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.78)) { revealed.toggle() }
                } label: {
                    VStack(alignment: .leading, spacing: 4) {
                        if revealed {
                            Text(w.meaning)
                                .font(CozyFont.title(17, weight: .bold))
                                .foregroundStyle(Color.inkCoffee)
                            if !w.example.isEmpty {
                                Text("“\(w.example)”")
                                    .font(.system(size: 13, design: .serif).italic())
                                    .foregroundStyle(Color.inkTaupe)
                            }
                        } else {
                            Text("Chạm để xem nghĩa")
                                .font(.system(size: 13.5, weight: .semibold, design: .rounded))
                                .foregroundStyle(Color.inkTaupe)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(12)
                    .background(RoundedRectangle(cornerRadius: 14).fill(revealed ? Color.accentSage.opacity(0.14) : Color.bgCream))
                }
                .buttonStyle(.plain)

                HStack(spacing: 8) {
                    Button { revealed = false; model.markLearned() } label: { Label("Đã thuộc", systemImage: "checkmark") }
                        .buttonStyle(CozyPillButtonStyle(tint: .accentSage))
                    Button { revealed = false; model.skipWord() } label: { Label("Đổi từ", systemImage: "shuffle") }
                        .buttonStyle(CozyPillButtonStyle(tint: .accentSage, filled: false))
                    Spacer(minLength: 0)
                    Button {
                        Haptics.tap()
                        showDecks = true
                    } label: {
                        Label("Kho từ", systemImage: "books.vertical.fill")
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundStyle(Color.inkTaupe)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 8)
                            .background(Capsule().fill(Color.bgCream))
                    }
                    .buttonStyle(.plain)
                }
            } else {
                Button("Chọn kho từ vựng") { showDecks = true }
                    .buttonStyle(CozyPillButtonStyle(tint: .accentSage))
            }
        }
        .cozyCard(accent: .accentSage)
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
                            HStack { Text(deck.emoji); Text(deck.displayName) }
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
            .navigationTitle("Kho từ vựng")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// MARK: - 3. Thời tiết thật (chọn thành phố / GPS ngay tại chỗ)

private struct WeatherCard: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        VStack(alignment: .leading, spacing: 11) {
            CozySectionHeader(
                title: "Thời tiết thật",
                symbol: "cloud.sun.fill",
                accent: .accentSky,
                trailing: model.snapshot.weather.map { $0.fetchedAt.formatted(date: .omitted, time: .shortened) },
                animatedIcon: .weather
            )

            if let w = model.snapshot.weather {
                HStack(alignment: .center) {
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(alignment: .firstTextBaseline, spacing: 8) {
                            Text(w.temperatureText)
                                .font(CozyFont.number(40))
                                .foregroundStyle(Color.inkCoffee)
                                .cozyNumeric(Int(w.temperatureC.rounded()))
                            Text(w.placeName)
                                .font(CozyFont.title(18, weight: .bold))
                                .foregroundStyle(Color.inkCoffee)
                        }
                        Text("\(w.condition.displayName) · Cảm giác \(Int(w.apparentC.rounded()))° · ↑\(Int(w.highC.rounded()))° ↓\(Int(w.lowC.rounded()))° · Ẩm \(Int((w.humidity * 100).rounded()))%")
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundStyle(Color.inkTaupe)
                    }
                    Spacer()
                    Image(systemName: w.condition.symbolName)
                        .symbolRenderingMode(.multicolor)
                        .font(.system(size: 36))
                }
            } else {
                HStack(spacing: 8) {
                    ProgressView()
                    Text("Đang tải thời tiết thật…")
                        .font(CozyFont.body(13))
                        .foregroundStyle(Color.inkTaupe)
                }
            }

            // Chọn nhanh thành phố / GPS để thời tiết luôn đúng nơi bạn ở
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(WeatherLocationPreset.allCases) { preset in
                        let selected = model.settings.weatherLocation == preset
                        Button {
                            Haptics.tap()
                            Task { await model.setWeatherLocation(preset) }
                        } label: {
                            Text(preset == .autoGPS ? "📍 GPS" : preset.shortName)
                                .font(.system(size: 12, weight: selected ? .bold : .medium, design: .rounded))
                                .foregroundStyle(selected ? .white : Color.inkCoffee)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(Capsule().fill(selected ? Color.accentSky : Color.bgCream))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            if let err = model.weather.lastError {
                Text(err).font(.caption).foregroundStyle(Color.accentPeach)
            }
        }
        .cozyCard(accent: .accentSky)
    }
}

// MARK: - 4. Cảm xúc của bạn & Người kết nối

private struct MoodAndPartnerCard: View {
    @Environment(AppModel.self) private var model
    @Binding var showCheckIn: Bool
    @State private var quickNote = ""

    private var partner: MemberStatus? {
        model.couple?.partner(of: DemoData.meID)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            CozySectionHeader(
                title: "Cảm xúc & Người kết nối",
                symbol: "heart.fill",
                accent: .accentPeach,
                trailing: model.latestCheckInToday.map { $0.mood.displayName },
                animatedIcon: .heart
            )

            // Hiển thị trạng thái thật của người kết nối (nếu đã ghép đôi)
            if let p = partner {
                HStack(spacing: 12) {
                    MascotView(
                        state: MascotEngine.resolve(species: p.species, mood: p.mood, weather: nil, date: model.now),
                        size: 52,
                        animated: false
                    )
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 6) {
                            Text(p.displayName)
                                .font(CozyFont.title(16, weight: .bold))
                                .foregroundStyle(Color.inkCoffee)
                            if let m = p.mood {
                                Text("\(m.emoji) \(m.displayName)")
                                    .font(.system(size: 12, weight: .bold, design: .rounded))
                                    .foregroundStyle(Color.accentPeach)
                            }
                        }
                        if !p.note.isEmpty {
                            Text("“\(p.note)”")
                                .font(.system(size: 13, weight: .medium, design: .rounded))
                                .foregroundStyle(Color.inkCoffee)
                        }
                        Text("\(p.weatherLine.map { "\($0) · " } ?? "")\(p.updatedAt.formatted(.relative(presentation: .named, unitsStyle: .narrow)))")
                            .font(.system(size: 11))
                            .foregroundStyle(Color.inkTaupe)
                    }
                    Spacer()
                }
                .padding(10)
                .background(RoundedRectangle(cornerRadius: 16).fill(Color.accentPeach.opacity(0.10)))
            } else {
                Text("Chưa kết nối ai. Bấm gửi cảm xúc bên dưới hoặc sang tab Kết nối để ghép đôi với người ấy.")
                    .font(CozyFont.body(12.5))
                    .foregroundStyle(Color.inkTaupe)
            }

            // Chọn nhanh cảm xúc của bạn (1 chạm)
            HStack(spacing: 5) {
                ForEach(Mood.allCases) { mood in
                    let isSelected = model.latestCheckInToday?.mood == mood
                    Button {
                        let last = model.latestCheckInToday
                        model.checkIn(mood: mood, foods: last?.foods ?? [], battery: last?.socialBattery ?? 60, note: quickNote.isEmpty ? (last?.note ?? "") : quickNote)
                        Haptics.tap()
                    } label: {
                        Text(mood.emoji)
                            .font(.system(size: isSelected ? 24 : 21))
                            .frame(maxWidth: .infinity, minHeight: 40)
                            .background(RoundedRectangle(cornerRadius: 12).fill(isSelected ? Color.accentPeach.opacity(0.28) : Color.bgCream))
                            .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(isSelected ? Color.accentPeach : .clear, lineWidth: 1.5))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(mood.displayName)
                }
            }

            // Viết note ngắn trực tiếp
            HStack(spacing: 8) {
                TextField("Trạng thái ngắn của bạn (tối đa 30 ký tự)…", text: $quickNote)
                    .font(.system(size: 13.5, weight: .medium, design: .rounded))
                    .padding(.horizontal, 11)
                    .padding(.vertical, 8)
                    .background(RoundedRectangle(cornerRadius: 12).fill(Color.bgCream))
                    .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Color.cardBorder))
                    .onChange(of: quickNote) { _, v in if v.count > CozyMetrics.noteMaxLength { quickNote = String(v.prefix(CozyMetrics.noteMaxLength)) } }
                    .submitLabel(.done)
                    .onSubmit { saveQuickNote() }
                Button("Lưu") { saveQuickNote() }
                    .buttonStyle(CozyPillButtonStyle(tint: .accentPeach, filled: false))
            }

            // Nút gửi cảm xúc thật qua iMessage / Zalo / Messenger (cozydaily://)
            HStack(spacing: 8) {
                if let url = model.myStatusShareURL {
                    ShareLink(
                        item: url,
                        subject: Text("Cảm xúc của \(model.settings.displayName)"),
                        message: Text("Chạm link này để cập nhật cảm xúc của \(model.settings.displayName) lên Lock Screen CozyDaily nhé!")
                    ) {
                        Label("Gửi cảm xúc cho người ấy", systemImage: "paperplane.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(CozyPillButtonStyle(tint: .accentPeach, filled: true))
                }
                Button { showCheckIn = true } label: {
                    Image(systemName: "slider.horizontal.3")
                        .font(.system(size: 14, weight: .bold))
                        .frame(width: 38, height: 38)
                        .background(Circle().fill(Color.bgCream))
                        .foregroundStyle(Color.inkTaupe)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Check-in đầy đủ")
            }
        }
        .cozyCard(accent: .accentPeach)
        .onAppear { quickNote = model.latestCheckInToday?.note ?? "" }
    }

    private func saveQuickNote() {
        let last = model.latestCheckInToday
        model.checkIn(mood: last?.mood ?? .chill, foods: last?.foods ?? [], battery: last?.socialBattery ?? 60, note: quickNote)
        Haptics.success()
    }
}

// MARK: - Check-in đầy đủ & EventRow (dùng chung)

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
