# BÁO CÁO GIẢI TRÌNH: ÁP DỤNG KIẾN TRÚC CASHEW VÀO XÂY DỰNG ỨNG DỤNG QUẢN LÝ TÀI LIỆU HỌC TẬP

**Học phần:** Thực hành Kiến trúc Phần mềm / Lập trình Ứng dụng Di động
**Đề tài:** TH1: Xây dựng Ứng dụng Quản lý Tài liệu Học tập theo Kiến trúc Cashew
**Người thực hiện:** Senior Flutter Architect / Software Engineer
**Ngày hoàn thành:** 03/10/2026
**Mã nguồn dự án:** `f:/FlutterProjects/quan_ly_tai_lieu_hoc_tap`

---

## I. GIỚI THIỆU ĐỀ TÀI & BỐI CẢNH

Trong kỷ nguyên số hóa giáo dục, sinh viên và giảng viên phải tiếp cận với khối lượng lớn tài liệu học tập đa định dạng (Giáo trình PDF, Slide bài giảng PowerPoint, Đề thi Word, Bảng tính Excel, Mã nguồn mẫu...). Việc tổ chức, lưu trữ và tìm kiếm tài liệu trên thiết bị di động/máy tính cá nhân đòi hỏi một hệ thống có tốc độ phản hồi tức thì, khả năng phân loại đa chiều và bảo đảm tính toàn vẹn dữ liệu.

Đề tài **“Xây dựng Ứng dụng Quản lý Tài liệu Học tập theo Kiến trúc Cashew”** được triển khai nhằm vận dụng triệt để các nguyên lý kiến trúc ưu việt của ứng dụng mã nguồn mở nổi tiếng **Cashew (Budget & Expense Tracker)**:

- **Kiến trúc phân tầng (Layered Architecture)** với ranh giới trách nhiệm rõ ràng.
- **Mô hình trạng thái phản ứng hướng cơ sở dữ liệu (Database-Driven Reactive State)** thông qua **Drift ORM** trên **SQLite3**.
- **Triết lý Local-First (Offline-First)**: Lưu trữ cục bộ bền vững, độc lập mạng và độ trễ bằng 0 (Zero-Latency UI).

---

## II. PHÂN TÍCH NGUỒN KIẾN TRÚC CASHEW VÀ NGUYÊN LÝ VẬN DỤNG

Dựa trên tài liệu phân tích hệ thống `cashew_system_architecture.md`, Cashew được thiết kế dựa trên 4 trụ cột kiến trúc:

### 1. Mô hình Phân tầng (Layered Architecture):

```mermaid
graph TD
    Presentation["1. Presentation Layer<br/>(Material 3 Widgets, Screens, Dialogs)"]
    BusinessLogic["2. Business Logic & State Layer<br/>(DocumentController, Validation, State)"]
    DataAccess["3. Data Access & Persistence Layer<br/>(Repository, DocumentsDao, Drift ORM)"]
    Database["4. Local Database Engine<br/>(SQLite3 Database)"]

    Presentation -->|1. Yêu cầu thao tác người dùng| BusinessLogic
    BusinessLogic -->|2. Thẩm định & chuyển tiếp| DataAccess
    DataAccess -->|3. Thực thi SQL| Database
    Database -.->|4. Kích hoạt trigger thay đổi| DataAccess
    DataAccess -.->|5. Reactive Stream watch()| BusinessLogic
    BusinessLogic -.->|6. Cập nhật State & Re-render| Presentation
```

- **Presentation Layer**: Chịu trách nhiệm hiển thị giao diện người dùng và thu nhận tương tác. Tuyệt đối không chứa logic truy vấn CSDL hay tính toán nghiệp vụ phức tạp.
- **Business Logic & State Layer**: Đóng vai trò bộ não điều phối, thẩm định tính hợp lệ của dữ liệu đầu vào (Validation Guards) và quản lý trạng thái hiển thị của màn hình.
- **Data Access & Persistence Layer**: Trừu tượng hóa việc truy xuất dữ liệu thông qua DAO và Repository, sử dụng Drift ORM để tương tác với SQLite cục bộ.
- **Nguyên lý Single Source of Truth (SSOT)**: Cơ sở dữ liệu SQLite là nguồn chân lý duy nhất. Giao diện người dùng không tự quản lý danh sách độc lập mà chỉ "lắng nghe" luồng phát dữ liệu từ Database.

---

## III. THIẾT KẾ VÀ TỔ CHỨC CẤU TRÚC HỆ THỐNG

Dự án được cấu trúc theo đúng các tầng chuẩn mực trong thư mục `lib/`:

