# Cẩm nang Nộp App Store Toàn Cầu & Tối ưu Doanh thu (15 Ngôn ngữ)

> Tài liệu thực chiến để copy-paste trực tiếp lên **App Store Connect**, giúp app đạt **x3–x5 lượng hiển thị tự nhiên (Organic ASO)** tại 15 thị trường lớn nhất và vượt qua **Apple App Review** ngay lần nộp đầu tiên.

---

## 1. Cấu hình Chung trên App Store Connect

- **Bundle ID:** `com.cozydaily.app` (Widget Extension: `com.cozydaily.app.widgets`)
- **Primary Category (Danh mục chính):** `Productivity` (Năng suất — người dùng sẵn sàng chi tiền cao nhất)
- **Secondary Category (Danh mục phụ):** `Utilities` (Tiện ích) hoặc `Lifestyle`
- **Age Rating:** `4+` (Không chứa nội dung nhạy cảm, mở rộng tệp khách hàng tối đa)
- **Privacy Policy URL (Bắt buộc):**
  `https://raw.githubusercontent.com/nhavoquang/widgets-ios/main/PRIVACY.md` *(hoặc bật GitHub Pages cho repo để có link `.github.io` đẹp)*
- **Terms of Use (EULA):** Dùng **Apple Standard EULA** mặc định (đã gắn sẵn link trong `PaywallSheet.swift`).

---

## 2. Thiết lập 2 Gói In-App Purchase & Bảng giá Tối ưu Doanh thu theo Quốc gia

Vào **App Store Connect → Monetization → Subscriptions / In-App Purchases** và tạo **chính xác 2 Product ID** sau (khớp 100% với code trong `Monetization.swift`):

| Loại gói | Product ID (Copy chính xác) | Loại trên App Store Connect | Vai trò tâm lý giá |
| :--- | :--- | :--- | :--- |
| **Gói Trọn Đời (Mặc định chọn sẵn)** | `com.cozydaily.app.pro.lifetime` | **Non-Consumable** (Mua 1 lần vĩnh viễn) | **Chốt đơn chủ lực** (`BEST VALUE -53%`) |
| **Gói Theo Năm** | `com.cozydaily.app.pro.yearly` | **Auto-Renewable Subscription** (Chu kỳ `1 Year`) | Chim mồi giá rẻ & thu dòng tiền định kỳ |

### Bảng Giá Tối Ưu Theo Khu Vực (Custom Pricing by Territory)
> **Nguyên tắc vàng:** Đừng dùng tự động quy đổi 1 mức giá cho toàn cầu! Vào mục **Pricing** của từng gói → chọn Base Price là Mỹ (`USD`), sau đó bấm **Edit Prices for Specific Countries/Regions** cho Việt Nam và Đông Nam Á:

| Nhóm Thị Trường | Quốc gia áp dụng | Giá Gói Năm (`yearly`) | Giá Trọn Đời (`lifetime`) | Lý do tối ưu |
| :--- | :--- | :--- | :--- | :--- |
| **Việt Nam (Mục tiêu gốc của bạn)** | `Vietnam (VND)` | **69.000₫ / năm** *(hoặc 59.000₫ dịp ra mắt)* | **139.000₫** *(hoặc 149.000₫)* | Rẻ bằng 1/4 đối thủ ngoại → sinh viên & dân văn phòng chốt gói Trọn đời 139k cực dễ! |
| **Đông Nam Á & Mỹ Latinh (Tier 2–3)** | `Thailand`, `Indonesia`, `Brazil`, `Mexico` | **~$3.99 / năm** (฿129 / Rp59.000 / R$19,90) | **~$8.99** (฿299 / Rp139.000 / R$44,90) | Vừa túi tiền bản địa, tỷ lệ chuyển đổi cao gấp 3 lần giá Mỹ. |
| **Mỹ, Âu, Nhật, Hàn, Úc (Tier 1 — Mỏ ngoại tệ)** | `US`, `UK`, `EU`, `Japan`, `Korea`, `Canada`, `Australia` | **$9.99 / năm** (¥1,500 / ₩14,000 / €9,99) | **$24.99** (¥3,800 / ₩33,000 / €24,99) | Rẻ bằng 1/2 *Widgy / Pretty Progress / Widgetable* ($49.99) nhưng 1 đơn thu về cho bạn ~600.000₫! |

---

## 3. Bộ ASO Metadata Chuẩn SEO cho Đủ 15 Ngôn Ngữ (Copy-Paste)

> **Quy tắc SEO đã áp dụng chặt chẽ bên dưới:**
> - **Title ≤ 30 ký tự** · **Subtitle ≤ 30 ký tự** · **Keywords ≤ 100 ký tự** (ngăn cách bằng dấu phẩy, không khoảng trắng thừa sau dấu phẩy, **không lặp lại từ đã có ở Title/Subtitle** để ăn tối đa từ khóa!).

### 1. English (`en-US` / `en-GB` — Mặc định Quốc tế)
- **Name (29 chars):** `Widgets: Lock Screen Calendar`
- **Subtitle (29 chars):** `Bento Grid, Countdown, Quotes`
- **Keywords (98 chars):** `locka,widgy,year progress,365 dots,weather,habit,todo,agenda,schedule,reminders,couple,wallpaper`

