import SwiftUI
import CozyCore

/// Tab 2 — Kết nối (Us & Squad).
struct ConnectView: View {
    @Environment(AppModel.self) private var model
    @State private var kind: SpaceKind = .couple

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    Picker("Không gian", selection: $kind) {
                        ForEach(SpaceKind.allCases, id: \.self) { Text($0.displayName).tag($0) }
                    }
                    .pickerStyle(.segmented)

                    switch kind {
                    case .couple:
                        if let space = model.couple { CoupleSpaceView(space: space) } else { InviteCard(kind: .couple) }
                    case .squad:
                        if let space = model.squad { SquadBoardView(space: space) } else { InviteCard(kind: .squad) }
                    }
                }
                .padding(16)
            }
            .background(Color.bgCream.ignoresSafeArea())
            .navigationTitle("Kết nối")
        }
    }
}

// MARK: - Couple

private struct CoupleSpaceView: View {
    @Environment(AppModel.self) private var model
    var space: SharedSpace
    @State private var showAnniversary = false

    var me: MemberStatus? { space.members.first { $0.id == DemoData.meID } }
    var partner: MemberStatus? { space.partner(of: DemoData.meID) }

    var body: some View {
        VStack(spacing: 16) {
            // Thẻ đôi song song
            VStack(spacing: 14) {
                if let a = space.anniversary {
                    Button { showAnniversary = true } label: {
                        VStack(spacing: 2) {
                            Text("Đã bên nhau").font(CozyFont.body(13)).foregroundStyle(Color.inkTaupe)
                            Text("\(model.status(of: CozyEvent(title: "", kind: .countUp(since: a))).days)")
                                .font(CozyFont.number(48)).foregroundStyle(Color.accentPeach)
                            Text("ngày 💞").font(CozyFont.title(15)).foregroundStyle(Color.inkCoffee)
                        }
                    }
                    .buttonStyle(.plain)
                }
                HStack(alignment: .top, spacing: 12) {
                    if let me { MemberCard(member: me, weather: model.snapshot.weather) }
                    if let partner { MemberCard(member: partner, weather: nil) }
                }
            }
            .cozyCard(accent: .accentPeach)

            // Quick Ping
            VStack(alignment: .leading, spacing: 12) {
                CozySectionHeader(title: "Quick Ping", symbol: "hand.wave.fill", accent: .accentPeach, trailing: "rung nhẹ khi gửi")
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(QuickPing.allCases) { p in
                            Button { model.sendPing(p) } label: { Text("\(p.emoji) \(p.text)") }
                                .buttonStyle(CozyPillButtonStyle(tint: .accentPeach, filled: p == .missYou))
                        }
                    }
                }
            }
            .cozyCard()

            InteractionFeed(space: space)
            InviteCard(kind: .couple, compact: true)
        }
        .sheet(isPresented: $showAnniversary) {
            AnniversarySheet(date: space.anniversary ?? Date())
                .presentationDetents([.medium])
        }
    }
}

private struct MemberCard: View {
    var member: MemberStatus
    var weather: WeatherSnapshot?

    var body: some View {
        VStack(spacing: 6) {
            MascotView(state: MascotEngine.resolve(species: member.species, mood: member.mood, weather: weather, date: Date()), size: 72)
            Text(member.displayName).font(CozyFont.title(16)).foregroundStyle(Color.inkCoffee)
            Text(member.mood.map { "\($0.emoji) \($0.displayName)" } ?? "Chưa cập nhật")
                .font(CozyFont.body(13, weight: .medium)).foregroundStyle(Color.inkCoffee)
            if !member.foods.isEmpty {
                Text(member.foods.map(\.emoji).joined(separator: " ")).font(.system(size: 18))
            }
            if let s = member.socialBattery {
                BatteryBar(value: s, tint: .accentPeach)
            }
            VStack(spacing: 2) {
                if let b = member.deviceBattery {
                    Label("Pin máy \(Int(b * 100))%", systemImage: b < 0.2 ? "battery.25percent" : "battery.75percent")
                }
                if let w = member.weatherLine { Label(w, systemImage: "cloud.sun") }
                Text("cập nhật \(member.updatedAt.formatted(.relative(presentation: .named, unitsStyle: .narrow)))")
            }
            .font(.system(size: 10))
            .foregroundStyle(Color.inkTaupe)
            .lineLimit(1)
            .minimumScaleFactor(0.8)
            if !member.note.isEmpty {
                Text("“\(member.note)”")
                    .font(.custom("Noteworthy-Bold", size: 14, relativeTo: .body))
                    .foregroundStyle(Color.inkCoffee)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 20).fill(Color.bgCream))
    }
}

private struct AnniversarySheet: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    @State var date: Date

    var body: some View {
        NavigationStack {
            Form {
                DatePicker("Ngày bắt đầu yêu", selection: $date, in: ...Date(), displayedComponents: .date)
                    .environment(\.locale, Locale(identifier: "vi_VN"))
            }
            .navigationTitle("Đếm ngày yêu")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Lưu") { model.setAnniversary(date); dismiss() }
                }
            }
        }
    }
}

// MARK: - Squad

private struct SquadBoardView: View {
    @Environment(AppModel.self) private var model
    var space: SharedSpace

