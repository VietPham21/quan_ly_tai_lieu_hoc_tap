# BÁO CÁO KIỂM THỬ HỆ THỐNG (TEST REPORT)

**Dự án:** Ứng dụng Quản lý Tài liệu Học tập theo Kiến trúc Cashew  
**Thời gian thực hiện:** 03/10/2026  
**Môi trường kiểm thử:** Flutter 3.47.5, Dart 3.13.4, Drift ORM 2.35.1, In-Memory SQLite  
**Tổng số test cases:** 17  
**Kết quả:** 17 Passed / 0 Failed (Tỷ lệ đạt: 100%)  

---

## 1. MỤC TIÊU KIỂM THỬ (TEST OBJECTIVES)

1. **Kiểm thử tính đúng đắn của việc phân tầng kiến trúc (Layered Architecture)**: Đảm bảo Data Layer, Business Logic Layer và Presentation Layer hoạt động độc lập, không vi phạm nguyên tắc phụ thuộc lỏng lẻo.
2. **Kiểm thử Data Access & Persistence Layer (Drift / SQLite)**: Xác thực các câu lệnh CRUD (Insert, Select, Update, Delete) và các truy vấn lọc, tìm kiếm hoạt động chính xác trên SQLite.
3. **Kiểm thử luồng dữ liệu phản ứng (Reactive Data Streams - Cashew Pattern)**: Đảm bảo cơ chế `watch()` tự động phát sinh sự kiện cập nhật dữ liệu khi CSDL thay đổi (Single Source of Truth).
4. **Kiểm thử Business Logic & State Layer (Controller)**: Xác thực các quy tắc thẩm định nghiệp vụ (Validation), xử lý ngoại lệ và điều phối cập nhật trạng thái UI.
5. **Kiểm thử Presentation & Widget Layer**: Kiểm tra khả năng render giao diện, thanh tìm kiếm, bộ lọc danh mục, hộp thoại xác nhận xóa và các trạng thái rỗng (Empty State).

---

## 2. DANH SÁCH VÀ KẾT QUẢ CÁC TEST CASES CHI TIẾT

### BẢNG 1: KIỂM THỬ DATA ACCESS & PERSISTENCE LAYER (`test/data/documents_dao_test.dart`)

| STT | Tên Test Case | Layer | Đầu vào (Input) | Kết quả kỳ vọng (Expected) | Kết quả thực tế (Actual) | Trạng thái |
| :---: | :--- | :---: | :--- | :--- | :--- | :---: |
| **TC-01** | Thêm tài liệu mới vào SQLite (INSERT) | Data | `DocumentsCompanion` với tiêu đề "Giáo trình Kiến trúc Phần mềm", ID "test-doc-01", type PDF, size 2048 | Bản ghi được ghi thành công, lấy lại theo ID trả về đúng các thuộc tính | Bản ghi được ghi thành công vào CSDL in-memory, các trường khớp 100% | **PASS** |
| **TC-02** | Lấy toàn bộ danh sách tài liệu (SELECT ALL) | Data | Thêm 2 tài liệu ("Toán rời rạc", "Vật lý đại cương") | Hàm `getAllDocuments()` trả về danh sách có độ dài = 2 | Trả về đúng danh sách 2 tài liệu | **PASS** |
| **TC-03** | Cập nhật thông tin tài liệu (UPDATE) | Data | Thay đổi tiêu đề thành "Tiêu đề mới đã chỉnh sửa", môn học "Flutter Nâng cao", type PPTX, isFavorite = true | Hàm `updateDocument()` trả về true, query lại kiểm tra thấy thông tin mới | CSDL cập nhật thành công, dữ liệu mới được ghi nhận đầy đủ | **PASS** |
| **TC-04** | Xóa tài liệu khỏi CSDL (DELETE) | Data | Gọi `deleteDocument('doc-delete')` | Số dòng bị ảnh hưởng = 1, query lại bằng ID trả về null | Bản ghi bị xóa hoàn toàn khỏi CSDL, query trả về null | **PASS** |
| **TC-05** | Tìm kiếm theo từ khóa và bộ lọc (SEARCH & FILTER) | Data | Tìm query: "Flutter", subject: "Lập trình Di động", category: "Đề thi & Đáp án" | - "Flutter": trả về 1 tài liệu<br/>- "Lập trình Di động": trả về 2 tài liệu<br/>- Kết hợp: trả về đúng bản ghi s-3<br/>- Từ khóa lạ: trả về rỗng | Kết quả truy vấn SQL LIKE và WHERE đa điều kiện khớp chính xác | **PASS** |
| **TC-06** | Luồng phản ứng tự động (REACTIVE STREAM `watch()`) | Data + Reactive | Đăng ký `watchAllDocuments()`, sau đó insert 1 tài liệu, tiếp theo delete tài liệu | Stream tự động phát lại danh sách mới ngay khi INSERT và DELETE mà không cần gọi hàm fetch | Stream phát tuần tự: `[0 docs] -> [1 doc] -> [0 docs]` theo thời gian thực | **PASS** |

---

### BẢNG 2: KIỂM THỬ BUSINESS LOGIC & STATE LAYER (`test/logic/document_controller_test.dart`)

