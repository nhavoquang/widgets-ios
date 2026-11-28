# CozyDaily — Kiến trúc rút gọn (1-Page Reference)

## 1. Cấu trúc 4 tầng
| Tầng | Đường dẫn | Vai trò | Compile ở đâu |
| --- | --- | --- | --- |
| **Core** | `Packages/CozyCore` | Model, logic thuần Swift (SRS 1-3-7-30, Âm lịch VN, EventCounter 5 chế độ, MascotEngine, MonthGrid, WeatherPolicy, Snapshot JSON, SyncMerge) | Windows (`swift test`) + macOS/iOS |
| **Shared** | `Shared/` | SwiftUI dùng chung giữa App & Widget: `CozyTheme`, `MascotView`, `CozyAssetViews`, `CozyWidgetData`, `CozyWidgetViews`, `CozyIntents`, `CloudSync` | macOS/iOS (CI) |
| **App** | `CozyDaily/` | 4 tab (`TodayView`, `ConnectView`, `CalendarGridView`, `StudioView`), `SettingsSheet`, `AppModel`, `Services` (WeatherKit, EventKit, Speech, Haptics), `AnimatedMascotView` | macOS/iOS (CI) |
| **Widgets** | `CozyWidgets/` | WidgetKit bundle (`CozyWidgetsBundle.swift`) đăng ký các widget Home Screen, Lock Screen & StandBy | macOS/iOS (CI) |

## 2. Luồng dữ liệu (Single Source of Truth)
```text
User Action (App UI / Widget AppIntent / Focus Filter)
  └─▶ CozyRepository.mutate(...)
        ├─▶ Lưu CozySnapshot JSON vào App Group (SnapshotStore)
        ├─▶ Cập nhật quick state (SharedWidgetStore)
        └─▶ Gửi tín hiệu CloudSync (nếu COZY_CLOUD_ENABLED=YES)
  └─▶ AppModel.commit() -> refresh() + WidgetCenter.shared.reloadAllTimelines()
```

## 3. Lệnh kiểm tra & Build
- **Chạy toàn bộ unit test lõi trên Windows:**
  ```powershell
  swift test --package-path Packages/CozyCore
  ```
- **Build IPA / kiểm tra compile SwiftUI + Widget:**
  Push lên GitHub để chạy `.github/workflows/ios.yml` (gồm 3 job: `core-tests`, `unsigned-ipa`, `widget-registration`, cộng `signed-ipa` nếu đủ secrets).

## 4. Lưu ý quan trọng khi chỉnh sửa
- **App Group ID:** `group.com.cozydaily.shared` (tự nhận diện `ALTAppGroups` khi sideload AltStore/SideStore).
- **Backward Compatibility:** `CozySnapshot` và `UserSettings` lưu JSON trên máy user — mọi thuộc tính mới bắt buộc có `decodeIfPresent` trong `init(from:)`.
- **Target `CozyWidgets`:** Mọi file trong `Shared/` tự động được include vào cả `CozyDaily` và `CozyWidgets` (xem `project.yml`). Tránh dùng API chỉ có ở Main App trong `Shared/`.
