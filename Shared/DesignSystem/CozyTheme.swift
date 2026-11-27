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

// MARK: - Card

struct CozyCardModifier: ViewModifier {
    var accent: Color?
    var padding: CGFloat = 16

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: CozyMetrics.cardCornerRadius, style: .continuous)
                    .fill(Color.cardIvory)
                    .overlay(alignment: .topLeading) {
                        if let accent {
                            RoundedRectangle(cornerRadius: CozyMetrics.cardCornerRadius, style: .continuous)
                                .fill(LinearGradient(colors: [accent.opacity(0.14), .clear], startPoint: .topLeading, endPoint: .center))
                        }
                    }
            )
            .overlay(
                RoundedRectangle(cornerRadius: CozyMetrics.cardCornerRadius, style: .continuous)
                    .strokeBorder(Color.cardBorder, lineWidth: CozyMetrics.cardBorderWidth)
            )
    }
}

extension View {
    func cozyCard(accent: Color? = nil, padding: CGFloat = 16) -> some View {
        modifier(CozyCardModifier(accent: accent, padding: padding))
    }
}

struct CozySectionHeader: View {
    var title: String
    var symbol: String
    var accent: Color
    var trailing: String?

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: symbol)
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 26, height: 26)
                .background(Circle().fill(accent))
            Text(title)
                .font(CozyFont.title(17))
                .foregroundStyle(Color.inkCoffee)
            Spacer()
            if let trailing {
                Text(trailing)
                    .font(CozyFont.body(12, weight: .medium))
                    .foregroundStyle(Color.inkTaupe)
            }
        }
    }
}

struct CozyPillButtonStyle: ButtonStyle {
    var tint: Color
    var filled = true

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(CozyFont.body(14, weight: .semibold))
            .padding(.horizontal, 14)
            .padding(.vertical, 9)
            .foregroundStyle(filled ? Color.white : tint)
            .background(
                Capsule().fill(filled ? tint : tint.opacity(0.14))
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
            .animation(.spring(response: 0.25, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

extension ColorToken {
    var color: Color { Color(self) }
}
