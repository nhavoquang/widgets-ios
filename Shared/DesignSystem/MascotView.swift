import SwiftUI
import CozyCore
#if canImport(WidgetKit)
import WidgetKit
#endif

/// Linh vật biểu cảm kawaii phong cách 3D Plush/Clay mềm mịn.
/// Nếu có asset minh họa `assetName` trong Assets.xcassets thì dùng ảnh,
/// nếu chưa có thì vẽ linh vật vector 3D thuần SwiftUI (đổ bóng khối cầu, má hồng,
/// mắt đổi biểu cảm + chớp mắt, tai khẽ nhúc nhích, phụ kiện trong sticker tròn pastel).
struct MascotView: View {
    var state: MascotState
    var size: CGFloat = 64
    var showsBackground = true
    var animated = true
    var isBlinking = false
    var earWiggle: Double = 0

    @State private var bob = false

    var body: some View {
        ZStack {
            if showsBackground {
                backdrop
            }
            content
                .offset(y: animated && bob ? -size * 0.035 : 0)
        }
        .frame(width: size, height: size)
        .onAppear {
            guard animated else { return }
            withAnimation(.easeInOut(duration: animationDuration).repeatForever(autoreverses: true)) { bob = true }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(state.caption)
    }

    private var backdrop: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color.cardIvory, backdropTint.opacity(0.28), backdropTint.opacity(0.14)],
                        center: UnitPoint(x: 0.32, y: 0.28),
                        startRadius: size * 0.06,
                        endRadius: size * 0.65
                    )
                )
            // Viền sáng 3D nhẹ mặt trên
            Circle()
                .strokeBorder(
                    LinearGradient(
                        colors: [Color.white.opacity(0.8), backdropTint.opacity(0.45)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: max(1.2, size * 0.024)
                )
            // Đốm sáng pha lê nhỏ góc trên trái
            Circle()
                .fill(Color.white.opacity(0.8))
                .frame(width: size * 0.085, height: size * 0.085)
                .offset(x: -size * 0.28, y: -size * 0.26)
            Circle()
                .fill(Color.white.opacity(0.6))
                .frame(width: size * 0.045, height: size * 0.045)
                .offset(x: -size * 0.19, y: -size * 0.34)
        }
        .shadow(color: backdropTint.opacity(0.22), radius: size * 0.10, y: size * 0.04)
    }

    private var backdropTint: Color {
        switch state.species {
        case .cat: return .accentPeach
        case .dog: return .accentHoney
        case .bunny: return Color(RGBA(hex: "#F2A9B8")!)
        case .bear: return Color(RGBA(hex: "#C89B74")!)
        }
    }

    @ViewBuilder
    private var content: some View {
        #if canImport(UIKit)
        if UIImage(named: state.assetName) != nil {
            Image(state.assetName).resizable().scaledToFit().padding(size * 0.08)
        } else {
            CuteMascotIllustration(state: state, size: size, isBlinking: isBlinking, earWiggle: earWiggle)
        }
        #else
        CuteMascotIllustration(state: state, size: size, isBlinking: isBlinking, earWiggle: earWiggle)
        #endif
    }

    private var animationDuration: Double {
        switch state.pose {
        case .jumping, .bouncing: return 0.45
        case .rushing: return 0.32
        case .sleeping, .yawning: return 2.2
        default: return 1.45
        }
    }
}

// MARK: - Minh họa linh vật 3D Plush/Clay Kawaii thuần SwiftUI

private struct CuteMascotIllustration: View {
    var state: MascotState
    var size: CGFloat
    var isBlinking: Bool
    var earWiggle: Double

    private let ink = Color(RGBA(hex: "#4A3A31")!)
    private let blush = Color(RGBA(hex: "#F58FA8")!)
    private let innerPink = Color(RGBA(hex: "#F9B4C4")!)

    var body: some View {
        ZStack {
            // Bóng nền 3D mềm dưới cằm tạo cảm giác nổi khối
            Ellipse()
                .fill(Color(RGBA(hex: "#5B4333")!).opacity(0.16))
                .frame(width: size * 0.54, height: size * 0.12)
                .blur(radius: max(1.5, size * 0.03))
                .offset(y: size * 0.36)

            // Tai phía sau có độ nhúc nhích đáng yêu
            ears
                .offset(y: -size * 0.02)

            // Đầu tròn khối cầu 3D mềm mịn
            head
                .offset(y: size * 0.05)

            // Gương mặt biểu cảm
            face
                .offset(y: size * 0.07)

            // Hai bàn chân tròn 3D dưới cằm
            paws
                .offset(y: size * 0.33)

            // Biểu tượng nhỏ theo tư thế (zZz, lấp lánh, tim)
            poseEmbellishment

            // Phụ kiện thời tiết & khung giờ trong sticker tròn 3D
            accessoryBadges
        }
        .rotationEffect(.degrees(state.pose == .sleeping ? -7 : (state.pose == .rushing ? 5 : 0)))
    }

