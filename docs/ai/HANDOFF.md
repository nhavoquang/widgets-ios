# Session Handoff — Stage 1 Completed (`Widgets: Lock Screen Calendar`)

## Vừa hoàn thành (Chặng 1 — Viral Features & Global Content)
- `Packages/CozyCore/Sources/CozyCore/Data/DailyQuotes.swift` + `VocabSeed.swift` + `Models/Vocab.swift`:
  - Bộ **Daily Quotes / Stoic & Focus Affirmations** đủ **15 ngôn ngữ** + tự động hiển thị định nghĩa Anh–Anh chuẩn cho kho từ vựng khi ngôn ngữ máy khác Tiếng Việt.
  - Thêm `WeekStartDay` (`.monday` / `.sunday`) và `syncAppleReminders` vào `UserSettings` (tương thích ngược JSON cũ).
- `CozyDaily/App/Services.swift` + `AppModel.swift` + `SettingsSheet.swift` + `project.yml`:
  - Tích hợp đồng bộ **Apple Reminders (`EKReminder`)** tự động đưa nhắc việc hôm nay lên Lock Screen & Shortcut chạy ngầm.
  - Thêm chọn **Ngày bắt đầu tuần (Thứ Hai / Chủ Nhật)** và công tắc **Đồng bộ Lời nhắc** ngay trong Cài đặt.
- `CozyDaily/Features/Studio/LockWallpaperStudio.swift`:
  - Thêm 3 khối ăn khách mới (nâng tổng lên **15 loại khối** & **18 mẫu dựng sẵn**):
    1. **Lưới 365 chấm Year Progress (`yearDots`)** — vẽ tĩnh 37×10 không dùng `LazyVGrid`, chấm ngày hôm nay phát sáng.
    2. **Thanh đếm nhiều sự kiện (`multiCountdown`)** — thanh progress màu sắc kiểu *Pretty Progress*.
    3. **Câu nói truyền cảm hứng (`dailyQuote`)** — tự đổi theo 15 ngôn ngữ.
  - Thêm thanh trượt **Độ tối ảnh nền (`photoDim`)** & **Độ mờ ảnh nền (`photoBlur`)** khi người dùng chọn ảnh cá nhân từ Thư viện.
- Kiểm chứng: `swift test --package-path Packages/CozyCore` — **40/40 PASS**.

## Prompt mẫu mở session mới làm Chặng 2 (Copy-paste)
```text
Đọc docs/ai/HANDOFF.md và docs/ai/TASK_QUEUE.md, triển khai Chặng 2: Tích hợp StoreKit 2 Paywall hiện đại (gói Yearly 59k-79k & Lifetime 139k tự động hiển thị giá bản địa theo Store từng nước + Restore Purchases, cho thử tính năng Pro trên Preview trước khi hiện Paywall) và thêm Quick Launcher Lock Screen Widget.
```
