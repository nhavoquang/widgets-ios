# Session Handoff — Ready for Global App Store Launch (`Widgets: Lock Screen Calendar`)

## Tổng kết toàn bộ 3 Chặng đã hoàn thành (40/40 Unit Tests PASS)
1. **Giao diện Hiện đại & Lưới Bento 1–4 Cột Kéo Thả (`LockWallpaperStudio.swift` + `AppIcon.png`):**
   - App Icon vector sắc nét mô tả khung Màn hình khóa iPhone + lưới Bento đa cột.
   - Lưới 1–4 cột (`1 cột`, `1/2`, `1/3`, `1/4`), nhấn giữ kéo thả trực tiếp (`.draggable`/`.dropDestination`), 18 mẫu hiện đại, 15 loại khối dữ liệu thật (gồm **Lưới 365 chấm Year Progress**, **Multi-Countdowns**, **Daily Quotes**, **Apple Reminders + Calendar**, **Thời tiết thật Open-Meteo/WeatherKit**, **Từ vựng**, **Cặp đôi**, **Âm lịch**, **Sticky Note**), kèm thanh kéo **Photo Dim & Photo Blur** và chọn **Đầu tuần Thứ Hai / Chủ Nhật**.
   - UX Shortcut 1 lần duy nhất (`shortcutInstalled`) + Interactive Lock Screen Vocab Shuffle (`↻`) + Quick Launcher 4 ô.
2. **Đa ngôn ngữ Toàn cầu (15 ngôn ngữ App Store):**
   - `Localization.swift` + `Localizable.xcstrings` + `InfoPlist.xcstrings` (đủ cả 4 quyền Location, Calendar, Reminders, Photos trên 15 thứ tiếng) + đổi ngôn ngữ trực tiếp trong Cài đặt.
3. **Thương mại hóa StoreKit 2 & Hồ sơ ASO App Store (`SubscriptionManager.swift`, `PaywallSheet.swift`, `PRIVACY.md`, `docs/ai/APP_STORE_SUBMISSION.md`):**
   - 2 gói IAP: `com.cozydaily.app.pro.lifetime` (**139.000₫ / $24.99**) và `com.cozydaily.app.pro.yearly` (**69.000₫ / $9.99**), luồng **Preview-First** chuyển đổi cao, đầy đủ nút Restore Purchases + Standard EULA + Privacy Policy.
   - Bảng ASO Title + Subtitle + 100-char Keywords cho đủ **15 ngôn ngữ** sẵn sàng copy-paste lên App Store Connect.

## Việc còn lại tùy chọn khi user sẵn sàng
- Khi tạo xong link iCloud Shortcut mới (đã bỏ `Wallpaper 7` để dùng chung cho mọi máy), dán vào `LockWallpaperStudio.templateShortcutShareURL`.
- Điền `DEVELOPMENT_TEAM` trong `project.yml` (hoặc GitHub Secrets `APPLE_TEAM_ID`, `ASC_KEY_ID`...) để xuất bản Signed IPA đẩy thẳng lên TestFlight / App Store Connect.
