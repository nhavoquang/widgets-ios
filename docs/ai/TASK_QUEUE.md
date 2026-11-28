# Task Queue — Commercial Global Launch (`Widgets: Lock Screen Calendar`)

> Mỗi Chặng (Stage) làm gọn trong 1 session để tiết kiệm token và kiểm chứng kỹ lưỡng trước khi sang chặng kế tiếp.

## Lộ trình 3 Chặng Thương mại hóa App Store Toàn cầu (15 ngôn ngữ)

- [x] **Chặng 1 (Đã hoàn thành): Tính năng Viral TikTok, Apple Reminders & Quốc tế hóa nội dung**
  - Khối **Lưới 365 chấm Year Progress (`yearDots`)** + **Thanh đếm nhiều sự kiện (`multiCountdown`)** kiểu *Pretty Progress / Locka*.
  - Khối **Daily Quote / Stoic Focus Affirmations** dịch chuẩn 15 ngôn ngữ + tự động chuyển giải nghĩa Từ vựng sang **Anh–Anh** trên máy khách quốc tế.
  - Đồng bộ **Apple Reminders (`EKReminder`)** gộp chung với Apple Calendar & Việc hôm nay.
  - Tùy chọn **Bắt đầu tuần từ Thứ Hai hoặc Chủ Nhật (`WeekStartDay`)** + thanh kéo **Làm tối & Làm mờ ảnh nền cá nhân (`photoDim`, `photoBlur`)**.

- [ ] **Chặng 2 (Tiếp theo): StoreKit 2 Paywall Thương mại (Yearly 59k–79k + Lifetime 139k) & Quick Launcher / Live Activities**
  - Tích hợp **StoreKit 2** thuần Apple (`SubscriptionManager.swift` + `PaywallSheet.swift` + file `.storekit` test local):
    - 2 gói chiến lược: **Pro Yearly** (59k–79k VNĐ / \$9.99–\$14.99 Tier 1) & **Early Bird Lifetime** (139k VNĐ / \$24.99 Tier 1 — mặc định nổi bật để chốt đơn trọn đời).
    - Nút **Restore Purchases (Khôi phục giao dịch)** + điều khoản rõ ràng đạt 100% chuẩn App Store Review Guideline 3.1.2.
    - Cho phép người dùng **thiết kế thử mọi tính năng Pro trên Live Preview**, chỉ bật Paywall sang trọng khi bấm `Update Lock Screen` nếu đang dùng tính năng Pro (3–4 cột, 365 chấm, ảnh nền Blur/Dim, mẫu VIP).
  - Thêm **Quick Launcher Widget** trên dải Lock Screen dưới đồng hồ (mở nhanh QR Ngân hàng, Camera, ChatGPT, Spotify, Thêm việc nhanh).

- [ ] **Chặng 3: Bộ hồ sơ nộp App Store Connect (ASO 15 ngôn ngữ + Privacy Policy + Review Checklist)**
  - Tạo trang `PrivacyPolicy.md` (host miễn phí trên GitHub Pages của repo) + link điều khoản sử dụng chuẩn Apple (`EULA`).
  - Xuất bảng **Title + Subtitle + 100-char Keywords + Promotional Text** đã tối ưu SEO cho đủ **15 ngôn ngữ** để copy-paste lên App Store Connect.
  - Rà soát toàn bộ quyền (`InfoPlist.xcstrings`), cấu hình giá theo từng quốc gia (Tier 1 vs VN/SEA) và kịch bản quay video App Preview.
