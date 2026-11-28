---
name: cozy-session-workflow
description: >-
  Quy trình chia nhỏ task, quản lý hàng đợi công việc và bàn giao giữa các session mới
  cho dự án CozyDaily iOS nhằm tiết kiệm token và tránh phình context. Dùng khi bắt đầu
  một yêu cầu lớn, tiếp nối từ session trước, hoặc kết thúc một lát cắt công việc.
---

# Quy trình chia Session tiết kiệm Token (CozyDaily)

## Khi nào cần chia session?
Chia thành nhiều session độc lập khi yêu cầu có **≥ 2 hạng mục lớn** hoặc chạm **> 6 file** ở nhiều tab/module khác nhau (ví dụ: vừa làm Settings, vừa thiết kế lại Connect, vừa thêm Widget mới).

## Bước 1 — Khởi động session siêu nhẹ
1. Chỉ đọc `docs/ai/HANDOFF.md` và `docs/ai/TASK_QUEUE.md` (không quét toàn bộ repo).
2. Chọn **duy nhất 1 Slice** (`S-xx`) để làm trong session hiện tại.
3. Chỉ đọc đúng các file liệt kê trong mục `Target files` của Slice đó.

## Bước 2 — Thực thi gọn & gom lệnh
- Đọc song song các file trong 1 lượt.
- Chỉnh sửa song song các file độc lập.
- Không đọc lại file mình vừa sửa.
- Sau khi sửa xong: chạy `swift test --package-path Packages/CozyCore` (nếu sửa `CozyCore`) và `git status --short` + `git diff --stat`.

## Bước 3 — Cập nhật bàn giao (BẮT BUỘC cuối session)
1. Cập nhật trạng thái Slice vừa làm sang `[x]` trong `docs/ai/TASK_QUEUE.md`.
2. Ghi đè `docs/ai/HANDOFF.md` thật ngắn gọn (< 40 dòng) theo mẫu:
   - **Vừa hoàn thành:** tóm tắt 3–5 gạch đầu dòng + danh sách file đã sửa.
   - **Kiểm chứng:** kết quả `swift test` hoặc kiểm tra cú pháp.
   - **Prompt cho session mới (copy-paste):** 1 đoạn prompt ngắn chỉ rõ `Đọc docs/ai/HANDOFF.md và làm Slice S-xx trong docs/ai/TASK_QUEUE.md`.
3. Nhắc người dùng có thể mở **chat mới** và dán prompt bàn giao đó để context quay về ~0 token!
