import SwiftUI
import CozyCore
#if canImport(WidgetKit)
import WidgetKit
#endif

/// Linh vật biểu cảm. Nếu có asset minh họa `assetName` trong Assets.xcassets thì dùng ảnh,
/// nếu chưa có thì vẽ bản giữ chỗ bằng emoji + phụ kiện.
struct MascotView: View {
    var state: MascotState
    var size: CGFloat = 64
    var showsBackground = true
    var animated = true

    @State private var bob = false

    var body: some View {
        ZStack {
            if showsBackground {
                Circle()
                    .fill(Color.accentPeach.opacity(0.16))
                    .overlay(Circle().strokeBorder(Color.cardBorder, lineWidth: 1))
            }
            content
                .offset(y: animated && bob ? -size * 0.04 : 0)
        }
        .frame(width: size, height: size)
        .onAppear {
            guard animated else { return }
            withAnimation(.easeInOut(duration: animationDuration).repeatForever(autoreverses: true)) { bob = true }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(state.caption)
    }

    @ViewBuilder
    private var content: some View {
        #if canImport(UIKit)
        if UIImage(named: state.assetName) != nil {
            Image(state.assetName).resizable().scaledToFit().padding(size * 0.08)
        } else {
            placeholder
        }
        #else
        placeholder
        #endif
    }

    private var placeholder: some View {
        ZStack(alignment: .bottomTrailing) {
            Text(state.species.emoji)
                .font(.system(size: size * 0.52))
                .rotationEffect(.degrees(state.pose == .sleeping ? -12 : 0))
            HStack(spacing: -size * 0.06) {
                ForEach(state.accessories, id: \.self) { a in
                    Text(a.emoji).font(.system(size: size * 0.24))
                }
            }
            .offset(x: size * 0.10, y: size * 0.04)
            if state.pose == .sleeping {
                Text("z").font(.system(size: size * 0.18, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.inkTaupe)
                    .offset(x: size * 0.05, y: -size * 0.42)
            }
        }
    }

    private var animationDuration: Double {
        switch state.pose {
        case .jumping, .bouncing: return 0.45
        case .rushing: return 0.3
        case .sleeping, .yawning: return 2.2
        default: return 1.4
        }
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
