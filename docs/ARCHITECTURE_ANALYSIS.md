# PHÂN TÍCH KIẾN TRÚC HIỆN TẠI VÀ ĐỊNH HƯỚNG CHUYỂN ĐỔI THEO KIẾN TRÚC CASHEW

**Dự án:** Ứng dụng Quản lý Tài liệu Học tập  
**Mã dự án:** TH1 - Quản lý Tài liệu Học tập theo Kiến trúc Cashew  
**Người thực hiện:** Senior Flutter Architect / Software Engineer  
**Ngày lập:** 03/10/2026  
**Tài liệu tham chiếu:** `cashew_system_architecture.md` (Cashew System Architecture)

---

## A. TỔNG QUAN KIẾN TRÚC HIỆN TẠI (AS-IS STATE)

Khảo sát mã nguồn thực tế tại workspace (`quan_ly_tai_lieu_hoc_tap`):
1. **Trạng thái khởi tạo**: Dự án được tạo mới từ mẫu mặc định của Flutter (`flutter create`).
2. **Cấu trúc thư mục hiện tại**:
   ```text
   quan_ly_tai_lieu_hoc_tap/
   ├── lib/
   │   └── main.dart             # Toàn bộ mã nguồn ứng dụng nằm trong 1 file (Counter App)
   ├── test/
   │   └── widget_test.dart      # Test mẫu kiểm tra nút bấm tăng counter
   ├── pubspec.yaml              # Cấu hình phụ thuộc cơ bản
   └── analysis_options.yaml     # Bộ quy tắc lint của Flutter
   ```
3. **Mã nguồn trong `lib/main.dart`**:
   - Chứa lớp `MyApp` (StatelessWidget) và `MyHomePage` (StatefulWidget).
   - Logic tăng số đếm (`_counter++`) gắn liền trực tiếp với trạng thái giao diện qua `setState()`.
   - Không có cấu trúc phân tầng, không có cơ chế lưu trữ bền vững (Persistence), không có ORM, không có kiến trúc Reactive Data Stream.

---

## B. PRESENTATION LAYER HIỆN TẠI

- **Các Screen**: Chỉ có duy nhất 1 màn hình `MyHomePage` (hiển thị văn bản đếm số lần bấm và nút FloatingActionButton `+`).
- **Widget**: Sử dụng trực tiếp các Flutter primitive widgets (`Scaffold`, `AppBar`, `Center`, `Column`, `Text`, `FloatingActionButton`). Chưa có hệ thống Design Tokens, Custom Components, Empty State, Error State hay Dialog tái sử dụng.
- **Navigation**: Ứng dụng chỉ có 1 Route đơn lập tải thẳng từ `MaterialApp(home: ...)`. Hoàn toàn chưa có hệ thống điều hướng thích ứng (Adaptive Navigation Framework) hay Route chuyển màn hình (List -> Detail -> Form).
- **Theme/UI Component**: Sử dụng `ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple))`. Chưa thiết lập hệ thống màu sắc nhận diện đặc thù cho tài liệu, chưa tối ưu bảng màu cho chế độ Sáng/Tối (Light/Dark mode) và độ tương phản trợ năng.

---

## C. BUSINESS LOGIC & STATE LAYER HIỆN TẠI

- **State**: Trạng thái cục bộ duy nhất là biến nguyên thủy `int _counter = 0` được quản lý bằng `StatefulWidget.setState()`.
- **Controller / Provider / Service**: Hoàn toàn vắng bóng. Không có lớp trung gian nào đóng vai trò tiếp nhận tương tác người dùng, thẩm định quy tắc nghiệp vụ (Validation) và điều phối dữ liệu.
- **Business Logic**: Logic nghiệp vụ bị gộp cứng vào sự kiện nhấn nút `_incrementCounter()` ngay trong Widget State.
- **Reactive State**: Không tồn tại. Giao diện phải gọi hàm `setState()` thủ công để vẽ lại UI; hoàn toàn không có luồng dữ liệu phản ứng (Reactive Stream) tự động đồng bộ khi nguồn dữ liệu bên dưới thay đổi.

---

## D. DATA ACCESS & PERSISTENCE LAYER HIỆN TẠI

