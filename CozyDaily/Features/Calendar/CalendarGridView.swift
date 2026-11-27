import SwiftUI
import CozyCore

/// Tab 3 — Lịch & Lưới.
struct CalendarGridView: View {
    @Environment(AppModel.self) private var model
    @State private var lens: GridLens = .mood
    @State private var monthOffset = 0
    @State private var editing: CozyEvent?
    @State private var creating = false
    @State private var exportImage: ExportedImage?
    @State private var importing = false

    private var monthStart: Date {
        let cal = Calendar.cozy
        let start = cal.date(from: cal.dateComponents([.year, .month], from: model.now))!
        return cal.date(byAdding: .month, value: monthOffset, to: start)!
    }

    private var grid: MonthGrid {
        let c = Calendar.cozy.dateComponents([.year, .month], from: monthStart)
        return MonthGrid.build(year: c.year!, month: c.month!, lens: lens, snapshot: model.snapshot, now: model.now)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    VStack(spacing: 12) {
                        HStack {
                            Button { monthOffset -= 1 } label: { Image(systemName: "chevron.left") }
                            Spacer()
                            Text(grid.title).font(CozyFont.title(18))
                            Spacer()
                            Button { monthOffset += 1 } label: { Image(systemName: "chevron.right") }
                        }
                        .foregroundStyle(Color.inkCoffee)
                        Picker("Chế độ xem", selection: $lens) {
                            ForEach(GridLens.allCases) { Text($0.displayName).tag($0) }
                        }
                        .pickerStyle(.segmented)
                        StickerGrid(grid: grid, lens: lens)
                        MonthSummary(grid: grid, snapshot: model.snapshot)
                        HStack {
                            Button { export(.story) } label: { Label("Story 9:16", systemImage: "rectangle.portrait") }
                                .buttonStyle(CozyPillButtonStyle(tint: .accentSage, filled: false))
                            Button { export(.square) } label: { Label("Vuông 1:1", systemImage: "square") }
                                .buttonStyle(CozyPillButtonStyle(tint: .accentSage, filled: false))
                        }
                    }
                    .cozyCard(accent: .accentSage)

                    VStack(alignment: .leading, spacing: 12) {
                        CozySectionHeader(title: "Sự kiện & Đếm ngày", symbol: "calendar", accent: .accentSky, trailing: "\(model.snapshot.events.count)")
                        ForEach(EventCounter().sortedByUrgency(model.snapshot.events, now: model.now)) { e in
                            Button { editing = e } label: { EventRow(event: e, status: model.status(of: e)) }
                                .buttonStyle(.plain)
                                .contextMenu {
                                    Button(role: .destructive) { model.deleteEvent(e.id) } label: { Label("Xóa", systemImage: "trash") }
                                }
                        }
                        HStack {
                            Button { creating = true } label: { Label("Thêm sự kiện", systemImage: "plus") }
                                .buttonStyle(CozyPillButtonStyle(tint: .accentSky))
                            Button {
                                importing = true
                                Task { await model.importAppleCalendar(); importing = false }
                            } label: {
                                Label(importing ? "Đang lấy…" : "Lấy từ Apple Calendar", systemImage: "calendar.badge.plus")
                            }
                            .buttonStyle(CozyPillButtonStyle(tint: .accentSky, filled: false))
                            .disabled(importing)
                        }
                    }
                    .cozyCard()
                }
                .padding(16)
            }
            .background(Color.bgCream.ignoresSafeArea())
            .navigationTitle("Lịch & Lưới")
            .sheet(item: $editing) { e in EventEditor(event: e) }
            .sheet(isPresented: $creating) { EventEditor(event: nil) }
            .sheet(item: $exportImage) { img in ExportPreview(image: img) }
        }
    }

    enum ExportRatio { case story, square }

    @MainActor
    private func export(_ ratio: ExportRatio) {
        let size = ratio == .story ? CGSize(width: 360, height: 640) : CGSize(width: 360, height: 360)
        let view = ExportCanvas(grid: grid, lens: lens, snapshot: model.snapshot, ratio: ratio)
            .frame(width: size.width, height: size.height)
        let renderer = ImageRenderer(content: view)
        renderer.scale = 3
        if let ui = renderer.uiImage { exportImage = ExportedImage(image: Image(uiImage: ui)) }
    }
}

struct ExportedImage: Identifiable {
    let id = UUID()
    let image: Image
}

