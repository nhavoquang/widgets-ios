# CozyDaily — Session Handoff

> Cập nhật cuối session. Tập trung làm sạch 100% data thật và tối ưu 4 Widget Lock Screen cốt lõi cực gọn đẹp & dễ dùng.

## Vừa hoàn thành (4 Trụ cột Lock Screen Data Thật & App Tinh Gọn)
1. **Dọn sạch dữ liệu giả & sửa dứt điểm lỗi thời tiết giả:**
   - `CozySnapshot.freshReal()` + `CozyRepository.loadOrCreate()`: khởi tạo app sạch hoàn toàn bằng **data thật** (không tạo người yêu `Gấu`, sự kiện `Đi Đà Lạt` hay thời tiết `TP.HCM 27°` giả).
   - Thêm banner 1 chạm **"Xóa sạch"** trên `TodayView` nếu máy cài bản cũ còn sót data mẫu.
   - `CozyWeatherService` (`CozyDaily/App/Services.swift`): tự phát hiện thời tiết mẫu cũ `TP.HCM 27° (C:31° T:24°)` để buộc tải lại **thời tiết thật Open-Meteo** và gọi ngay `CozyShared.didChange()` để Lock Screen cập nhật tức thì.
2. **4 Widget Lock Screen chỉnh chu, tối giản, sắc nét (chống cắt chữ `...`):**
   - `CozyWidgets/CozyWidgetsBundle.swift` & `Shared/Widgets/CozyWidgetViews.swift`:
     1. **`Lịch & Việc hôm nay` (`TodayScheduleWidget` — mới):** Hiện lịch thật từ Apple Calendar + công việc hôm nay (`CozyTask`) trên Lock Screen (`Rectangular`, `Circular`, `Inline`) và tích xong ngay trên Home Screen (`ToggleTaskIntent`).
     2. **`Từ vựng hôm nay` (`VocabWidget`):** 3 dòng SF Rounded + Mono cực sắc nét (`từ` / `phiên âm` / `nghĩa`), bỏ icon sách chật chội và font serif khó đọc.
     3. **`Thời tiết thật` (`WeatherCozyWidget`):** Gọn chuẩn Apple (`[Icon] 28° Hà Nội` / `Ít mây · Cảm giác 30°` / `↑31° ↓24° · Ẩm 72%`), bỏ hẳn dòng mô tả linh vật bị cắt `...`.
     4. **`Cảm xúc người kết nối` (`CoupleWidget`):** Hiện tên + cảm xúc + % pin + note ngắn + thời tiết thật của người kết nối (không còn `Gấu` giả).
3. **Kết nối 2 người hoạt động THẬT ngay cả trên bản IPA miễn phí chưa bật iCloud:**
   - Đăng ký URL scheme `cozydaily://` trong `project.yml` + thêm `PartnerStatusLink` (`Social.swift`) + `.onOpenURL` (`CozyDailyApp.swift`).
   - Gửi cảm xúc qua Zalo / iMessage / AirDrop bằng 1 chạm (`ShareLink`) → người kia chạm link là cảm xúc thật cập nhật thẳng lên App & Lock Screen Widget (và vẫn đồng bộ tự động qua CloudKit nếu cài bản trả phí).
4. **Tinh gọn `TodayView.swift` siêu dễ dùng:**
   - Đúng 4 thẻ thẳng hàng tương ứng 1-1 với 4 Widget Lock Screen: (1) Thêm việc & đồng bộ Apple Calendar, (2) Từ vựng hôm nay, (3) Thời tiết thật + chọn nhanh TP/GPS, (4) Cảm xúc của bạn + Gửi cho người kết nối.

## Kiểm chứng
- `swift test --package-path Packages/CozyCore`: **39/39 PASS** (gồm `testTasksTodayScheduleAndPartnerLink`).

## Prompt mở session mới (nếu muốn làm tiếp S-04 / S-06 sau khi test bản này trên iPhone)
```text
Đọc docs/ai/HANDOFF.md và docs/ai/DESIGN_SPEC.md, sau đó làm tiếp Slice kế tiếp trong docs/ai/TASK_QUEUE.md.
```
