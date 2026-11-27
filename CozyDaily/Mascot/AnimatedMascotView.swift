import SwiftUI
import UIKit
import CozyCore

/// Bộ phát animation (Rive, Lottie…). Thêm provider mới bằng cách đăng ký vào `MascotAnimationRegistry`.
@MainActor
protocol MascotAnimationProvider {
    /// Có file tài nguyên cho tên này trong bundle không.
    func canRender(resource: String) -> Bool
    func makeView(resource: String, state: MascotState, isPaused: Bool) -> AnyView
}

@MainActor
enum MascotAnimationRegistry {
    /// Thử theo thứ tự; không provider nào nhận thì dùng ảnh tĩnh.
    static var providers: [any MascotAnimationProvider] = defaultProviders

    private static var defaultProviders: [any MascotAnimationProvider] {
        var list: [any MascotAnimationProvider] = []
        #if canImport(RiveRuntime)
        list.append(RiveMascotProvider())
        #endif
        #if canImport(Lottie)
        list.append(LottieMascotProvider())
        #endif
        return list
    }

    static func match(for state: MascotState) -> (provider: any MascotAnimationProvider, resource: String)? {
        for asset in MascotAssetManager.candidates(for: state) {
            if let p = providers.first(where: { $0.canRender(resource: asset.animationResourceName) }) {
                return (p, asset.animationResourceName)
            }
        }
        return nil
    }
}

/// Linh vật động trong Main App.
/// - Có file `.riv`/`.json` và thư viện tương ứng: phát animation.
/// - Thiếu file: ảnh tĩnh (hoặc emoji) kèm chuyển động thở/nhún theo tư thế.
/// - Tự dừng khi app không ở foreground; rung nhẹ + nảy khi `reaction` đổi.
struct AnimatedMascotView<Reaction: Equatable>: View {
    var state: MascotState
    var size: CGFloat
    /// Giá trị đại diện cho mood/món ăn; đổi giá trị sẽ kích hoạt hiệu ứng phản hồi.
    var reaction: Reaction

    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var bounce: CGFloat = 1
    @State private var haptic = UIImpactFeedbackGenerator(style: .soft)

    private var isPaused: Bool { scenePhase != .active || reduceMotion }

    var body: some View {
        Group {
            if let match = MascotAnimationRegistry.match(for: state) {
                match.provider.makeView(resource: match.resource, state: state, isPaused: isPaused)
                    .frame(width: size, height: size)
            } else {
                ProceduralMascot(state: state, size: size, isPaused: isPaused)
            }
        }
        .scaleEffect(bounce)
        .onChange(of: reaction) { _, _ in react() }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(state.caption)
    }

    private func react() {
        haptic.impactOccurred()
        haptic.prepare()
        guard !reduceMotion else { return }
        withAnimation(.spring(response: 0.18, dampingFraction: 0.6)) { bounce = 1.16 }
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(160))
            withAnimation(.spring(response: 0.4, dampingFraction: 0.45)) { bounce = 1 }
        }
    }
}

/// Fallback không cần file animation: `TimelineView` dừng hẳn khi `isPaused`.
private struct ProceduralMascot: View {
    var state: MascotState
    var size: CGFloat
    var isPaused: Bool

    private var period: Double {
        switch state.pose {
        case .rushing: return 0.6
        case .jumping, .bouncing: return 0.9
        case .sleeping, .yawning: return 4.4
        default: return 2.8
        }
    }

    private var amplitude: CGFloat {
        switch state.pose {
        case .jumping: return 0.08
        case .bouncing, .rushing: return 0.05
        default: return 0.025
        }
    }

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: isPaused)) { context in
            let t = context.date.timeIntervalSinceReferenceDate
            let wave = isPaused ? 0 : sin(t / period * 2 * .pi)
            MascotView(state: state, size: size, animated: false)
                .scaleEffect(x: 1 - 0.012 * wave, y: 1 + 0.018 * wave, anchor: .bottom)
                .offset(y: -size * amplitude * max(0, wave))
        }
    }
}