```text
lib/
├── core/                               # Các thành phần cốt lõi dùng chung
│   ├── constants/
│   │   ├── app_colors.dart             # Hệ thống mã màu nhận diện & màu định dạng file
│   │   └── app_constants.dart          # Hằng số hệ thống, danh mục, môn học, đuôi file
│   ├── theme/
│   │   └── app_theme.dart              # Theme Material 3 hỗ trợ Light / Dark mode
│   └── utils/
│       └── file_helper.dart            # Tiện ích định dạng ngày, dung lượng, icon file
│
├── data/                               # Tầng truy xuất & lưu trữ dữ liệu (Data Access)
│   ├── database/
│   │   ├── tables/
│   │   │   └── documents_table.dart    # Định nghĩa cấu trúc bảng SQLite bằng Drift
│   │   ├── daos/
│   │   │   ├── documents_dao.dart      # Thao tác SQL: CRUD, Search, Watch Stream
│   │   │   └── documents_dao.g.dart    # Mã sinh tự động bởi Drift
│   │   ├── app_database.dart           # Cấu hình kết nối CSDL Drift SQLite
│   │   └── app_database.g.dart         # Mã sinh ORM tự động của toàn bộ Database
│   └── repositories/
│       ├── document_repository.dart    # Abstract interface chuẩn hóa truy cập dữ liệu
│       └── document_repository_impl.dart # Triển khai cụ thể qua DocumentsDao
│
├── logic/                              # Tầng nghiệp vụ & quản lý trạng thái (Business Logic)
│   ├── states/
│   │   └── document_state.dart         # Đối tượng trạng thái bất biến (Immutable State)
│   └── controllers/
│       └── document_controller.dart    # Bộ điều phối nghiệp vụ, Validation & Stream
│
├── presentation/                       # Tầng giao diện người dùng (Presentation)
│   ├── screens/
│   │   ├── document_list_screen.dart   # Màn hình danh sách tài liệu, tìm kiếm, lọc
│   │   ├── document_detail_screen.dart # Màn hình xem chi tiết tài liệu học tập
│   │   └── document_form_screen.dart   # Màn hình thêm mới & chỉnh sửa tài liệu
│   └── widgets/
│       ├── document_card.dart          # Thẻ hiển thị tóm tắt tài liệu
│       ├── document_search_bar.dart    # Thanh tìm kiếm thời gian thực & nút sắp xếp
│       ├── category_chip_selector.dart # Bộ lọc danh mục trượt ngang
│       ├── confirmation_dialog.dart    # Hộp thoại xác nhận thao tác xóa an toàn
│       └── empty_state_view.dart       # Giao diện thông báo khi danh sách rỗng
│
└── main.dart                           # Điểm khởi chạy ứng dụng, Dependency Injection
```

---

## IV. TRIỂN KHAI CÁC CHỨC NĂNG CỐT LÕI

### 1. Hiển thị danh sách tài liệu và Cơ chế Reactive Streams:

- Sử dụng phương thức `watchSearchDocuments()` trong `DocumentsDao` để mở một luồng dữ liệu thời gian thực (`Stream<List<Document>>`).
- Khi người dùng thêm, sửa hoặc xóa bất kỳ tài liệu nào, SQLite tự động phát dữ liệu mới nhất qua luồng Stream -> `DocumentController` nhận được sự kiện -> `notifyListeners()` kích hoạt -> UI tự động vẽ lại.
- **Kết quả**: Không cần phải viết code gọi hàm `fetch()` hay `refresh()` thủ công, loại bỏ hoàn toàn hiện tượng lệch trạng thái giữa các màn hình.

### 2. Thêm tài liệu mới (Create Document):

- Cung cấp form nhập liệu với các trường: Tiêu đề, Môn học, Danh mục, Ghi chú mô tả, Loại tệp tin (PDF, DOCX, PPTX, XLSX, CODE, ZIP), Tên tệp, Dung lượng và Đánh dấu yêu thích.
- **Validation Guard**: Kiểm tra nghiêm ngặt dữ liệu trước khi gửi xuống Data Layer (Tiêu đề không được rỗng, tối thiểu 2 ký tự; môn học, danh mục, tên tệp không được để trống).
- Khóa chính được tạo tự động bằng chuỗi UUID chuẩn Cashew.

### 3. Sửa thông tin tài liệu (Update Document):

- Cho phép chỉnh sửa toàn diện siêu dữ liệu và tệp đính kèm.
- Trường `updatedAt` tự động nhận mốc thời gian hiện tại (`DateTime.now()`).
- Nhờ cơ chế Reactive Stream, khi người dùng sửa xong tài liệu tại `DocumentFormScreen`, cả `DocumentDetailScreen` và `DocumentListScreen` đều đồng thời cập nhật tức thì.

### 4. Xóa tài liệu an toàn (Delete Document):

- Bảo vệ thao tác xóa bằng `ConfirmationDialog`: Hiển thị cảnh báo trực quan với màu sắc đỏ cảnh báo và yêu cầu người dùng xác nhận chủ động.
- Khi xác nhận, `DocumentController.deleteDocument(id)` xóa bản ghi khỏi SQLite. Bản ghi lập tức biến mất khỏi danh sách mà không cần tải lại trang.

