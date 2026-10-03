# ỨNG DỤNG QUẢN LÝ TÀI LIỆU HỌC TẬP (CASHEW ARCHITECTURE)

> **Bài tập lớn TH1:** Xây dựng Ứng dụng Quản lý Tài liệu Học tập theo Kiến trúc Cashew  
> **Nền tảng:** Flutter 3.47+ (Dart 3.13+)  
> **Cơ sở dữ liệu:** SQLite3 với Drift ORM  
> **Quản lý trạng thái:** Reactive Data Streams (`watch()`) kết hợp `Provider` & `ChangeNotifier`  

---

## 📖 1. TỔNG QUAN HỆ THỐNG

Dự án áp dụng mô hình **Kiến trúc Phân tầng (Layered Architecture)** kết hợp với cơ chế **Database-Driven Reactive State** được đúc kết từ ứng dụng mã nguồn mở nổi tiếng **Cashew (Budget & Expense Tracker)** để giải quyết bài toán quản lý tài liệu học tập của sinh viên và giảng viên.

### Các đặc tính cốt lõi:
- **Local-First (Offline-First)**: Toàn bộ dữ liệu lưu trữ trực tiếp trong SQLite cục bộ, bảo đảm tính riêng tư, an toàn và phản hồi tức thì với độ trễ bằng 0.
- **Single Source of Truth (SSOT)**: Cơ sở dữ liệu SQLite là nguồn chân lý duy nhất. Mọi thay đổi dữ liệu (Insert, Update, Delete) đều được phát tự động lên giao diện qua Reactive Stream `watch()` mà không cần gọi hàm tải lại thủ công.
- **Phân tách trách nhiệm triệt để (Separation of Concerns)**: Tầng giao diện không truy vấn SQL trực tiếp, tầng logic không phụ thuộc vào widget giao diện.

---

## 🏛️ 2. KIẾN TRÚC TỔNG THỂ (HIGH-LEVEL ARCHITECTURE)

```mermaid
graph TD
    subgraph UI_Layer ["1. Presentation Layer (Giao diện người dùng)"]
        ListScreen["DocumentListScreen (Danh sách, Tìm kiếm, Lọc)"]
        DetailScreen["DocumentDetailScreen (Chi tiết tài liệu)"]
        FormScreen["DocumentFormScreen (Thêm / Sửa tài liệu)"]
        CustomWidgets["Custom Widgets (DocumentCard, SearchBar, CategoryChips, ConfirmDialog)"]
    end

    subgraph Logic_Layer ["2. Business Logic & State Management"]
        DocController["DocumentController (ChangeNotifier & Stream Coordinator)"]
        DocState["DocumentState (Trạng thái bất biến & Bộ lọc)"]
    end

    subgraph Data_Layer ["3. Data Access & Persistence (Local-First)"]
        DocRepo["DocumentRepository (Interface & Impl)"]
        DocDAO["DocumentsDao (Drift DAO: CRUD, Search, Watch)"]
        DocTable["Documents Table (SQLite Schema)"]
        DriftDB["AppDatabase (SQLite Engine)"]
    end

    UI_Layer -->|Thao tác người dùng| Logic_Layer
    Logic_Layer -->|Validation & CRUD| Data_Layer
    Data_Layer -->|Ghi dữ liệu SQLite| DriftDB
    DriftDB -.->|Phát luồng dữ liệu thay đổi qua watch()| DocDAO
    DocDAO -.->|Reactive Stream| Logic_Layer
    Logic_Layer -.->|Cập nhật State tự động| UI_Layer
```

---

## 📁 3. CẤU TRÚC THƯ MỤC DỰ ÁN

