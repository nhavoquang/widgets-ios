import SwiftUI
import CozyCore

// MARK: - CozyDaily Brand Motion Identity (theo LottieFiles motion-design skill — Playful Archetype)

enum CozyMotionTokens {
    /// Duration palette (Playful archetype)
    static let quick: Double = 0.15
    static let standard: Double = 0.25
    static let slow: Double = 0.40

    /// Signature easing: bouncy overshoot 10-18%
    static let playfulSpring = Animation.spring(response: 0.28, dampingFraction: 0.62)
    static let gentleFloat = Animation.easeInOut(duration: 2.6).repeatForever(autoreverses: true)
    static let cardEnter = Animation.spring(response: 0.34, dampingFraction: 0.76)
}

/// Bộ icon động phong cách LottieFiles (duotone bo tròn, có đủ 3 lớp: Primary + Secondary + Ambient).
/// - Trong Main App: chuyển động mượt bằng TimelineView / spring, tự dừng khi bật Reduce Motion.
/// - Trong Widget (`animated: false`): hiển thị bản tĩnh duotone sắc nét, không tốn pin.
enum CozyIconKind: String, CaseIterable, Sendable {
    case vocab
    case mood
    case weather
    case calendar
    case heart
    case flame
    case settings
    case sparkles
}

struct CozyAnimatedIcon: View {
    var kind: CozyIconKind
    var accent: Color
    var size: CGFloat = 30
    var animated: Bool = true

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var scenePhase