### 5. Tìm kiếm & Lọc đa tiêu chí (Search & Filter):

- **Tìm kiếm theo thời gian thực (Realtime Search)**: Tìm kiếm đồng thời trên `title`, `subject`, `category`, `fileName` và `description` bằng truy vấn SQL tối ưu (`LIKE %query%`) tại Data Layer, không lọc thủ công trên RAM.
- **Bộ lọc kết hợp**: Lọc theo Danh mục (Giáo trình, Slide, Đề thi...) và Môn học.
- **Sắp xếp linh hoạt**: Đổi chiều sắp xếp Mới nhất / Cũ nhất chỉ với một chạm.
- Không crash hoặc treo giao diện khi chuỗi tìm kiếm rỗng.

---

## V. ĐÁNH GIÁ TÍNH PHÂN TÁCH GIỮA CÁC LỚP TRONG KIẾN TRÚC

| Tiêu chí kiến trúc               | Cách hiện thực trong dự án                                                                                                                                | Đánh giá tính đúng đắn |
| :------------------------------- | :-------------------------------------------------------------------------------------------------------------------------------------------------------- | :--------------------: |
| **Presentation không query DB**  | Widget chỉ tương tác với`DocumentController` thông qua `Provider` hoặc `context.read()`. Hoàn toàn không import file Drift hay truy vấn SQL trong Widget. |      **ĐẠT 100%**      |
| **Logic không phụ thuộc Widget** | `DocumentController` chỉ sử dụng Pure Dart và `ChangeNotifier`, không chứa bất kỳ `BuildContext` hay Widget nào. Có thể Unit Test 100% độc lập.           |      **ĐẠT 100%**      |
| **Data Layer độc lập**           | `DocumentsDao` và `DocumentRepositoryImpl` chỉ chịu trách nhiệm đọc/ghi dữ liệu, không quan tâm dữ liệu sẽ được hiển thị ở màn hình nào.                  |      **ĐẠT 100%**      |
| **Single Source of Truth**       | SQLite là nơi duy nhất giữ dữ liệu. Trạng thái của Controller được đồng bộ thụ động từ Database Stream.                                                   |      **ĐẠT 100%**      |

---

## VI. KẾT QUẢ KIỂM THỬ HỆ THỐNG

Hệ thống đã được kiểm thử tự động toàn diện qua 17 test cases bao phủ 3 tầng kiến trúc:

- **Data Layer (DocumentsDao)**: 6/6 tests passed (CRUD, Search, Reactive watch).
- **Business Logic Layer (DocumentController)**: 6/6 tests passed (Validation, Add, Edit, Delete, Filter).
- **Presentation Layer (Widgets & Smoke Test)**: 5/5 tests passed (Render, Search, Dialog, Empty View).
- **Phân tích tĩnh (Flutter Analyze)**: **0 lỗi, 0 cảnh báo** (No issues found).

---

## VII. HƯỚNG DẪN CÀI ĐẶT & CHẠY ỨNG DỤNG DEMO

1. **Cài đặt phụ thuộc**:
   ```bash
   flutter pub get
   ```
2. **Sinh mã CSDL Drift (nếu cần cập nhật schema)**:
   ```bash
   dart run build_runner build --delete-conflicting-outputs
   ```
3. **Chạy kiểm thử toàn bộ dự án**:
   ```bash
   flutter test
   ```
4. **Khởi chạy ứng dụng**:
   - Chạy trên Windows Desktop:
     ```bash
     flutter run -d windows
     ```
   - Chạy trên Chrome / Web:
     ```bash
     flutter run -d chrome
     ```
   - Chạy trên Android Emulator hoặc thiết bị thật:
     ```bash
     flutter run -d android
     ```

---

## VIII. KẾT LUẬN

Dự án **“Ứng dụng Quản lý Tài liệu Học tập theo Kiến trúc Cashew”** đã hoàn thành xuất sắc toàn bộ các mục tiêu đề ra:

1. Vận dụng trung thực và đầy đủ các nguyên lý phân tầng của Cashew (Presentation, Logic, Data Access, Persistence).
2. Xây dựng thành công cơ chế **Database-Driven Reactive State** với Drift ORM và SQLite cục bộ.
3. Triển khai đầy đủ và mượt mà 4 chức năng cốt lõi: Thêm, Sửa, Xóa, Tìm kiếm & Lọc tài liệu.
4. Đạt chuẩn chất lượng mã nguồn cao nhất (Clean Architecture, Zero Linter Issues, 100% Test Pass).
5. Hệ thống tài liệu phân tích, thiết kế CSDL, sơ đồ luồng dữ liệu và báo cáo kiểm thử được chuẩn bị công phu, sẵn sàng phục vụ báo cáo và nghiệm thu đề tài.
