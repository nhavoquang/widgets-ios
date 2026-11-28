import SwiftUI
import WidgetKit
import CozyCore

/// 4 widget Lock Screen cốt lõi.
enum CozyLockWidget: String, CaseIterable, Identifiable {
    case schedule, vocab, weather, partner

    var id: String { rawValue }

    var kind: String {
        switch self {
        case .schedule: return "CozyTodayScheduleWidget"
        case .vocab: return "CozyVocabWidget"
        case .weather: return "CozyWeatherWidget"
        case .partner: return "CozyCoupleWidget"
        }
    }

    var title: String {
        switch self {
        case .schedule: return "Lịch & Việc"
        case .vocab: return "Từ vựng"
        case .weather: return "Thời tiết"
        case .partner: return "Người kết nối"
        }
    }

    var symbol: String {
        switch self {
        case .schedule: return "checklist"
        case .vocab: return "character.book.closed.fill"
        case .weather: return "cloud.sun.fill"
        case .partner: return "heart.fill"
        }
    }

    var accent: Color {
        switch self {
        case .schedule, .weather: return .accentSky
        case .vocab: return .accentSage
        case .partner: return .accentPeach
        }
    }
}

@MainActor
@Observable
final class WidgetPlacementTracker {
    private(set) var onLock: Set<String> = []
    private(set) var onHome: Set<String> = []

    func refresh() {
        WidgetCenter.shared.getCurrentConfigurations { result in
            guard case .success(let list) = result else { return }
            let lock = Set(list.filter { $0.family.isAccessory }.map(\.kind))
            let home = Set(list.filter { !$0.family.isAccessory }.map(\.kind))
            Task { @MainActor in
                self.onLock = lock
                self.onHome = home
            }
        }
    }

    func isOnLock(_ w: CozyLockWidget) -> Bool { onLock.contains(w.kind) }
    var lockCount: Int { CozyLockWidget.allCases.filter(isOnLock).count }
}

/// Nút gọn mở hướng dẫn thêm widget Lock Screen.
struct WidgetSetupGuideButton: View {
    @State private var tracker = WidgetPlacementTracker()
    @State private var showGuide = false
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        Button {
            Haptics.tap()
            showGuide = true
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "lock.iphone")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 34, height: 34)
                    .background(RoundedRectangle(cornerRadius: 10, style: .continuous).fill(Color.accentSky))
                VStack(alignment: .leading, spacing: 2) {
                    Text("Thêm lên Lock Screen")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Color.inkCoffee)
                    Text("Đã đặt \(tracker.lockCount)/\(CozyLockWidget.allCases.count) widget")
                        .font(.system(size: 12))
                        .foregroundStyle(Color.inkTaupe)
                }
                Spacer()
                Text("Hướng dẫn")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color.accentSky)
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color.inkTaupe)
            }
            .cozyCard(padding: 12)
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showGuide) {
            WidgetSetupGuideSheet(tracker: tracker)
                .presentationCornerRadius(24)
        }
        .onAppear { tracker.refresh() }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { tracker.refresh() }
        }
    }
}

struct WidgetSetupGuideSheet: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase
    var tracker: WidgetPlacementTracker

    var body: some View {
        NavigationStack {
            ZStack {
                CozyAmbientBackground()
                ScrollView {
                    VStack(spacing: 14) {
                        stepsCard
                        ForEach(CozyLockWidget.allCases) { w in
                            widgetCard(w)
                        }
                    }
                    .padding(16)
                }
            }
            .navigationTitle("Thêm lên Lock Screen")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) { Button("Xong") { dismiss() }.bold() }
            }
            .onAppear { tracker.refresh() }
            .onChange(of: scenePhase) { _, phase in
                if phase == .active { tracker.refresh() }
            }
        }
    }

    private var stepsCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            step(1, "Nhấn giữ Lock Screen → Tùy chỉnh")
            step(2, "Chạm khung dưới đồng hồ → Tìm Widgets")
            step(3, "Chọn 1 trong 4 widget dưới → Xong")
        }
        .cozyCard(padding: 14)
    }

    private func step(_ n: Int, _ text: String) -> some View {
        HStack(spacing: 10) {
            Text("\(n)")
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .frame(width: 22, height: 22)
                .background(Circle().fill(Color.accentSky))
            Text(text)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Color.inkCoffee)
            Spacer(minLength: 0)
        }
    }

    private func widgetCard(_ w: CozyLockWidget) -> some View {
        let placed = tracker.isOnLock(w)
        return VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: w.symbol)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(w.accent)
                    .frame(width: 26, height: 26)
                    .background(RoundedRectangle(cornerRadius: 7, style: .continuous).fill(w.accent.opacity(0.14)))
                Text(w.title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Color.inkCoffee)
                Spacer()
                Label(placed ? "Đã đặt" : "Chưa đặt", systemImage: placed ? "checkmark.circle.fill" : "circle.dashed")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(placed ? Color.accentSage : Color.inkTaupe)
            }
            LockWidgetMockPreview(widget: w)
        }
        .cozyCard(padding: 12)
    }
}

/// Ô mô phỏng Lock Screen Rectangular hiện đại, dùng chung cho TodayView & Hướng dẫn.
struct LockWidgetMockPreview: View {
    @Environment(AppModel.self) private var model
    var widget: CozyLockWidget

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            ForEach(Array(lines.enumerated()), id: \.offset) { i, line in
                Text(line)
                    .font(.system(size: i == 0 ? 15 : 12.5, weight: i == 0 ? .bold : .medium))
                    .foregroundStyle(.white.opacity(i == 0 ? 1 : 0.8))
                    .lineLimit(1)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color(RGBA(hex: "#1C1C22")!))
        )
    }

    private var lines: [String] {
        switch widget {
        case .schedule:
            let pending = model.todaySchedule.filter { !$0.isDone }
            guard !pending.isEmpty else { return ["Hôm nay", "Trống lịch hôm nay"] }
            return ["Hôm nay"] + pending.prefix(2).map { "\($0.timeText.map { "\($0) " } ?? "")\($0.title)" }
        case .vocab:
            guard let word = model.currentWord else { return ["Từ vựng", "Chọn kho từ"] }
            return [word.word, word.phonetic, word.meaning].filter { !$0.isEmpty }
        case .weather:
            guard let weather = model.snapshot.weather else { return ["Thời tiết", "Đang tải…"] }
            return [
                "\(weather.temperatureText) \(weather.placeName)",
                "\(weather.condition.displayName) · ↑\(Int(weather.highC.rounded()))° ↓\(Int(weather.lowC.rounded()))°",
                "Cảm giác \(Int(weather.apparentC.rounded()))° · Ẩm \(Int((weather.humidity * 100).rounded()))%",
            ]
        case .partner:
            guard let p = model.couple?.partner(of: DemoData.meID) else { return ["Chưa kết nối", "Mở Kết nối"] }
            return [
                p.displayName,
                p.mood.map { "\($0.emoji) \($0.displayName)" } ?? "Đã kết nối",
                p.note.isEmpty ? (p.weatherLine ?? "Đang kết nối") : p.note,
            ]
        }
    }
}
