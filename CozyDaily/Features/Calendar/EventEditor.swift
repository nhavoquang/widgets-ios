import SwiftUI
import CozyCore

/// Tạo/sửa sự kiện với 5 chế độ đếm thời gian.
struct EventEditor: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss

    enum Mode: String, CaseIterable, Identifiable {
        case countdown, countUp, lunar, weekly, deadline
        var id: String { rawValue }
        var title: String {
            switch self {
            case .countdown: return "Đếm ngược"
            case .countUp: return "Đếm tiến"
            case .lunar: return "Âm lịch"
            case .weekly: return "Hằng tuần"
            case .deadline: return "Deadline"
            }
        }
    }

    let original: CozyEvent?
    @State private var title: String
    @State private var emoji: String
    @State private var accent: ColorToken
    @State private var isShared: Bool
    @State private var mode: Mode
    @State private var date: Date
    @State private var repeatsYearly: Bool
    @State private var lunarDay: Int
    @State private var lunarMonth: Int
    @State private var lunarMonthly: Bool
    @State private var weekdays: Set<Int>
    @State private var time: Date

    init(event: CozyEvent?) {
        original = event
        _title = State(initialValue: event?.title ?? "")
        _emoji = State(initialValue: event?.emoji ?? "📅")
        _accent = State(initialValue: event?.accent ?? .accentSky)
        _isShared = State(initialValue: event?.isShared ?? false)
        var mode = Mode.countdown
        var date = Calendar.cozy.date(byAdding: .day, value: 7, to: Date())!
        var yearly = false
        var lDay = 1, lMonth = 1, lMonthly = false
        var wds: Set<Int> = [2]
        var time = Calendar.cozy.date(bySettingHour: 19, minute: 0, second: 0, of: Date())!
        switch event?.kind {
        case let .countdown(d, r)?: mode = .countdown; date = d; yearly = r
        case let .countUp(d)?: mode = .countUp; date = d
        case let .lunar(d, m)?: mode = .lunar; lDay = d; lMonth = m ?? 1; lMonthly = m == nil
        case let .weekly(w, h, mi)?:
            mode = .weekly; wds = Set(w)
            time = Calendar.cozy.date(bySettingHour: h, minute: mi, second: 0, of: Date())!
        case let .deadline(d)?: mode = .deadline; date = d
        case nil: break
        }
        _mode = State(initialValue: mode)
        _date = State(initialValue: date)
        _repeatsYearly = State(initialValue: yearly)
        _lunarDay = State(initialValue: lDay)
        _lunarMonth = State(initialValue: lMonth)
        _lunarMonthly = State(initialValue: lMonthly)
        _weekdays = State(initialValue: wds)
        _time = State(initialValue: time)
    }

    private var kind: EventKind {
        let cal = Calendar.cozy
        switch mode {
        case .countdown: return .countdown(date: cal.startOfDay(for: date), repeatsYearly: repeatsYearly)
        case .countUp: return .countUp(since: cal.startOfDay(for: date))
        case .lunar: return .lunar(day: lunarDay, month: lunarMonthly ? nil : lunarMonth)
        case .weekly:
            let c = cal.dateComponents([.hour, .minute], from: time)
            return .weekly(weekdays: weekdays.sorted(), hour: c.hour ?? 19, minute: c.minute ?? 0)
        case .deadline: return .deadline(due: date)
        }
    }

    private var draft: CozyEvent {
        CozyEvent(id: original?.id ?? UUID(), title: title.isEmpty ? "Sự kiện" : title, emoji: emoji, kind: kind, accent: accent, isShared: isShared, externalIdentifier: original?.externalIdentifier, createdAt: original?.createdAt ?? Date())
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack {
                        TextField("📅", text: $emoji)
                            .frame(width: 44)
                            .multilineTextAlignment(.center)
                            .onChange(of: emoji) { _, v in if v.count > 1 { emoji = String(v.suffix(1)) } }
                        TextField("Tên sự kiện", text: $title)
                    }
                    let s = model.status(of: draft)
                    HStack {
                        Text("Xem trước").foregroundStyle(.secondary)
                        Spacer()
                        Text(s.sentence).bold()
                    }
                }

                Section("Chế độ đếm") {
                    Picker("Chế độ", selection: $mode) {
                        ForEach(Mode.allCases) { Text($0.title).tag($0) }
                    }
                    .pickerStyle(.menu)

                    switch mode {
                    case .countdown:
                        DatePicker("Ngày", selection: $date, displayedComponents: .date)
                        Toggle("Lặp lại hằng năm (sinh nhật, kỷ niệm)", isOn: $repeatsYearly)
                    case .countUp:
                        DatePicker("Bắt đầu từ", selection: $date, in: ...Date(), displayedComponents: .date)
                    case .lunar:
                        Toggle("Lặp hằng tháng (Mùng 1, Rằm)", isOn: $lunarMonthly)
                        Stepper("Ngày âm: \(lunarDay)", value: $lunarDay, in: 1...30)
                        if !lunarMonthly {
                            Stepper("Tháng âm: \(lunarMonth)", value: $lunarMonth, in: 1...12)
                        }
                        HStack {
                            Button("Mùng 1") { lunarDay = 1; lunarMonthly = true }
                            Button("Rằm") { lunarDay = 15; lunarMonthly = true }
                            Button("Tết") { lunarDay = 1; lunarMonth = 1; lunarMonthly = false }
                        }
                        .buttonStyle(.bordered)
                        if let next = EventCounter().nextOccurrence(of: draft, now: Date()) {
                            Text("Lần tới: \(next.formatted(date: .complete, time: .omitted))")
                                .font(.caption).foregroundStyle(.secondary)
                        }
                    case .weekly:
                        HStack {
                            ForEach(WeekdayName.mondayFirst, id: \.self) { wd in
                                Button(WeekdayName.short(wd)) {
                                    if weekdays.contains(wd) { if weekdays.count > 1 { weekdays.remove(wd) } } else { weekdays.insert(wd) }
                                }
                                .buttonStyle(.borderedProminent)
                                .tint(weekdays.contains(wd) ? Color.accentSky : Color.gray.opacity(0.3))
                                .font(.caption.bold())
                            }
                        }
                        DatePicker("Giờ", selection: $time, displayedComponents: .hourAndMinute)
                    case .deadline:
                        DatePicker("Hạn chót", selection: $date)
                    }
                }

                Section("Hiển thị") {
                    Picker("Màu nhấn", selection: $accent) {
                        ForEach(ColorToken.accents, id: \.self) { t in
                            Label(t.displayName, systemImage: "circle.fill").tint(t.color).tag(t)
                        }
                    }
                    Toggle("Chia sẻ với người yêu / nhóm bạn", isOn: $isShared)
                }

                if let original {
                    Section {
                        Button("Xóa sự kiện", role: .destructive) {
                            model.deleteEvent(original.id)
                            dismiss()
                        }
                    }
                }
            }
            .environment(\.locale, Locale(identifier: "vi_VN"))
            .navigationTitle(original == nil ? "Sự kiện mới" : "Sửa sự kiện")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Hủy") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Lưu") { model.save(draft); dismiss() }.bold()
                }
            }
        }
    }
}
