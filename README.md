# CozyDaily (iOS)

App iOS cá nhân hóa nhịp sống hằng ngày với widget Lock Screen, Home Screen và StandBy. Đặc tả gốc: [c_t_d_n_cozydaily_ios.md](c_t_d_n_cozydaily_ios.md).

## Cấu trúc

| Thư mục | Nội dung |
| --- | --- |
| `Packages/CozyCore` | Logic thuần Swift, không phụ thuộc UI: model, Spaced Repetition 1‑3‑7‑30, Âm lịch Việt Nam, đếm ngày 5 chế độ, cache WeatherKit, máy trạng thái linh vật, lưới sticker tháng, kho lưu JSON trong App Group. Build và test được cả trên Windows/Linux. |
| `Shared` | Code SwiftUI dùng chung cho App và Widget: design system, `MascotView`, các `AppIntent` (Đã thuộc, Đổi từ, Mood, Quick Ping, chọn mẫu widget), view widget. |
| `CozyDaily` | App chính: 4 tab (Hôm nay, Kết nối, Lịch & Lưới, Xưởng Widget), dịch vụ WeatherKit, EventKit, phát âm, haptic, Shortcuts, Focus Filter. |
| `ci` | Script và cấu hình đóng gói IPA. |
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

## Cài IPA từ GitHub Actions

Mỗi lần push, workflow **iOS build** tạo artifact trong trang của lần chạy (tab Actions).

### Cách 1: IPA chưa ký (`CozyDaily-unsigned-ipa`), dùng Apple ID miễn phí
1. Tải artifact, giải nén lấy file `.ipa`.
2. Cài bằng AltStore / SideStore (khuyên dùng vì giữ được App Group để widget đọc dữ liệu của app) hoặc Sideloadly.
3. Apple ID miễn phí: app hết hạn sau 7 ngày, cần ký lại. Bản này không có iCloud, Push, WeatherKit (dùng dữ liệu mẫu).

### Cách 2: IPA đã ký (`CozyDaily-signed-ipa`), cần Apple Developer trả phí
1. Trong Apple Developer portal:
   - Đăng ký UDID iPhone (của bạn và người test).
   - Tạo App ID `<prefix>.app` và `<prefix>.app.widgets`, App Group `group.<prefix>.shared`, iCloud container `iCloud.<prefix>`.
   - Bật App Groups, iCloud (CloudKit), Push Notifications, WeatherKit cho App ID của app (WeatherKit bật cả ở mục App Services); App Groups và iCloud cho App ID của widget.
2. App Store Connect > Users and Access > Integrations: tạo API key quyền **Admin**, tải file `.p8`.
3. GitHub repo > Settings > Secrets and variables > Actions:
   - Secrets: `APPLE_TEAM_ID`, `ASC_KEY_ID`, `ASC_ISSUER_ID`, `ASC_PRIVATE_KEY` (toàn bộ nội dung file `.p8`).
   - Variable: `COZY_BUNDLE_PREFIX` (vd. `com.tenban.cozydaily`).
4. Chạy lại workflow. Cài IPA bằng Apple Configurator, Xcode hoặc dịch vụ OTA.

IPA này dùng môi trường CloudKit **Development**. Trước khi phát hành thật cần Deploy Schema sang Production trong CloudKit Console.

## Tài nguyên linh vật

Tên file do `MascotAssetManager` quy định (danh sách đầy đủ: `MascotAssetManager.allAssets`):

| Bề mặt | Tên | Ví dụ | Đặt ở |
| --- | --- | --- | --- |
| Animation trong app | `anim_<key>.riv` / `.json` | `anim_mascot_cat_sleeping.json` | `CozyDaily/Resources` |
| Widget full color | `img_<key>` (PNG trong suốt) | `img_mascot_cat`, `img_food_pho` | Asset catalog của **cả** app và widget |
| Lock Screen / Tinted | `tint_<key>` (template) | `tint_mood_happy` | Asset catalog của cả hai |

Thiếu file thì tự dùng emoji hoặc SF Symbol. Để chạy Rive/Lottie, thêm package vào `project.yml` (xem `CozyDaily/Mascot/MascotAnimationAdapters.swift`).

## Chạy test logic lõi

```bash
swift test --package-path Packages/CozyCore
```

## Trạng thái

**Đã có:** 4 tab, widget tương tác, chuyển cảnh và chế độ đơn sắc cho widget, lớp animation linh vật, đồng bộ CloudKit (Private + Shared DB, `CKShare`, Silent Push).

**Chưa kiểm chứng:** đồng bộ CloudKit và IPA ký số chưa chạy thử (cần tài khoản trả phí và 2 máy thật); adapter Rive/Lottie chưa được biên dịch; giao diện chưa được xem trên thiết bị.

**Còn thiếu:** minh họa linh vật, font viết tay riêng.

Giới hạn số người (2 cho cặp đôi, 8 cho nhóm) chưa được CloudKit ép buộc.
