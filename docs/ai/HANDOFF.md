# CozyDaily — Session Handoff

> Cập nhật cuối session. Khi mở **chat mới** để tiết kiệm token, chỉ cần đọc file này + `docs/ai/DESIGN_SPEC.md` + đúng các file của Slice kế tiếp trong `docs/ai/TASK_QUEUE.md`.

## Vừa hoàn thành (S-03: Kết nối 2 người Couple & 3–8 người Squad + Thiết kế lại ConnectView)
1. **Ép giới hạn thành viên & đồng bộ CloudKit chuẩn chỉnh:**
   - `Packages/CozyCore/Sources/CozyCore/Sync/SyncMerge.swift`: giới hạn cứng thành viên theo `space.kind.memberLimit.upperBound` (2 cho Couple, 8 cho Squad) trong `SpaceMerge.merge` + thêm helper `SpaceMerge.canAcceptMember`.
   - `Shared/Cloud/CloudSync.swift`: thêm `CloudSyncError.spaceFull`, tự kiểm tra giới hạn khi `accept(_ metadata:)` và lưu `shareURL` về `SharedSpace` để sao chép link mời 1 chạm.
   - `CozyDaily/App/AppModel.swift`: thêm `sendMessage(_:in:)`, `renameSpace(_:to:)`, và `createLocalSpace(kind:name:)`.
   - `Packages/CozyCore/Tests/CozyCoreTests/SyncAndAssetTests.swift`: thêm unit test `testSpaceMergeEnforcesCoupleAndSquadMemberLimits`.
2. **Thiết kế lại toàn bộ `CozyDaily/Features/Connect/ConnectView.swift` (Huddle + 3D Plush Cute):**
   - Thanh chuyển pastel `Hai đứa (X/2)` / `Hội bạn (X/8)`, thẻ trạng thái live nền tối kiểu Huddle kèm nút nhịp tim động (`CozyAnimatedIcon`), thẻ thành viên squircle 3D Plush, hiệu ứng Quick Ping tim bay, thả sticker nảy spring, ô gửi lời nhắn nhanh trực tiếp, thẻ quản lý quyền vào phòng + sao chép link mời 1 chạm, và đổi tên / tạo không gian.
3. **Lưu bản thiết kế đã duyệt:**
   - Đã chốt và lưu ngắn gọn tại `docs/ai/DESIGN_SPEC.md` + cập nhật lộ trình `S-04`, `S-05`, `S-06` trong `docs/ai/TASK_QUEUE.md`.

## Kiểm chứng
- `swift test --package-path Packages/CozyCore`: **38/38 PASS** (gồm test mới `testSpaceMergeEnforcesCoupleAndSquadMemberLimits`).
- Lưu ý: SwiftUI iOS & WidgetKit target sẽ được kiểm chứng biên dịch tự động trên GitHub Actions (`.github/workflows/ios.yml`).

## Prompt mở session mới (copy-paste để làm tiếp Slice S-04 không đốt token)
```text
Đọc docs/ai/HANDOFF.md và docs/ai/DESIGN_SPEC.md, sau đó thực hiện duy nhất Slice S-04 trong docs/ai/TASK_QUEUE.md (Bộ Home Screen Widgets kiểu CatDays + Lưới Sticker Tháng 26 Grids + Chuỗi 7 ngày T2–CN + Floating Pill Tab Bar). Chỉ đọc đúng Target files của S-04, chạy swift test và cập nhật TASK_QUEUE.md + HANDOFF.md khi xong.
```
