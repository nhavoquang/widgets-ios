import SwiftUI
import CozyCore

/// Màn hình Paywall hiện đại, tối giản, tỷ lệ chuyển đổi cao chuẩn App Store toàn cầu (15 ngôn ngữ).
/// Mặc định chọn sẵn gói Lifetime (Decoy Pricing: 139k so với 69k/năm) để tối đa hóa doanh thu thu về ngay.
struct PaywallSheet: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    @State private var selectedPlan: ProPlanKind = .lifetime
    var onUnlocked: (() -> Void)? = nil

    var body: some View {
        let lang = model.settings.language
        ZStack {
            LinearGradient(
                colors: [Color(RGBA(hex: "#0B101E")!), Color(RGBA(hex: "#131C31")!), Color(RGBA(hex: "#0A0D14")!)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // Thanh đóng góc phải gọn gàng
                HStack {
                    HStack(spacing: 6) {
                        Image(systemName: "crown.fill")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(Color.accentHoney)
                        Text("WIDGETS PRO")
                            .font(.system(size: 12, weight: .heavy, design: .rounded))
                            .tracking(1.1)
                            .foregroundStyle(Color.accentHoney)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Capsule().fill(Color.accentHoney.opacity(0.16)))

                    Spacer()

                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(.white.opacity(0.7))
                            .frame(width: 30, height: 30)
                            .background(Circle().fill(Color.white.opacity(0.10)))
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        // Hero Visual Bento Showcase
                        heroShowcase

                        VStack(spacing: 8) {
                            Text(CozyL10n.t("pro.headline", lang: lang))
                                .font(.system(size: 24, weight: .bold))
                                .foregroundStyle(.white)
                                .multilineTextAlignment(.center)
                            Text(CozyL10n.t("pro.subheadline", lang: lang))
                                .font(.system(size: 14, weight: .regular))
                                .foregroundStyle(.white.opacity(0.72))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 8)
                        }

                        // 4 Lợi ích cốt lõi ngắn gọn, trực diện
                        VStack(spacing: 11) {
                            featureRow(symbol: "square.grid.3x2.fill", tint: .accentSky, text: lang.isVietnamese ? "Chia lưới Bento 1–4 cột & kéo thả không giới hạn" : "Unlimited 1–4 Column Bento Grid & Drag-and-Drop")
                            featureRow(symbol: "circle.grid.3x3.fill", tint: .accentHoney, text: lang.isVietnamese ? "Lưới 365 chấm Năm, Multi-Countdown & 18+ mẫu VIP" : "365 Year Dots, Multi-Countdowns & All 18+ Templates")
                            featureRow(symbol: "photo.fill", tint: .accentPeach, text: lang.isVietnamese ? "Ảnh nền cá nhân kèm thanh chỉnh Làm mờ & Độ tối" : "Custom Photo Wallpapers with Smart Blur & Dimming")
                            featureRow(symbol: "bolt.badge.clock.fill", tint: .accentSage, text: lang.isVietnamese ? "Đồng bộ Lịch, Apple Reminders, Thời tiết & Cặp đôi" : "Live Weather, Calendar, Apple Reminders & Partner Sync")
                        }
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .fill(Color.white.opacity(0.06))
                                .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).strokeBorder(Color.white.opacity(0.10), lineWidth: 1))
                        )

                        // 2 Thẻ chọn gói: Lifetime (Nổi bật -53%) & Yearly
                        VStack(spacing: 10) {
                            planCard(
                                plan: .lifetime,
                                title: CozyL10n.t("pro.plan.lifetime", lang: lang),
                                subtitle: CozyL10n.t("pro.plan.lifetimeDesc", lang: lang),
                                badge: CozyL10n.t("pro.plan.bestValue", lang: lang),
                                lang: lang
                            )
                            planCard(
                                plan: .yearly,
                                title: CozyL10n.t("pro.plan.yearly", lang: lang),
                                subtitle: CozyL10n.t("pro.plan.yearlyDesc", lang: lang),
                                badge: nil,
                                lang: lang
                            )
                        }

                        if let msg = model.subscriptions.lastMessage {
                            Text(msg)
                                .font(.caption)
                                .foregroundStyle(Color.accentPeach)
                                .multilineTextAlignment(.center)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 14)
                    .padding(.bottom, 20)
                }

                // Cụm nút hành động cố định dưới đáy
                VStack(spacing: 10) {
                    Button {
                        Haptics.tap()
                        Task {
                            let ok = await model.purchasePlan(selectedPlan)
                            if ok {
                                onUnlocked?()
                                dismiss()
                            }
                        }
                    } label: {
                        HStack(spacing: 8) {
                            if model.subscriptions.isPurchasing {
                                ProgressView().tint(.white)
                            } else {
                                Text(CozyL10n.t("pro.cta", lang: lang))
                                    .font(.system(size: 16, weight: .bold))
                                Image(systemName: "arrow.right")
                                    .font(.system(size: 14, weight: .bold))
                            }
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 15)
                        .background(
                            LinearGradient(
                                colors: [Color.accentSky, Color(RGBA(hex: "#2563EB")!)],
                                startPoint: .leading,
                                endPoint: .trailing
                            ),
                            in: RoundedRectangle(cornerRadius: 16, style: .continuous)
                        )
                        .shadow(color: Color.accentSky.opacity(0.35), radius: 12, y: 4)
                    }
                    .buttonStyle(.plain)
                    .disabled(model.subscriptions.isPurchasing)

                    HStack(spacing: 16) {
                        Button {
                            Task {
                                let ok = await model.restorePurchases()
                                if ok {
                                    onUnlocked?()
                                    dismiss()
                                }
                            }
                        } label: {
                            Text(CozyL10n.t("pro.restore", lang: lang))
                                .font(.system(size: 12.5, weight: .semibold))
                                .foregroundStyle(.white.opacity(0.68))
                        }
                        .buttonStyle(.plain)

                        Text("·").foregroundStyle(.white.opacity(0.35))

                        Link("Terms", destination: URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!)
                            .font(.system(size: 12.5, weight: .medium))
                            .foregroundStyle(.white.opacity(0.55))

                        Text("·").foregroundStyle(.white.opacity(0.35))

                        Link("Privacy", destination: URL(string: "https://github.com/nhavoquang/widgets-ios/blob/main/PRIVACY.md")!)
                            .font(.system(size: 12.5, weight: .medium))
                            .foregroundStyle(.white.opacity(0.55))
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 16)
                .padding(.top, 8)
                .background(Color(RGBA(hex: "#0A0D14")!).opacity(0.95))
            }
        }
        .preferredColorScheme(.dark)
        .task { await model.subscriptions.refreshStoreState() }
    }

    private var heroShowcase: some View {
        HStack(spacing: 8) {
            // Ô 1: 365 Dots mini card
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("2026").font(.system(size: 10, weight: .bold, design: .monospaced)).foregroundStyle(.white)
                    Spacer()
                    Text("91%").font(.system(size: 10, weight: .heavy, design: .monospaced)).foregroundStyle(Color.accentHoney)
                }
                VStack(spacing: 3) {
                    ForEach(0..<4, id: \.self) { r in
                        HStack(spacing: 3) {
                            ForEach(0..<10, id: \.self) { c in
                                let active = (r * 10 + c) < 34
                                Circle()
                                    .fill(active ? (r == 3 && c == 3 ? Color.accentHoney : .white.opacity(0.88)) : .white.opacity(0.16))
                                    .frame(width: 5, height: 5)
                            }
                        }
                    }
                }
            }
            .padding(11)
            .frame(maxWidth: .infinity)
            .background(RoundedRectangle(cornerRadius: 16).fill(Color.white.opacity(0.08)))
            .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(Color.accentHoney.opacity(0.45), lineWidth: 1))

            // Ô 2: Bento Multi-Countdown mini card
            VStack(alignment: .leading, spacing: 6) {
                Label("Bento 4-Col", systemImage: "square.grid.3x2.fill")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(Color.accentSky)
                VStack(spacing: 5) {
                    miniProgressRow(color: .accentSky, ratio: 0.82)
                    miniProgressRow(color: .accentPeach, ratio: 0.58)
                    miniProgressRow(color: .accentSage, ratio: 0.92)
                }
            }
            .padding(11)
            .frame(maxWidth: .infinity)
            .background(RoundedRectangle(cornerRadius: 16).fill(Color.white.opacity(0.08)))
            .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(Color.accentSky.opacity(0.45), lineWidth: 1))
        }
    }

    private func miniProgressRow(color: Color, ratio: CGFloat) -> some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(Color.white.opacity(0.14))
                Capsule().fill(color).frame(width: geo.size.width * ratio)
            }
        }
        .frame(height: 6)
    }

    private func featureRow(symbol: String, tint: Color, text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: symbol)
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(tint)
                .frame(width: 30, height: 30)
                .background(RoundedRectangle(cornerRadius: 9, style: .continuous).fill(tint.opacity(0.16)))
            Text(text)
                .font(.system(size: 13.5, weight: .medium))
                .foregroundStyle(.white.opacity(0.92))
            Spacer(minLength: 0)
        }
    }

    private func planCard(plan: ProPlanKind, title: String, subtitle: String, badge: String?, lang: AppLanguage) -> some View {
        let selected = (selectedPlan == plan)
        let price = model.subscriptions.displayPrice(for: plan)
        let strikePrice = plan.fallbackOriginalPrice(for: lang)

        return Button {
            Haptics.tap()
            withAnimation(.easeOut(duration: 0.16)) { selectedPlan = plan }
        } label: {
            HStack(spacing: 12) {
                Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(selected ? Color.accentSky : .white.opacity(0.35))

                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Text(title)
                            .font(.system(size: 15.5, weight: .bold))
                            .foregroundStyle(.white)
                        if let badge {
                            Text(badge)
                                .font(.system(size: 9.5, weight: .heavy))
                                .foregroundStyle(.black)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2.5)
                                .background(Capsule().fill(Color.accentHoney))
                        }
                    }
                    Text(subtitle)
                        .font(.system(size: 12))
                        .foregroundStyle(.white.opacity(0.65))
                        .lineLimit(1)
                }

                Spacer(minLength: 4)

                VStack(alignment: .trailing, spacing: 2) {
                    Text(price)
                        .font(.system(size: 17, weight: .heavy, design: .rounded))
                        .foregroundStyle(.white)
                    if model.subscriptions.productsByID[plan.rawValue] == nil {
                        Text(strikePrice)
                            .font(.system(size: 11, weight: .medium, design: .rounded))
                            .strikethrough()
                            .foregroundStyle(.white.opacity(0.42))
                    }
                }
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(selected ? Color.accentSky.opacity(0.16) : Color.white.opacity(0.06))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .strokeBorder(selected ? Color.accentSky : Color.white.opacity(0.12), lineWidth: selected ? 2 : 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }
}
