# Task Queue — Commercial Global Launch (`Widgets: Lock Screen Calendar`)

- [x] **Chặng 1 (Đã hoàn thành): Tính năng Viral TikTok, Apple Reminders & Quốc tế hóa nội dung**
- [x] **Chặng 2 (Đã hoàn thành): StoreKit 2 Paywall Thương mại (Yearly 69k + Lifetime 139k) & Quick Launcher Widget**
  - Tích hợp `SubscriptionManager.swift` (StoreKit 2 thuần Apple) + `PaywallSheet.swift` 15 ngôn ngữ + `Products.storekit` + `PRIVACY.md`.
  - Cơ chế **Preview-First**: cho người dùng thiết kế thử thoải mái 3–4 cột, 365 chấm, ảnh nền Blur/Dim trên màn hình Live Preview; khi bấm `Update Lock Screen` với tính năng Pro mới bật Paywall sang trọng (chọn sẵn gói Lifetime -53%).
  - Thêm **Quick Launcher Widget** 4 ô dưới đồng hồ Lock Screen (mở nhanh Việc mới, Lịch, Spotify, ChatGPT hoặc QR/URL tùy chỉnh).

- [ ] **Chặng 3 (Cuối cùng): Bảng ASO Metadata 15 ngôn ngữ App Store Connect + Bảng giá theo Quốc gia & Checklist Duyệt App**
  - Xuất tài liệu `docs/ai/APP_STORE_SUBMISSION.md` hoàn chỉnh để copy-paste thẳng lên App Store Connect:
    1. Bảng **App Name (30 ký tự) + Subtitle (30 ký tự) + Keywords (100 ký tự) + Mô tả ngắn** tối ưu SEO cho đủ **15 ngôn ngữ**.
    2. Hướng dẫn tạo 2 mã In-App Purchase (`com.cozydaily.app.pro.yearly` & `com.cozydaily.app.pro.lifetime`) và bảng set giá tối ưu doanh thu (69k/139k cho VN & SEA; \$9.99/\$24.99 cho Mỹ/Nhật/Hàn/Âu).
    3. Kịch bản 6 tấm Screenshot App Store chuyển đổi cao + Checklist vượt qua App Review ngay lần nộp đầu tiên.
