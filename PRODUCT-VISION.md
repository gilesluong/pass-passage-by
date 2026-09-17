# Pass Passage By! — Tầm nhìn và kế hoạch dài hạn

Cập nhật 17/09/2026. Đây là định hướng sản phẩm của người dùng, không phải danh sách tính năng đã hoàn thành. Đọc cùng AGENTS.md, NEXT-STEPS.md và mục mới nhất của HANDOFF-ANTIGRAVITY.md.

## Tầm nhìn
PPB là không gian native trên macOS để viết, đọc sâu, sửa bài và trình bày tài liệu. Chất lượng thao tác, độ ổn định và sự nhất quán phải đạt mức một editor dùng hằng ngày như Notion/Ulysses; không đặt mục tiêu sao chép toàn bộ tính năng của họ. Lợi thế riêng là ngữ cảnh ngay bên lề, semantic zoom và cầu nối với agent mà người dùng đã có.

Người học viết và tra từ ngay trong bài; giáo viên chụp tài liệu, OCR, sửa bài và trình chiếu; người nghiên cứu gắn nguồn và giới hạn của lập luận; doanh nghiệp dùng tài liệu có cấu trúc cho SOP/onboarding; người viết văn bản hành chính bớt phải vật lộn với tab, lề và định dạng. Các nhóm này dùng chung editor đáng tin cậy trước khi có các bộ công cụ chuyên biệt.

## Những nguyên tắc không đánh đổi
- Văn bản là trung tâm. Nền trung tính, phân cấp typography rõ, sidebar và inspector có thể đóng. Học sự tiết chế từ ảnh ZCode người dùng cung cấp; Prism là hướng tham khảo chưa được kiểm chứng trực tiếp. Hình ảnh chỉ thuộc nội dung hoặc bìa tài liệu, không phủ sau vùng làm việc.
- Annotation là một ghi chú nhỏ bên lề: context, trạng thái, ý nhớ nhanh, giải nghĩa. Có thể chủ quan. Không bắt người dùng điền biểu mẫu hay tiêu đề.
- Comment là bình phẩm, phản hồi sâu, câu hỏi hoặc trao đổi với người/agent. Hiển thị ở inspector; tương lai có thread, reply, resolve và tác giả. Không nhân đôi thành card annotation.
- Dữ liệu local trước, export được, không khoá tài liệu. Không tự thay nội dung khi agent trả kết quả. Có review và khả năng hoàn tác.
- Dùng năng lực native: AppKit, từ điển đã cài, Vision OCR. Apple Intelligence chỉ khi khả dụng. Không yêu cầu tải mô hình lớn, không tải Llama/AI package trên hotspot.
- Cầu nối MCP/skill dùng các ứng dụng/agent người dùng đã đăng ký. Không yêu cầu API trả phí để dùng editor, không hứa mọi subscription hỗ trợ MCP hoặc có thể chuyển quota sang app khác. Chỉ dùng tích hợp mà host cho phép.
- Sparkle là đường cập nhật duy nhất của app đã cài. Không quảng bá production notarized khi chưa có Developer ID và notarization.

## Lộ trình theo điều kiện hoàn thành, không theo ngày hứa hẹn

### Giai đoạn 1 — Editor và mô hình ghi chú rõ ràng
Tách presentation annotation/comment, bảo toàn note cũ, không suy luận loại ghi chú chỉ bằng kind hoặc độ dài. Hoàn thiện thao tác tạo/sửa/xoá/chuyển vai trò. Inspector comment riêng; annotation gọn bên lề. Sau đó kiểm tra autosave/recovery, undo/redo, IME và Unicode, anchors khi sửa văn bản, find/replace, keyboard và accessibility. Hoàn thành khi bài dài, nhiều ghi chú, task toggle, resize và reopen không làm mất dữ liệu hoặc lệch neo.