    // MARK: Palette 3D theo loài (Highlight -> Midtone -> Soft Shade)

    private var furHighlight: Color {
        switch state.species {
        case .cat: return Color(RGBA(hex: "#FFF9F0")!)
        case .dog: return Color(RGBA(hex: "#FFF0D1")!)
        case .bunny: return Color(RGBA(hex: "#FFFFFF")!)
        case .bear: return Color(RGBA(hex: "#EED0B4")!)
        }
    }

    private var furMid: Color {
        switch state.species {
        case .cat: return Color(RGBA(hex: "#FCE0BE")!)
        case .dog: return Color(RGBA(hex: "#F4CE95")!)
        case .bunny: return Color(RGBA(hex: "#FAF3EE")!)
        case .bear: return Color(RGBA(hex: "#D7AC84")!)
        }
    }

    private var furShadow: Color {
        switch state.species {
        case .cat: return Color(RGBA(hex: "#E9B585")!)
        case .dog: return Color(RGBA(hex: "#DC9F5B")!)
        case .bunny: return Color(RGBA(hex: "#E8D7CE")!)
        case .bear: return Color(RGBA(hex: "#B58259")!)
        }
    }

    private var earAccent: Color {
        switch state.species {
        case .cat: return Color(RGBA(hex: "#F1BC92")!)
        case .dog: return Color(RGBA(hex: "#BE7F47")!)
        case .bunny: return Color(RGBA(hex: "#F6E9E2")!)
        case .bear: return Color(RGBA(hex: "#BF8C62")!)
        }
    }

    // MARK: Ears

    @ViewBuilder
    private var ears: some View {
        switch state.species {
        case .cat:
            HStack(spacing: size * 0.14) {
                catEar.rotationEffect(.degrees(-14 - earWiggle))
                catEar.rotationEffect(.degrees(14 + earWiggle))
            }
            .offset(y: -size * 0.22)
        case .dog:
            HStack(spacing: size * 0.44) {
                dogEar.rotationEffect(.degrees(18 + earWiggle))
                dogEar.rotationEffect(.degrees(-18 - earWiggle))
            }
            .offset(y: size * 0.03)
        case .bunny:
            HStack(spacing: size * 0.09) {
                bunnyEar.rotationEffect(.degrees(-10 - earWiggle * 1.4))
                bunnyEar.rotationEffect(.degrees(10 + earWiggle * 1.4))
            }
            .offset(y: -size * 0.26)
        case .bear:
            HStack(spacing: size * 0.26) {
                bearEar.rotationEffect(.degrees(-earWiggle * 0.5))
                bearEar.rotationEffect(.degrees(earWiggle * 0.5))
            }
            .offset(y: -size * 0.21)
        }
    }

    private var catEar: some View {
        ZStack {
            RoundedTriangle()
                .fill(LinearGradient(colors: [furMid, furShadow], startPoint: .top, endPoint: .bottom))
                .frame(width: size * 0.24, height: size * 0.24)
                .overlay(RoundedTriangle().stroke(ink.opacity(0.24), lineWidth: max(0.8, size * 0.014)))
            RoundedTriangle()
                .fill(LinearGradient(colors: [innerPink, Color(RGBA(hex: "#EF8CA3")!)], startPoint: .top, endPoint: .bottom))
                .frame(width: size * 0.13, height: size * 0.13)
                .offset(y: size * 0.025)
        }
    }

    private var dogEar: some View {
        RoundedRectangle(cornerRadius: size * 0.11, style: .continuous)
            .fill(
                RadialGradient(
                    colors: [Color(RGBA(hex: "#D99C64")!), earAccent],
                    center: UnitPoint(x: 0.35, y: 0.25),
                    startRadius: size * 0.02,
                    endRadius: size * 0.22
                )
            )
            .frame(width: size * 0.19, height: size * 0.31)
            .overlay(RoundedRectangle(cornerRadius: size * 0.11, style: .continuous).strokeBorder(ink.opacity(0.24), lineWidth: max(0.8, size * 0.014)))
            .shadow(color: ink.opacity(0.12), radius: 2, y: 1.5)
    }

