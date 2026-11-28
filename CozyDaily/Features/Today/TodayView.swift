import SwiftUI
import CozyCore

/// Tab 1 — Lock Screen Hub: Hiện đại, tối giản, nút gọn, điều khiển thẳng 4 Widget Lock Screen thật.
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
                                Text(toast).font(.system(size: 13, weight: .semibold)).foregroundStyle(Color.inkCoffee)
                                Spacer()
                                Button { model.incomingPartnerToast = nil } label: {
                                    Image(systemName: "xmark").font(.caption.bold()).foregroundStyle(Color.inkTaupe)
                                }
                            }
                            .padding(12)
                            .background(RoundedRectangle(cornerRadius: 14).fill(Color.accentSage.opacity(0.14)))
                        }

                        if model.hasDemoData {
                            DemoCleanupBanner()
                        }

                        // Xem trước trực tiếp Lock Screen (2 ô song song + nút Hướng dẫn)
                        LiveLockScreenPreviewCard()
                        WidgetSetupGuideButton()

                        // 4 Thẻ điều khiển dữ liệu thật cho 4 Widget Lock Screen
                        TodayScheduleCard()
                        VocabCard(showDecks: $showDecks)
                        WeatherCard()
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
                CheckInSheet().presentationDetents([.large]).presentationCornerRadius(24)
            }
            .sheet(isPresented: $showSettings) { SettingsSheet() }
            .sheet(isPresented: $showDecks) {
                DeckPickerSheet().presentationDetents([.medium, .large])
            }
        }
    }
}

// MARK: - Top Bar & Live Lock Preview

private struct TopHeaderBar: View {
    @Environment(AppModel.self) private var model
    @Binding var showSettings: Bool

    var body: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 2) {
                Text(dateLine)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Color.inkTaupe)
                Text("Lock Screen")
                    .font(CozyFont.title(26, weight: .bold))
                    .foregroundStyle(Color.inkCoffee)
            }
            Spacer()
            Button {
                Haptics.tap()
                showSettings = true
            } label: {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color.inkCoffee)
                    .frame(width: 38, height: 38)
                    .background(Circle().fill(Color.cardIvory))
                    .overlay(Circle().strokeBorder(Color.cardBorder, lineWidth: 1))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Cài đặt")
        }
        .padding(.top, 8)
    }

    private var dateLine: String {
        let lang = model.settings.language
        let formatted = CozyL10n.formatLockDate(model.now, lang: lang)
        return lang.isVietnamese ? "\(formatted) · \(model.lunarToday.shortText) ÂL" : formatted
    }
}

private struct LiveLockScreenPreviewCard: View {
    @State private var leftSlot: CozyLockWidget = .schedule
    @State private var rightSlot: CozyLockWidget = .weather

    var body: some View {
        VStack(spacing: 12) {
            Text(Date(), style: .time)
                .font(.system(size: 46, weight: .bold, design: .rounded))
                .foregroundStyle(.white.opacity(0.92))
                .monospacedDigit()

            HStack(spacing: 10) {
                Button {
                    Haptics.tap()
                    leftSlot = next(leftSlot)
                } label: {
                    LockWidgetMockPreview(widget: leftSlot)
                }
                .buttonStyle(.plain)

                Button {
                    Haptics.tap()
                    rightSlot = next(rightSlot)
                } label: {
                    LockWidgetMockPreview(widget: rightSlot)
                }
                .buttonStyle(.plain)
            }

            Text("Chạm ô bất kỳ để đổi xem trước 4 widget")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.white.opacity(0.65))
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color(RGBA(hex: "#1C2438")!), Color(RGBA(hex: "#2C2438")!)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
    }

    private func next(_ current: CozyLockWidget) -> CozyLockWidget {
        let all = CozyLockWidget.allCases
        let idx = all.firstIndex(of: current) ?? 0
        return all[(idx + 1) % all.count]
    }
}

private struct DemoCleanupBanner: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        HStack(spacing: 10) {
            Text("Còn dữ liệu mẫu cũ")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Color.inkCoffee)
            Spacer()
            Button("Xóa sạch") {
                model.removeDemoData()
                Task { await model.refreshWeatherNow() }
            }
            .buttonStyle(CozyPillButtonStyle(tint: .accentPeach, filled: true))
        }
        .cozyCard(padding: 12)
    }
}

// MARK: - 1. Lịch & Việc hôm nay

private struct TodayScheduleCard: View {
    @Environment(AppModel.self) private var model
    @State private var newTitle = ""
    @State private var newTime = ""
    @State private var syncingCal = false

