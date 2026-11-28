# CozyDaily iOS — Agent Index & Session Rules

> **Mục tiêu file này:** Giúp mỗi session mới nắm đúng kiến trúc trong < 600 token, chỉ đọc đúng file cần sửa, không quét toàn repo và không kéo dài 1 session gây tốn token.

## 1. Tổng quan nhanh
- **App:** CozyDaily (iOS 17+, SwiftUI + WidgetKit + AppIntents + CloudKit). Ngôn ngữ UI: Tiếng Việt thân thiện, ấm áp, dễ thương.
- **Môi trường dev:** Windows (chỉnh sửa code & chạy test logic lõi `swift test --package-path Packages/CozyCore`); build IPA & test Simulator qua GitHub Actions (`.github/workflows/ios.yml` + `project.yml` XcodeGen).
- **Quy tắc dữ liệu:** Local-first JSON snapshot (`CozySnapshot`) trong App Group → `CozyRepository` → `AppModel` (`@Observable`) → `WidgetCenter.shared.reloadAllTimelines()`.

## 2. Bản đồ file theo khu vực (chỉ đọc file thuộc lát cắt đang làm)
- **Logic lõi & Model (test được trên Windows):** `Packages/CozyCore/Sources/CozyCore/`
  - `Models/` (`ColorTokens`, `CheckIn`, `CozyEvent`, `Social`, `Vocab`, `Weather`, `WidgetConfig`)
  - `Logic/` (`MascotEngine`, `SpacedRepetition`, `EventCounter`, `MonthGrid`, `VietnameseLunarCalendar`, `WeatherPolicy`)
  - `Storage/` (`CozySnapshot` + `UserSettings`, `CozyRepository`, `SnapshotStore`, `SharedWidgetStore`)
  - `Tests/CozyCoreTests/` (`LogicTests`, `LunarCalendarTests`, `SyncAndAssetTests`)
- **Design System & Widget dùng chung (App + Widget Extension):** `Shared/`
  - `DesignSystem/` (`CozyTheme.swift`, `CozyAnimatedIcon.swift`, `MascotView.swift`, `CozyAssetViews.swift`)
  - `Widgets/` (`CozyWidgetData.swift`, `CozyWidgetViews.swift`)
  - `Intents/CozyIntents.swift`, `Cloud/CloudSync.swift`
- **Main App UI:** `CozyDaily/`
  - `App/` (`CozyDailyApp.swift`, `AppModel.swift`, `Services.swift`, `CloudAppSupport.swift`)
  - `Features/Today/` (`TodayView.swift`, `SettingsSheet.swift`, `WidgetDiagnostics.swift`)
  - `Features/Connect/ConnectView.swift`
  - `Features/Calendar/` (`CalendarGridView.swift`, `EventEditor.swift`)
  - `Features/Studio/StudioView.swift`
  - `Mascot/` (`AnimatedMascotView.swift`, `MascotAnimationAdapters.swift`)

## 3. Quy tắc tiết kiệm token & chia session
1. **Đọc tối thiểu:** Bắt đầu session bằng cách đọc `docs/ai/HANDOFF.md` (nếu có) + tối đa 3–6 file liên quan trực tiếp. **Không** đọc file đặc tả gốc `c_t_d_n_cozydaily_ios.md` (~dài) trừ khi cần đối chiếu 1 mục cụ thể.
2. **Mỗi session = 1 lát cắt (Slice) nhỏ:** Tối đa ~5 file sửa đổi, hoàn thành gọn trong 1 lượt công việc rõ ràng. Nếu yêu cầu người dùng lớn (>1 khu vực), hãy chia thành các Slice nhỏ trong `docs/ai/TASK_QUEUE.md`, làm xong Slice đầu tiên rồi bàn giao để mở session mới.
3. **Bàn giao cuối session:** Luôn cập nhật `docs/ai/HANDOFF.md` (đã làm gì, file đã sửa, kết quả test, và **1 prompt mẫu copy-paste** để mở session mới làm Slice kế tiếp).
4. **Dùng skill theo nhu cầu:**
   - Chia task / bàn giao session → đọc skill `cozy-session-workflow`.
   - Sửa UI / thẩm mỹ dễ thương / UX cài đặt → đọc skill `cozy-ui-design`.
   - Thiết kế animation, icon động, micro-interaction → đọc skill `motion-design` (chuẩn LottieFiles Playful archetype, 3 lớp Primary + Secondary + Ambient).
5. **Tương thích dữ liệu:** Khi thêm field vào `UserSettings` hay `CozySnapshot`, luôn dùng `decodeIfPresent` có giá trị mặc định và thêm unit test giải mã JSON cũ trong `CozyCoreTests`.
6. **Kiểm tra sau khi sửa:** Luôn chạy `swift test --package-path Packages/CozyCore` nếu có đụng `CozyCore`, và kiểm tra lại tính nhất quán SwiftUI / iOS 17 API khi sửa `CozyDaily` hoặc `Shared`.
7. **Quy ước Git:** Khi người dùng yêu cầu "commit", mặc định thực hiện cả `git commit` lẫn `git push` lên `origin/main` để kích hoạt GitHub Actions build & kiểm chứng iOS.
