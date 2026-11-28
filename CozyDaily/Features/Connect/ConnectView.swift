import SwiftUI
import UIKit
import CozyCore

/// Tab 2 — Kết nối (Couple 2 người & Squad 3–8 người) theo thiết kế Huddle kết hợp Linh vật 3D Kawaii.
struct ConnectView: View {
    @Environment(AppModel.self) private var model
    @State private var kind: SpaceKind = .couple
    @State private var showRename = false
    @State private var renameDraft = ""
    @State private var showCreateLocal = false
    @State private var createName = ""

    private var activeSpace: SharedSpace? {
        kind == .couple ? model.couple : model.squad
    }

    var body: some View {
        NavigationStack {
            ZStack {
                CozyAmbientBackground()
                ScrollView {
                    VStack(spacing: 16) {
                        headerBar
                        spaceKindSwitcher

                        switch kind {
                        case .couple:
                            if let space = model.couple {
                                CoupleSpaceView(space: space, onRename: { openRename(space) })
                            } else {
                                EmptySpaceInviteCard(kind: .couple, onCreateLocal: { openCreate(.couple) })
                            }
                        case .squad:
                            if let space = model.squad {
                                SquadBoardView(space: space, onRename: { openRename(space) })
                            } else {
                                EmptySpaceInviteCard(kind: .squad, onCreateLocal: { openCreate(.squad) })
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .padding(.bottom, 28)
                }
                .scrollDismissesKeyboard(.interactively)
            }
            .toolbar(.hidden, for: .navigationBar)
            .alert("Đổi tên không gian", isPresented: $showRename) {
                TextField("Tên không gian", text: $renameDraft)
                Button("Hủy", role: .cancel) {}
                Button("Lưu") {
                    if let space = activeSpace { model.renameSpace(space, to: renameDraft) }
                }
            }
            .alert(kind == .couple ? "Tạo Couple Space" : "Tạo Squad Board", isPresented: $showCreateLocal) {
                TextField(kind == .couple ? "VD: Mình & Gấu" : "VD: Hội Bánh Tráng", text: $createName)
                Button("Hủy", role: .cancel) {}
                Button("Tạo") { model.createLocalSpace(kind: kind, name: createName) }
            }
        }
    }

    private var headerBar: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Không gian chung")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color.inkTaupe)
                Text("Kết nối 💞")
                    .font(CozyFont.title(26, weight: .heavy))
                    .foregroundStyle(Color.inkCoffee)
            }
            Spacer()
            if let space = activeSpace {
                Button {
                    Haptics.tap()
                    openRename(space)
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: "pencil")
                            .font(.system(size: 12, weight: .bold))
                        Text("Đổi tên")
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                    }
                    .foregroundStyle(Color.inkCoffee)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Capsule().fill(Color.cardIvory))
                    .overlay(Capsule().strokeBorder(Color.cardBorder, lineWidth: 1))
                    .shadow(color: Color.inkCoffee.opacity(0.06), radius: 6, y: 2)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var spaceKindSwitcher: some View {
        HStack(spacing: 6) {
            switcherPill(
                target: .couple,
                title: "Hai đứa",
                emoji: "💞",
                count: model.couple?.members.count ?? 0,
                limit: SpaceKind.couple.memberLimit.upperBound,
                tint: .accentPeach
            )
            switcherPill(
                target: .squad,
                title: "Hội bạn",
                emoji: "🧸",
                count: model.squad?.members.count ?? 0,
                limit: SpaceKind.squad.memberLimit.upperBound,
                tint: .accentHoney
            )
        }
        .padding(5)
        .background(RoundedRectangle(cornerRadius: 20, style: .continuous).fill(Color.cardIvory))
        .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).strokeBorder(Color.cardBorder, lineWidth: 1))
        .shadow(color: Color.inkCoffee.opacity(0.05), radius: 8, y: 3)
    }

    private func switcherPill(target: SpaceKind, title: String, emoji: String, count: Int, limit: Int, tint: Color) -> some View {
        let selected = kind == target
        return Button {
            Haptics.tap()
            withAnimation(CozyMotionTokens.playfulSpring) { kind = target }
        } label: {
            HStack(spacing: 6) {
                Text(emoji).font(.system(size: 15))
                Text(title)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                Text("\(count)/\(limit)")
                    .font(.system(size: 11, weight: .heavy, design: .rounded))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Capsule().fill(selected ? Color.white.opacity(0.24) : tint.opacity(0.16)))
            }
            .foregroundStyle(selected ? Color.white : Color.inkCoffee)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 15, style: .continuous)
                    .fill(selected ? tint : .clear)
            )
        }
        .buttonStyle(.plain)
    }

    private func openRename(_ space: SharedSpace) {
        renameDraft = space.name
        showRename = true
    }

    private func openCreate(_ target: SpaceKind) {
        kind = target
        createName = ""
        showCreateLocal = true
    }
}

