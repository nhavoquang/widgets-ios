import SwiftUI
import CozyCore

/// Cài đặt tối giản, hiện đại, lưu tức thì — không dùng linh vật mèo/chó.
struct SettingsSheet: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var confirmClear = false
    @State private var showAdvanced = false

    var body: some View {
        NavigationStack {
            ZStack {
                CozyAmbientBackground()
                ScrollView {
                    VStack(spacing: 14) {
                        profileCard
                        appearanceCard
                        weatherLocationCard
                        vocabDecksCard
                        sharingCard
                        WidgetSetupGuideButton()
                        advancedCard
                    }
                    .padding(16)
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
                    .bold()
                }
            }
            .onAppear { name = model.settings.displayName }
            .onDisappear { commitName() }
            .confirmationDialog("Xóa dữ liệu mẫu cũ?", isPresented: $confirmClear, titleVisibility: .visible) {
                Button("Xóa dữ liệu mẫu", role: .destructive) {
                    model.removeDemoData()
                    Haptics.tap()
                }
            }
        }
        .presentationCornerRadius(24)
    }

    private var profileCard: some View {
        HStack(spacing: 12) {
            ModernAvatar(name: liveName, tint: .accentSky, size: 48)
            VStack(alignment: .leading, spacing: 4) {
                Text("Tên hiển thị")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Color.inkTaupe)
                TextField("Nhập tên của bạn", text: $name)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color.inkCoffee)
                    .submitLabel(.done)
                    .onSubmit { commitName() }
                    .onChange(of: name) { _, newValue in
                        let trimmed = newValue.trimmingCharacters(in: .whitespacesAndNewlines)
                        if !trimmed.isEmpty, trimmed != model.settings.displayName {
                            model.updateSettings { $0.displayName = trimmed }
                        }
                    }
            }
        }
        .cozyCard(padding: 14)
    }

    private var appearanceCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            CozySectionHeader(title: "Giao diện", symbol: "circle.lefthalf.filled", accent: .accentSky, trailing: nil)

            Picker("Giao diện", selection: Binding(
                get: { model.settings.appearance },
                set: { mode in
                    model.updateSettings { $0.appearance = mode }
                    Haptics.tap()
                }
            )) {
                ForEach(AppAppearance.allCases) { Text($0.displayName).tag($0) }
            }
            .pickerStyle(.segmented)

            Toggle("Rung phản hồi", isOn: Binding(
                get: { model.settings.hapticsEnabled },
                set: { v in
                    model.updateSettings { $0.hapticsEnabled = v }
                    if v { Haptics.tap() }
                }
            ))
            .font(.system(size: 15, weight: .medium))
            .tint(.accentSky)
        }
        .cozyCard(padding: 14)
    }

    private var weatherLocationCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            CozySectionHeader(
                title: "Thời tiết",
                symbol: "cloud.sun.fill",
                accent: .accentSky,
                trailing: model.snapshot.weather.map { "\($0.temperatureText) · \($0.placeName)" }
            )
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(WeatherLocationPreset.allCases) { preset in
                        let selected = model.settings.weatherLocation == preset
                        Button {
                            Haptics.tap()
                            Task { await model.setWeatherLocation(preset) }
                        } label: {
                            Text(preset == .autoGPS ? "GPS" : preset.shortName)
                                .font(.system(size: 13, weight: selected ? .semibold : .medium))
                                .foregroundStyle(selected ? .white : Color.inkCoffee)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 7)
                                .background(Capsule().fill(selected ? Color.accentSky : Color.bgCream))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            Button {
                Haptics.tap()
                Task { await model.refreshWeatherNow() }
            } label: {
                Label(model.weather.isRefreshing ? "Đang tải…" : "Cập nhật", systemImage: "arrow.clockwise")
            }
            .buttonStyle(CozyPillButtonStyle(tint: .accentSky, filled: false))
            .disabled(model.weather.isRefreshing)
        }
        .cozyCard(padding: 14)
    }

    private var vocabDecksCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            CozySectionHeader(title: "Kho từ vựng", symbol: "character.book.closed.fill", accent: .accentSage, trailing: "\(model.settings.activeDecks.count) kho")
            LazyVGrid(columns: [GridItem(.flexible(), spacing: 8), GridItem(.flexible(), spacing: 8)], spacing: 8) {
                ForEach(VocabDeck.allCases) { deck in
                    let active = model.settings.activeDecks.contains(deck)
                    Button {
                        model.setDeck(deck, active: !active)
                        Haptics.tap()
                    } label: {
                        HStack(spacing: 6) {
                            Text(deck.displayName)
                                .font(.system(size: 13, weight: active ? .semibold : .regular))
                                .foregroundStyle(Color.inkCoffee)
                                .lineLimit(1)
                            Spacer(minLength: 0)
                            Image(systemName: active ? "checkmark.circle.fill" : "circle")
                                .font(.system(size: 14))
                                .foregroundStyle(active ? Color.accentSage : Color.inkTaupe.opacity(0.4))
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 9)
                        .background(RoundedRectangle(cornerRadius: 10).fill(active ? Color.accentSage.opacity(0.14) : Color.bgCream))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .cozyCard(padding: 14)
    }

    private var sharingCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            CozySectionHeader(title: "Chia sẻ", symbol: "heart.fill", accent: .accentPeach, trailing: nil)
            Toggle("Thời tiết của bạn", isOn: Binding(
                get: { model.settings.shareWeatherWithSpaces },
                set: { v in model.updateSettings { $0.shareWeatherWithSpaces = v } }
            ))
            .font(.system(size: 15, weight: .medium))
            .tint(.accentSky)
            Toggle("Pin điện thoại", isOn: Binding(
                get: { model.settings.shareDeviceBattery },
                set: { v in model.updateSettings { $0.shareDeviceBattery = v } }
            ))
            .font(.system(size: 15, weight: .medium))
            .tint(.accentSky)
        }
        .cozyCard(padding: 14)
    }

    private var advancedCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Button {
                withAnimation { showAdvanced.toggle() }
            } label: {
                HStack {
                    Text("Nâng cao & Chẩn đoán")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Color.inkTaupe)
                    Spacer()
                    Image(systemName: "chevron.down")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Color.inkTaupe)
                        .rotationEffect(.degrees(showAdvanced ? 180 : 0))
                }
            }
            .buttonStyle(.plain)

            if showAdvanced {
                Divider()
                HStack {
                    Text("iCloud").font(.system(size: 13, weight: .medium))
                    Spacer()
                    Text(CloudConfig.isEnabled ? "Đang bật" : "Chưa bật").font(.caption).foregroundStyle(Color.inkTaupe)
                }
                WidgetDiagnosticsContent()
                    .padding(10)
                    .background(RoundedRectangle(cornerRadius: 10).fill(Color.bgCream))
                Button("Xóa dữ liệu mẫu", role: .destructive) { confirmClear = true }
                    .font(.system(size: 14, weight: .semibold))
            }
        }
        .cozyCard(padding: 14)
    }

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