    var body: some View {
        VStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 12) {
                CozySectionHeader(title: space.name, symbol: "person.3.fill", accent: .accentHoney, trailing: "\(space.members.count)/\(space.kind.memberLimit.upperBound) người")
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                    ForEach(space.members) { m in
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                MascotView(state: MascotEngine.resolve(species: m.species, mood: m.mood, weather: nil, date: Date()), size: 44, animated: false)
                                VStack(alignment: .leading) {
                                    Text(m.displayName).font(CozyFont.title(15))
                                    Text(m.mood.map { "\($0.emoji) \($0.displayName)" } ?? "–").font(.system(size: 11)).foregroundStyle(Color.inkTaupe)
                                }
                            }
                            if let s = m.socialBattery { BatteryBar(value: s, tint: .accentHoney) }
                            if !m.note.isEmpty {
                                Text(m.note).font(.custom("Noteworthy-Bold", size: 13, relativeTo: .body)).lineLimit(2)
                            }
                        }
                        .padding(10)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(RoundedRectangle(cornerRadius: 18).fill(Color.bgCream))
                    }
                }
            }
            .cozyCard(accent: .accentHoney)

            VStack(alignment: .leading, spacing: 12) {
                CozySectionHeader(title: "Thả sticker", symbol: "face.smiling.inverse", accent: .accentHoney, trailing: nil)
                HStack {
                    ForEach(SquadReaction.all, id: \.self) { s in
                        Button { model.react(s, in: space) } label: { Text(s).font(.system(size: 26)) }
                            .buttonStyle(.plain)
                            .frame(maxWidth: .infinity)
                    }
                }
            }
            .cozyCard()

            SharedEventsCard(space: space)
            InteractionFeed(space: space)
            InviteCard(kind: .squad, compact: true)
        }
    }
}

private struct SharedEventsCard: View {
    @Environment(AppModel.self) private var model
    var space: SharedSpace

    var body: some View {
        let events = model.snapshot.events.filter { space.sharedEventIDs.contains($0.id) || $0.isShared }
        VStack(alignment: .leading, spacing: 12) {
            CozySectionHeader(title: "Đếm ngược chung", symbol: "calendar.badge.clock", accent: .accentSky, trailing: "hiện trên Lock Screen cả nhóm")
            if events.isEmpty {
                Text("Đánh dấu “Chia sẻ với nhóm” khi tạo sự kiện ở tab Lịch.").font(.caption).foregroundStyle(Color.inkTaupe)
            }
            ForEach(events) { e in EventRow(event: e, status: model.status(of: e)) }
        }
        .cozyCard()
    }
}

// MARK: - Feed & Invite

private struct InteractionFeed: View {
    var space: SharedSpace

    var body: some View {
        let items = space.interactions(on: Date())
        VStack(alignment: .leading, spacing: 10) {
            CozySectionHeader(title: "Hôm nay", symbol: "bubble.left.and.bubble.right.fill", accent: .accentSky, trailing: "\(items.count) tương tác")
            if items.isEmpty {
                Text("Chưa có tương tác nào hôm nay. Gửi một ping đi! 💌").font(.caption).foregroundStyle(Color.inkTaupe)
            }
            ForEach(items) { it in
                let who = space.members.first { $0.id == it.fromMemberID }
                let mine = it.fromMemberID == DemoData.meID
                HStack {
                    if mine { Spacer() }
                    VStack(alignment: mine ? .trailing : .leading, spacing: 2) {
                        Text("\(who?.displayName ?? "?") · \(it.sentAt.formatted(date: .omitted, time: .shortened))")
                            .font(.system(size: 10)).foregroundStyle(Color.inkTaupe)
                        Text(it.displayText)
                            .font(CozyFont.body(15, weight: .medium))
                            .padding(.horizontal, 12).padding(.vertical, 8)
                            .background(RoundedRectangle(cornerRadius: 16).fill(mine ? Color.accentPeach.opacity(0.22) : Color.bgCream))
                    }
                    if !mine { Spacer() }
                }
            }
        }
        .cozyCard()
    }
}

private struct InviteCard: View {
    var kind: SpaceKind
    var compact = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if !compact {
                Text(kind == .couple ? "Mời người yêu vào Couple Space" : "Tạo Squad Board (3–8 người)")
                    .font(CozyFont.title(17))
            }
            Text("Gửi link mời qua iMessage hoặc AirDrop. Không cần đăng ký tài khoản: dữ liệu đồng bộ bằng iCloud của mỗi người.")
                .font(.caption).foregroundStyle(Color.inkTaupe)
            // Giai đoạn 2: tạo CKShare và mở UICloudSharingController.
            ShareLink(item: URL(string: "https://www.icloud.com/share/cozydaily-demo")!, subject: Text("CozyDaily"), message: Text(kind == .couple ? "Vào Couple Space với mình nha 💞" : "Vào Squad Board của tụi mình nè 🎉")) {
                Label("Mời qua iMessage / AirDrop", systemImage: "square.and.arrow.up")
            }
            .buttonStyle(CozyPillButtonStyle(tint: kind == .couple ? .accentPeach : .accentHoney, filled: false))
        }
        .cozyCard()
    }
}