### Giai đoạn 2 — Editor dùng hằng ngày
Hoàn thiện heading/list/link/code/table/image qua các lát nhỏ có test; clipboard, drag/drop, OCR review, thư viện/search/recents; PDF có annotation và MD+JSON roundtrip. Phân biệt bài trống với template. Settings gọn, dark/light tương phản, zoom path trực quan. Đánh giá chất lượng bằng tác vụ thật của giáo viên/học sinh, không chỉ build thành công.

### Giai đoạn 3 — Agent workspace
Cài skill/MCP dễ hiểu, mô tả quyền và phạm vi tài liệu. Agent đọc snapshot được chia sẻ, trả bản đề xuất có provenance vào Inbox; người dùng duyệt từng thay đổi. Bảo toàn ID/anchor, kiểm tra schema, không import đè. Xác minh end-to-end từng host (Antigravity, ZCode và host hỗ trợ khác), ghi rõ hỗ trợ thực tế. Thêm comment agent và phản hồi theo thread sau khi có hợp đồng dữ liệu phiên bản mới hoặc sidecar portable.

### Giai đoạn 4 — Cộng tác
Local thread trước; shared document sau. Cần identity, quyền đọc/sửa, đồng bộ, xử lý conflict/offline, lịch sử và phục hồi. Reply local không đồng nghĩa collaboration online. Không tạo tài khoản/backend chỉ để mô phỏng tính năng chưa có. Quyết định hạ tầng và chi phí trước khi triển khai đồng bộ.

### Giai đoạn 5 — Tài liệu chuyên biệt và trình bày
IELTS chất lượng thay vì số lượng; research có giấy phép/nguồn; rhetorical analysis; văn bản hành chính; SOP/onboarding. Template không phải bảo chứng pháp lý. Kiểm tra quy định hiện hành trước nội dung pháp lý. Presentation/Stage Manager/fullscreen và recording phải giữ chữ, anchors, tương phản rõ. Thêm tag presets và tài liệu tương tác sau khi editor ổn định.

### Giai đoạn 6 — Showcase và kinh doanh
Homepage có khu khám phá kiểu Apple TV, carousel bài sửa nổi bật và các bộ sưu tập; workspace viết vẫn yên tĩnh. Giáo viên/trung tâm có uy tín có thể đăng hoặc ghim bài sửa để thu hút học viên khi đủ người dùng. Chưa cần hồ sơ trung tâm chi tiết. Bài tài trợ phải được gắn nhãn, có quyền sử dụng và tác giả thật; không bịa danh tiếng/chứng chỉ, không trộn tài trợ với đánh giá học thuật. Xác thực publisher, moderation, quản lý quyền và đo hiệu quả trước khi thu tiền. Không đặt paywall cho các công cụ đọc/tra từ cốt lõi chỉ để bán thêm một gói AI.

### Giai đoạn 7 — Sẵn sàng phát hành rộng
Developer ID/notarization, Sparkle ký và kiểm tra rollback, recovery dữ liệu, export/migration test, accessibility, hiệu năng tài liệu dài, privacy/ToS phù hợp chức năng thực tế, kênh phản hồi và xử lý sự cố. Không có telemetry nội dung mặc định. Mọi release có test, ghi rõ giới hạn và bàn giao cho agent kế tiếp.

## Tiêu chí theo dõi
Không đặt KPI giả khi chưa có đo đạc. Thiết lập baseline cho độ trễ gõ/cuộn, thời gian mở tài liệu dài, lỗi save/recovery, tỷ lệ import/export thành công và số bước tạo một note. Kiểm thử người dùng: viết bài trống; chụp/OCR/sửa; ghi chú nhanh; nhận xét dài; tra từ; trình chiếu; nhận sửa từ agent; xuất và mở lại. Không đổi độ tin cậy lấy thêm màn hình.

## Thứ tự hiện tại
Thực hiện giai đoạn 1 theo NEXT-STEPS.md. Tag presets, Loom polish, thêm template và mở rộng monetization không được chen trước lỗi dữ liệu/anchor hoặc sự nhập nhằng comment–annotation. Cập nhật bàn giao sau mỗi lát triển khai: commit, test thực chạy, hạn chế, việc kế tiếp, không chỉ mô tả ý định.
