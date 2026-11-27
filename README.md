# CozyDaily (iOS)

App iOS cá nhân hóa nhịp sống hằng ngày với widget Lock Screen, Home Screen và StandBy. Đặc tả gốc: [c_t_d_n_cozydaily_ios.md](c_t_d_n_cozydaily_ios.md).

## Cấu trúc

| Thư mục | Nội dung |
| --- | --- |
| `Packages/CozyCore` | Logic thuần Swift, không phụ thuộc UI: model, Spaced Repetition 1‑3‑7‑30, Âm lịch Việt Nam, đếm ngày 5 chế độ, cache WeatherKit, máy trạng thái linh vật, lưới sticker tháng, kho lưu JSON trong App Group. Build và test được cả trên Windows/Linux. |
| `Shared` | Code SwiftUI dùng chung cho App và Widget: design system, `MascotView`, các `AppIntent` (Đã thuộc, Đổi từ, Mood, Quick Ping, chọn mẫu widget), view widget. |
| `CozyDaily` | App chính: 4 tab (Hôm nay, Kết nối, Lịch & Lưới, Xưởng Widget), dịch vụ WeatherKit, EventKit, phát âm, haptic, Shortcuts, Focus Filter. |
| `CozyWidgets` | Widget Extension: Xưởng Widget (tùy biến), Từ vựng, Người yêu, Đếm ngày, StandBy. |
| `project.yml` | Cấu hình XcodeGen để sinh `CozyDaily.xcodeproj`. |

## Build trên Mac

Yêu cầu: macOS 14+, Xcode 16+, iOS 17+.

```bash
brew install xcodegen
xcodegen generate
open CozyDaily.xcodeproj
```

Trong Xcode, ở tab **Signing & Capabilities** của cả hai target `CozyDaily` và `CozyWidgets`:

1. Chọn Team của bạn.
2. Đổi App Group `group.com.cozydaily.shared` và bundle id `com.cozydaily.app` sang tên riêng nếu bị trùng (nhớ sửa hằng `SnapshotStore.appGroupID` cho khớp).
3. WeatherKit và iCloud/CloudKit cần tài khoản Apple Developer trả phí. Khi chưa có, app vẫn chạy với dữ liệu thời tiết mẫu.

## Chạy test logic lõi

```bash
swift test --package-path Packages/CozyCore
```

27 test bao gồm: Tết 2024/2025/2026, tháng 6 nhuận 2025, chuyển đổi khứ hồi âm ↔ dương 2024–2027, Can Chi, chu kỳ SRS, các chế độ đếm ngày, chính sách cache thời tiết, linh vật, streak, lưới tháng, Auto‑Theme ngày lễ.

## Trạng thái

**Giai đoạn 1 (đã có):** chạy offline đầy đủ giao diện, dữ liệu local-first trong App Group, widget tương tác, dữ liệu mẫu cho Couple/Squad.

**Giai đoạn 2 (chưa làm):**
- CloudKit Private DB + Shared DB, `CKShare` mời qua iMessage/AirDrop, `CKDatabaseSubscription` + Silent Push để cập nhật widget khi đối phương đổi trạng thái (điểm móc: `CloudSyncService`).
- Bộ minh họa linh vật màu nước: thêm ảnh vào `Assets.xcassets/Mascots` theo tên `MascotState.assetName` (vd. `cat_sleeping_blanket`), `MascotView` sẽ tự dùng ảnh thay cho emoji.
- Font viết tay riêng (hiện dùng Noteworthy có sẵn của iOS).
