import SwiftUI
import WidgetKit
import CozyCore

/// 4 widget Lock Screen cốt lõi của CozyDaily.
/// `kind` phải khớp đúng với `kind:` khai báo trong `CozyWidgetsBundle.swift`.
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
        case .schedule: return "Lịch & Việc hôm nay"
        case .vocab: return "Từ vựng hôm nay"
        case .weather: return "Thời tiết thật"
        case .partner: return "Cảm xúc người kết nối"
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

/// Đọc xem widget CozyDaily nào đang được đặt, ở Lock Screen hay Home Screen.
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

/// Nút/thẻ mở màn hướng dẫn, tự quản lý sheet để gắn vào đâu cũng được.
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
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 36, height: 36)
                    .background(Circle().fill(Color.accentPeach))
                VStack(alignment: .leading, spacing: 2) {
                    Text("Thêm widget lên Lock Screen")
                        .font(CozyFont.title(15, weight: .bold))
                        .foregroundStyle(Color.inkCoffee)
                    Text(tracker.lockCount == CozyLockWidget.allCases.count
                         ? "Đã đặt đủ 4/4 widget ✓"
                         : "Đã đặt \(tracker.lockCount)/\(CozyLockWidget.allCases.count) · chạm xem hướng dẫn")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(Color.inkTaupe)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(Color.inkTaupe)
            }
            .cozyCard(accent: .accentPeach, padding: 12)
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showGuide) {
            WidgetSetupGuideSheet(tracker: tracker)
                .presentationCornerRadius(28)
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
                        intro
                        stepsCard
                        ForEach(CozyLockWidget.allCases) { w in
                            widgetCard(w)
                        }
                        Text("iOS không cho app tự thêm widget hay mở thẳng trình chỉnh sửa Lock Screen, nên bước thêm phải do bạn chạm. Quay lại đây là dấu ✓ tự cập nhật.")
                            .font(.caption)
                            .foregroundStyle(Color.inkTaupe)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 8)
                    }
                    .padding(16)
                }
            }
            .navigationTitle("Widget Lock Screen")
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

    private var intro: some View {
        HStack(spacing: 12) {
            AnimatedMascotView(state: model.mascot, size: 64, reaction: tracker.lockCount)
            VStack(alignment: .leading, spacing: 3) {
                Text("Chỉ mất 4 bước, làm 1 lần")
                    .font(CozyFont.title(17, weight: .heavy))
                    .foregroundStyle(Color.inkCoffee)
                Text("Widget sẽ tự cập nhật dữ liệu thật từ app, bạn không cần thêm lại.")
                    .font(CozyFont.body(12.5))
                    .foregroundStyle(Color.inkTaupe)
            }
        }
        .cozyCard(accent: .accentPeach)
    }

    private var stepsCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            step(1, "hand.tap.fill", "Mở khóa máy rồi nhấn giữ Màn hình khóa, chọn Tùy chỉnh → Màn hình khóa.")
            step(2, "rectangle.dashed", "Chạm vào khung ngay dưới đồng hồ (Thêm tiện ích).")
            step(3, "magnifyingglass", "Tìm CozyDaily, chọn widget bên dưới. Hình chữ nhật cho 3 dòng thông tin, hình tròn cho gọn.")
            step(4, "checkmark.circle.fill", "Bấm Xong. Quay lại app để thấy dấu ✓.")
        }
        .cozyCard()
    }

    private func step(_ n: Int, _ symbol: String, _ text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Text("\(n)")
                .font(.system(size: 12, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)
                .frame(width: 22, height: 22)
                .background(Circle().fill(Color.accentPeach))
            Text(text)
                .font(CozyFont.body(13))
                .foregroundStyle(Color.inkCoffee)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
            Image(systemName: symbol)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Color.accentPeach)
                .symbolEffect(.bounce, options: .repeating.speed(0.4))
        }
    }

    private func widgetCard(_ w: CozyLockWidget) -> some View {
        let placed = tracker.isOnLock(w)
        return VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: w.symbol)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 28, height: 28)
                    .background(Circle().fill(w.accent))
                Text(w.title)
                    .font(CozyFont.title(16, weight: .bold))
                    .foregroundStyle(Color.inkCoffee)
                Spacer()
                Label(placed ? "Đã đặt" : "Chưa đặt", systemImage: placed ? "checkmark.circle.fill" : "circle.dashed")
                    .font(.system(size: 11.5, weight: .bold, design: .rounded))
                    .foregroundStyle(placed ? Color.accentSage : Color.inkTaupe)
            }
            preview(w)
        }
        .cozyCard(accent: w.accent, padding: 12)
    }

    /// Mô phỏng ô chữ nhật Lock Screen bằng dữ liệu thật của bạn.
    private func preview(_ w: CozyLockWidget) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            ForEach(Array(lines(w).enumerated()), id: \.offset) { i, line in
                Text(line)
                    .font(.system(size: i == 0 ? 14 : 12, weight: i == 0 ? .bold : .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(i == 0 ? 1 : 0.8))
                    .lineLimit(1)
            }
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(LinearGradient(colors: [Color(RGBA(hex: "#3B4A63")!), Color(RGBA(hex: "#6B5470")!)], startPoint: .topLeading, endPoint: .bottomTrailing))
        )
    }

    private func lines(_ w: CozyLockWidget) -> [String] {
        switch w {
        case .schedule:
            let pending = model.todaySchedule.filter { !$0.isDone }
            guard !pending.isEmpty else { return ["Hôm nay", "Chưa có lịch hay việc nào"] }
            return ["Hôm nay"] + pending.prefix(2).map { "\($0.timeText.map { "\($0) " } ?? "")\($0.title)" }
        case .vocab:
            guard let word = model.currentWord else { return ["Từ vựng hôm nay", "Chọn kho từ trong app"] }
            return [word.word, word.phonetic, word.meaning].filter { !$0.isEmpty }
        case .weather:
            guard let weather = model.snapshot.weather else { return ["Thời tiết", "Đang tải thời tiết thật…"] }
            return [
                "\(weather.temperatureText) \(weather.placeName)",
                "\(weather.condition.displayName) · Cảm giác \(Int(weather.apparentC.rounded()))°",
                "↑\(Int(weather.highC.rounded()))° ↓\(Int(weather.lowC.rounded()))°",
            ]
        case .partner:
            guard let p = model.couple?.partner(of: DemoData.meID) else { return ["Chưa kết nối", "Sang tab Kết nối để ghép đôi"] }
            return [
                "\(p.displayName)\(p.mood.map { " · \($0.displayName)" } ?? "")",
                p.note.isEmpty ? (p.weatherLine ?? "Đang kết nối") : "“\(p.note)”",
            ]
        }
    }
}