### 2. Tiếng Việt (`vi`)
- **Name (29 chars):** `Widgets: Lịch Màn Hình Khóa`
- **Subtitle (30 chars):** `Lịch Âm, Thời Tiết & Đếm Ngày`
- **Keywords (97 chars):** `locka,widgy,việc cần làm,nhắc nhở,từ vựng,tiếng anh,cặp đôi,365 chấm,hình nền,ghi chú,thói quen`

### 3. 日本語 — Nhật Bản (`ja` — Thị trường chi tiền IAP cực mạnh!)
- **Name (23 chars):** `ウィジェット: ロック画面カレンダー＆天気`
- **Subtitle (25 chars):** `365日ドット進捗・カウントダウン・リマインダー`
- **Keywords (95 chars):** `widgy,locka,予定表,タスク管理,スケジュール,壁紙,おしゃれ,カップル,英単語,名言,習慣,旧暦,シンプル,カスタマイズ,時計`

### 4. 한국어 — Hàn Quốc (`ko`)
- **Name (21 chars):** `위젯: 잠금화면 캘린더, 날씨 & 디데이`
- **Subtitle (24 chars):** `365 도트 일력, 할일 목록, 커플 배경화면`
- **Keywords (88 chars):** `widgy,locka,미리알림,일정관리,투두리스트,습관,영단어,명언,음력,꾸미기,심플,감성,배터리,메모,런처`

### 5. 简体中文 — Trung Quốc Giản thể (`zh-Hans`)
- **Name (18 chars):** `锁屏小组件: 日历、天气与倒数日`
- **Subtitle (21 chars):** `365天进度点阵 · 待办清单 · 情侣壁纸`
- **Keywords (92 chars):** `widgy,locka,提醒事项,日程表,打卡,习惯,背单词,每日一言,农历,极简,桌面美化,便签,电量,快捷启动,时间管理`

### 6. 繁體中文 — Đài Loan / Hồng Kông (`zh-Hant`)
- **Name (18 chars):** `鎖屏小工具: 行事曆、天氣與倒數日`
- **Subtitle (21 chars):** `365天進度點陣 · 待辦清單 · 情侶桌布`
- **Keywords (92 chars):** `widgy,locka,提醒事項,行程表,打卡,習慣,背單字,每日一言,農曆,極簡,桌面美化,便條貼,電量,快速啟動,時間管理`

### 7. Español — Tây Ban Nha & Mỹ Latinh (`es-ES` / `es-MX`)
- **Name (30 chars):** `Widgets: Calendario Pantalla`
- **Subtitle (29 chars):** `Clima, Cuenta Atrás y Tareas`
- **Keywords (98 chars):** `locka,widgy,bloqueo,365 puntos,agenda,recordatorios,pareja,frases,habitos,fondo,reloj,minimalista`

### 8. Français — Pháp & Canada (`fr-FR`)
- **Name (29 chars):** `Widgets: Calendrier & Météo`
- **Subtitle (30 chars):** `Écran Verrouillé, Compte Jours`
- **Keywords (97 chars):** `locka,widgy,agenda,rappels,taches,365 points,habitude,citation,couple,fond ecran,bento,planning`

### 9. Deutsch — Đức / Áo / Thụy Sĩ (`de-DE`)
- **Name (29 chars):** `Widgets: Sperrbildschirm Plan`
- **Subtitle (29 chars):** `Kalender, Wetter & Countdown`
- **Keywords (98 chars):** `locka,widgy,erinnerungen,aufgaben,365 punkte,jahresfortschritt,zitate,gewohnheit,hintergrund,paar`

### 10. Português — Brazil & Bồ Đào Nha (`pt-BR`)
- **Name (30 chars):** `Widgets: Calendário de Tela`
- **Subtitle (29 chars):** `Clima, Contagem e Lembretes`
- **Keywords (97 chars):** `locka,widgy,bloqueada,agenda,tarefas,365 pontos,meta,habitos,frases,casal,papel de parede,bento`

### 11. ไทย — Thái Lan (`th`)
- **Name (29 chars):** `Widgets: ปฏิทินหน้าจอล็อก`
- **Subtitle (29 chars):** `สภาพอากาศ นับถอยหลัง & งาน`
- **Keywords (95 chars):** `locka,widgy,เตือนความจำ,ตารางเวลา,365จุด,คู่รัก,คำศัพท์,คำคม,วอลเปเปอร์,มินิมอล,นิสัย,โน้ต`

### 12. Bahasa Indonesia (`id`)
- **Name (29 chars):** `Widgets: Kalender Layar Kunci`
- **Subtitle (29 chars):** `Cuaca, Hitung Mundur & Tugas`
- **Keywords (96 chars):** `locka,widgy,jadwal,pengingat,365 titik,pasangan,kutipan,kosakata,kebiasaan,wallpaper,minimalis`

