# CozyDaily — ASO (tối ưu tìm kiếm App Store)

> Tên/phụ đề/từ khóa nhập ở **App Store Connect**, không nằm trong code. Tên hiển thị dưới icon (`CFBundleDisplayName`) nên giữ ngắn: `CozyDaily`.

## Quy tắc App Store
- **Name** ≤ 30 ký tự, **Subtitle** ≤ 30, **Keywords** ≤ 100 (ngăn bằng dấu phẩy, không dấu cách).
- Chữ trong Name + Subtitle đã được index, **không lặp lại trong Keywords**. Không cần số nhiều (widget/widgets) và không cần chữ "app".
- Mỗi ngôn ngữ (Localization) có bộ Name/Subtitle/Keywords riêng. Một app VN nên có cả `Vietnamese` và `English (U.S.)` để được index ở cả hai.

## Đề xuất — Vietnamese (thị trường chính)
| Trường | Nội dung | Ký tự |
| --- | --- | --- |
| Name | `CozyDaily: Widget Lịch Khóa` | 27 |
| Subtitle | `Lịch, từ vựng, thời tiết` | 24 |
| Keywords | `widget,màn hình khóa,lock screen,việc cần làm,học từ vựng,tiếng anh,cặp đôi,đếm ngày,âm lịch,ghi chú` | ≤ 100 |

Không lặp chữ đã nằm ở Name/Subtitle (`widget`, `lịch`, `từ vựng`, `thời tiết`) trong ô Keywords.

## Đề xuất — English (U.S.)
| Trường | Nội dung | Ký tự |
| --- | --- | --- |
| Name | `CozyDaily: Lock Screen Widget` | 29 |
| Subtitle | `Planner, Vocab, Weather, Couple` | 31 → rút `Planner, Vocab & Weather` (24) |
| Keywords | `widgets,calendar,to do,reminder,english,learn words,countdown,days counter,lunar,couple,mood,cute` | ≤ 100 |

## Việc cần làm ngoài code
1. Chọn tên cuối cùng, kiểm tra trùng trong App Store Connect (tên là duy nhất toàn cầu).
2. Nhập Name/Subtitle/Keywords cho từng localization.
3. Ảnh chụp màn hình: ảnh đầu tiên cần thấy ngay **Lock Screen có 4 widget** (App Store đọc chữ trong ảnh để xếp hạng gợi ý).
4. Mô tả (Description) không ảnh hưởng thứ hạng, nhưng nên đặt "widget màn hình khóa" ở câu đầu cho người đọc.

## Lưu ý trung thực
- Không ai đảm bảo thứ hạng cho từ khóa "widget": đó là từ rất cạnh tranh. Hướng thực tế là bám cụm dài ít đối thủ (`widget lịch màn hình khóa`, `widget từ vựng`, `widget thời tiết cặp đôi`).
- Thứ hạng còn phụ thuộc lượt tải, đánh giá và tỷ lệ giữ chân người dùng, không chỉ từ khóa.
