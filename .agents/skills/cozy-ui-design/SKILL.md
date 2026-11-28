---
name: cozy-ui-design
description: >-
  Hệ thống thiết kế dễ thương, ấm áp và UX cài đặt đơn giản cho ứng dụng CozyDaily iOS.
  Dùng khi thiết kế hoặc nâng cấp màn hình SwiftUI, linh vật, widget, thẻ nội dung, hoặc cài đặt.
---

# CozyDaily Cute & Effortless UI/UX Guide

## 1. Tinh thần thẩm mỹ ("Cozy Stationery & Kawaii Mascot")
- **Bảng màu ấm áp:** Nền kem giấy (`Color.bgCream`), thẻ ngà (`Color.cardIvory`) có viền ấm (`Color.cardBorder`) + bóng mềm rất nhẹ (`Color.inkCoffee.opacity(0.06)`) + lớp màu nước pastel ở góc thẻ.
- **4 màu nhấn pastel theo ngữ cảnh:**
  - `accentSage` (Xanh xô thơm): Từ vựng, chuỗi học, xuất lưới.
  - `accentPeach` (Đào hồng): Linh vật, mood, người yêu, nút yêu thích.
  - `accentHoney` (Mật ong): Món ăn, nhóm bạn (Squad), nổi bật ấm áp.
  - `accentSky` (Bầu trời): Thời tiết, lịch & đếm ngày.
- **Typography:** `CozyFont.title` (`.rounded`), `CozyFont.number` (`.rounded` + `.monospacedDigit()`), `CozyFont.body` rõ ràng, không quá nhỏ; tránh nhồi nhét chữ.
- **Linh vật dễ thương (`MascotView` / `AnimatedMascotView`):**
  - Ưu tiên hình minh họa kawaii vẽ vector trong `MascotView.swift` (má hồng, mắt biểu cảm theo pose, tai/mũi/râu đáng yêu, phụ kiện trong pill pastel) thay vì emoji thô.
  - Hỗ trợ tương tác chạm (pet/vỗ về linh vật → nảy + tim bay + rung nhẹ nếu bật haptic).

## 2. Nguyên tắc UX cho phần Cài đặt (Dễ dùng nhất cho user)
- **Trực quan trước, chữ ít đi:** Chọn linh vật bằng lưới thẻ hình linh vật lớn có preview ngay; chọn giao diện (Sáng ấm / Tối dịu / Theo máy) bằng 3 thẻ bấm trực quan.
- **Lưu tức thì (Instant Save):** Mọi thao tác đổi tên, chọn linh vật, bật/tắt tùy chọn đều phản ánh ngay trên preview (không bắt user phải nhớ bấm nút Lưu mới ăn, dù vẫn có nút Đóng/Xong rõ ràng).
- **Giấu kỹ thuật vào "Nâng cao":** Thông số sideload, Bundle ID, App Group, chẩn đoán widget phải nằm trong `DisclosureGroup` đóng mặc định để người dùng thường không bị choáng.
- **Tiếng Việt ấm áp, không dùng thuật ngữ lập trình:** Dùng "Giao diện", "Rung nhẹ khi chạm", "Học từ vựng", "Hướng dẫn thêm Widget" thay vì "App Group", "Widget Diagnostics", "SyncEngine".

## 3. Ràng buộc kỹ thuật SwiftUI iOS 17+
- Mọi view nằm trong `Shared/` được biên dịch cho **cả `CozyDaily` và `CozyWidgets`**:
  - Không dùng `UIApplication.shared` hoặc API bị cấm trong Widget Extension.
  - Dùng `#if canImport(UIKit)` khi chạm `UIColor`/`UIImage`.
  - Chú ý `WidgetMascot` và `renderingMode != .fullColor` (Lock Screen / Tinted mode giữ nét đơn sắc rõ ràng).
- Luôn tôn trọng `@Environment(\.accessibilityReduceMotion)` cho chuyển động.