```text
quan_ly_tai_lieu_hoc_tap/
├── docs/                               # Hồ sơ tài liệu kiến trúc & báo cáo hoàn chỉnh
│   ├── ARCHITECTURE_ANALYSIS.md        # Phân tích kiến trúc hiện tại & kế hoạch chuyển đổi
│   ├── DATABASE_DESIGN.md              # Thiết kế CSDL chi tiết (Bảng, Index, DAO, Drift)
│   ├── DATA_FLOW.md                    # Sơ đồ ngữ cảnh, DFD Level 1, Mermaid sequence flows
│   ├── TEST_REPORT.md                  # Báo cáo kết quả kiểm thử 17 test cases (100% PASS)
│   └── REPORT_CASHEW.md                # Báo cáo giải trình toàn diện nộp bài
│
├── lib/
│   ├── core/                           # Cấu hình chung, Theme, Hằng số & Tiện ích
│   │   ├── constants/
│   │   │   ├── app_colors.dart         # Bảng màu thương hiệu & màu định dạng tệp tin
│   │   │   └── app_constants.dart      # Danh mục, môn học, đuôi tệp tin hỗ trợ
│   │   ├── theme/
│   │   │   └── app_theme.dart          # Light Theme & Dark Theme Material Design 3
│   │   └── utils/
│   │       └── file_helper.dart        # Định dạng dung lượng (KB/MB), ngày giờ, icon tệp
│   │
│   ├── data/                           # Tầng Data Access & Persistence (Cashew Layer 3)
│   │   ├── database/
│   │   │   ├── tables/
│   │   │   │   └── documents_table.dart# Định nghĩa bảng Documents bằng Drift ORM
│   │   │   ├── daos/
│   │   │   │   ├── documents_dao.dart  # Data Access Object (CRUD, Search, Watch)
│   │   │   │   └── documents_dao.g.dart# Drift generated code
│   │   │   ├── app_database.dart       # Kết nối SQLite cục bộ Native
│   │   │   └── app_database.g.dart     # Drift generated database
│   │   └── repositories/
│   │       ├── document_repository.dart# Repository Interface
│   │       └── document_repository_impl.dart # Triển khai với DAO & SQLite
│   │
│   ├── logic/                          # Tầng Business Logic & State (Cashew Layer 2)
│   │   ├── states/
│   │   │   └── document_state.dart     # Trạng thái bất biến (Immutable State)
│   │   └── controllers/
│   │       └── document_controller.dart# Điều phối nghiệp vụ, Validation & Reactive Stream
│   │
│   ├── presentation/                   # Tầng Presentation (Cashew Layer 1)
│   │   ├── screens/
│   │   │   ├── document_list_screen.dart   # Màn hình danh sách tài liệu
│   │   │   ├── document_detail_screen.dart # Màn hình chi tiết tài liệu
│   │   │   └── document_form_screen.dart   # Màn hình thêm / sửa tài liệu
│   │   └── widgets/
│   │       ├── document_card.dart          # Thẻ tài liệu học tập
│   │       ├── document_search_bar.dart    # Thanh tìm kiếm thời gian thực
│   │       ├── category_chip_selector.dart # Bộ lọc danh mục dạng thẻ trượt
│   │       ├── confirmation_dialog.dart    # Dialog xác nhận xóa an toàn
│   │       └── empty_state_view.dart       # Giao diện khi danh sách rỗng
│   │
│   └── main.dart                       # Điểm khởi chạy ứng dụng & nạp dữ liệu mẫu demo
│
└── test/                               # Bộ kiểm thử tự động đa tầng
    ├── data/
    │   └── documents_dao_test.dart     # Unit test Data Layer (In-Memory SQLite)
    ├── logic/
    │   └── document_controller_test.dart# Unit test Logic, Validation & State
    ├── presentation/
    │   └── document_widget_test.dart   # Widget test UI, Tìm kiếm, Dialog
    └── widget_test.dart                # Smoke test khởi chạy ứng dụng
```

---

## ⚡ 4. CÁC TÍNH NĂNG CỐT LÕI