// MARK: - Live Status Dark Card (phong cách Huddle nổi bật)

private struct SpaceLiveBanner: View {
    var space: SharedSpace
    var subtitle: String
    var accent: Color
    var iconKind: CozyIconKind
    var onAction: () -> Void

    private var isCloudSynced: Bool { space.cloud != nil }

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Circle()
                        .fill(isCloudSynced ? Color.accentSage : Color.accentHoney)
                        .frame(width: 8, height: 8)
                    Text(isCloudSynced ? "Đang đồng bộ iCloud · \(space.members.count)/\(space.kind.memberLimit.upperBound) người" : "Không gian mẫu · \(space.members.count)/\(space.kind.memberLimit.upperBound) người")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundStyle(isCloudSynced ? Color(RGBA(hex: "#A8D5BA")!) : Color(RGBA(hex: "#F2CF88")!))
                }
                Text(space.name)
                    .font(CozyFont.title(20, weight: .heavy))
                    .foregroundStyle(Color(RGBA(hex: "#FFFDF9")!))
                    .lineLimit(1)
                Text(subtitle)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(Color(RGBA(hex: "#C8BEB4")!))
            }
            Spacer(minLength: 4)
            Button(action: onAction) {
                CozyAnimatedIcon(kind: iconKind, accent: accent, size: 44)
            }
            .buttonStyle(.plain)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color(RGBA(hex: "#2C2621")!), Color(RGBA(hex: "#3B312A")!)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .strokeBorder(Color.white.opacity(0.08), lineWidth: 1)
        )
        .shadow(color: Color.inkCoffee.opacity(0.18), radius: 16, y: 8)
    }
}

// MARK: - Couple (2 người)

private struct CoupleSpaceView: View {
    @Environment(AppModel.self) private var model
    var space: SharedSpace
    var onRename: () -> Void

    @State private var showAnniversary = false
    @State private var lastSentPing: QuickPing?
    @State private var showBurst = false

    var me: MemberStatus? { space.members.first { $0.id == DemoData.meID } }
    var partner: MemberStatus? { space.partner(of: DemoData.meID) }

    private var loveDays: Int? {
        guard let a = space.anniversary else { return nil }
        return model.status(of: CozyEvent(title: "", kind: .countUp(since: a))).days
    }