| STT | Tên Test Case | Layer | Đầu vào (Input) | Kết quả kỳ vọng (Expected) | Kết quả thực tế (Actual) | Trạng thái |
| :---: | :--- | :---: | :--- | :--- | :--- | :---: |
| **TC-07** | Thẩm định hợp lệ Tiêu đề (Validation Title) | Logic | `null`, chuỗi rỗng `""`, chuỗi cách `"   "`, chuỗi 1 ký tự `"A"` | Trả về thông báo lỗi yêu cầu tối thiểu 2 ký tự | Trả về thông báo lỗi tương ứng, chặn không cho submit | **PASS** |
| **TC-08** | Thẩm định Môn học, Danh mục, Tên file | Logic | Giá trị rỗng cho các trường bắt buộc | Trả về thông báo lỗi bắt buộc nhập | Trả về thông báo lỗi chính xác | **PASS** |
| **TC-09** | Thêm tài liệu qua Controller (Create Flow) | Logic | Thông tin hợp lệ: Tiêu đề "Giáo trình Cơ sở Dữ liệu", CSDL, PDF | Controller gọi Repository, trả về `true`, `successMessage` có giá trị, state cập nhật tài liệu mới | Tài liệu được tạo thành công, state tự động chứa tài liệu mới | **PASS** |
| **TC-10** | Chặn lưu tài liệu khi vi phạm Validation | Logic | Tiêu đề rỗng `""` | Hàm `createDocument()` trả về `false`, `errorMessage` chứa lỗi, danh sách rỗng | Không ghi CSDL, trả về lỗi thân thiện | **PASS** |
| **TC-11** | Sửa tài liệu qua Controller (Update Flow) | Logic | Cập nhật tên tài liệu thành "Tên đã cập nhật", file PPTX | Cập nhật thành công, state phản ánh bản ghi đã sửa | Bản ghi được cập nhật và giao diện nhận dữ liệu mới qua Stream | **PASS** |
| **TC-12** | Xóa tài liệu qua Controller (Delete Flow) | Logic | Gọi `deleteDocument(id)` | Xóa thành công, danh sách trong state giảm về 0, hiển thị successMessage | Tài liệu được xóa, state cập nhật tự động | **PASS** |
| **TC-13** | Quản lý trạng thái Tìm kiếm & Lọc (Filter State) | Logic | `setSearchQuery('Flutter')`, `setSelectedCategory('Slide bài giảng')`, `clearFilters()` | State chuyển đổi chính xác, Stream cập nhật danh sách tương ứng với bộ lọc | Bộ lọc và tìm kiếm hoạt động chính xác, reset bộ lọc hoàn hảo | **PASS** |

---

### BẢNG 3: KIỂM THỬ PRESENTATION & WIDGET LAYER (`test/presentation/document_widget_test.dart` & `test/widget_test.dart`)

| STT | Tên Test Case | Layer | Đầu vào (Input) | Kết quả kỳ vọng (Expected) | Kết quả thực tế (Actual) | Trạng thái |
| :---: | :--- | :---: | :--- | :--- | :--- | :---: |
| **TC-14** | Smoke test khởi chạy ứng dụng (`widget_test.dart`) | UI | Khởi chạy `MyApp` với Repository | Widget tree build thành công, tìm thấy AppBar "Tài Liệu Học Tập" | Ứng dụng khởi động mượt mà không có exception | **PASS** |
| **TC-15** | Render màn hình chính `DocumentListScreen` | UI | Nạp 2 tài liệu mẫu vào CSDL In-memory | Hiển thị AppBar, SearchBar, CategoryChips, và 2 DocumentCard | Tất cả widget hiển thị đầy đủ, đúng layout | **PASS** |
| **TC-16** | Tương tác tìm kiếm trên giao diện người dùng | UI | Nhập từ khóa "Flutter" vào ô TextField | Màn hình tự động ẩn tài liệu khác, chỉ hiển thị tài liệu chứa "Flutter" | Thẻ "Slide Kiến trúc Cashew" biến mất, thẻ "Giáo trình Flutter" hiển thị | **PASS** |
| **TC-17** | Xác nhận xóa an toàn qua `ConfirmationDialog` | UI | Kích hoạt dialog và bấm nút "Xác nhận xóa" | Dialog hiển thị cảnh báo, bấm "Xác nhận xóa" trả về `true` | Dialog đóng và trả về kết quả `true` xác nhận thao tác xóa | **PASS** |
| **TC-18** | Hiển thị `EmptyStateView` khi không có dữ liệu | UI | Render widget `EmptyStateView` với thông điệp tìm kiếm | Hiển thị icon kính lúp, tiêu đề, thông điệp hướng dẫn và nút bấm | Giao diện thân thiện, nút bấm hoạt động tốt | **PASS** |

---

## 3. KẾT LUẬN & ĐÁNH GIÁ CHẤT LƯỢNG

- **Tính cô lập của các tầng**:
  - Tầng Data Access được test độc lập qua In-Memory SQLite (`NativeDatabase.memory()`), kiểm chứng triệt để SQL syntax và ORM mapping.
  - Tầng Business Logic được test đầy đủ các kịch bản biên (Boundary conditions), Validation Guard và State mutation.
  - Tầng Presentation được test bằng Flutter Widget Tester, đảm bảo trải nghiệm tương tác thực tế của người dùng.
- **Tính phản xạ (Reactive Streams)**: Đã chứng minh được nguyên lý cốt lõi của Cashew: Mọi thao tác ghi dữ liệu vào SQLite đều phát sinh luồng dữ liệu tự động đồng bộ lên giao diện mà không cần refresh thủ công.
- Toàn bộ 17 test cases đều vượt qua thành công (**0 lỗi, 0 cảnh báo, 100% PASS**).