    private var items: [TodayScheduleItem] { model.todaySchedule }
    private var doneCount: Int { items.filter { $0.isTask && $0.isDone }.count }
    private var totalTasks: Int { items.filter(\.isTask).count }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            CozySectionHeader(
                title: "Lịch & Việc",
                symbol: "checklist",
                accent: .accentSky,
                trailing: totalTasks > 0 ? "\(doneCount)/\(totalTasks)" : nil
            )

            HStack(spacing: 6) {
                TextField("Giờ", text: $newTime)
                    .font(.system(size: 13, weight: .semibold, design: .monospaced))
                    .multilineTextAlignment(.center)
                    .frame(width: 54)
                    .padding(.vertical, 9)
                    .background(RoundedRectangle(cornerRadius: 10).fill(Color.bgCream))
                TextField("Thêm việc hôm nay…", text: $newTitle)
                    .font(.system(size: 14))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 9)
                    .background(RoundedRectangle(cornerRadius: 10).fill(Color.bgCream))
                    .submitLabel(.done)
                    .onSubmit { addQuickTask() }
                Button { addQuickTask() } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 36, height: 36)
                        .background(RoundedRectangle(cornerRadius: 10, style: .continuous).fill(newTitle.trimmingCharacters(in: .whitespaces).isEmpty ? Color.inkTaupe.opacity(0.3) : Color.accentSky))
                }
                .buttonStyle(.plain)
                .disabled(newTitle.trimmingCharacters(in: .whitespaces).isEmpty)
            }

            if !items.isEmpty {
                VStack(spacing: 6) {
                    ForEach(items) { item in
                        HStack(spacing: 9) {
                            if item.isTask, let taskID = item.taskID {
                                Button { model.toggleTask(taskID) } label: {
                                    Image(systemName: item.isDone ? "checkmark.circle.fill" : "circle")
                                        .font(.system(size: 19))
                                        .foregroundStyle(item.isDone ? Color.accentSage : Color.accentSky)
                                }
                                .buttonStyle(.plain)
                            } else {
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(item.accent.color)
                                    .frame(width: 3, height: 18)
                            }
                            if let time = item.timeText {
                                Text(time)
                                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                                    .foregroundStyle(Color.accentSky)
                            }
                            Text(item.title)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(Color.inkCoffee)
                                .strikethrough(item.isDone)
                                .opacity(item.isDone ? 0.5 : 1)
                            Spacer()
                            if item.isTask, let taskID = item.taskID {
                                Button { model.deleteTask(taskID) } label: {
                                    Image(systemName: "xmark")
                                        .font(.system(size: 11, weight: .semibold))
                                        .foregroundStyle(Color.inkTaupe.opacity(0.6))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 8)
                        .background(RoundedRectangle(cornerRadius: 10).fill(Color.bgCream))
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
                Label(syncingCal ? "Đang đồng bộ…" : "Lịch iPhone", systemImage: "calendar.badge.plus")
            }
            .buttonStyle(CozyPillButtonStyle(tint: .accentSky, filled: false))
            .disabled(syncingCal)
        }
        .cozyCard(padding: 14)
    }

    private func addQuickTask() {
        let title = newTitle
        let time = newTime
        newTitle = ""
        newTime = ""
        model.addTask(title: title, timeText: time)
    }
}

// MARK: - 2. Từ vựng

private struct VocabCard: View {
    @Environment(AppModel.self) private var model
    @Binding var showDecks: Bool
    @State private var revealed = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            CozySectionHeader(
                title: "Từ vựng",
                symbol: "character.book.closed.fill",
                accent: .accentSage,
                trailing: "\(model.streak) ngày · \(model.dueCount) ôn"
            )
            if let w = model.currentWord {
                HStack(alignment: .center) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(w.word)
                            .font(.system(size: 24, weight: .bold))
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
                            .frame(width: 36, height: 36)
                            .background(Circle().fill(Color.accentSage.opacity(0.14)))
                            .foregroundStyle(Color.accentSage)
                    }
                    .buttonStyle(.plain)
                }

                Button {
                    Haptics.tap()
                    withAnimation(.easeOut(duration: 0.2)) { revealed.toggle() }
                } label: {
                    Text(revealed ? w.meaning : "Xem nghĩa")
                        .font(.system(size: 14, weight: revealed ? .semibold : .medium))
                        .foregroundStyle(revealed ? Color.inkCoffee : Color.inkTaupe)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(11)
                        .background(RoundedRectangle(cornerRadius: 10).fill(Color.bgCream))
                }
                .buttonStyle(.plain)

                HStack(spacing: 8) {
                    Button { revealed = false; model.markLearned() } label: { Text("Đã thuộc") }
                        .buttonStyle(CozyPillButtonStyle(tint: .accentSage))
                    Button { revealed = false; model.skipWord() } label: { Text("Đổi từ") }
                        .buttonStyle(CozyPillButtonStyle(tint: .accentSage, filled: false))
                    Spacer(minLength: 0)
                    Button("Kho từ") {
                        Haptics.tap()
                        showDecks = true
                    }
                    .buttonStyle(CozyPillButtonStyle(tint: .inkTaupe, filled: false))
                }
            } else {
                Button("Chọn kho từ") { showDecks = true }
                    .buttonStyle(CozyPillButtonStyle(tint: .accentSage))
            }
        }
        .cozyCard(padding: 14)
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
                Section("Kho từ") {
                    ForEach(VocabDeck.allCases) { deck in
                        Toggle(deck.displayName, isOn: Binding(
                            get: { model.settings.activeDecks.contains(deck) },
                            set: { model.setDeck(deck, active: $0) }
                        ))
                    }
                }
                Section("Thêm từ mới") {
                    TextField("Từ tiếng Anh", text: $newWord).textInputAutocapitalization(.never)
                    TextField("Phiên âm", text: $newPhonetic)
                    TextField("Nghĩa", text: $newMeaning)
                    Button("Thêm") {
                        model.addCustomWord(VocabWord(word: newWord, phonetic: newPhonetic, meaning: newMeaning, example: newExample, deck: .custom))
                        newWord = ""; newMeaning = ""; newPhonetic = ""; newExample = ""
                    }
                    .disabled(newWord.trimmingCharacters(in: .whitespaces).isEmpty || newMeaning.isEmpty)
                }
            }
            .navigationTitle("Kho từ")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// MARK: - 3. Thời tiết thật