    var body: some View {
        VStack(spacing: 16) {
            // 1. Live Banner + Chạm tim gửi nhanh "Đang nhớ nè"
            ZStack(alignment: .topTrailing) {
                SpaceLiveBanner(
                    space: space,
                    subtitle: loveDays.map { "Đã bên nhau \($0) ngày 💞 · chạm đổi ngày yêu" } ?? "Chạm để đặt ngày bắt đầu yêu",
                    accent: .accentPeach,
                    iconKind: .heart,
                    onAction: { triggerPing(.missYou) }
                )
                .onTapGesture { showAnniversary = true }

                if showBurst {
                    Text(lastSentPing.map { "\($0.emoji) Đã gửi!" } ?? "💓")
                        .font(.system(size: 12, weight: .heavy, design: .rounded))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Capsule().fill(Color.accentPeach))
                        .shadow(color: Color.accentPeach.opacity(0.4), radius: 6, y: 3)
                        .offset(x: -14, y: -10)
                        .transition(.scale(scale: 0.5).combined(with: .opacity))
                }
            }

            // 2. Thẻ đôi song song phong cách Squircle + Linh vật 3D Plush
            HStack(alignment: .top, spacing: 12) {
                if let me {
                    CoupleMemberCard(member: me, weather: model.snapshot.weather, isHighlighted: false, tint: .accentSky)
                }
                if let partner {
                    CoupleMemberCard(member: partner, weather: nil, isHighlighted: true, tint: .accentPeach)
                } else {
                    WaitingPartnerCard()
                }
            }

            // 3. Quick Ping rung tim
            VStack(alignment: .leading, spacing: 12) {
                CozySectionHeader(
                    title: "Quick Ping",
                    symbol: "hand.wave.fill",
                    accent: .accentPeach,
                    trailing: "rung tim khi gửi",
                    animatedIcon: .heart
                )
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(QuickPing.allCases) { p in
                            Button { triggerPing(p) } label: {
                                Text("\(p.emoji) \(p.text)")
                            }
                            .buttonStyle(CozyPillButtonStyle(tint: .accentPeach, filled: p == .missYou))
                        }
                    }
                    .padding(.vertical, 2)
                }
            }
            .cozyCard(accent: .accentPeach)

            SharedEventsCard(space: space)
            InteractionFeed(space: space, accent: .accentPeach)
            InviteAccessCard(space: space, onRename: onRename)
        }
        .sheet(isPresented: $showAnniversary) {
            AnniversarySheet(date: space.anniversary ?? Date())
                .presentationDetents([.medium])
                .presentationCornerRadius(28)
        }
    }

    private func triggerPing(_ ping: QuickPing) {
        model.sendPing(ping)
        lastSentPing = ping
        withAnimation(CozyMotionTokens.playfulSpring) { showBurst = true }
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(1300))
            withAnimation(.easeOut(duration: 0.25)) { showBurst = false }
        }
    }
}

private struct CoupleMemberCard: View {
    var member: MemberStatus
    var weather: WeatherSnapshot?
    var isHighlighted: Bool
    var tint: Color

    var body: some View {
        VStack(spacing: 8) {
            ModernAvatar(name: member.displayName, tint: tint, size: 54)
            Text(member.displayName)
                .font(CozyFont.title(15, weight: .bold))
                .foregroundStyle(Color.inkCoffee)
                .lineLimit(1)
            Text(member.mood.map { "\($0.emoji) \($0.displayName)" } ?? "Chưa cập nhật")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(tint)
                .lineLimit(1)
            if let s = member.socialBattery {
                BatteryBar(value: s, tint: tint)
            }
            VStack(spacing: 2) {
                if let b = member.deviceBattery {
                    Label("Pin \(Int(b * 100))%", systemImage: b < 0.2 ? "battery.25percent" : "battery.75percent")
                }
                if let w = member.weatherLine {
                    Label(w, systemImage: "cloud.sun")
                }
                Text(member.updatedAt.formatted(.relative(presentation: .named, unitsStyle: .narrow)))
            }
            .font(.system(size: 10.5))
            .foregroundStyle(Color.inkTaupe)
            .lineLimit(1)

            if !member.note.isEmpty {
                Text(member.note)
                    .font(.system(size: 12.5, weight: .medium))
                    .foregroundStyle(Color.inkCoffee)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .frame(maxWidth: .infinity)
                    .background(RoundedRectangle(cornerRadius: 10).fill(Color.bgCream))
            }
        }
        .frame(maxWidth: .infinity)
        .cozyCard(padding: 12)
    }
}