    private var bunnyEar: some View {
        ZStack {
            Capsule()
                .fill(LinearGradient(colors: [furHighlight, furShadow], startPoint: .topLeading, endPoint: .bottomTrailing))
                .frame(width: size * 0.175, height: size * 0.36)
                .overlay(Capsule().strokeBorder(ink.opacity(0.22), lineWidth: max(0.8, size * 0.014)))
            Capsule()
                .fill(LinearGradient(colors: [innerPink, Color(RGBA(hex: "#F299B0")!)], startPoint: .top, endPoint: .bottom))
                .frame(width: size * 0.088, height: size * 0.23)
                .offset(y: size * 0.015)
        }
    }

    private var bearEar: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [furMid, earAccent],
                        center: UnitPoint(x: 0.35, y: 0.3),
                        startRadius: size * 0.02,
                        endRadius: size * 0.15
                    )
                )
                .frame(width: size * 0.22, height: size * 0.22)
                .overlay(Circle().strokeBorder(ink.opacity(0.22), lineWidth: max(0.8, size * 0.014)))
            Circle()
                .fill(Color(RGBA(hex: "#F9E7D2")!))
                .frame(width: size * 0.11, height: size * 0.11)
        }
    }

    // MARK: Head (3D Plush Sphere)

    private var head: some View {
        ZStack {
            Ellipse()
                .fill(
                    RadialGradient(
                        colors: [furHighlight, furMid, furShadow],
                        center: UnitPoint(x: 0.34, y: 0.24),
                        startRadius: size * 0.04,
                        endRadius: size * 0.44
                    )
                )
                .frame(width: size * 0.65, height: size * 0.57)
                .overlay(
                    // Điểm bóng mượt trên trán tạo chất liệu đất sét/gấu bông 3D
                    Ellipse()
                        .fill(Color.white.opacity(0.45))
                        .frame(width: size * 0.22, height: size * 0.095)
                        .rotationEffect(.degrees(-14))
                        .offset(x: -size * 0.10, y: -size * 0.17)
                )
                .overlay(
                    Ellipse().strokeBorder(ink.opacity(0.22), lineWidth: max(0.9, size * 0.015))
                )
                .shadow(color: furShadow.opacity(0.35), radius: size * 0.06, y: size * 0.03)

            // Điểm nhấn đặc trưng từng loài
            switch state.species {
            case .cat:
                HStack(spacing: size * 0.034) {
                    Capsule().fill(Color(RGBA(hex: "#D69C6E")!)).frame(width: size * 0.026, height: size * 0.072)
                    Capsule().fill(Color(RGBA(hex: "#D69C6E")!)).frame(width: size * 0.028, height: size * 0.098)
                    Capsule().fill(Color(RGBA(hex: "#D69C6E")!)).frame(width: size * 0.026, height: size * 0.072)
                }
                .offset(y: -size * 0.205)
            case .dog:
                Ellipse()
                    .fill(
                        RadialGradient(colors: [.white, Color(RGBA(hex: "#FFF3E0")!)], center: .top, startRadius: 1, endRadius: size * 0.16)
                    )
                    .frame(width: size * 0.27, height: size * 0.185)
                    .offset(y: size * 0.09)
            case .bear:
                Ellipse()
                    .fill(
                        RadialGradient(colors: [.white, Color(RGBA(hex: "#F6E5D2")!)], center: .top, startRadius: 1, endRadius: size * 0.16)
                    )
                    .frame(width: size * 0.28, height: size * 0.195)
                    .offset(y: size * 0.085)
            case .bunny:
                EmptyView()
            }
        }
    }

    // MARK: Face

    private var face: some View {
        ZStack {
            // Má hồng 3D mềm tan
            HStack(spacing: size * 0.30) {
                blushSpot
                blushSpot
            }
            .offset(y: size * 0.045)

            // Râu mèo
            if state.species == .cat {
                HStack(spacing: size * 0.44) {
                    whiskers(left: true)
                    whiskers(left: false)
                }
                .offset(y: size * 0.045)
            }

            // Đôi mắt biểu cảm + chớp mắt tự nhiên
            HStack(spacing: size * 0.17) {
                eye
                eye
            }
            .offset(y: -size * 0.02)

            // Mũi bóng 3D + Miệng
            VStack(spacing: size * 0.008) {
                ZStack {
                    Ellipse()
                        .fill(state.species == .bunny ? Color(RGBA(hex: "#EE8FA5")!) : ink)
                        .frame(width: size * 0.064, height: size * 0.044)
                    Circle()
                        .fill(.white.opacity(0.65))
                        .frame(width: size * 0.018, height: size * 0.018)
                        .offset(x: -size * 0.012, y: -size * 0.008)
                }
                mouth
            }
            .offset(y: size * 0.06)
        }
    }

    private var blushSpot: some View {
        Ellipse()
            .fill(
                RadialGradient(colors: [blush.opacity(0.6), blush.opacity(0.05)], center: .center, startRadius: 0, endRadius: size * 0.075)
            )
            .frame(width: size * 0.135, height: size * 0.085)
    }

    @ViewBuilder
    private var eye: some View {
        if isBlinking {
            ArcSmile(upward: false)
                .stroke(ink, style: StrokeStyle(lineWidth: max(1.4, size * 0.026), lineCap: .round))
                .frame(width: size * 0.095, height: size * 0.038)
        } else {
            switch state.pose {
            case .sleeping, .yawning:
                ArcSmile(upward: false)
                    .stroke(ink, style: StrokeStyle(lineWidth: max(1.4, size * 0.028), lineCap: .round))
                    .frame(width: size * 0.095, height: size * 0.045)
            case .bouncing, .jumping:
                ArcSmile(upward: true)
                    .stroke(ink, style: StrokeStyle(lineWidth: max(1.5, size * 0.03), lineCap: .round))
                    .frame(width: size * 0.095, height: size * 0.05)
            case .slumped:
                ZStack {
                    Circle().fill(ink).frame(width: size * 0.078, height: size * 0.078)
                    Rectangle().fill(furMid).frame(width: size * 0.095, height: size * 0.04).offset(y: -size * 0.025)
                }
            case .hugging:
                ZStack {
                    Circle().fill(ink).frame(width: size * 0.098, height: size * 0.098)
                    Circle().fill(.white).frame(width: size * 0.036, height: size * 0.036).offset(x: -size * 0.018, y: -size * 0.018)
                    Circle().fill(.white.opacity(0.9)).frame(width: size * 0.019, height: size * 0.019).offset(x: size * 0.02, y: size * 0.018)
                }
            default:
                ZStack {
                    Circle().fill(ink).frame(width: size * 0.088, height: size * 0.088)
                    Circle().fill(.white).frame(width: size * 0.032, height: size * 0.032).offset(x: -size * 0.016, y: -size * 0.018)
                    Circle().fill(.white.opacity(0.6)).frame(width: size * 0.014, height: size * 0.014).offset(x: size * 0.018, y: size * 0.018)
                }
            }
        }
    }

    @ViewBuilder
    private var mouth: some View {
        switch state.pose {
        case .yawning:
            Circle()
                .fill(Color(RGBA(hex: "#E88795")!))
                .frame(width: size * 0.06, height: size * 0.065)
                .overlay(Circle().strokeBorder(ink.opacity(0.45), lineWidth: max(0.7, size * 0.012)))
        case .slumped:
            ArcSmile(upward: true)
                .stroke(ink, style: StrokeStyle(lineWidth: max(1.1, size * 0.022), lineCap: .round))
                .frame(width: size * 0.08, height: size * 0.03)
        default:
            ZStack(alignment: .bottom) {
                CatMouthShape()
                    .stroke(ink, style: StrokeStyle(lineWidth: max(1.2, size * 0.022), lineCap: .round, lineJoin: .round))
                    .frame(width: size * 0.11, height: size * 0.04)
                if state.species == .dog && (state.pose == .bouncing || state.pose == .jumping) {
                    Capsule()
                        .fill(Color(RGBA(hex: "#F28B9C")!))
                        .frame(width: size * 0.045, height: size * 0.042)
                        .offset(y: size * 0.024)
                }
            }
        }
    }

    private func whiskers(left: Bool) -> some View {
        VStack(spacing: size * 0.028) {
            Capsule().fill(ink.opacity(0.30)).frame(width: size * 0.085, height: max(0.8, size * 0.014))
                .rotationEffect(.degrees(left ? 10 : -10))
            Capsule().fill(ink.opacity(0.30)).frame(width: size * 0.075, height: max(0.8, size * 0.014))
                .rotationEffect(.degrees(left ? -8 : 8))
        }
    }

    // MARK: Paws (3D Plush)

    private var paws: some View {
        HStack(spacing: size * 0.16) {
            paw
            paw
        }
    }

    private var paw: some View {
        Ellipse()
            .fill(RadialGradient(colors: [furHighlight, furMid], center: .topLeading, startRadius: 1, endRadius: size * 0.1))
            .frame(width: size * 0.14, height: size * 0.10)
            .overlay(Ellipse().strokeBorder(ink.opacity(0.22), lineWidth: max(0.8, size * 0.014)))
            .shadow(color: ink.opacity(0.10), radius: 2, y: 1)
    }

    // MARK: Pose & Accessories

    @ViewBuilder
    private var poseEmbellishment: some View {
        switch state.pose {
        case .sleeping:
            Text("zZ")
                .font(.system(size: max(9, size * 0.16), weight: .heavy, design: .rounded))
                .foregroundStyle(Color.accentSky)
                .offset(x: size * 0.27, y: -size * 0.30)
        case .jumping, .bouncing:
            Image(systemName: "sparkle")
                .font(.system(size: max(9, size * 0.15), weight: .bold))
                .foregroundStyle(Color.accentHoney)
                .offset(x: size * 0.30, y: -size * 0.28)
        case .hugging:
            Image(systemName: "heart.fill")
                .font(.system(size: max(9, size * 0.15)))
                .foregroundStyle(Color.accentPeach)
                .offset(x: size * 0.30, y: -size * 0.27)
        default:
            EmptyView()
        }
    }

    @ViewBuilder
    private var accessoryBadges: some View {
        let items = state.accessories.filter { $0 != .none }
        if !items.isEmpty {
            HStack(spacing: -size * 0.04) {
                ForEach(items.prefix(2), id: \.self) { a in
                    Text(a.emoji)
                        .font(.system(size: max(10, size * 0.21)))
                        .padding(size * 0.045)
                        .background(
                            Circle()
                                .fill(Color.cardIvory)
                                .shadow(color: Color.inkCoffee.opacity(0.15), radius: 3.5, y: 2)
                        )
                        .overlay(Circle().strokeBorder(Color.white.opacity(0.85), lineWidth: 1))
                }
            }
            .offset(x: size * 0.26, y: size * 0.28)
        }
    }
}

