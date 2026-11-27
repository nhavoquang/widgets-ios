import SwiftUI
import WidgetKit
import CozyCore

/// Thông tin về widget extension trong bản đã cài, dùng để tìm lỗi sau khi sideload.
struct WidgetDiagnosticsSection: View {
    @State private var placed = "đang đọc…"

    var body: some View {
        Section("Chẩn đoán widget") {
            ForEach(Array(lines.enumerated()), id: \.offset) { _, line in
                Text(line).font(.caption.monospaced()).textSelection(.enabled)
            }
            Text("Widget đã đặt: \(placed)").font(.caption.monospaced())
        }
        .onAppear {
            WidgetCenter.shared.getCurrentConfigurations { result in
                let text: String
                switch result {
                case .success(let list): text = "\(list.count)"
                case .failure(let error): text = error.localizedDescription
                }
                Task { @MainActor in placed = text }
            }
        }
    }

    private var lines: [String] {
        var out = ["iOS \(ProcessInfo.processInfo.operatingSystemVersionString)",
                   "App: \(Bundle.main.bundleIdentifier ?? "?")"]
        let plugins = Bundle.main.builtInPlugInsURL
            .flatMap { try? FileManager.default.contentsOfDirectory(at: $0, includingPropertiesForKeys: nil) } ?? []
        if plugins.isEmpty { out.append("Widget: KHÔNG có trong bản cài") }
        for url in plugins {
            let profile = FileManager.default.fileExists(atPath: url.appendingPathComponent("embedded.mobileprovision").path)
            out.append("Widget: \(Bundle(url: url)?.bundleIdentifier ?? url.lastPathComponent)")
            out.append("Hồ sơ ký của widget: \(profile ? "có" : "KHÔNG")")
        }
        out.append("App Group: \(SnapshotStore.activeAppGroupID ?? "KHÔNG truy cập được")")
        return out
    }
}