private struct WeatherCard: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            CozySectionHeader(
                title: "Thời tiết",
                symbol: "cloud.sun.fill",
                accent: .accentSky,
                trailing: model.snapshot.weather.map { $0.fetchedAt.formatted(date: .omitted, time: .shortened) }
            )

            if let w = model.snapshot.weather {
                HStack(alignment: .center) {
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(alignment: .firstTextBaseline, spacing: 8) {
                            Text(w.temperatureText)
                                .font(CozyFont.number(36))
                                .foregroundStyle(Color.inkCoffee)
                            Text(w.placeName)
                                .font(CozyFont.title(17, weight: .semibold))
                                .foregroundStyle(Color.inkCoffee)
                        }
                        Text("\(w.condition.displayName) · ↑\(Int(w.highC.rounded()))° ↓\(Int(w.lowC.rounded()))° · Ẩm \(Int((w.humidity * 100).rounded()))%")
                            .font(.system(size: 12))
                            .foregroundStyle(Color.inkTaupe)
                    }
                    Spacer()
                    Image(systemName: w.condition.symbolName)
                        .symbolRenderingMode(.multicolor)
                        .font(.system(size: 32))
                }
            } else {
                HStack(spacing: 8) {
                    ProgressView()
                    Text("Đang tải thời tiết…").font(.system(size: 13)).foregroundStyle(Color.inkTaupe)
                }
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(WeatherLocationPreset.allCases) { preset in
                        let selected = model.settings.weatherLocation == preset
                        Button {
                            Haptics.tap()
                            Task { await model.setWeatherLocation(preset) }
                        } label: {
                            Text(preset == .autoGPS ? "GPS" : preset.shortName)
                                .font(.system(size: 12, weight: selected ? .semibold : .medium))
                                .foregroundStyle(selected ? .white : Color.inkCoffee)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(Capsule().fill(selected ? Color.accentSky : Color.bgCream))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .cozyCard(padding: 14)
    }
}

// MARK: - 4. Cảm xúc & Người kết nối

private struct MoodAndPartnerCard: View {
    @Environment(AppModel.self) private var model
    @Binding var showCheckIn: Bool
    @State private var quickNote = ""

    private var partner: MemberStatus? {
        model.couple?.partner(of: DemoData.meID)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            CozySectionHeader(
                title: "Cảm xúc & Kết nối",
                symbol: "heart.fill",
                accent: .accentPeach,
                trailing: model.latestCheckInToday?.mood.displayName
            )

            if let p = partner {
                HStack(spacing: 10) {
                    ModernAvatar(name: p.displayName, tint: .accentPeach, size: 42)
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 6) {
                            Text(p.displayName).font(.system(size: 15, weight: .semibold)).foregroundStyle(Color.inkCoffee)
                            if let m = p.mood {
                                Text("\(m.emoji) \(m.displayName)")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundStyle(Color.accentPeach)
                            }
                        }
                        if !p.note.isEmpty {
                            Text(p.note).font(.system(size: 13)).foregroundStyle(Color.inkCoffee)
                        }
                    }
                    Spacer()
                }
                .padding(10)
                .background(RoundedRectangle(cornerRadius: 12).fill(Color.bgCream))
            }

            HStack(spacing: 5) {
                ForEach(Mood.allCases) { mood in
                    let isSelected = model.latestCheckInToday?.mood == mood
                    Button {
                        let last = model.latestCheckInToday
                        model.checkIn(mood: mood, foods: last?.foods ?? [], battery: last?.socialBattery ?? 60, note: quickNote.isEmpty ? (last?.note ?? "") : quickNote)
                        Haptics.tap()
                    } label: {
                        Text(mood.emoji)
                            .font(.system(size: 21))
                            .frame(maxWidth: .infinity, minHeight: 38)
                            .background(RoundedRectangle(cornerRadius: 10).fill(isSelected ? Color.accentPeach.opacity(0.22) : Color.bgCream))
                            .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(isSelected ? Color.accentPeach : .clear, lineWidth: 1.5))
                    }
                    .buttonStyle(.plain)
                }
            }

            HStack(spacing: 8) {
                TextField("Ghi chú ngắn…", text: $quickNote)
                    .font(.system(size: 14))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                    .background(RoundedRectangle(cornerRadius: 10).fill(Color.bgCream))
                    .onChange(of: quickNote) { _, v in if v.count > CozyMetrics.noteMaxLength { quickNote = String(v.prefix(CozyMetrics.noteMaxLength)) } }
                    .submitLabel(.done)
                    .onSubmit { saveQuickNote() }
                Button("Lưu") { saveQuickNote() }
                    .buttonStyle(CozyPillButtonStyle(tint: .accentPeach, filled: false))
            }

            if let url = model.myStatusShareURL {
                ShareLink(
                    item: url,
                    subject: Text("Cảm xúc của \(model.settings.displayName)"),
                    message: Text("Chạm link để cập nhật cảm xúc lên Lock Screen.")
                ) {
                    Label("Gửi cảm xúc", systemImage: "paperplane.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(CozyPillButtonStyle(tint: .accentPeach, filled: true))
            }
        }
        .cozyCard(padding: 14)
        .onAppear { quickNote = model.latestCheckInToday?.note ?? "" }
    }

    private func saveQuickNote() {
        let last = model.latestCheckInToday
        model.checkIn(mood: last?.mood ?? .chill, foods: last?.foods ?? [], battery: last?.socialBattery ?? 60, note: quickNote)
        Haptics.success()
    }
}