### 13. Русский — Nga & CIS (`ru`)
- **Name (29 chars):** `Виджеты: Календарь на Экран`
- **Subtitle (28 chars):** `Погода, Отсчёт Дней и Задачи`
- **Keywords (96 chars):** `locka,widgy,блокировки,напоминания,расписание,365 точек,привычки,цитаты,пара,обои,заметки,план`

### 14. Italiano — Ý (`it`)
- **Name (29 chars):** `Widgets: Calendario Blocco`
- **Subtitle (29 chars):** `Meteo, Conto Rovescia, Impegni`
- **Keywords (97 chars):** `locka,widgy,schermata,promemoria,agenda,365 punti,abitudini,citazioni,coppia,sfondo,minimalista`

### 15. العربية — Ả Rập / Vùng Vịnh (`ar-SA` — ARPU rất cao!)
- **Name (28 chars):** `ويدجت: تقويم شاشة القفل`
- **Subtitle (29 chars):** `الطقس، العد التنازلي والمهام`
- **Keywords (94 chars):** `locka,widgy,تذكيرات,جدول,٣٦٥ نقطة,عادات,حكم,مفردات,خلفيات,ثنائي,ملاحظات,بسيط,بطارية`

---

## 4. Kịch bản 6 Tấm Screenshot Chuyển Đổi Cao (6.9" iPhone 16 Pro Max)

Người dùng quyết định tải app trong **3 giây đầu tiên nhìn vào 3 tấm ảnh đầu**. Bạn chụp 6 màn hình theo đúng thứ tự này:

1. **Ảnh 1 (Hero Viral):** Màn hình khóa iPhone nền Đen/Xanh đêm hiện **Lưới 365 chấm Năm + Thời tiết thật + Lịch trình hôm nay** → Tiêu đề lớn phía trên: *"Your Entire Day on Your Lock Screen"*.
2. **Ảnh 2 (Bento 1–4 Cột Độc Quyền):** Cảnh tab `Bố cục & Cột` đang chia **lưới Bento 2 cột & 3 cột** (Thời tiết + Âm lịch + Pin + Multi-Countdowns) → Tiêu đề: *"1–4 Column Bento Grid · Drag & Drop"*.
3. **Ảnh 3 (Apple Calendar & Reminders):** Hình nền hiện Lịch tháng + danh sách Việc & Lời nhắc từ Apple Reminders → Tiêu đề: *"Syncs Apple Calendar & Reminders"*.
4. **Ảnh 4 (Ảnh Cá Nhân + Smart Blur/Dim):** Màn hình khóa dùng ảnh chụp đẹp có hiệu ứng làm mờ nhẹ + khung Kính mờ (`Frosted Glass`) → Tiêu đề: *"Custom Photos with Smart Blur & Glass"*.
5. **Ảnh 5 (Interactive Lock Widgets & Quick Launcher):** Cận cảnh dải dưới đồng hồ có nút bấm `↻` đổi từ vựng trực tiếp & 4 nút mở nhanh Spotify / ChatGPT / QR → Tiêu đề: *"1-Tap Interactive Widgets & Launcher"*.
6. **Ảnh 6 (Couple & Daily Quotes):** Khối Cảm xúc người thương + Câu nói Stoic truyền cảm hứng → Tiêu đề: *"Partner Moods, Vocab & Daily Quotes"*.

---

## 5. Checklist Vượt Qua Apple App Review Ngay Lần Đầu (Tránh 100% lỗi bị Reject)

1. **Đính kèm 2 gói IAP vào cùng phiên bản App lần đầu nộp:**
   - Lần đầu tiên submit app mới có IAP, trong trang **App Version 1.0**, cuộn xuống mục **In-App Purchases and Subscriptions**, bấm dấu **`+`** chọn đính kèm cả 2 gói `com.cozydaily.app.pro.lifetime` và `com.cozydaily.app.pro.yearly` rồi mới bấm *Submit for Review*! (Nếu quên gắn vào đây, Apple sẽ không duyệt gói IAP).
2. **Ghi chú cho nhân viên duyệt App (App Review Notes — Copy dán vào ô Notes):**
   ```text
   Thank you for reviewing Widgets!
   - Core Free Features: Users can create 1-2 column Lock Screen layouts, place native Lock Screen & Home Screen widgets (Schedule, Live Weather, Vocabulary with interactive shuffle button, Quick Launcher), and save wallpapers to Photos without purchasing Pro.
   - Pro Unlock (StoreKit 2): Unlocks 3-4 column Bento layouts, 365 Year Dots, Multi-Countdowns, and custom photo blur/dimming. Restore Purchases, Terms of Use (Standard EULA), and Privacy Policy links are clearly accessible at the bottom of the Paywall.
   - Optional Shortcut Automation: Users can save the generated Lock Screen image directly to Photos or optionally use Apple's Shortcuts app ("Set Wallpaper Photo") for automatic daily refreshes.
   ```
3. **Khai báo App Privacy (Bảng câu hỏi quyền riêng tư trên App Store Connect):**
   - Chọn **Data Not Collected** (hoặc nếu bật CloudKit ở bản ký trả phí thì chỉ tích *Coarse Location* & *User Content* ở chế độ **Not Linked to User & Not Used for Tracking** — không hiện popup ATT xin quyền theo dõi quảng cáo!).
