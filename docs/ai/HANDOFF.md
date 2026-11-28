# Session Handoff — Stage 2 Completed (`Widgets: Lock Screen Calendar`)

## Vừa hoàn thành (Chặng 2 — StoreKit 2 Paywall & Quick Launcher)
- `Packages/CozyCore/Sources/CozyCore/Models/Monetization.swift` + `Localization.swift` + `CozySnapshot.swift`:
  - Khai báo 2 mã IAP chuẩn: `com.cozydaily.app.pro.yearly` (**69.000₫ / \$9.99**) và `com.cozydaily.app.pro.lifetime` (**139.000₫ / \$24.99**), kèm từ điển Paywall đủ **15 ngôn ngữ**.
  - Lưu trạng thái `isProUnlocked`, `quickLaunchSlots` (4 ô) và `customQuickLaunchURL` trong `UserSettings` (App Group).
- `CozyDaily/Features/Paywall/SubscriptionManager.swift`, `PaywallSheet.swift`, `CozyDaily/Resources/Products.storekit`, `PRIVACY.md`:
  - StoreKit 2 thuần Apple tự tải mệnh giá tiền tệ thực tế trên Store từng nước, có nút **Restore Purchases**, link **Terms (Apple Standard EULA)** & **Privacy Policy** đạt chuẩn App Review 3.1.2.
  - Luồng chuyển đổi cao **Preview-First** trong `LockWallpaperStudio.swift`: user được kéo thả, thử mẫu VIP, thử lưới 3–4 cột & ảnh nền Blur/Dim thoải mái trên màn hình thử; chỉ khi bấm `Update Lock Screen` với tính năng Pro mới hiện Paywall (và vừa mua xong tự động áp dụng hình nền ngay!).
- `CozyWidgets/CozyWidgetsBundle.swift` + `SettingsSheet.swift`:
  - Thêm **Quick Launcher Widget** (1 chạm mở Việc mới, Lock Studio, Lịch, Reminders, Spotify, ChatGPT, Google Maps hoặc link QR Ngân hàng/MoMo tùy chỉnh ngay từ Lock Screen).
- Kiểm chứng: `swift test --package-path Packages/CozyCore` — **40/40 PASS**.

## Prompt mẫu mở session mới làm Chặng 3 (Copy-paste)
```text
Đọc docs/ai/HANDOFF.md và docs/ai/TASK_QUEUE.md, hoàn thiện Chặng 3: Tạo cẩm nang nộp App Store Connect toàn diện tại docs/ai/APP_STORE_SUBMISSION.md (bộ Title + Subtitle + 100-char Keywords tối ưu SEO đủ 15 ngôn ngữ, hướng dẫn tạo 2 gói IAP Yearly 69k / Lifetime 139k & set giá theo quốc gia, kịch bản 6 ảnh Screenshot và Checklist vượt App Review).
```