- **Drift ORM / SQLite**: Chưa được tích hợp trong mã nguồn ban đầu.
- **Database / Table**: Không có bảng CSDL nào tồn tại.
- **DAO (Data Access Object)**: Chưa có.
- **Repository**: Chưa có lớp trừu tượng hóa truy cập dữ liệu.
- **Độ bền vững (Persistence)**: Toàn bộ dữ liệu nằm trên bộ nhớ RAM (In-Memory cục bộ trong vòng đời Widget State). Khi người dùng khởi động lại ứng dụng hoặc xoay màn hình (Hot Restart), dữ liệu sẽ mất hoàn toàn về giá trị ban đầu (`_counter = 0`).

---

## E. REACTIVE DATA FLOW HIỆN TẠI

- **Luồng hiện tại**:
  ```mermaid
  flowchart LR
      User[Người dùng nhấn nút] --> Widget[MyHomePage Widget]
      Widget --> SetState[Gọi setState]
      SetState --> Rerender[Build lại Tree hiển thị counter mới]
  ```
- **Hạn chế**:
  - Không có Data Layer và Database.
  - Không có nguyên lý **Single Source of Truth** (SSOT).
  - Không có Reactive Stream để thông báo thay đổi cho nhiều màn hình cùng lúc.

---

## F. DEPENDENCY GIỮA CÁC LAYER HIỆN TẠI

- Hiện tại không có sự phân tầng: Presentation và Logic bị trộn lẫn vào một khối duy nhất (`_MyHomePageState`).
- Mức độ thắt chặt liên kết (Tight Coupling) là 100%: không thể tái sử dụng logic đếm số ở bất kỳ màn hình nào khác mà không sao chép lại mã nguồn; không thể viết Unit Test cho logic mà không cần khởi tạo Widget Test.

---

## G. NHỮNG ĐIỂM PHÙ HỢP VỚI NGUYÊN LÝ CASHEW

1. Sử dụng nền tảng **Flutter SDK & Material Design**: Sẵn sàng để mở rộng UI đa nền tảng (Android, iOS, Windows, macOS, Web).
2. Mã nguồn sạch, không chứa các thư viện xung đột hay kiến trúc lỗi thời cần dọn dẹp phức tạp.

---

## H. NHỮNG ĐIỂM CHƯA PHÙ HỢP VỚI KIẾN TRÚC CASHEW

Đối chiếu với tài liệu `cashew_system_architecture.md`:

| Tiêu chuẩn Kiến trúc Cashew | Trạng thái Dự án Hiện tại | Đánh giá / Khoảng cách |
| :--- | :--- | :--- |
| **Layered Architecture (4 tầng)** | 1 file duy nhất `lib/main.dart` | Vi phạm hoàn toàn nguyên lý phân tách trách nhiệm (Separation of Concerns). |
| **Local-First & SQLite (Drift ORM)** | Không có CSDL, chỉ có RAM state | Thiếu tầng lưu trữ cục bộ bền vững. |
| **Reactive Data Streams (`watch()`)** | Gọi `setState()` thủ công | Thiếu cơ chế phản xạ dữ liệu tự động từ Database lên UI. |
| **Single Source of Truth (SSOT)** | Biến tạm thời trong Widget | Không có nguồn dữ liệu chuẩn mực. |
| **DAO & Modular Database** | Không có DAO / Table | Cần triển khai cấu trúc Table và DAO độc lập theo khuyến nghị tại Mục 8 của tài liệu Cashew. |
| **Validation & Controller Layer** | Logic đặt trong hàm callback của nút | Thiếu lớp kiểm tra hợp lệ dữ liệu và điều phối nghiệp vụ. |
| **Error Handling & UX States** | Không có xử lý lỗi, không có trạng thái rỗng | Thiếu Empty State, Loading State, Error SnackBar và Confirmation Dialog. |

---

## I. KẾ HOẠCH CHUYỂN ĐỔI: XÂY DỰNG MODULE QUẢN LÝ TÀI LIỆU HỌC TẬP

Để đáp ứng 100% chuẩn mực kiến trúc Cashew và yêu cầu của bài tập lớn, chúng tôi tiến hành tái cấu trúc toàn diện hệ thống:

