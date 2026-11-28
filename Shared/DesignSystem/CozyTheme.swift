import SwiftUI
import CozyCore

// MARK: - Colors

extension Color {
    init(_ rgba: RGBA) {
        self.init(.sRGB, red: rgba.red, green: rgba.green, blue: rgba.blue, opacity: rgba.alpha)
    }

    /// Màu token tự đổi theo sáng/tối.
    init(_ token: ColorToken) {
        #if canImport(UIKit)
        self.init(UIColor { trait in
            let c = trait.userInterfaceStyle == .dark ? token.darkRGBA : token.rgba
            return UIColor(red: c.red, green: c.green, blue: c.blue, alpha: c.alpha)
        })
        #else
        self.init(token.rgba)
        #endif
    }

    static let bgCream = Color(ColorToken.bgCream)
    static let cardIvory = Color(ColorToken.cardIvory)
    static let cardBorder = Color(ColorToken.cardBorder)
    static let inkCoffee = Color(ColorToken.inkCoffee)
    static let inkTaupe = Color(ColorToken.inkTaupe)
    static let accentSage = Color(ColorToken.accentSage)
    static let accentPeach = Color(ColorToken.accentPeach)
    static let accentHoney = Color(ColorToken.accentHoney)
    static let accentSky = Color(ColorToken.accentSky)
}

extension AppAppearance {
    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}

// MARK: - Typography

enum CozyFont {
    /// SF Pro Rounded cho tiêu đề/con số.
    static func title(_ size: CGFloat = 22, weight: Font.Weight = .bold) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }

    /// SF Pro Text cho nội dung nhỏ.
    static func body(_ size: CGFloat = 15, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .default)
    }

    static func number(_ size: CGFloat) -> Font {
        .system(size: size, weight: .heavy, design: .rounded).monospacedDigit()
    }
}

extension WidgetFontStyle {
    /// Font hiển thị trên widget theo lựa chọn của người dùng.
    func font(size: CGFloat, weight: Font.Weight = .semibold) -> Font {
        switch self {
        case .cozyRounded:
            return .system(size: size, weight: weight, design: .rounded)
        case .editorialSerif:
            return .system(size: size, weight: weight, design: .serif)
        case .cleanModern:
            return .system(size: size, weight: weight, design: .default)
        case .cuteHandwritten:
            // Font viết tay có sẵn trên iOS; có thể thay bằng font tùy chỉnh trong Resources/Fonts.
            return .custom("Noteworthy-Bold", size: size * 1.05, relativeTo: .body)
        }
    }
}

extension WidgetTheme {
    var background: Color {
        switch self {
        case .paper: return Color(RGBA(hex: "#FFFDF9")!)
        case .watercolor: return Color(RGBA(hex: "#F4EEF6")!)
        case .night: return Color(RGBA(hex: "#2A251F")!)
        case .festive: return Color(RGBA(hex: "#FCE9DF")!)
        }
    }

    var ink: Color {
        self == .night ? Color(RGBA(hex: "#F3EDE4")!) : Color(RGBA(hex: "#3D352E")!)
    }

    var secondaryInk: Color {
        self == .night ? Color(RGBA(hex: "#B3A89C")!) : Color(RGBA(hex: "#8C8278")!)
    }

    /// Lớp gradient nhẹ giả hiệu ứng màu nước.
    func wash(accent: Color) -> LinearGradient {
        switch self {
        case .watercolor:
            return LinearGradient(colors: [accent.opacity(0.28), accent.opacity(0.05), .clear], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .festive:
            return LinearGradient(colors: [Color.accentPeach.opacity(0.35), Color.accentHoney.opacity(0.2)], startPoint: .top, endPoint: .bottom)
        case .night:
            return LinearGradient(colors: [accent.opacity(0.18), .clear], startPoint: .top, endPoint: .bottom)
        case .paper:
            return LinearGradient(colors: [accent.opacity(0.10), .clear], startPoint: .topLeading, endPoint: .center)
        }
    }
}

// MARK: - Ambient Pastel Background

/// Nền giấy kem kèm các vệt màu nước pastel siêu dịu cho toàn màn hình.
struct CozyAmbientBackground: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ZStack {
            Color.bgCream
            Circle()
                .fill(Color.accentPeach.opacity(colorScheme == .dark ? 0.14 : 0.20))
                .frame(width: 280, height: 280)
                .blur(radius: 75)
                .offset(x: 130, y: -260)
            Circle()
                .fill(Color.accentHoney.opacity(colorScheme == .dark ? 0.10 : 0.18))
                .frame(width: 240, height: 240)
                .blur(radius: 70)
                .offset(x: -140, y: -120)
            Circle()
                .fill(Color.accentSky.opacity(colorScheme == .dark ? 0.10 : 0.16))
                .frame(width: 260, height: 260)
                .blur(radius: 80)
                .offset(x: -100, y: 280)
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }
}