// MARK: - CheckInSheet & EventRow

struct CheckInSheet: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    @State private var mood: Mood = .chill
    @State private var foods: Set<FoodSticker> = []
    @State private var battery: Double = 60
    @State private var note = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Cảm xúc") {
                    Picker("Cảm xúc", selection: $mood) {
                        ForEach(Mood.allCases) { Text("\($0.emoji) \($0.displayName)").tag($0) }
                    }
                    .pickerStyle(.wheel)
                    .frame(height: 110)
                }
                Section("Ghi chú") {
                    TextField("Tối đa 30 ký tự", text: $note)
                        .onChange(of: note) { _, v in if v.count > CozyMetrics.noteMaxLength { note = String(v.prefix(CozyMetrics.noteMaxLength)) } }
                }
            }
            .navigationTitle("Cập nhật")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Đóng") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Lưu") {
                        model.checkIn(mood: mood, foods: FoodSticker.allCases.filter(foods.contains), battery: Int(battery), note: note)
                        dismiss()
                    }.bold()
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
            Image(systemName: event.kind.symbolName)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(event.accent.color)
                .frame(width: 38, height: 38)
                .background(RoundedRectangle(cornerRadius: 10, style: .continuous).fill(event.accent.color.opacity(0.14)))
            VStack(alignment: .leading, spacing: 2) {
                Text(event.title).font(.system(size: 15, weight: .semibold)).foregroundStyle(Color.inkCoffee)
                Text(event.kind.modeName).font(.system(size: 12)).foregroundStyle(Color.inkTaupe)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 0) {
                Text(status.headline).font(CozyFont.number(20)).foregroundStyle(status.direction == .overdue ? Color.accentPeach : Color.inkCoffee)
                Text(status.caption).font(.system(size: 11)).foregroundStyle(Color.inkTaupe)
            }
        }
    }
}
