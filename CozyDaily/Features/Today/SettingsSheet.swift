import SwiftUI
import CozyCore

struct SettingsSheet: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var confirmClear = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Bạn") {
                    TextField("Tên hiển thị", text: $name)
                    Picker("Linh vật", selection: Binding(
                        get: { model.settings.species },
                        set: { v in model.updateSettings { $0.species = v } }
                    )) {
                        ForEach(MascotSpecies.allCases) { Text("\($0.emoji) \($0.displayName)").tag($0) }
                    }
                }
                Section("Chia sẻ với người yêu & nhóm") {
                    Toggle("Thời tiết nơi mình ở", isOn: Binding(
                        get: { model.settings.shareWeatherWithSpaces },
                        set: { v in model.updateSettings { $0.shareWeatherWithSpaces = v } }
                    ))
                    Toggle("Pin điện thoại", isOn: Binding(
                        get: { model.settings.shareDeviceBattery },
                        set: { v in model.updateSettings { $0.shareDeviceBattery = v } }
                    ))
                }
                WidgetDiagnosticsSection()
                Section("iCloud") {
                    Label(CloudConfig.isEnabled ? "Đang bật đồng bộ" : "Chưa bật trong bản cài này", systemImage: CloudConfig.isEnabled ? "checkmark.icloud" : "icloud.slash")
                    if let error = model.cloudError {
                        Text(error).font(.caption).foregroundStyle(.red)
                    }
                }
                Section {
                    Button("Xóa dữ liệu mẫu", role: .destructive) { confirmClear = true }
                }
            }
            .navigationTitle("Cài đặt")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Xong") {
                        let trimmed = name.trimmingCharacters(in: .whitespaces)
                        if !trimmed.isEmpty { model.updateSettings { $0.displayName = trimmed } }
                        dismiss()
                    }
                }
            }
            .onAppear { name = model.settings.displayName }
            .confirmationDialog("Xóa sự kiện, check-in và không gian mẫu?", isPresented: $confirmClear, titleVisibility: .visible) {
                Button("Xóa", role: .destructive) { model.removeDemoData() }
            }
        }
    }
}
