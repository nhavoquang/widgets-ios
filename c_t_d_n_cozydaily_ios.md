# CozyDaily — Đặc Tả Dự Án Ứng Dụng iOS & Hệ Sinh Thái Widget

## 1. Tổng Quan & Triết Lý Sản Phẩm
**CozyDaily** là ứng dụng iOS cá nhân hóa nhịp sống hằng ngày, biến **Lock Screen**, **Home Screen** và **StandBy Mode** thành một không gian ấm áp, dễ thương và kết nối cảm xúc.

* **Định hướng thẩm mỹ:** Ấm áp (Warm & Cozy), minh họa vẽ tay/màu nước, linh vật biểu cảm động theo ngữ cảnh, bảng màu pastel/kem giấy dịu mắt (`#F7F4EE`), bo góc lớn mềm mại.
* **Kiến trúc hạ tầng (100% Apple Native — Zero Server Cost):**
  * **CloudKit (`Private DB` + `Shared DB`):** Không cần đăng nhập tài khoản riêng, dùng trực tiếp Apple Account/iCloud của người dùng. Hỗ trợ chia sẻ không gian riêng cho Cặp đôi (1-1) và Nhóm bạn (3–8 người) qua `CKShare` (gửi link mời qua iMessage/AirDrop).
  * **WeatherKit (500k calls/tháng):** Lấy dữ liệu thời tiết thực tế để thay đổi trang phục/hoạt động của linh vật và gợi ý món ăn/trạng thái theo thời tiết, áp dụng cơ chế cache theo vùng tọa độ và khung giờ để tối ưu quota.
  * **Local-First + App Groups:** Mọi thao tác lưu trực tiếp vào bộ nhớ cục bộ dùng chung (`App Group`) giúp giao diện App và Widgets phản hồi tức thì `0ms`, sau đó tự động đồng bộ ngầm lên iCloud.

---

## 2. Hệ Thống Thiết Kế (Design System)

### 2.1. Bảng Màu (Color Tokens)
| Vai trò | Tên Token | Mã HEX | Ứng dụng |
| :--- | :--- | :--- | :--- |
| **Nền chính (Canvas)** | `bgCream` | `#F7F4EE` | Nền tổng thể các màn hình trong app |
| **Nền thẻ (Card Surface)** | `cardIvory` | `#FFFDF9` | Nền các thẻ chức năng, bo góc `24pt`, viền `#EBE4D8` |
| **Chữ chính (Primary Ink)** | `inkCoffee` | `#3D352E` | Tiêu đề, số đếm ngày, nội dung quan trọng |
| **Chữ phụ (Secondary Ink)** | `inkTaupe` | `#8C8278` | Mô tả phụ, mốc thời gian, phiên âm |
| **Nhấn Từ Vựng** | `accentSage` | `#7FA98E` | Thẻ học tiếng Anh, tiến độ streak |
| **Nhấn Cảm Xúc** | `accentPeach` | `#E8927C` | Thẻ mood, thông báo tương tác đôi |
| **Nhấn Món Ăn** | `accentHoney` | `#E6B85C` | Thẻ món ăn hôm nay, gợi ý bữa ăn |
| **Nhấn Sự Kiện & Thời Tiết** | `accentSky` | `#7BA7CC` | Thẻ đếm ngày, lịch trình, thời tiết |

### 2.2. Kiểu Chữ (Typography Options)
* **Giao diện App:** `SF Pro Rounded` cho tiêu đề/con số kết hợp `SF Pro Text` cho nội dung nhỏ.
* **4 Tùy chọn Font trên Widget:**
  1. `Cozy Rounded` (Bo tròn mềm mại — mặc định)
  2. `Editorial Serif` (Chữ có chân thanh lịch — hợp từ vựng & trích dẫn)
  3. `Clean Modern` (Không chân gọn gàng — hợp lịch sự kiện & deadline)
  4. `Cute Handwritten` (Chữ viết tay tự nhiên — hợp lời nhắn đôi/nhóm bạn)

### 2.3. Hệ Thống Linh Vật (Mascot State Machine)
Linh vật đồng hành (Mèo, Cún, Thỏ, Gấu) tự động thay đổi tư thế và phụ kiện dựa trên 3 yếu tố:
1. **Cảm xúc người dùng:** Vui vẻ, Chill, Buồn ngủ, Háo hức, Mệt mỏi, Nhớ nhung, Bận rộn.
2. **Thời tiết (WeatherKit):** Trời mưa (đội mũ/cầm ô), Trời nắng (đeo kính râm/cầm trà sữa), Trời lạnh (quàng khăn len).
3. **Khung giờ trong ngày:** Sáng (uống cà phê), Trưa/Chiều (ăn cơm/đọc sách), Khuya sau 22:30 (trùm chăn ngủ).

---

## 3. Bảy Trụ Cột Tính Năng Toàn Diện

### 3.1. Học Tiếng Anh Mỗi Ngày (Smart Daily Vocab)
* **Kho từ vựng đa dạng:** Giao tiếp đời thường, Idioms & Slang, IELTS/TOEIC, Từ vựng chữa lành, hoặc bộ từ do người dùng tự nhập.
* **Spaced Repetition (Lặp lại ngắt quãng):** Tự động tính chu kỳ ôn tập (`1 - 3 - 7 - 30 ngày`).
* **Interactive Widget & Flashcard:** Bấm *"Đã thuộc"* hoặc *"Đổi từ"* trực tiếp trên Home Screen Widget; chế độ ẩn nghĩa trên Lock Screen để luyện phản xạ; phát âm offline qua `AVSpeechSynthesizer`.