private struct ExportPreview: View {
    var image: ExportedImage

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                image.image.resizable().scaledToFit().clipShape(RoundedRectangle(cornerRadius: 20)).padding()
                ShareLink(item: image.image, preview: SharePreview("CozyDaily", image: image.image)) {
                    Label("Chia sẻ / Lưu ảnh", systemImage: "square.and.arrow.up")
                }
                .buttonStyle(CozyPillButtonStyle(tint: .accentSage))
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.bgCream)
        }
    }
}

// MARK: - Grid

struct StickerGrid: View {
    var grid: MonthGrid
    var lens: GridLens
    var compact = false

    var body: some View {
        VStack(spacing: 6) {
            HStack {
                ForEach(WeekdayName.mondayFirst, id: \.self) { wd in
                    Text(WeekdayName.short(wd))
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.inkTaupe)
                        .frame(maxWidth: .infinity)
                }
            }
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 7), spacing: 4) {
                ForEach(grid.cells) { cell in
                    GridCell(cell: cell, lens: lens, compact: compact)
                }
            }
        }
    }
}

private struct GridCell: View {
    var cell: MonthGridCell
    var lens: GridLens
    var compact: Bool

    var tint: Color {
        switch lens {
        case .mood: return .accentPeach
        case .food: return .accentHoney
        case .vocab: return .accentSage
        }
    }

    var body: some View {
        if cell.date == nil {
            Color.clear.frame(height: compact ? 34 : 50)
        } else {
            VStack(spacing: 0) {
                HStack(spacing: 2) {
                    Text("\(cell.day)").font(.system(size: compact ? 9 : 11, weight: cell.isToday ? .heavy : .semibold, design: .rounded))
                    if cell.hasEvent { Circle().fill(Color.accentSky).frame(width: 4, height: 4) }
                }
                if let s = cell.sticker {
                    Text(s).font(.system(size: compact ? 14 : 20))
                } else {
                    Spacer(minLength: 0)
                }
                if !compact, let l = cell.lunar {
                    Text(l.cellLabel)
                        .font(.system(size: 8, weight: l.day == 1 || l.day == 15 ? .bold : .regular))
                        .foregroundStyle(l.day == 1 || l.day == 15 ? Color.accentPeach : Color.inkTaupe)
                }
            }
            .foregroundStyle(Color.inkCoffee)
            .frame(maxWidth: .infinity, minHeight: compact ? 34 : 50)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(tint.opacity(cell.sticker == nil ? 0.05 : 0.12 + 0.2 * cell.intensity))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .strokeBorder(cell.isToday ? Color.inkCoffee : .clear, lineWidth: 1.5)
            )
            .accessibilityLabel("Ngày \(cell.day)\(cell.lunar.map { ", âm lịch \($0.shortText)" } ?? "")\(cell.sticker.map { ", \($0)" } ?? "")")
        }
    }
}

private struct MonthSummary: View {
    var grid: MonthGrid
    var snapshot: CozySnapshot

    var body: some View {
        let s = MonthGrid.summary(year: grid.year, month: grid.month, snapshot: snapshot)
        HStack {
            stat(s.topMood?.emoji ?? "–", "mood nhiều nhất")
            stat(s.topFood?.emoji ?? "–", "món ăn top")
            stat("\(s.wordsLearned)", "từ đã học")
            stat("\(s.checkInDays)", "ngày check-in")
        }
    }

    func stat(_ v: String, _ label: String) -> some View {
        VStack(spacing: 2) {
            Text(v).font(CozyFont.number(18)).foregroundStyle(Color.inkCoffee)
            Text(label).font(.system(size: 10)).foregroundStyle(Color.inkTaupe).multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }
}

private struct ExportCanvas: View {
    var grid: MonthGrid
    var lens: GridLens
    var snapshot: CozySnapshot
    var ratio: CalendarGridView.ExportRatio

    var body: some View {
        VStack(spacing: 14) {
            if ratio == .story { Spacer() }
            Text("CozyDaily").font(.system(size: 14, weight: .bold, design: .rounded)).foregroundStyle(Color(ColorToken.inkTaupe.rgba))
            Text("\(grid.title) · \(lens.displayName)").font(.system(size: 22, weight: .heavy, design: .rounded)).foregroundStyle(Color(ColorToken.inkCoffee.rgba))
            StickerGrid(grid: grid, lens: lens, compact: ratio == .square)
                .padding(12)
                .background(RoundedRectangle(cornerRadius: 24).fill(Color(ColorToken.cardIvory.rgba)))
            if ratio == .story {
                MonthSummary(grid: grid, snapshot: snapshot)
                Spacer()
            }
        }
        .padding(20)
        .background(Color(ColorToken.bgCream.rgba))
        .environment(\.colorScheme, .light)
    }
}
