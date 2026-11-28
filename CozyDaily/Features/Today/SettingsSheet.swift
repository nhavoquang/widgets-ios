import SwiftUI
import CozyCore

/// Màn hình Cài đặt thân thiện, trực quan và dễ thương: lưu tức thì mọi tùy chọn,
/// giấu các thông số kỹ thuật vào mục Nâng cao để người dùng thao tác cực nhẹ nhàng.
struct SettingsSheet: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var confirmClear = false
    @State private var showWidgetGuide = false
    @State private var showAdvanced = false

    var body: some View {
        NavigationStack {
            ZStack {
                CozyAmbientBackground()
                ScrollView {
                    VStack(spacing: 16) {
                        profileCard
                        appearanceCard
                        weatherLocationCard
                        vocabDecksCard
                        sharingCard
                        widgetGuideCard
                        advancedCard
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }
                .scrollDismissesKeyboard(.interactively)
            }
            .navigationTitle("Cài đặt")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Xong") {
                        commitName()
                        dismiss()
                    }
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.accentPeach)
                }
            }
            .onAppear { name = model.settings.displayName }
            .onDisappear { commitName() }
            .confirmationDialog(
                "Xóa sự kiện, check-in và không gian mẫu?",
                isPresented: $confirmClear,
                titleVisibility: .visible
            ) {
                Button("Xóa dữ liệu mẫu", role: .destructive) {
                    model.removeDemoData()
                    Haptics.tap()
                }
            } message: {
                Text("Các dữ liệu do bạn tự thêm sẽ vẫn được giữ nguyên.")
            }
        }
        .presentationCornerRadius(28)
    }

    // MARK: - 1. Hồ sơ & Linh vật

    private var profileCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 14) {
                AnimatedMascotView(
                    state: model.mascot,
                    size: 76,
                    reaction: model.settings.species
                )
                VStack(alignment: .leading, spacing: 4) {
                    Text("Xin chào, \(liveName) ✨")
                        .font(CozyFont.title(20, weight: .heavy))
                        .foregroundStyle(Color.inkCoffee)
                        .lineLimit(1)
                    Text("Bạn \(model.settings.species.displayName.lowercased()) đang đồng hành cùng bạn trên app & widget.")
                        .font(CozyFont.body(13))
                        .foregroundStyle(Color.inkTaupe)
                }
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("Tên gọi thân mật")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color.inkTaupe)
                HStack(spacing: 8) {
                    Image(systemName: "sparkles")
                        .foregroundStyle(Color.accentPeach)
                    TextField("Nhập tên bạn muốn hiển thị", text: $name)
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundStyle(Color.inkCoffee)
                        .submitLabel(.done)
                        .onSubmit { commitName() }
                        .onChange(of: name) { _, newValue in
                            let trimmed = newValue.trimmingCharacters(in: .whitespacesAndNewlines)
                            if !trimmed.isEmpty, trimmed != model.settings.displayName {
                                model.updateSettings { $0.displayName = trimmed }
                            }
                        }
                    if !name.isEmpty {
                        Button { name = "" } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(Color.inkTaupe.opacity(0.6))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 11)
                .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Color.bgCream))
                .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).strokeBorder(Color.cardBorder, lineWidth: 1))
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Chọn bạn linh vật")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color.inkTaupe)
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 4), spacing: 10) {
                    ForEach(MascotSpecies.allCases) { species in
                        let selected = model.settings.species == species
                        let previewState = MascotEngine.resolve(
                            species: species,
                            mood: selected ? (model.latestCheckInToday?.mood ?? .happy) : .happy,
                            weather: nil,
                            date: model.now
                        )
                        Button {
                            model.updateSettings { $0.species = species }
                            Haptics.tap()
                        } label: {
                            VStack(spacing: 6) {
                                MascotView(state: previewState, size: 52, animated: false)
                                Text(species.displayName)
                                    .font(.system(size: 12, weight: selected ? .heavy : .semibold, design: .rounded))
                                    .foregroundStyle(Color.inkCoffee)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(
                                RoundedRectangle(cornerRadius: 18, style: .continuous)
                                    .fill(selected ? Color.accentPeach.opacity(0.22) : Color.bgCream)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 18, style: .continuous)
                                    .strokeBorder(selected ? Color.accentPeach : Color.cardBorder, lineWidth: selected ? 2 : 1)
                            )
                            .scaleEffect(selected ? 1.02 : 1)
                        }
                        .buttonStyle(.plain)
                        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: selected)
                    }
                }
            }
        }
        .cozyCard(accent: .accentPeach)
    }

    // MARK: - 2. Giao diện & Cảm giác

    private var appearanceCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            CozySectionHeader(title: "Giao diện & Cảm giác", symbol: "paintpalette.fill", accent: .accentHoney, trailing: nil, animatedIcon: .sparkles)

            HStack(spacing: 8) {
                ForEach(AppAppearance.allCases) { mode in
                    let selected = model.settings.appearance == mode
                    Button {
                        withAnimation(CozyMotion.spring) {
                            model.updateSettings { $0.appearance = mode }
                        }
                        Haptics.tap()
                    } label: {
                        VStack(spacing: 6) {
                            Image(systemName: mode.symbolName)
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundStyle(selected ? .white : Color.accentHoney)
                                .frame(width: 34, height: 34)
                                .background(Circle().fill(selected ? Color.accentHoney : Color.accentHoney.opacity(0.16)))
                            Text(mode.displayName)
                                .font(.system(size: 12, weight: selected ? .bold : .medium, design: .rounded))
                                .foregroundStyle(Color.inkCoffee)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(selected ? Color.accentHoney.opacity(0.20) : Color.bgCream)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .strokeBorder(selected ? Color.accentHoney : Color.cardBorder, lineWidth: selected ? 1.8 : 1)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }

            SettingsToggleRow(
                icon: "waveform.path",
                tint: .accentHoney,
                title: "Rung nhẹ khi chạm",
                subtitle: "Phản hồi êm tay khi check-in, học từ & nựng linh vật",
                isOn: Binding(
                    get: { model.settings.hapticsEnabled },
                    set: { v in
                        model.updateSettings { $0.hapticsEnabled = v }
                        if v { Haptics.tap() }
                    }
                )
            )
        }
        .cozyCard(accent: .accentHoney)
    }

    // MARK: - 2b. Thời tiết thật (GPS hoặc chọn thành phố)

    private var weatherLocationCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            CozySectionHeader(
                title: "Thời tiết thật",
                symbol: "cloud.sun.fill",
                accent: .accentSky,
                trailing: model.snapshot.weather.map { "\($0.temperatureText) · \($0.placeName)" },
                animatedIcon: .weather
            )
            Text("Chọn GPS tự động hoặc chọn nhanh thành phố để app & Lock Screen Widget luôn hiện thời tiết thật.")
                .font(CozyFont.body(12))
                .foregroundStyle(Color.inkTaupe)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(WeatherLocationPreset.allCases) { preset in
                        let selected = model.settings.weatherLocation == preset
                        Button {
                            Haptics.tap()
                            Task { await model.setWeatherLocation(preset) }
                        } label: {
                            HStack(spacing: 5) {
                                if preset == .autoGPS {
                                    Image(systemName: "location.fill").font(.system(size: 11, weight: .bold))
                                }
                                Text(preset.displayName)
                                    .font(.system(size: 13, weight: selected ? .bold : .medium, design: .rounded))
                            }
                            .foregroundStyle(selected ? .white : Color.inkCoffee)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(
                                Capsule().fill(selected ? Color.accentSky : Color.bgCream)
                            )
                            .overlay(
                                Capsule().strokeBorder(selected ? Color.accentSky : Color.cardBorder, lineWidth: 1)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            HStack {
                Button {
                    Haptics.tap()
                    Task { await model.refreshWeatherNow() }
                } label: {
                    Label(model.weather.isRefreshing ? "Đang cập nhật…" : "Cập nhật thời tiết ngay", systemImage: "arrow.clockwise")
                }
                .buttonStyle(CozyPillButtonStyle(tint: .accentSky, filled: false))
                .disabled(model.weather.isRefreshing)
                Spacer()
            }
            if let err = model.weather.lastError {
                Text(err).font(.caption).foregroundStyle(Color.accentPeach)
            }
        }
        .cozyCard(accent: .accentSky)
    }

    // MARK: - 3. Kho từ vựng bật sẵn

    private var vocabDecksCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            CozySectionHeader(
                title: "Kho từ vựng",
                symbol: "character.book.closed.fill",
                accent: .accentSage,
                trailing: "\(model.settings.activeDecks.count) kho đang bật",
                animatedIcon: .vocab
            )
            Text("Chạm để bật/tắt chủ đề từ vựng hiện mỗi ngày (giữ ít nhất 1 kho).")
                .font(CozyFont.body(12))
                .foregroundStyle(Color.inkTaupe)

            LazyVGrid(columns: [GridItem(.flexible(), spacing: 8), GridItem(.flexible(), spacing: 8)], spacing: 8) {
                ForEach(VocabDeck.allCases) { deck in
                    let active = model.settings.activeDecks.contains(deck)
                    Button {
                        model.setDeck(deck, active: !active)
                        Haptics.tap()
                    } label: {
                        HStack(spacing: 8) {
                            Text(deck.emoji).font(.system(size: 18))
                            Text(deck.displayName)
                                .font(.system(size: 13, weight: active ? .bold : .medium, design: .rounded))
                                .foregroundStyle(Color.inkCoffee)
                                .lineLimit(1)
                                .minimumScaleFactor(0.85)
                            Spacer(minLength: 0)
                            Image(systemName: active ? "checkmark.circle.fill" : "circle")
                                .font(.system(size: 15))
                                .foregroundStyle(active ? Color.accentSage : Color.inkTaupe.opacity(0.45))
                        }
                        .padding(.horizontal, 11)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 15, style: .continuous)
                                .fill(active ? Color.accentSage.opacity(0.18) : Color.bgCream)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 15, style: .continuous)
                                .strokeBorder(active ? Color.accentSage.opacity(0.7) : Color.cardBorder, lineWidth: active ? 1.5 : 1)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .cozyCard(accent: .accentSage)
    }

    // MARK: - 4. Quyền riêng tư & chia sẻ

    private var sharingCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            CozySectionHeader(title: "Chia sẻ với người thương", symbol: "heart.text.square.fill", accent: .accentSky, trailing: nil, animatedIcon: .heart)

            SettingsToggleRow(
                icon: "cloud.sun.fill",
                tint: .accentSky,
                title: "Thời tiết nơi bạn ở",
                subtitle: "Hiện nắng mưa & nhiệt độ trên thẻ của bạn trong Couple/Squad",
                isOn: Binding(
                    get: { model.settings.shareWeatherWithSpaces },
                    set: { v in
                        model.updateSettings { $0.shareWeatherWithSpaces = v }
                        Haptics.tap()
                    }
                )
            )

            Divider().overlay(Color.cardBorder)

            SettingsToggleRow(
                icon: "battery.75percent",
                tint: .accentPeach,
                title: "Pin điện thoại",
                subtitle: "Chia sẻ % pin để người ấy biết lúc máy sắp hết pin",
                isOn: Binding(
                    get: { model.settings.shareDeviceBattery },
                    set: { v in
                        model.updateSettings { $0.shareDeviceBattery = v }
                        Haptics.tap()
                    }
                )
            )
        }
        .cozyCard(accent: .accentSky)
    }

    // MARK: - 5. Hướng dẫn thêm Widget nhanh

    private var widgetGuideCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Button {
                withAnimation(CozyMotion.spring) { showWidgetGuide.toggle() }
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "sparkles.rectangle.stack.fill")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 28, height: 28)
                        .background(Circle().fill(Color.accentPeach))
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Cách đưa Widget ra màn hình")
                            .font(CozyFont.title(16))
                            .foregroundStyle(Color.inkCoffee)
                        Text("3 bước cực nhanh cho Home & Lock Screen")
                            .font(CozyFont.body(12))
                            .foregroundStyle(Color.inkTaupe)
                    }
                    Spacer()
                    Image(systemName: "chevron.down")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(Color.inkTaupe)
                        .rotationEffect(.degrees(showWidgetGuide ? 180 : 0))
                }
            }
            .buttonStyle(.plain)

            if showWidgetGuide {
                VStack(alignment: .leading, spacing: 8) {
                    guideStep("1", "Chạm giữ vùng trống trên Màn hình chính rồi bấm nút “+” (Sửa → Thêm tiện ích).")
                    guideStep("2", "Tìm CozyDaily và chọn loại widget bạn thích (Xưởng Widget, Từ vựng, Người yêu…).")
                    guideStep("3", "Muốn đổi mẫu đẹp hơn? Chạm giữ widget → “Sửa tiện ích” để chọn mẫu từ Xưởng Widget!")
                }
                .padding(.top, 4)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .cozyCard()
    }

    private func guideStep(_ num: String, _ text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Text(num)
                .font(.system(size: 12, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)
                .frame(width: 22, height: 22)
                .background(Circle().fill(Color.accentPeach))
            Text(text)
                .font(CozyFont.body(13))
                .foregroundStyle(Color.inkCoffee)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: - 6. Nâng cao & Chẩn đoán (thu gọn)

    private var advancedCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button {
                withAnimation(CozyMotion.spring) { showAdvanced.toggle() }
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "wrench.and.screwdriver.fill")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(Color.inkTaupe)
                        .frame(width: 28, height: 28)
                        .background(Circle().fill(Color.bgCream))
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Nâng cao & Dữ liệu")
                            .font(CozyFont.title(15, weight: .bold))
                            .foregroundStyle(Color.inkCoffee)
                        Text("iCloud, chẩn đoán widget & xóa dữ liệu mẫu")
                            .font(CozyFont.body(12))
                            .foregroundStyle(Color.inkTaupe)
                    }
                    Spacer()
                    Image(systemName: "chevron.down")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(Color.inkTaupe)
                        .rotationEffect(.degrees(showAdvanced ? 180 : 0))
                }
            }
            .buttonStyle(.plain)

            if showAdvanced {
                VStack(alignment: .leading, spacing: 12) {
                    Divider().overlay(Color.cardBorder)

                    HStack(spacing: 10) {
                        Image(systemName: CloudConfig.isEnabled ? "checkmark.icloud.fill" : "icloud.slash")
                            .foregroundStyle(CloudConfig.isEnabled ? Color.accentSage : Color.inkTaupe)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Đồng bộ iCloud")
                                .font(.system(size: 14, weight: .semibold, design: .rounded))
                                .foregroundStyle(Color.inkCoffee)
                            Text(CloudConfig.isEnabled ? "Đang bật đồng bộ tự động" : "Chưa bật trong bản cài này (chỉ lưu trên máy)")
                                .font(CozyFont.body(12))
                                .foregroundStyle(Color.inkTaupe)
                        }
                    }

                    if let error = model.cloudError {
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(Color.accentPeach)
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Chẩn đoán Widget")
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundStyle(Color.inkTaupe)
                        WidgetDiagnosticsContent()
                            .padding(10)
                            .background(RoundedRectangle(cornerRadius: 12).fill(Color.bgCream))
                    }

                    Button(role: .destructive) {
                        confirmClear = true
                    } label: {
                        Label("Xóa dữ liệu mẫu", systemImage: "trash")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(CozyPillButtonStyle(tint: .accentPeach, filled: false))
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .cozyCard()
    }

    // MARK: - Helpers

    private var liveName: String {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? model.settings.displayName : trimmed
    }

    private func commitName() {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty, trimmed != model.settings.displayName {
            model.updateSettings { $0.displayName = trimmed }
        }
    }
}

private struct SettingsToggleRow: View {
    var icon: String
    var tint: Color
    var title: String
    var subtitle: String
    @Binding var isOn: Bool

    var body: some View {
        Toggle(isOn: $isOn) {
            HStack(spacing: 11) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(tint)
                    .frame(width: 32, height: 32)
                    .background(Circle().fill(tint.opacity(0.16)))
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundStyle(Color.inkCoffee)
                    Text(subtitle)
                        .font(CozyFont.body(12))
                        .foregroundStyle(Color.inkTaupe)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .tint(tint)
    }
}
