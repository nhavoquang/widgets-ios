# Task Queue — Modern Clean iOS UI (`Widgets Home & Lock`)

> Mỗi Slice làm gọn trong **1 session mới** để tiết kiệm token. Luôn tuân thủ `docs/ai/DESIGN_SPEC.md` (**UI hiện đại, tối giản, KHÔNG dùng style mèo/chó/linh vật**).

## Hàng đợi tiếp theo (1 Slice = 1 Session mới)
- [x] **S-04: Hiện đại hóa toàn bộ giao diện App & bỏ hẳn style linh vật mèo/chó**
  - Mục tiêu:
    - Chuyển bảng màu & thẻ trong `CozyTheme.swift` sang phong cách **Modern Clean iOS** (nền sáng/tối tinh tế, thẻ sắc nét, chữ SF Pro hiện đại, bỏ phong cách giấy kem/mèo/chó).
    - Bỏ `MascotView` / `AnimatedMascotView` khỏi `TodayView`, `SettingsSheet`, `WidgetSetupGuide`, `ConnectView`, `StudioView` và `CozyWidgetViews` — thay bằng **icon SF Symbols hiện đại, avatar chữ cái / vòng tròn màu tinh tế, vòng tiến độ và số liệu sắc nét** (giống Widgy / Huddle / Learn on Widgets).
    - Đổi `CFBundleDisplayName` trong `project.yml` sang tên gọn không gắn `Cozy`.
  - Target files: `project.yml`, `Shared/DesignSystem/CozyTheme.swift`, `Shared/Widgets/CozyWidgetViews.swift`, `CozyDaily/Features/Today/TodayView.swift`, `CozyDaily/Features/Today/SettingsSheet.swift`, `CozyDaily/Features/Today/WidgetSetupGuide.swift`, `CozyDaily/Features/Connect/ConnectView.swift`
- [ ] **S-05: Nâng cấp Home Screen Widgets hiện đại (Lịch tuần, Danh sách việc, Chuỗi 7 ngày T2–CN, Thời tiết & Couple)**
  - Mục tiêu:
    - Thiết kế các mẫu Home Screen Widget hiện đại kiểu **Widgy / Learn on Widgets**: Lịch tuần + Việc hôm nay có thanh màu dọc, Chuỗi 7 ngày `T2–CN` + mục tiêu từ vựng ngày, Thời tiết sạch gọn, Thẻ người kết nối hiện đại.
  - Target files: `Shared/Widgets/CozyWidgetViews.swift`, `CozyWidgets/CozyWidgetsBundle.swift`, `CozyDaily/Features/Studio/StudioView.swift`
- [ ] **S-06: Lock Screen Planner Wallpaper (Ảnh 1–6) & Shortcut tự động đổi mỗi sáng**
  - Mục tiêu:
    - Tạo công cụ ghép Lịch tuần / Việc hôm nay / Nhắc nhở nền kính mờ hiện đại lên ảnh nền Lock Screen + `AppIntent` để Apple Shortcuts tự động cập nhật hằng ngày.
  - Target files: `CozyDaily/Features/Studio/LockWallpaperStudio.swift` (mới), `CozyDaily/Features/Studio/StudioView.swift`, `Shared/Intents/CozyIntents.swift`
