# Session Handoff — Modern Lock Screen Studio (`Widgets`)

## Vừa hoàn thành (`8bdbebd` & `0c56160`)
- `CozyDaily/Resources/Assets.xcassets/AppIcon.appiconset/AppIcon.png`:
  - Thiết kế lại bằng hình học phẳng/vector 2x downsample (không dùng AI render), mô tả rõ khung Màn hình khóa iPhone + lưới Bento 1–2–3 cột trực quan.
- `CozyDaily/Features/Studio/LockWallpaperStudio.swift`:
  - Nâng cấp lên **hệ lưới Bento 1–4 cột** (`spanTwelfths` = `12` / `6` / `4` / `3` tương ứng `1 cột`, `1/2`, `1/3`, `1/4`).
  - Hỗ trợ **nhấn giữ kéo thả trực tiếp (`.draggable` / `.dropDestination`)** để hoán đổi vị trí ô trong tab `Bố cục & Cột` + kéo tay dịch chuyển dọc trên khung Lock Screen.
  - Mở rộng lên **12 loại khối dữ liệu thật** (Lịch tuần, Lịch trình hôm nay, Thời tiết thật, Từ vựng, Người kết nối, Lịch tháng, Đếm ngày sự kiện, Tiến độ năm %, Chuỗi học 7 ngày, Âm lịch, Ghi chú ghim, Pin iPhone) và **16 mẫu hiện đại**.
  - Thêm thanh tùy chỉnh sâu: **Độ bo góc**, **Khoảng cách giữa các ô**, **Cỡ chữ (%)**, **Độ đậm nền thẻ (%)**, **Vị trí dọc**.
  - UX Shortcut 1 lần duy nhất (`shortcutInstalled`): cài xong lần đầu thì nút `Update Lock Screen` chạy thẳng Shortcut; `GenerateLockWallpaperIntent` tự đồng bộ Thời tiết + iCloud + Lịch Apple trước khi vẽ ảnh.
- `Shared/Widgets/CozyWidgetViews.swift` + `Shared/Intents/CozyIntents.swift`:
  - Thêm nút tương tác `↻` (`NextVocabIntent`) bấm đổi từ trực tiếp ngay trên Widget Lock Screen (iOS 17 Interactive Widget).
- Kiểm chứng: `swift test --package-path Packages/CozyCore` — **39/39 PASS**.

## Việc tiếp theo (Chờ user gửi lại link iCloud Shortcut chuẩn mới)
```text
Đọc docs/ai/HANDOFF.md, cập nhật link iCloud Shortcut mới do user gửi vào `LockWallpaperStudio.templateShortcutShareURL`, commit và hướng dẫn push.
```