1. **Hiển thị danh sách tài liệu phản ứng (Reactive Stream)**: Tự động cập nhật thời gian thực khi CSDL thay đổi.
2. **Thêm tài liệu mới (Create)**: Form thẩm định hợp lệ nghiêm ngặt, hỗ trợ nạp siêu dữ liệu tệp tin.
3. **Chỉnh sửa tài liệu (Update)**: Cập nhật thông tin, đồng bộ đa màn hình tức thì.
4. **Xóa tài liệu an toàn (Delete)**: Có hộp thoại cảnh báo và xác nhận chủ động (`ConfirmationDialog`).
5. **Tìm kiếm & Lọc đa tiêu chí (Search & Filter)**:
   - Tìm kiếm đồng thời theo Tên tài liệu, Môn học, Danh mục, Tên tệp, Ghi chú.
   - Lọc nhanh theo Danh mục (Giáo trình, Slide, Đề thi, Đồ án, Ghi chú...).
   - Đảo chiều sắp xếp Mới nhất / Cũ nhất.
6. **Đánh dấu tài liệu yêu thích / quan trọng**: Ghim tài liệu để tra cứu nhanh.

---

## 🧪 5. KIỂM THỬ HỆ THỐNG (AUTOMATED TESTING)

Chạy toàn bộ 17 test cases bao phủ cả 3 tầng:

```bash
flutter test
```

### Kết quả kiểm thử:
```text
00:01 +17: All tests passed!
```
- **Data Layer Tests (DocumentsDao)**: 6/6 tests passed.
- **Business Logic Tests (DocumentController)**: 6/6 tests passed.
- **Presentation Layer Tests (Widgets & Smoke Test)**: 5/5 tests passed.
- **Static Analysis (`flutter analyze`)**: 0 lỗi, 0 cảnh báo.

---

## 🚀 6. HƯỚNG DẪN KHỞI CHẠY ỨNG DỤNG DEMO

### Yêu cầu môi trường:
- Flutter SDK 3.13+ (Khuyến nghị Flutter 3.24+ hoặc Flutter 3.47.x)
- Dart SDK 3.x
- Git

### Các bước khởi chạy:
```bash
# 1. Cài đặt các gói phụ thuộc
flutter pub get

# 2. Sinh mã Drift ORM (nếu có thay đổi schema)
dart run build_runner build --delete-conflicting-outputs

# 3. Chạy kiểm thử tự động
flutter test

# 4. Khởi chạy ứng dụng
flutter run
```

---

## 📚 7. TÀI LIỆU DỰ ÁN CHI TIẾT

- [ARCHITECTURE_ANALYSIS.md](file:///f:/FlutterProjects/quan_ly_tai_lieu_hoc_tap/docs/ARCHITECTURE_ANALYSIS.md): Báo cáo phân tích hiện trạng và kế hoạch chuyển đổi theo Cashew.
- [DATABASE_DESIGN.md](file:///f:/FlutterProjects/quan_ly_tai_lieu_hoc_tap/docs/DATABASE_DESIGN.md): Đặc tả thiết kế CSDL SQLite với Drift ORM.
- [DATA_FLOW.md](file:///f:/FlutterProjects/quan_ly_tai_lieu_hoc_tap/docs/DATA_FLOW.md): Sơ đồ ngữ cảnh và sơ đồ luồng dữ liệu (Context, DFD, Sequence).
- [TEST_REPORT.md](file:///f:/FlutterProjects/quan_ly_tai_lieu_hoc_tap/docs/TEST_REPORT.md): Báo cáo kiểm thử chi tiết 17 test cases.
- [WEB_SUPPORT.md](file:///f:/FlutterProjects/quan_ly_tai_lieu_hoc_tap/docs/WEB_SUPPORT.md): Giải pháp và báo cáo kỹ thuật hỗ trợ Google Chrome / Flutter Web với SQLite WASM.
- [REPORT_CASHEW.md](file:///f:/FlutterProjects/quan_ly_tai_lieu_hoc_tap/docs/REPORT_CASHEW.md): Báo cáo giải trình tổng hợp nộp bài tập lớn.