    private var isActive: Bool { animated && !reduceMotion && scenePhase == .active }

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 24.0, paused: !isActive)) { context in
            let t = isActive ? context.date.timeIntervalSinceReferenceDate : 0
            ZStack {
                // Layer 3 — Ambient: nền tròn pastel có vòng sáng thở nhẹ
                ambientHalo(t: t)
                // Layer 1 + 2 — Primary & Secondary duotone icon
                iconLayers(t: t)
            }
            .frame(width: size, height: size)
        }
    }

    private func ambientHalo(t: Double) -> some View {
        let pulse = isActive ? (0.5 + 0.5 * sin(t * 2.1)) : 0.4
        return ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [accent.opacity(0.32), accent.opacity(0.12)],
                        center: UnitPoint(x: 0.3, y: 0.25),
                        startRadius: 1,
                        endRadius: size * 0.6
                    )
                )
                .scaleEffect(1 + 0.04 * pulse)
            Circle()
                .strokeBorder(accent.opacity(0.35 + 0.15 * pulse), lineWidth: max(1, size * 0.04))
        }
    }

    @ViewBuilder
    private func iconLayers(t: Double) -> some View {
        switch kind {
        case .vocab:
            let sway = isActive ? sin(t * 2.4) * 5 : 0
            let sparkleScale = isActive ? 0.72 + 0.35 * (0.5 + 0.5 * sin(t * 3.8)) : 0.9
            ZStack {
                Image(systemName: "book.closed.fill")
                    .font(.system(size: size * 0.46, weight: .bold))
                    .foregroundStyle(accent)
                    .rotationEffect(.degrees(sway), anchor: .bottom)
                Image(systemName: "sparkle")
                    .font(.system(size: size * 0.22, weight: .bold))
                    .foregroundStyle(Color.accentHoney)
                    .scaleEffect(sparkleScale)
                    .offset(x: size * 0.24, y: -size * 0.24)
            }

        case .mood:
            let bounce = isActive ? sin(t * 2.8) : 0
            let tilt = isActive ? sin(t * 1.9) * 6 : 0
            ZStack {
                Circle()
                    .fill(accent)
                    .frame(width: size * 0.56, height: size * 0.56)
                    .scaleEffect(x: 1 - 0.03 * bounce, y: 1 + 0.04 * bounce)
                Image(systemName: "face.smiling.inverse")
                    .font(.system(size: size * 0.48, weight: .semibold))
                    .foregroundStyle(.white)
                    .rotationEffect(.degrees(tilt))
            }

        case .weather:
            let sunSpin = isActive ? (t * 26).truncatingRemainder(dividingBy: 360) : 0
            let cloudDrift = isActive ? sin(t * 2.0) * (size * 0.06) : 0
            ZStack {
                Image(systemName: "sun.max.fill")
                    .font(.system(size: size * 0.34, weight: .bold))
                    .foregroundStyle(Color.accentHoney)
                    .rotationEffect(.degrees(sunSpin))
                    .offset(x: size * 0.12, y: -size * 0.12)
                Image(systemName: "cloud.fill")
                    .font(.system(size: size * 0.42, weight: .bold))
                    .foregroundStyle(accent)
                    .shadow(color: .white.opacity(0.6), radius: 1, y: -0.5)
                    .offset(x: -size * 0.06 + cloudDrift, y: size * 0.08)
            }

        case .calendar:
            let bob = isActive ? abs(sin(t * 2.5)) * (-size * 0.05) : 0
            ZStack {
                Image(systemName: "calendar")
                    .font(.system(size: size * 0.48, weight: .bold))
                    .foregroundStyle(accent)
                Circle()
                    .fill(Color.accentPeach)
                    .frame(width: size * 0.16, height: size * 0.16)
                    .offset(x: size * 0.14, y: size * 0.12 + bob)
            }

        case .heart:
            // Nhịp đập lub-dub đôi vui tươi
            let cycle = t.truncatingRemainder(dividingBy: 1.6)
            let beat: Double = {
                guard isActive else { return 0 }
                if cycle < 0.18 { return sin(cycle / 0.18 * .pi) }
                if cycle > 0.24 && cycle < 0.42 { return 0.7 * sin((cycle - 0.24) / 0.18 * .pi) }
                return 0
            }()
            ZStack {
                Image(systemName: "heart.fill")
                    .font(.system(size: size * 0.48, weight: .bold))
                    .foregroundStyle(
                        LinearGradient(colors: [accent, Color(RGBA(hex: "#F27B9B")!)], startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                    .scaleEffect(1 + 0.16 * beat)
                Image(systemName: "sparkle")
                    .font(.system(size: size * 0.20, weight: .bold))
                    .foregroundStyle(Color.accentHoney)
                    .opacity(0.5 + 0.5 * beat)
                    .offset(x: size * 0.24, y: -size * 0.22 - size * 0.06 * beat)
            }

        case .flame:
            let flicker = isActive ? sin(t * 5.2) : 0
            let sway = isActive ? sin(t * 3.1) * 5 : 0
            ZStack {
                Image(systemName: "flame.fill")
                    .font(.system(size: size * 0.50, weight: .bold))
                    .foregroundStyle(
                        LinearGradient(colors: [Color.accentHoney, accent], startPoint: .top, endPoint: .bottom)
                    )
                    .scaleEffect(x: 1 - 0.06 * flicker, y: 1 + 0.09 * flicker, anchor: .bottom)
                    .rotationEffect(.degrees(sway), anchor: .bottom)
            }

        case .settings:
            let spin = isActive ? (t * 22).truncatingRemainder(dividingBy: 360) : 0
            ZStack {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: size * 0.48, weight: .bold))
                    .foregroundStyle(accent)
                    .rotationEffect(.degrees(spin))
                Circle()
                    .fill(Color.cardIvory)
                    .frame(width: size * 0.15, height: size * 0.15)
            }

        case .sparkles:
            let a = isActive ? sin(t * 2.8) : 0
            let b = isActive ? cos(t * 3.4) : 0
            ZStack {
                Image(systemName: "sparkle")
                    .font(.system(size: size * 0.44, weight: .bold))
                    .foregroundStyle(accent)
                    .scaleEffect(1 + 0.12 * a)
                    .rotationEffect(.degrees(a * 12))
                Image(systemName: "sparkle")
                    .font(.system(size: size * 0.22, weight: .bold))
                    .foregroundStyle(Color.accentPeach)
                    .scaleEffect(0.85 + 0.22 * b)
                    .offset(x: size * 0.22, y: -size * 0.20)
            }
        }
    }
}