### 3.2. Nhật Ký Cảm Xúc, Món Ăn & Nhịp Sống (Mood, Food & Vibe)
* **Check-in 1 chạm:** Chọn Mood + Sticker Món ăn (Phở, Bún bò, Trà sữa, Cà phê, Bánh mì, Sushi...) + Thanh pin xã hội (`Social Battery`) + Note ngắn tối đa 30 ký tự.
* **Tự động hóa thông minh:** Hỗ trợ **iOS Shortcuts & Focus Mode** qua `AppIntents` (tự cập nhật mood khi bật chế độ Làm việc, Ngủ hoặc hoàn thành bài tập trên Apple Watch).

### 3.3. Thời Tiết & Ngữ Cảnh Thông Minh (WeatherKit Integration)
* **Tối ưu 500k calls/tháng:** Fetch dữ liệu tập trung tại Main App khi mở app hoặc khi di chuyển sang khu vực mới (làm tròn tọa độ ~1km, cache tối thiểu 30–60 phút), lưu vào App Group cho Widget đọc lại mà không tốn thêm quota.
* **Hiển thị giàu cảm xúc:** Kết hợp nhiệt độ, trạng thái bầu trời với gợi ý món ăn/trang phục và chia sẻ thời tiết hiện tại cho người yêu/nhóm bạn.

### 3.4. Kết Nối Người Yêu & Nhóm Bạn (Us & Squad Live Space)
* **Couple Space (1-1):** Thẻ trạng thái đôi hiển thị song song trên widget, đếm ngày yêu, chia sẻ thời tiết/pin/mood và nút **Quick Ping** (*"Ăn cơm chưa?"*, *"Đang nhớ nè"*, *"Thèm trà sữa"*) kèm phản hồi rung Haptic.
* **Squad Board (Nhóm 3–8 người):** Bảng trạng thái cả nhóm, thả sticker phản hồi nhanh và đồng bộ sự kiện/đếm ngược chung của cả nhóm lên Lock Screen mọi thành viên.
* **Đồng bộ nền (`CKDatabaseSubscription`):** Nhận Silent Push qua APNs để cập nhật widget khi đối phương thay đổi trạng thái.

### 3.5. Lịch Sự Kiện, Đếm Ngày & Âm Lịch Việt Nam (Events & Calendar)
* **5 chế độ đếm thời gian:** Đếm ngược (Countdown), Đếm tiến (Count up), Âm lịch Việt Nam (Rằm, Mùng 1, Tết, giỗ chạp), Lịch lặp lại hằng tuần (lịch học/dạy/họp), Deadline nhắc việc.
* **Monthly Sticker Grid:** Bảng lịch tháng tự động lấp đầy sticker cảm xúc/món ăn/chuỗi học mỗi ngày; hỗ trợ xuất ảnh đẹp tỷ lệ Story (9:16) hoặc Vuông (1:1).
* **Đồng bộ Apple Calendar (`EventKit`):** Kéo lịch hệ thống ra hiển thị theo giao diện dễ thương của app.

### 3.6. Xưởng Tùy Biến Widget (Pro Widget Studio)
* Tùy biến độc lập từng chiếc widget qua 4 lớp: **Nội dung** -> **Theme & Linh vật** -> **Bảng màu & Độ trong suốt** -> **Font chữ & Khung viền**.
* Hỗ trợ **Smart Auto-Theme** tự động đổi giao diện sáng/tối theo khung giờ hoặc dịp lễ đặc biệt.

### 3.7. Phủ Sóng Trọn Bộ Bề Mặt iOS
* **Lock Screen Widgets:** `Rectangular` (Từ vựng, Mood+Món ăn, Trạng thái Người yêu, Sự kiện, Combo 2-in-1), `Circular` (Linh vật mood, Vòng streak, Đếm ngày), `Inline` (1 dòng trạng thái cạnh ngày tháng). Hỗ trợ tối ưu hiển thị đơn sắc (Tinted/Monochrome).
* **Home Screen Widgets:** `Small` (2x2), `Medium` (4x2), `Large` (4x4).
* **StandBy Mode:** Giao diện đồng hồ ngang ban đêm kèm linh vật ngủ và lịch trình ngày mai.

---

## 4. Kiến Trúc Màn Hình (4 Tab Chính)
1. **Tab 1 — Hôm nay (Today Hub):** Bảng điều khiển nhanh gồm Thẻ Từ vựng hôm nay, Thanh Check-in Mood & Món ăn, Thời tiết ngữ cảnh và Sự kiện sắp tới.
2. **Tab 2 — Kết nối (Us & Squad):** Chuyển đổi giữa không gian Cặp đôi và Nhóm bạn, thẻ đôi trực quan, hàng nút Quick Ping và luồng tương tác sticker trong ngày.
3. **Tab 3 — Lịch & Lưới (Calendar & Grid):** Lưới Sticker tổng kết tháng (chuyển chế độ xem Mood / Món ăn / Vocab) kết hợp danh sách Sự kiện & Đếm ngày.
4. **Tab 4 — Xưởng Widget (Widget Studio):** Khung xem trước trực tiếp (Live Preview) trên màn hình khóa/màn hình chính giả lập cùng thanh công cụ tùy biến 4 bước.