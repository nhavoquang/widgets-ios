# Session Handoff — Modern Lock Screen Studio (`Widgets Home & Lock`)

## Vừa hoàn thành
- `CozyDaily/Features/Studio/LockWallpaperStudio.swift`:
  - 10 mẫu Lock Screen hiện đại (nền, viền, bo góc, sáng/tối) + 6 kiểu thẻ + chọn ảnh nền từ Thư viện.
  - Hỗ trợ **kéo thả vị trí dọc trực tiếp bằng tay (`DragGesture`)** trên khung Lock Screen.
  - Tích hợp nút **Áp dụng ngay bằng Shortcut ⚡** (`shortcuts://run-shortcut?name=Update%20Lock%20Screen`) và sẵn chỗ dán `templateShortcutShareURL` (`icloud.com/shortcuts/...`) để user bấm 1 chạm cài Shortcut mẫu.

## Prompt mở session mới (Slice S-05: Mở rộng 20+ mẫu Lock Screen & 12+ khối hiện đại + kéo thả tự do từng khối)
```text
Đọc docs/ai/HANDOFF.md và docs/ai/DESIGN_SPEC.md, nâng cấp LockWallpaperStudio.swift lên 20+ mẫu Lock Screen hiện đại (lấy cảm hứng từ Widgy / Locka / Apple iOS 18) và thêm các khối mới (Tiến độ năm 2026 %, Đếm ngược sự kiện, Giấy nhớ Sticky Note, Chuỗi thói quen 7 ngày, Lịch 3 tháng, Pin thiết bị) kèm kéo thả vị trí mượt mà.
```