private struct RoundedTriangle: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let top = CGPoint(x: rect.midX, y: rect.minY)
        let left = CGPoint(x: rect.minX, y: rect.maxY)
        let right = CGPoint(x: rect.maxX, y: rect.maxY)
        p.move(to: CGPoint(x: rect.midX, y: rect.maxY))
        p.addArc(tangent1End: left, tangent2End: top, radius: rect.width * 0.16)
        p.addArc(tangent1End: top, tangent2End: right, radius: rect.width * 0.22)
        p.addArc(tangent1End: right, tangent2End: left, radius: rect.width * 0.16)
        p.closeSubpath()
        return p
    }
}

private struct ArcSmile: Shape {
    var upward: Bool
    func path(in rect: CGRect) -> Path {
        var p = Path()
        if upward {
            p.move(to: CGPoint(x: rect.minX, y: rect.maxY))
            p.addQuadCurve(to: CGPoint(x: rect.maxX, y: rect.maxY), control: CGPoint(x: rect.midX, y: rect.minY))
        } else {
            p.move(to: CGPoint(x: rect.minX, y: rect.minY))
            p.addQuadCurve(to: CGPoint(x: rect.maxX, y: rect.minY), control: CGPoint(x: rect.midX, y: rect.maxY))
        }
        return p
    }
}

private struct CatMouthShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.minX, y: rect.minY))
        p.addQuadCurve(to: CGPoint(x: rect.midX, y: rect.minY + rect.height * 0.35), control: CGPoint(x: rect.width * 0.25, y: rect.maxY))
        p.addQuadCurve(to: CGPoint(x: rect.maxX, y: rect.minY), control: CGPoint(x: rect.width * 0.75, y: rect.maxY))
        return p
    }
}

/// Bản đơn sắc cho Lock Screen (Tinted/Monochrome).
struct MascotGlyph: View {
    var state: MascotState

    var body: some View {
        ZStack {
            Image(systemName: "pawprint.fill")
                .font(.system(size: 18, weight: .bold))
            Image(systemName: state.pose.symbolName)
                .font(.system(size: 9, weight: .bold))
                .offset(x: 10, y: -10)
        }
        .widgetAccentableIfAvailable()
    }
}

extension View {
    @ViewBuilder
    func widgetAccentableIfAvailable() -> some View {
        #if canImport(WidgetKit)
        self.widgetAccentable()
        #else
        self
        #endif
    }
}
