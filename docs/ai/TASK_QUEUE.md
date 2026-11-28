# CozyDaily — Task Queue (Đã duyệt theo Design Blueprint)

> Mỗi Slice làm gọn trong **1 session mới**, tiết kiệm tối đa token. Tham chiếu thiết kế đã duyệt tại `docs/ai/DESIGN_SPEC.md`.

## Đã hoàn thành
- [x] **S-00:** Thiết lập hệ thống học project & chia session tiết kiệm token (`AGENTS.md`, skills, `docs/ai/`)
- [x] **S-01:** Giao diện dễ thương nền tảng & Cài đặt 1 chạm (`SettingsSheet`, `TodayView`, `CozyTheme`, `AppAppearance`)
- [x] **S-02:** Thời tiết thật Open-Meteo + Fix Widget Cache + Linh vật 3D Plush + `motion-design` skill + `CozyAnimatedIcon` + Widget Lock/Home Screen

## Đang thực hiện
- [x] **S-03: Kết nối 2 người (Couple) & 3–8 người (Squad) chuẩn chỉnh + Redesigned ConnectView (Huddle + 3D Cute)**
  - Mục tiêu:
    - Ép giới hạn thành viên (2 cho Couple, 8 cho Squad) trong `SpaceMerge` & `CloudSync`, lưu `shareURL` để sao chép link mời 1 chạm, thêm đổi tên phòng & gửi tin nhắn nhanh trong `AppModel`.
    - Thiết kế lại `ConnectView.swift` theo thiết kế đã duyệt (thẻ live nền tối kiểu Huddle + nút nhịp tim `CozyAnimatedIcon`, thẻ thành viên squircle 3D Plush, hiệu ứng Quick Ping tim bay, thẻ quyền truy cập & mời 1 chạm, ô gửi lời nhắn nhanh).
  - Target files: `Packages/CozyCore/Sources/CozyCore/Sync/SyncMerge.swift`, `Packages/CozyCore/Tests/CozyCoreTests/SyncAndAssetTests.swift`, `Shared/Cloud/CloudSync.swift`, `CozyDaily/App/AppModel.swift`, `CozyDaily/Features/Connect/ConnectView.swift`

## Hàng đợi các session tiếp theo (1 Slice = 1 Session mới)
- [ ] **S-04: Bộ Home Screen Widgets kiểu CatDays + Lưới Sticker Tháng + Chuỗi 7 ngày T2–CN + Floating Pill Tab Bar**
  - Mục tiêu:
    - Thêm `dailyVocabGoal` vào `UserSettings` (tương thích ngược JSON) + helper chuỗi 7 ngày (`T2→CN`) trong `CozyCore`.
    - Thêm 3 kiểu Widget Home Screen mới trong `CozyWidgetViews.swift` & `CozyWidgetsBundle.swift`: **Lịch tuần + Linh vật CatDays** (4×2), **Lưới Sticker Tháng** (4×2 kiểu Ảnh 13), **Danh sách 3 sự kiện gọn** (4×2), và nâng cấp **Streak Widget** có dải lửa 7 ngày `T2–CN`.
    - Nâng cấp `RootTabView` sang **Floating Pill Tab Bar** (kiểu Huddle Ảnh 12) + thêm dải Chuỗi 7 ngày `T2–CN` & Hero CatDays trên `TodayView` + chọn `dailyVocabGoal` trong `SettingsSheet`.
  - Target files: `Packages/CozyCore/Sources/CozyCore/Storage/CozySnapshot.swift`, `Packages/CozyCore/Sources/CozyCore/Models/WidgetConfig.swift`, `Shared/Widgets/CozyWidgetData.swift`, `Shared/Widgets/CozyWidgetViews.swift`, `CozyWidgets/CozyWidgetsBundle.swift`, `CozyDaily/App/CozyDailyApp.swift`, `CozyDaily/Features/Today/TodayView.swift`, `CozyDaily/Features/Today/SettingsSheet.swift`
- [ ] **S-05: 6 Mẫu Sự Kiện kiểu CatDays + Nhắc Nhở (`CozyReminder`) + Sổ tay Lịch & Lưới**
  - Mục tiêu:
    - Thêm model `CozyReminder` (có hoàn thành/quá hạn) vào `CozySnapshot` (tương thích ngược JSON + test).
    - Nâng cấp `EventEditor.swift` bắt đầu bằng màn hình **6 Mẫu Sự Kiện 2×3 kiểu CatDays** (Sinh nhật, Kỷ niệm yêu, Deadline, Thói quen, Lịch tuần, Âm lịch VN) + chọn emoji nhanh & màu pastel.
    - Nâng cấp `CalendarGridView.swift`: chạm ngày xem chi tiết Check-in/Âm lịch, danh sách Nhắc nhở (`Reminders`) tích nhanh, xuất Story 9:16 đẹp mắt.
  - Target files: `Packages/CozyCore/Sources/CozyCore/Models/CozyEvent.swift`, `Packages/CozyCore/Sources/CozyCore/Storage/CozySnapshot.swift`, `Packages/CozyCore/Sources/CozyCore/Storage/CozyRepository.swift`, `CozyDaily/Features/Calendar/EventEditor.swift`, `CozyDaily/Features/Calendar/CalendarGridView.swift`
- [ ] **S-06: Xưởng Widget Preset 1 Chạm + Lock Screen Planner Wallpaper Studio (Ảnh 1–6) + Cute Onboarding**
  - Mục tiêu:
    - Nâng cấp `StudioView.swift` với **4 Preset 1 chạm** (`CatDays Giấy kem`, `Pastel Màu nước`, `Đêm ấm`, `Kính mờ`) + **Lock Screen Planner Wallpaper Studio** (chọn ảnh nền từ PhotosPicker, ghép lớp kính mờ Lịch tuần/3 tháng + Việc hôm nay + Nhắc nhở đúng khung iPhone, xuất ảnh & thêm `GenerateLockWallpaperIntent` cho Apple Shortcuts tự cập nhật mỗi sáng).
    - Tạo `OnboardingView.swift` (3 bước chào lần đầu đặt tên, chọn linh vật, thành phố thời tiết & tùy chọn bắt đầu sạch bằng data thật).
  - Target files: `CozyDaily/Features/Studio/StudioView.swift`, `CozyDaily/Features/Studio/LockWallpaperStudio.swift` (mới), `Shared/Intents/CozyIntents.swift`, `CozyDaily/Features/Today/OnboardingView.swift` (mới), `CozyDaily/App/CozyDailyApp.swift`