private struct WaitingPartnerCard: View {
    var body: some View {
        VStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(Color.accentPeach.opacity(0.14))
                    .frame(width: 72, height: 72)
                Image(systemName: "person.badge.plus")
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundStyle(Color.accentPeach)
            }
            Text("Chờ người ấy")
                .font(CozyFont.title(15, weight: .bold))
                .foregroundStyle(Color.inkCoffee)
            Text("Gửi link mời bên dưới để 2 đứa nối widget chung nhé 💌")
                .font(CozyFont.body(11))
                .foregroundStyle(Color.inkTaupe)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, minHeight: 210)
        .cozyCard(accent: .accentPeach, padding: 12)
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
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Đóng") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Lưu") {
                        model.setAnniversary(date)
                        Haptics.success()
                        dismiss()
                    }
                    .bold()
                }
            }
        }
    }
}

// MARK: - Squad (3–8 người)

private struct SquadBoardView: View {
    @Environment(AppModel.self) private var model
    var space: SharedSpace
    var onRename: () -> Void

    @State private var tappedSticker: String?

    private let squadAccents: [Color] = [.accentPeach, .accentHoney, .accentSage, .accentSky]

    var body: some View {
        VStack(spacing: 16) {
            // 1. Live Banner của nhóm
            SpaceLiveBanner(
                space: space,
                subtitle: "Tối đa \(space.kind.memberLimit.upperBound) bạn thân · chung lịch & widget",
                accent: .accentHoney,
                iconKind: .sparkles,
                onAction: { onRename() }
            )

            // 2. Lưới thành viên squircle đa sắc (kiểu Huddle + Linh vật 3D)
            VStack(alignment: .leading, spacing: 12) {
                CozySectionHeader(
                    title: "Thành viên nhóm",
                    symbol: "person.3.fill",
                    accent: .accentHoney,
                    trailing: "\(space.members.count)/\(space.kind.memberLimit.upperBound) bạn",
                    animatedIcon: .mood
                )
                LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)], spacing: 10) {
                    ForEach(Array(space.members.enumerated()), id: \.element.id) { idx, m in
                        let tint = squadAccents[idx % squadAccents.count]
                        VStack(alignment: .leading, spacing: 7) {
                            HStack(spacing: 8) {
                                ModernAvatar(name: m.displayName, tint: tint, size: 38)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(m.displayName)
                                        .font(CozyFont.title(15, weight: .bold))
                                        .foregroundStyle(Color.inkCoffee)
                                        .lineLimit(1)
                                    Text(m.mood.map { "\($0.emoji) \($0.displayName)" } ?? "Đang nghỉ")
                                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                                        .foregroundStyle(Color.inkTaupe)
                                        .lineLimit(1)
                                }
                            }
                            if let s = m.socialBattery {
                                BatteryBar(value: s, tint: tint)
                            }
                            if !m.note.isEmpty {
                                Text("“\(m.note)”")
                                    .font(.custom("Noteworthy-Bold", size: 13, relativeTo: .body))
                                    .foregroundStyle(Color.inkCoffee)
                                    .lineLimit(2)
                                    .padding(.horizontal, 7)
                                    .padding(.vertical, 4)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(RoundedRectangle(cornerRadius: 10).fill(Color.cardIvory))
                            }
                        }
                        .padding(11)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .fill(Color.bgCream)
                                .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).fill(tint.opacity(0.08)))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .strokeBorder(tint.opacity(0.28), lineWidth: 1)
                        )
                    }
                }
            }
            .cozyCard(accent: .accentHoney)

            // 3. Thả sticker tương tác có nảy spring
            VStack(alignment: .leading, spacing: 12) {
                CozySectionHeader(title: "Thả cảm xúc nhanh", symbol: "face.smiling.inverse", accent: .accentHoney, trailing: "chạm gửi cả nhóm", animatedIcon: .sparkles)
                HStack(spacing: 4) {
                    ForEach(SquadReaction.all, id: \.self) { s in
                        let popped = tappedSticker == s
                        Button {
                            model.react(s, in: space)
                            withAnimation(CozyMotionTokens.playfulSpring) { tappedSticker = s }
                            Task { @MainActor in
                                try? await Task.sleep(for: .milliseconds(350))
                                withAnimation(.easeOut) { if tappedSticker == s { tappedSticker = nil } }
                            }
                        } label: {
                            Text(s)
                                .font(.system(size: 24))
                                .frame(maxWidth: .infinity, minHeight: 40)
                                .background(RoundedRectangle(cornerRadius: 12).fill(popped ? Color.accentHoney.opacity(0.32) : Color.bgCream))
                                .scaleEffect(popped ? 1.2 : 1)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .cozyCard()

            SharedEventsCard(space: space)
            InteractionFeed(space: space, accent: .accentHoney)
            InviteAccessCard(space: space, onRename: onRename)
        }
    }
}

// MARK: - Shared Events & Live Feed

private struct SharedEventsCard: View {
    @Environment(AppModel.self) private var model
    var space: SharedSpace

    var body: some View {
        let events = model.snapshot.events.filter { space.sharedEventIDs.contains($0.id) }
        VStack(alignment: .leading, spacing: 12) {
            CozySectionHeader(
                title: "Đếm ngược chung",
                symbol: "calendar.badge.clock",
                accent: .accentSky,
                trailing: "hiện trên Lock Screen",
                animatedIcon: .calendar
            )
            if events.isEmpty {
                Text("Bật “Chia sẻ với \(space.name)” khi tạo sự kiện ở tab Lịch để cả nhà cùng đếm ngược nhé 🗓️")
                    .font(CozyFont.body(12.5))
                    .foregroundStyle(Color.inkTaupe)
            } else {
                ForEach(events) { e in EventRow(event: e, status: model.status(of: e)) }
            }
        }
        .cozyCard(accent: .accentSky)
    }
}

private struct InteractionFeed: View {
    @Environment(AppModel.self) private var model
    var space: SharedSpace
    var accent: Color
    @State private var draftMessage = ""

    var body: some View {
        let items = space.interactions(on: Date())
        VStack(alignment: .leading, spacing: 11) {
            CozySectionHeader(
                title: "Nhắn nhanh hôm nay",
                symbol: "bubble.left.and.bubble.right.fill",
                accent: accent,
                trailing: "\(items.count) tin"
            )

            // Ô nhắn nhanh trực tiếp (không cần rời màn hình)
            HStack(spacing: 8) {
                TextField("Gửi lời nhắn dễ thương…", text: $draftMessage)
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 9)
                    .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Color.bgCream))
                    .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).strokeBorder(Color.cardBorder, lineWidth: 1))
                    .submitLabel(.send)
                    .onSubmit { submitMessage() }
                Button { submitMessage() } label: {
                    Image(systemName: "paperplane.fill")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 38, height: 38)
                        .background(Circle().fill(draftMessage.trimmingCharacters(in: .whitespaces).isEmpty ? Color.inkTaupe.opacity(0.3) : accent))
                }
                .buttonStyle(.plain)
                .disabled(draftMessage.trimmingCharacters(in: .whitespaces).isEmpty)
            }

            if items.isEmpty {
                Text("Chưa có tương tác nào hôm nay. Gửi một ping hoặc lời nhắn đi! 💌")
                    .font(.caption)
                    .foregroundStyle(Color.inkTaupe)
            } else {
                ForEach(items.prefix(12)) { it in
                    let who = space.members.first { $0.id == it.fromMemberID }
                    let mine = it.fromMemberID == DemoData.meID
                    HStack {
                        if mine { Spacer(minLength: 28) }
                        VStack(alignment: mine ? .trailing : .leading, spacing: 2) {
                            Text("\(who?.displayName ?? "?") · \(it.sentAt.formatted(date: .omitted, time: .shortened))")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundStyle(Color.inkTaupe)
                            Text(it.displayText)
                                .font(.system(size: 14.5, weight: .medium, design: .rounded))
                                .foregroundStyle(Color.inkCoffee)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(
                                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                                        .fill(mine ? accent.opacity(0.22) : Color.bgCream)
                                )
                        }
                        if !mine { Spacer(minLength: 28) }
                    }
                }
            }
        }
        .cozyCard()
    }

    private func submitMessage() {
        let text = draftMessage
        draftMessage = ""
        model.sendMessage(text, in: space)
    }
}

