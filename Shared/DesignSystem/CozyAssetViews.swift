import SwiftUI
import WidgetKit
import CozyCore
#if canImport(UIKit)
import UIKit
#endif

extension CozyAsset {
    /// Asset catalog hiện có ảnh tên này không.
    static func imageExists(_ name: String) -> Bool {
        #if canImport(UIKit)
        return UIImage(named: name) != nil
        #else
        return false
        #endif
    }
}

/// Vẽ một trạng thái theo đúng chế độ hiển thị của widget:
/// - `.fullColor`: PNG 3D, thiếu thì dùng emoji.
/// - `.accented` / `.vibrant`: ảnh template hoặc SF Symbol, tránh bị bệt màu.
struct CozyAssetImage: View {
    @Environment(\.widgetRenderingMode) private var renderingMode
    var asset: CozyAsset
    var size: CGFloat

    var body: some View {
        Group {
            if renderingMode == .fullColor {
                if CozyAsset.imageExists(asset.staticFullColorImageName) {
                    Image(asset.staticFullColorImageName).resizable().scaledToFit()
                } else {
                    Text(asset.fallbackEmoji).font(.system(size: size * 0.82))
                }
            } else {
                monochrome.widgetAccentable()
            }
        }
        .frame(width: size, height: size)
        .accessibilityLabel(asset.accessibilityName)
    }

    @ViewBuilder
    private var monochrome: some View {
        if CozyAsset.imageExists(asset.tintedImageName) {
            Image(asset.tintedImageName).renderingMode(.template).resizable().scaledToFit()
        } else {
            Image(systemName: asset.monochromeSymbolName).resizable().scaledToFit().padding(size * 0.1)
        }
    }
}

/// Linh vật trong widget: ảnh tĩnh (full color) hoặc nét đơn sắc.
struct WidgetMascot: View {
    @Environment(\.widgetRenderingMode) private var renderingMode
    var state: MascotState
    var size: CGFloat

    var body: some View {
        if renderingMode != .fullColor {
            CozyAssetImage(asset: state.asset, size: size * 0.8)
        } else if let asset = MascotAssetManager.candidates(for: state).first(where: { CozyAsset.imageExists($0.staticFullColorImageName) }) {
            CozyAssetImage(asset: asset, size: size)
        } else {
            MascotView(state: state, size: size, animated: false)
        }
    }
}

// MARK: - Chuyển động cho WidgetKit

enum CozyMotion {
    static let spring = Animation.spring(response: 0.4, dampingFraction: 0.75)
}

extension View {
    /// Chữ số cuộn khi giá trị đổi.
    func cozyNumeric(_ value: Int) -> some View {
        contentTransition(.numericText(value: Double(value)))
            .animation(CozyMotion.spring, value: value)
    }

    /// Nội dung cũ thu nhỏ mờ đi, nội dung mới phóng ra khi `id` đổi (vd. sau AppIntent).
    func cozySwap<ID: Hashable>(_ id: ID) -> some View {
        ZStack(alignment: .topLeading) {
            self.id(id).transition(.scale.combined(with: .opacity))
        }
        .animation(CozyMotion.spring, value: id)
    }
}