// MARK: - Card

struct CozyCardModifier: ViewModifier {
    var accent: Color?
    var padding: CGFloat = 16

    func body(content: Content) -> some View {
        let shape = RoundedRectangle(cornerRadius: CozyMetrics.cardCornerRadius, style: .continuous)
        content
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                shape
                    .fill(Color.cardIvory)
                    .overlay {
                        if let accent {
                            shape.fill(
                                LinearGradient(
                                    colors: [accent.opacity(0.16), accent.opacity(0.04), .clear],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                        }
                    }
            )
            .overlay(
                shape.strokeBorder(
                    accent?.opacity(0.24) ?? Color.cardBorder,
                    lineWidth: CozyMetrics.cardBorderWidth
                )
            )
            .shadow(color: Color.inkCoffee.opacity(0.06), radius: 14, x: 0, y: 6)
    }
}

extension View {
    func cozyCard(accent: Color? = nil, padding: CGFloat = 16) -> some View {
        modifier(CozyCardModifier(accent: accent, padding: padding))
    }
}

// MARK: - Cute Reusable Pieces

struct CozySectionHeader: View {
    var title: String
    var symbol: String
    var accent: Color
    var trailing: String?
    var animatedIcon: CozyIconKind? = nil

    var body: some View {
        HStack(spacing: 9) {
            if let animatedIcon {
                CozyAnimatedIcon(kind: animatedIcon, accent: accent, size: 30)
            } else {
                Image(systemName: symbol)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 28, height: 28)
                    .background(
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [accent, accent.opacity(0.78)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    )
                    .shadow(color: accent.opacity(0.28), radius: 5, y: 2)
            }
            Text(title)
                .font(CozyFont.title(17))
                .foregroundStyle(Color.inkCoffee)
            Spacer()
            if let trailing {
                Text(trailing)
                    .font(CozyFont.body(11, weight: .semibold))
                    .foregroundStyle(Color.inkTaupe)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(accent.opacity(0.12)))
            }
        }
    }
}

struct CozyBadgePill: View {
    var text: String
    var symbol: String?
    var tint: Color

    var body: some View {
        HStack(spacing: 4) {
            if let symbol {
                Image(systemName: symbol)
                    .font(.system(size: 11, weight: .bold))
            }
            Text(text)
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .lineLimit(1)
        }
        .foregroundStyle(Color.inkCoffee)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(Color.cardIvory.opacity(0.92))
                .overlay(Capsule().fill(tint.opacity(0.14)))
        )
        .overlay(Capsule().strokeBorder(tint.opacity(0.28), lineWidth: 1))
    }
}

struct CozySpeechBubble: View {
    var text: String
    var tint: Color = .accentPeach

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "sparkle")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(tint)
                .symbolEffect(.pulse.byLayer, options: .repeating.speed(0.5))
            Text(text)
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundStyle(Color.inkCoffee)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.cardIvory)
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(tint.opacity(0.10))
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(tint.opacity(0.25), lineWidth: 1)
        )
    }
}

struct CozyPillButtonStyle: ButtonStyle {
    var tint: Color
    var filled = true

    func makeBody(configuration: Configuration) -> some View {
        // Áp dụng Playful Button Press (motion-design skill): squash-and-stretch + shadow shrink + spring settle
        configuration.label
            .font(.system(size: 14, weight: .semibold, design: .rounded))
            .padding(.horizontal, 14)
            .padding(.vertical, 9)
            .foregroundStyle(filled ? Color.white : tint)
            .background(
                Capsule()
                    .fill(filled ? tint : tint.opacity(0.14))
                    .shadow(
                        color: filled ? tint.opacity(configuration.isPressed ? 0.12 : 0.28) : .clear,
                        radius: configuration.isPressed ? 2 : 7,
                        y: configuration.isPressed ? 1 : 3.5
                    )
            )
            .scaleEffect(x: configuration.isPressed ? 1.03 : 1, y: configuration.isPressed ? 0.93 : 1)
            .offset(y: configuration.isPressed ? 1.5 : 0)
            .animation(CozyMotionTokens.playfulSpring, value: configuration.isPressed)
    }
}

extension ColorToken {
    var color: Color { Color(self) }
}