// MARK: - Huddle-Style Invite & Access Management

private struct InviteAccessCard: View {
    @Environment(AppModel.self) private var model
    var space: SharedSpace
    var onRename: () -> Void

    @State private var invitation: ShareInvitation?
    @State private var working = false
    @State private var copiedLink = false
    @State private var confirmLeave = false

    private var tint: Color { space.kind == .couple ? .accentPeach : .accentHoney }
    private var cloudSpace: SharedSpace? {
        model.snapshot.spaces.first { $0.kind == space.kind && $0.cloud != nil }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Quyền vào phòng", systemImage: "lock.shield.fill")
                    .font(CozyFont.title(16, weight: .bold))
                    .foregroundStyle(Color.inkCoffee)
                Spacer()
                Text(space.canAddMember ? "Còn chỗ (\(space.members.count)/\(space.kind.memberLimit.upperBound))" : "Đã đủ \(space.kind.memberLimit.upperBound)/\(space.kind.memberLimit.upperBound)")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundStyle(space.canAddMember ? Color.accentSage : Color.accentPeach)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 4)
                    .background(Capsule().fill((space.canAddMember ? Color.accentSage : Color.accentPeach).opacity(0.16)))
            }

            Text("Chỉ những người nhận link mời iMessage / AirDrop mới vào được. Đồng bộ trực tiếp bằng iCloud riêng tư, không cần tạo tài khoản.")
                .font(CozyFont.body(12))
                .foregroundStyle(Color.inkTaupe)

            if let url = cloudSpace?.shareURL {
                HStack(spacing: 8) {
                    Image(systemName: "link")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(Color.inkTaupe)
                    Text(url.absoluteString)
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundStyle(Color.inkCoffee)
                        .lineLimit(1)
                        .truncationMode(.middle)
                    Spacer(minLength: 4)
                    Button {
                        UIPasteboard.general.string = url.absoluteString
                        Haptics.success()
                        withAnimation(CozyMotionTokens.playfulSpring) { copiedLink = true }
                        Task { @MainActor in
                            try? await Task.sleep(for: .seconds(1.5))
                            withAnimation { copiedLink = false }
                        }
                    } label: {
                        Text(copiedLink ? "Đã chép ✓" : "Sao chép")
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Capsule().fill(copiedLink ? Color.accentSage : Color.inkCoffee))
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 9)
                .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Color.bgCream))
            }

            if CloudConfig.isEnabled {
                HStack(spacing: 8) {
                    Button {
                        working = true
                        Task {
                            invitation = await model.prepareInvitation(space.kind)
                            working = false
                        }
                    } label: {
                        Label(
                            working ? "Đang tạo link…" : (cloudSpace == nil ? "Tạo phòng & Mời" : "Mời thêm / Quản lý"),
                            systemImage: "square.and.arrow.up"
                        )
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(CozyPillButtonStyle(tint: tint, filled: true))
                    .disabled(working)

                    if cloudSpace != nil {
                        Button(role: .destructive) { confirmLeave = true } label: {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                                .font(.system(size: 15, weight: .bold))
                                .frame(width: 40, height: 38)
                                .background(Circle().fill(Color.accentPeach.opacity(0.16)))
                                .foregroundStyle(Color.accentPeach)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Rời không gian")
                    }
                }
            } else {
                if let statusURL = model.myStatusShareURL {
                    ShareLink(
                        item: statusURL,
                        subject: Text("Cảm xúc của \(model.settings.displayName)"),
                        message: Text("Chạm link này để cập nhật cảm xúc của \(model.settings.displayName) lên Lock Screen CozyDaily!")
                    ) {
                        Label("Gửi cảm xúc trực tiếp (Zalo / iMessage)", systemImage: "paperplane.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(CozyPillButtonStyle(tint: tint, filled: true))
                }
                HStack(spacing: 8) {
                    Image(systemName: "link.badge.plus")
                        .foregroundStyle(Color.inkTaupe)
                    Text("Hoạt động ngay cả trên bản cài miễn phí: gửi link cho người ấy chạm mở là cập nhật cảm xúc thật lên Lock Screen.")
                        .font(.caption)
                        .foregroundStyle(Color.inkTaupe)
                }
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(RoundedRectangle(cornerRadius: 12).fill(Color.bgCream))
            }

            if let error = model.cloudError {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(Color.accentPeach)
            }
        }
        .cozyCard()
        .sheet(item: $invitation) { CloudSharingView(invitation: $0) }
        .confirmationDialog(
            "Rời không gian? Nếu bạn là người tạo, không gian sẽ bị xóa cho mọi người.",
            isPresented: $confirmLeave,
            titleVisibility: .visible
        ) {
            Button("Rời / Xóa", role: .destructive) {
                if let cloudSpace { Task { await model.leave(cloudSpace) } }
            }
        }
    }
}

private struct EmptySpaceInviteCard: View {
    @Environment(AppModel.self) private var model
    var kind: SpaceKind
    var onCreateLocal: () -> Void
    @State private var invitation: ShareInvitation?
    @State private var working = false

    private var tint: Color { kind == .couple ? .accentPeach : .accentHoney }

    var body: some View {
        VStack(spacing: 14) {
            CozyAnimatedIcon(kind: kind == .couple ? .heart : .sparkles, accent: tint, size: 54)
            Text(kind == .couple ? "Tạo Couple Space (2 người)" : "Tạo Squad Board (3–8 người)")
                .font(CozyFont.title(19, weight: .heavy))
                .foregroundStyle(Color.inkCoffee)
            Text(
                kind == .couple
                    ? "Đếm ngày yêu, xem mood & thời tiết của người ấy, gửi Quick Ping rung tim ngay trên màn hình khóa."
                    : "Tụ tập 3–8 bạn thân: xem pin xã hội, thả sticker và cùng đếm ngược chuyến đi chung trên Lock Screen."
            )
            .font(CozyFont.body(13))
            .foregroundStyle(Color.inkTaupe)
            .multilineTextAlignment(.center)

            if CloudConfig.isEnabled {
                Button {
                    working = true
                    Task {
                        invitation = await model.prepareInvitation(kind)
                        working = false
                    }
                } label: {
                    Label(working ? "Đang tạo phòng…" : "Tạo & gửi link mời iCloud", systemImage: "square.and.arrow.up")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(CozyPillButtonStyle(tint: tint, filled: true))
                .disabled(working)
            } else {
                if kind == .couple, let statusURL = model.myStatusShareURL {
                    ShareLink(
                        item: statusURL,
                        subject: Text("Kết nối CozyDaily với \(model.settings.displayName)"),
                        message: Text("Chạm link này để hiện cảm xúc của \(model.settings.displayName) lên Lock Screen CozyDaily nhé!")
                    ) {
                        Label("Gửi link kết nối cảm xúc (Zalo / iMessage)", systemImage: "paperplane.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(CozyPillButtonStyle(tint: tint, filled: true))
                }
                Button { onCreateLocal() } label: {
                    Label("Tạo không gian trên máy", systemImage: "plus.circle.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(CozyPillButtonStyle(tint: tint, filled: kind == .squad))
                Text("Người ấy chỉ cần chạm link gửi qua Zalo/iMessage là cảm xúc thật tự hiện lên màn hình khóa.")
                    .font(.caption)
                    .foregroundStyle(Color.inkTaupe)
                    .multilineTextAlignment(.center)
            }
        }
        .cozyCard(accent: tint, padding: 20)
        .sheet(item: $invitation) { CloudSharingView(invitation: $0) }
    }
}
