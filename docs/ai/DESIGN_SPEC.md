# CozyDaily — Bản Thiết Kế Đã Duyệt (Approved Design Reference)

> Người dùng đã duyệt bản thiết kế tổng hợp từ 15 ảnh tham khảo. Các session sau đọc file này (~30 dòng) thay vì đọc lại ảnh hay đặc tả dài.

## 6 Nguyên tắc thiết kế đã chốt
1. **CatDays Warm Stationery (Ảnh 7–11):** Nền giấy kem `#FFFDF9`, số đếm ngày lớn đậm, linh vật 3D Plush đặt cạnh số, Widget **Lịch tuần + Linh vật** (4×2), **Danh sách 3 sự kiện gọn** (4×2), và Sheet **"Chọn mẫu sự kiện"** 2×3 ô (Sinh nhật, Kỷ niệm yêu, Deadline, Thói quen, Lịch tuần, Âm lịch VN).
2. **Huddle Clean Room & Floating Dock (Ảnh 12):** Thanh tab nổi bo tròn (`Floating Pill Dock`), thẻ trạng thái live nền tối (`#2A251F`) nổi bật giữa nền sáng, thẻ thành viên squircle đa sắc, thẻ quản lý quyền vào phòng + nút **Gửi mời / Sao chép link** 1 chạm.
3. **Monthly Sticker Grid Widget (Ảnh 13):** Widget 4×2 `"Tháng 11 · 26 Stickers · ĐỦ LƯỚI ✨"` hiển thị lưới sticker Mood/Món ăn thật của user trên Home Screen.
4. **Learn-on-Widgets Streak Chain (Ảnh 14):** Dải lửa 7 ngày (`T2 → CN`), mục tiêu số từ/ngày (`dailyVocabGoal`), vòng tròn tiến độ ngày trên cả `TodayView` và `StreakWidget`.
5. **Lock Screen 2 tầng chuẩn iOS (Ảnh 1–6 & 15):**
   - Tầng 1 (WidgetKit thật ngay dưới đồng hồ): Thời tiết thật, Từ vựng, Chuỗi học, Couple, Đếm ngày.
   - Tầng 2 (Lock Screen Planner Wallpaper): App vẽ lớp kính mờ Lịch tuần / 3 tháng + Việc hôm nay + Nhắc nhở (`CozyReminder`) lên ảnh nền của user + `AppIntent` để Apple Shortcuts tự cập nhật mỗi sáng.
6. **Chuyển động chuẩn LottieFiles (`motion-design` skill):** Archetype Playful (`CozyMotionTokens`, `CozyAnimatedIcon`, 3 lớp Primary + Secondary + Ambient).
