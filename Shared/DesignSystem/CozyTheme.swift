import SwiftUI
import CozyCore

// MARK: - Modern Clean iOS Colors

extension Color {
    init(_ rgba: RGBA) {
        self.init(.sRGB, red: rgba.red, green: rgba.green, blue: rgba.blue, opacity: rgba.alpha)
    }

    /// Bảng màu hiện đại, sạch, tương phản cao cho cả Light & Dark Mode (chuẩn iOS 17/18).
    init(_ token: ColorToken) {
        #if canImport(UIKit)
        self.init(UIColor { trait in
            let isDark = trait.userInterfaceStyle == .dark
            switch token {
            case .bgCream:
                return isDark ? UIColor(red: 0.05, green: 0.05, blue: 0.06, alpha: 1) : UIColor(red: 0.95, green: 0.95, blue: 0.97, alpha: 1)
            case .cardIvory:
                return isDark ? UIColor(red: 0.11, green: 0.11, blue: 0.13, alpha: 1) : UIColor.white
            case .cardBorder:
                return isDark ? UIColor(white: 1, alpha: 0.10) : UIColor(white: 0, alpha: 0.07)
            case .inkCoffee:
                return isDark ? UIColor(white: 0.96, alpha: 1) : UIColor(red: 0.08, green: 0.08, blue: 0.10, alpha: 1)
            case .inkTaupe:
                return isDark ? UIColor(white: 0.62, alpha: 1) : UIColor(red: 0.43, green: 0.43, blue: 0.48, alpha: 1)
            case .accentSky:
                return isDark ? UIColor(red: 0.25, green: 0.62, blue: 1.0, alpha: 1) : UIColor(red: 0.0, green: 0.48, blue: 1.0, alpha: 1)
            case .accentSage:
                return isDark ? UIColor(red: 0.25, green: 0.82, blue: 0.55, alpha: 1) : UIColor(red: 0.16, green: 0.68, blue: 0.42, alpha: 1)
            case .accentPeach:
                return isDark ? UIColor(red: 1.0, green: 0.35, blue: 0.48, alpha: 1) : UIColor(red: 0.95, green: 0.24, blue: 0.38, alpha: 1)
            case .accentHoney:
                return isDark ? UIColor(red: 1.0, green: 0.68, blue: 0.20, alpha: 1) : UIColor(red: 0.95, green: 0.56, blue: 0.05, alpha: 1)
            }
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
    static func title(_ size: CGFloat = 20, weight: Font.Weight = .bold) -> Font {
        .system(size: size, weight: weight, design: .default)
    }

    static func body(_ size: CGFloat = 15, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .default)
    }

    static func number(_ size: CGFloat) -> Font {
        .system(size: size, weight: .bold, design: .rounded).monospacedDigit()
    }
}

extension WidgetFontStyle {
    func font(size: CGFloat, weight: Font.Weight = .semibold) -> Font {
        switch self {
        case .cozyRounded:
            return .system(size: size, weight: weight, design: .rounded)
        case .editorialSerif:
            return .system(size: size, weight: weight, design: .serif)
        case .cleanModern, .cuteHandwritten:
            return .system(size: size, weight: weight, design: .default)
        }
    }
}

extension WidgetTheme {
    var background: Color {
        switch self {
        case .paper: return Color(RGBA(hex: "#FFFFFF")!)
        case .watercolor: return Color(RGBA(hex: "#F2F4F8")!)
        case .night: return Color(RGBA(hex: "#161618")!)
        case .festive: return Color(RGBA(hex: "#FFF5F5")!)
        }
    }

    var ink: Color {
        self == .night ? Color(RGBA(hex: "#F5F5F7")!) : Color(RGBA(hex: "#141416")!)
    }

    var secondaryInk: Color {
        self == .night ? Color(RGBA(hex: "#98989F")!) : Color(RGBA(hex: "#6E6E73")!)
    }

    func wash(accent: Color) -> LinearGradient {
        LinearGradient(colors: [accent.opacity(self == .night ? 0.14 : 0.08), .clear], startPoint: .topLeading, endPoint: .bottomTrailing)
    }
}

// MARK: - Clean Background & Modern Card

struct CozyAmbientBackground: View {
    var body: some View {
        Color.bgCream.ignoresSafeArea()
    }
}

struct CozyCardModifier: ViewModifier {
    var accent: Color?
    var padding: CGFloat = 16

    func body(content: Content) -> some View {
        let shape = RoundedRectangle(cornerRadius: 20, style: .continuous)
        content
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(shape.fill(Color.cardIvory))
            .overlay(shape.strokeBorder(Color.cardBorder, lineWidth: 1))
    }
}

extension View {
    func cozyCard(accent: Color? = nil, padding: CGFloat = 16) -> some View {
        modifier(CozyCardModifier(accent: accent, padding: padding))
    }
}

// MARK: - Clean Modern Components

struct CozySectionHeader: View {
    var title: String
    var symbol: String
    var accent: Color
    var trailing: String?
    var animatedIcon: CozyIconKind? = nil

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: symbol)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(accent)
                .frame(width: 28, height: 28)
                .background(RoundedRectangle(cornerRadius: 8, style: .continuous).fill(accent.opacity(0.14)))
            Text(title)
                .font(CozyFont.title(16, weight: .semibold))
                .foregroundStyle(Color.inkCoffee)
            Spacer()
            if let trailing {
                Text(trailing)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Color.inkTaupe)
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
                Image(systemName: symbol).font(.system(size: 11, weight: .semibold))
            }
            Text(text).font(.system(size: 12, weight: .semibold)).lineLimit(1)
        }
        .foregroundStyle(tint)
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(Capsule().fill(tint.opacity(0.12)))
    }
}

struct CozySpeechBubble: View {
    var text: String
    var tint: Color = .accentSky

    var body: some View {
        Text(text)
            .font(.system(size: 13, weight: .medium))
            .foregroundStyle(Color.inkTaupe)
            .fixedSize(horizontal: false, vertical: true)
    }
}

struct CozyPillButtonStyle: ButtonStyle {
    var tint: Color
    var filled = true

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 14, weight: .semibold))
            .padding(.horizontal, 14)
            .padding(.vertical, 9)
            .foregroundStyle(filled ? Color.white : tint)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(filled ? tint : tint.opacity(0.12))
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.easeOut(duration: 0.14), value: configuration.isPressed)
    }
}

/// Avatar chữ cái hiện đại thay cho linh vật mèo/chó.
struct ModernAvatar: View {
    var name: String
    var tint: Color
    var size: CGFloat = 44

    private var initials: String {
        let parts = name.split(separator: " ").prefix(2)
        let chars = parts.compactMap(\.first).map(String.init).joined()
        return chars.isEmpty ? "?" : chars.uppercased()
    }

    var body: some View {
        Text(initials)
            .font(.system(size: size * 0.38, weight: .bold, design: .rounded))
            .foregroundStyle(.white)
            .frame(width: size, height: size)
            .background(
                RoundedRectangle(cornerRadius: size * 0.32, style: .continuous)
                    .fill(LinearGradient(colors: [tint, tint.opacity(0.75)], startPoint: .topLeading, endPoint: .bottomTrailing))
            )
    }
}

extension ColorToken {
    var color: Color { Color(self) }
}