```mermaid
graph TD
    subgraph Presentation_Layer ["1. Presentation Layer (Giao diện người dùng)"]
        DocumentListScreen["DocumentListScreen (Danh sách, Tìm kiếm, Lọc)"]
        DocumentDetailScreen["DocumentDetailScreen (Xem chi tiết, Thao tác)"]
        DocumentFormScreen["DocumentFormScreen (Thêm / Sửa tài liệu)"]
        Widgets["Widgets (DocumentCard, SearchBar, CategoryFilter, ConfirmDialog)"]
    end

    subgraph Logic_Layer ["2. Business Logic & State Management"]
        DocController["DocumentController (ChangeNotifier & Stream Coordinator)"]
        DocState["DocumentState (Trạng thái UI, SearchFilter, FormValidation)"]
    end

    subgraph Data_Layer ["3. Data Access & Persistence (Local-First Drift/SQLite)"]
        DocRepository["DocumentRepository (Interface & Implementation)"]
        DocDao["DocumentsDao (Drift DAO: CRUD, Search, Watch)"]
        DocTable["Documents Table (SQLite Schema)"]
        AppDB["AppDatabase (Drift Database Singleton / Provider)"]
    end

    Presentation_Layer -->|Tương tác người dùng| Logic_Layer
    Logic_Layer -->|Gọi thao tác CRUD| Data_Layer
    Data_Layer -->|Ghi dữ liệu SQLite| AppDB
    AppDB -.->|Phát luồng dữ liệu thay đổi qua watch()| DocDao
    DocDao -.->|Reactive Stream| Logic_Layer
    Logic_Layer -.->|Cập nhật State tự động| Presentation_Layer
```

### Các bước cụ thể:
1. **Bổ sung phụ thuộc chuẩn Cashew**:
   - `drift`, `sqlite3_flutter_libs`, `path_provider`, `path` (Data Persistence).
   - `provider` (Quản lý trạng thái và tiêm phụ thuộc DI chuẩn Cashew).
   - `uuid` (Tạo khóa chính ngẫu nhiên dạng chuỗi `documentPk` chuẩn Cashew).
   - `intl` (Định dạng ngày tháng và thời gian).
   - `drift_dev`, `build_runner` (Dev dependencies cho code generation).
2. **Xây dựng Data Layer**:
   - Định nghĩa bảng `Documents` trong `lib/data/database/tables/documents_table.dart`.
   - Xây dựng `DocumentsDao` trong `lib/data/database/daos/documents_dao.dart` với các phương thức Reactive Query (`watchAllDocuments`, `watchSearchDocuments`) và CRUD (`insertDocument`, `updateDocument`, `deleteDocument`).
   - Cấu hình `AppDatabase` kết nối SQLite hỗ trợ nền tảng Desktop/Mobile.
   - Xây dựng `DocumentRepository` để trừu tượng hóa truy cập CSDL cho tầng Logic.
3. **Xây dựng Business Logic & State Management Layer**:
   - `DocumentController`: Tiếp nhận các thao tác từ UI, thẩm định tính hợp lệ của trường dữ liệu (tiêu đề, môn học, danh mục, file metadata), gọi Repository và quản lý bộ lọc tìm kiếm.
   - Tích hợp `Stream` để đón nhận dữ liệu tự động từ Drift mà không cần gọi hàm refresh thủ công.
4. **Xây dựng Presentation Layer (Material Design 3)**:
   - Màn hình hiển thị danh sách tài liệu với thiết kế thẻ hiện đại, phân loại theo màu sắc môn học, biểu tượng định dạng tệp (PDF, Word, Excel, Slide, Code, Khác).
   - Thanh tìm kiếm thời gian thực (Search Bar) kết hợp bộ lọc Môn học / Danh mục.
   - Màn hình thêm / sửa tài liệu với validation đầy đủ, thông báo SnackBar trực quan.
   - Hộp thoại xác nhận (Confirmation Dialog) trước khi xóa tài liệu.
   - Xử lý đầy đủ các trạng thái: Loading, Empty Data, Empty Search Result, Error.
5. **Kiểm thử đa tầng (Automated Testing)**:
   - Data Layer Test (In-Memory SQLite Drift Database Test).
   - Business Logic & Controller Test (Validation, State mutation, Stream forwarding).
   - Presentation Widget Test (Smoke test, Render danh sách, Tìm kiếm, Xác nhận xóa).
