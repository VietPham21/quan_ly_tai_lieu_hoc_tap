# BÁO CÁO ĐÁNH GIÁ TÁC ĐỘNG BẢO MẬT, CHI PHÍ VÀ HIỆU SUẤT

## HỆ THỐNG QUẢN LÝ TÀI LIỆU HỌC TẬP — TÍCH HỢP CLOUD (CHECKLIST 5)

- **Tên dự án:** Ứng dụng Quản lý Tài liệu Học tập (Document Management System)
- **Học phần:** Thực hành Kiến trúc Phần mềm / Tích hợp Hệ thống Cloud
- **Tài liệu tham chiếu:**
  - [docs/CLOUD_ANALYSIS.md](file:///f:/FlutterProjects/quan_ly_tai_lieu_hoc_tap/docs/CLOUD_ANALYSIS.md) (Checklist 1: Khảo sát hiện trạng)
  - [docs/TRADITIONAL_LIMITATIONS.md](file:///f:/FlutterProjects/quan_ly_tai_lieu_hoc_tap/docs/TRADITIONAL_LIMITATIONS.md) (Checklist 2: Nhận diện điểm nghẽn)
  - [docs/CLOUD_MODEL_SELECTION.md](file:///f:/FlutterProjects/quan_ly_tai_lieu_hoc_tap/docs/CLOUD_MODEL_SELECTION.md) (Checklist 3: Lựa chọn mô hình & dịch vụ)
  - [docs/CLOUD_ARCHITECTURE.md](file:///f:/FlutterProjects/quan_ly_tai_lieu_hoc_tap/docs/CLOUD_ARCHITECTURE.md) (Checklist 4: Thiết kế kiến trúc & luồng dữ liệu)
- **Người thực hiện:** Nhóm sinh viên thực hiện đề tài (Software Architecture Team)
- **Ngày lập báo cáo:** 09/10/2026
- **Phạm vi thực hiện:** **Chỉ thực hiện Checklist 5** (Đánh giá bảo mật, chi phí và hiệu suất khi chuyển đổi từ mô hình truyền thống sang Cloud). Tuyệt đối chưa can thiệp sửa code, chưa cài đặt package, chưa sửa database, chưa bật billing.

> [!NOTE]
> **PHÂN ĐỊNH TRẠNG THÁI ĐÁNH GIÁ:**
>
> 1. **Hiện trạng đã xác minh:** Dựa trên phân tích mã nguồn thực tế ở Checklist 1 và Checklist 2.
> 2. **Tác động dự kiến:** Phân tích kỹ thuật lý thuyết dựa trên đặc tả kiến trúc TO-BE của Firebase.
> 3. **Số liệu thực tế:** Các thông số về độ trễ mạng (latency) và chi phí thực phát sinh sẽ được đo đạc sau khi hoàn tất triển khai ở Checklist 6.

---

## 1. MỤC TIÊU ĐÁNH GIÁ

1. Nhận diện và so sánh đa chiều bức tranh kỹ thuật giữa **Mô hình Truyền thống (Local-First SQLite)** và **Mô hình Đám mây (Google Firebase)** trên 3 trụ cột: **Bảo mật (Security)**, **Chi phí (Cost)**, và **Hiệu suất (Performance)**.
2. Thiết lập bộ nguyên tắc bảo vệ dữ liệu theo tiêu chuẩn **Least Privilege** và kiểm soát rủi ro phân quyền trên Cloud Firestore và Cloud Storage.
3. Dự toán chi phí dựa trên bảng giá chính thức của Google Firebase, phân tích các kịch bản sử dụng thực tế của sinh viên và đề ra giải pháp ngăn ngừa phát sinh chi phí ngoài tầm kiểm soát.
4. Phân tích sự đánh đổi về hiệu năng (Performance Trade-offs) giữa truy xuất bộ nhớ cục bộ và truyền nhận qua mạng Internet.
5. Xây dựng Kế hoạch Kiểm chứng Thực nghiệm (Test Plan Matrix) sẵn sàng áp dụng sau khi hoàn thành tích hợp ở Checklist 6.

---

## 2. PHẠM VI VÀ GIẢ ĐỊNH KỸ THUẬT

### 2.1. Phạm vi đánh giá

- **Mô hình truyền thống:** Ứng dụng Flutter chạy độc lập, dữ liệu lưu trong SQLite cục bộ (`hoc_tap_documents.sqlite`), chưa lưu file nhị phân thực tế.
- **Mô hình Cloud dự kiến:** Public Cloud BaaS gồm Firebase Authentication (Google Sign-In), Cloud Firestore (Metadata NoSQL), Cloud Storage for Firebase (File PDF/Word/Slide), và Offline Persistence của Firestore SDK.

### 2.2. Các giả định đo lường và kịch bản sử dụng

Để phục vụ việc ước tính chi phí và hiệu năng một cách khoa học mà không bịa đặt số liệu, nhóm thiết lập kịch bản mẫu cho quy mô **1 sinh viên cá nhân** và **nhóm học tập 50 sinh viên**:

- **Số lượng tài liệu:** Mỗi sinh viên quản lý trung bình **50 tài liệu** học tập trong một học kỳ.
- **Kích thước file trung bình:** **3 MB / tệp tin** (tài liệu giáo trình PDF từ 2 - 10MB, slide bài giảng PPTX từ 1 - 5MB, đề thi Word từ 0.5 - 2MB). Giới hạn trần tối đa cho 1 file là **25 MB**.
- **Tần suất thao tác hàng ngày của 1 sinh viên:**
  - Mở ứng dụng và tải danh sách: 5 lần/ngày.
  - Thêm/Upload tài liệu mới: 2 tài liệu/ngày.
  - Sửa/Xem chi tiết: 10 lần/ngày.
  - Tải về/Đọc file: 5 lần/ngày.

---

## 3. ĐÁNH GIÁ BẢO MẬT (SECURITY EVALUATION)

### 3.1. Mô hình truyền thống (Local-First Standalone)

- **Vị trí lưu trữ dữ liệu:**
  - Native: File CSDL [hoc_tap_documents.sqlite](file:///f:/FlutterProjects/quan_ly_tai_lieu_hoc_tap/lib/data/database/connection/native.dart#L13) nằm trong thư mục sandbox của ứng dụng.
  - Web: IndexedDB trên trình duyệt.
- **Xác thực và Phân quyền:** **HOÀN TOÀN KHÔNG CÓ**. Bất kỳ ai mở được ứng dụng hoặc cầm thiết bị đều có toàn quyền đọc, sửa, xóa toàn bộ tài liệu mà không cần mật khẩu.
- **Nguy cơ mất thiết bị và can thiệp vật lý:** Nếu thiết bị bị thất lạc, bị root/jailbreak, hoặc người dùng cắm cáp trích xuất file `.sqlite`, toàn bộ siêu dữ liệu học tập đều bị đọc dưới dạng plain-text không mã hóa.
- **Sao lưu và Phục hồi:** Không có cơ chế backup. Xóa app hoặc hỏng máy là mất vĩnh viễn dữ liệu.
- **Đánh giá chung:** Bảo mật phụ thuộc 100% vào lớp khóa màn hình của hệ điều hành thiết bị. Không có khả năng phân quyền đa người dùng.

---

### 3.2. Mô hình Cloud (Google Firebase)

Mô hình Cloud giải quyết triệt để vấn đề định danh và phân quyền, nhưng cũng đặt ra những bề mặt tấn công mới cần phòng vệ nghiêm ngặt:

#### A. Định danh và Quản lý phiên (Authentication & Session)

- **Google Sign-In qua Firebase Auth:** Loại bỏ hoàn toàn rủi ro lộ mật khẩu cục bộ vì ứng dụng không lưu trữ mật khẩu của người dùng. Quá trình xác thực tuân thủ giao thức OAuth 2.0 / OpenID Connect.
- **Cơ chế Token:** Firebase Auth quản lý ID Token (hạn 1 giờ) và Refresh Token tự động. Khi người dùng đăng xuất, toàn bộ token trên thiết bị bị thu hồi, ngăn ngừa việc truy cập trái phép sau đó.
- **Định danh duy nhất:** Mỗi sinh viên được cấp một chuỗi `Firebase UID` bất biến, dùng làm "chìa khóa" phân định quyền sở hữu tài sản số.

#### B. Kiểm soát truy cập phía Đám mây (Cloud Security Perimeter)

> [!IMPORTANT]
> **NGUYÊN TẮC BẢO MẬT CỐT LÕI:**
>
> 1. **Client Configuration (`firebase_options.dart`) KHÔNG PHẢI là cơ chế bảo mật:** Các khóa `apiKey`, `appId` chỉ là định danh dự án, bất kỳ ai dịch ngược app đều có thể trích xuất được.
> 2. **Hàng rào bảo vệ thực sự là Security Rules trên máy chủ Firebase:** Mọi yêu cầu từ Client đều bị kiểm duyệt trước khi chạm vào dữ liệu.
> 3. **Tuyệt đối không sử dụng quyền mở công khai (`allow read, write: if true;`)**.

#### C. Đề xuất quy tắc bảo mật Cloud Firestore Rules

Dữ liệu phân cấp theo cấu trúc `users/{uid}/documents/{documentId}`:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Chỉ cho phép người dùng đã xác thực thao tác với kho tài liệu của chính họ
    match /users/{userId}/documents/{documentId} {
      allow read, delete: if request.auth != null && request.auth.uid == userId;

      allow create: if request.auth != null && request.auth.uid == userId
                    && request.resource.data.ownerUid == userId
                    && request.resource.data.title is string
                    && request.resource.data.title.size() >= 2
                    && request.resource.data.title.size() <= 200;

      allow update: if request.auth != null && request.auth.uid == userId
                    && request.resource.data.ownerUid == userId;
    }
  }
}
```

#### D. Đề xuất quy tắc bảo mật Cloud Storage Rules

Đường dẫn lưu trữ tệp tin: `users/{userId}/documents/{documentId}/{fileName}`:

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /users/{userId}/documents/{documentId}/{fileName} {
      // Chỉ chủ sở hữu mới được tải về hoặc xóa tệp
      allow read, delete: if request.auth != null && request.auth.uid == userId;

      // Chỉ cho phép upload khi đúng chủ sở hữu và file nhỏ hơn hoặc bằng 25MB
      allow write: if request.auth != null && request.auth.uid == userId
                   && request.resource.size <= 25 * 1024 * 1024
                   && request.resource.contentType.matches('.*');
    }
  }
}
```

#### E. Đánh giá rủi ro bảo mật còn tồn tại trên Cloud

- **Không có hệ thống an toàn tuyệt đối 100%:** Dữ liệu đám mây vẫn đối mặt với rủi ro người dùng bị lộ tài khoản Google (ví dụ: đăng nhập máy công cộng quên thoát, dính mã độc đánh cắp cookie).
- **Rủi ro chia sẻ URL:** Nếu `downloadUrl` của Storage được sinh ra dưới dạng public token link và người dùng vô tình gửi link đó ra ngoài, bất kỳ ai có link đều tải được file (trừ khi áp dụng quy tắc tải qua SDK xác thực).

---

## 4. ĐÁNH GIÁ CHI PHÍ (COST EVALUATION)

### 4.1. Bảng giá chính thức của Google Firebase (Gói Spark & Gói Blaze)

Dựa trên tài liệu công bố chính thức của Google Firebase (cập nhật mới nhất):

| Dịch vụ             | Gói Spark (Miễn phí hoàn toàn)                                                    | Hạn mức Miễn phí hàng tháng của Gói Blaze (Free Tier Allocation)                                         | Chi phí khi vượt hạn mức miễn phí (Gói Blaze)                                                                                    |
| :------------------ | :-------------------------------------------------------------------------------- | :------------------------------------------------------------------------------------------------------- | :------------------------------------------------------------------------------------------------------------------------------- |
| **Firebase Auth**   | Miễn phí không giới hạn cho Google Sign-In                                        | Miễn phí không giới hạn cho Google Sign-In                                                               | Không tính phí cho Google OAuth                                                                                                  |
| **Cloud Firestore** | • 1 GiB lưu trữ• 50.000 lượt đọc/ngày• 20.000 lượt ghi/ngày• 20.000 lượt xóa/ngày | • 1 GiB lưu trữ• 50.000 lượt đọc/ngày• 20.000 lượt ghi/ngày• 20.000 lượt xóa/ngày                        | • $0.18 / GiB lưu trữ/tháng• $0.06 / 100.000 lượt đọc• $0.18 / 100.000 lượt ghi• $0.02 / 100.000 lượt xóa                        |
| **Cloud Storage**   | _Không cho tạo bucket mới nếu chưa nâng cấp Blaze_                                | •**5 GiB dung lượng lưu trữ**• **1 GiB tải về/ngày**• 20.000 lượt upload/ngày• 50.000 lượt download/ngày | • $0.026 / GiB lưu trữ/tháng• $0.12 / GiB băng thông tải xuống• $0.05 / 10.000 thao tác tải lên• $0.004 / 10.000 thao tác tải về |

---

### 4.2. Kịch bản tính toán chi phí cụ thể

#### Kịch bản 1: Mức sử dụng của 1 Sinh viên (Đồ án cá nhân / Kiểm thử)

- **Lưu trữ Firestore Metadata:** 50 tài liệu $\times$ 1 KB/document = 50 KB (Giới hạn: 1 GB) $\to$ **Dưới 0.005% hạn mức**.
- **Lưu trữ Cloud Storage File:** 50 file $\times$ 3 MB = 150 MB (Giới hạn: 5 GB) $\to$ **Dưới 3% hạn mức**.
- **Lượt đọc Firestore hàng ngày:** 5 lần mở app $\times$ 50 docs = 250 lượt đọc/ngày (Hạn mức: 50.000) $\to$ **Dưới 0.5% hạn mức**.
- **Băng thông tải file hàng ngày:** 5 file $\times$ 3 MB = 15 MB/ngày (Hạn mức: 1.000 MB) $\to$ **Dưới 1.5% hạn mức**.
- $\implies$ **TỔNG CHI PHÍ THỰC TẾ: 0 VNĐ / THÁNG (Hoàn toàn nằm trong Free Tier)**.

#### Kịch bản 2: Nhóm học tập hoặc Lớp học gồm 50 Sinh viên

- **Lưu trữ Firestore Metadata:** 50 user $\times$ 50 docs = 2.500 docs $\approx$ 2.5 MB (Hạn mức 1 GB) $\to$ **0 VNĐ**.
- **Lưu trữ Cloud Storage File:** 50 user $\times$ 150 MB = 7.5 GB (Vượt hạn mức 5 GB là 2.5 GB).
  - Chi phí lưu trữ phụ trội: $2.5 \text{ GB} \times \$0.026 \approx \$0.065$ (khoảng **1.600 VNĐ / tháng**).
- **Băng thông tải file hàng ngày:** Giả sử 50 sinh viên tải 100 file/ngày = 300 MB/ngày (Vẫn nằm trong hạn mức 1 GB/ngày) $\to$ **0 VNĐ**.
- $\implies$ **TỔNG CHI PHÍ ƯỚC TÍNH: ~ 1.600 - 5.000 VNĐ / THÁNG**.

---

### 4.3. Biện pháp kiểm soát chi phí và ngăn ngừa rủi ro phát sinh

1. **Thiết lập Ngân sách Cảnh báo (Budget & Billing Alerts):** Trong Google Cloud Console, đặt ngưỡng cảnh báo ngân sách ở mức **1 USD (hoặc 25.000 VNĐ)**. Nếu chi phí vượt quá 50% hoặc 90% ngưỡng này, hệ thống sẽ tự động gửi email cảnh báo tức thì.
2. **Khống chế kích thước tệp tải lên:** Kiểm tra phía Client trước khi upload (`file.length() <= 25 * 1024 * 1024`) kết hợp chặn cứng trong Storage Rules để tránh sinh viên vô tình tải lên file video nặng hàng GB.
3. **Chống file mồ côi (Orphan File Prevention):** Áp dụng luồng bù trừ giao dịch (Compensating Transaction) như đã thiết kế ở Checklist 4 để tự động xóa file trên Storage nếu thao tác ghi metadata Firestore thất bại.
4. **Tránh Query dư thừa:** Sử dụng Stream `snapshots()` trên subcollection của chính người dùng (`users/{uid}/documents`), không lắng nghe collection tổng để hạn chế số lượt đọc Firestore không cần thiết.

---

## 5. ĐÁNH GIÁ HIỆU SUẤT (PERFORMANCE EVALUATION)

### 5.1. Bảng đối chiếu hiệu suất 10 thao tác cốt lõi

| Thao tác nghiệp vụ            | Mô hình Truyền thống (SQLite cục bộ)                                   | Mô hình Cloud (Firebase tích hợp)                                                                | Đánh giá & Phân tích Đánh đổi (Trade-offs)                                                                                     | Giải pháp tối ưu hóa                                                                   |
| :---------------------------- | :--------------------------------------------------------------------- | :----------------------------------------------------------------------------------------------- | :----------------------------------------------------------------------------------------------------------------------------- | :------------------------------------------------------------------------------------- |
| **1. Khởi động ứng dụng**     | **Rất nhanh (10 - 50ms)**: Mở file database cục bộ trên ổ đĩa.         | **Nhanh (50 - 200ms)**: Khởi tạo Firebase SDK và phục hồi phiên đăng nhập từ cache.              | Local nhanh hơn do không phải khởi tạo kết nối mạng và kiểm tra token.                                                         | Tận dụng Offline Persistence của Firebase để nạp dữ liệu tức thì không chờ mạng.       |
| **2. Tải danh sách tài liệu** | **Tức thì (< 10ms)**: Đọc toàn bộ bảng từ SQLite qua Drift DAO.        | **Phụ thuộc mạng (100 - 500ms)** lần đầu; **tức thì (< 10ms)** từ cache lần sau.                 | Local nhanh hơn khi kết nối mạng kém; Cloud vượt trội khi đồng bộ đa thiết bị.                                                 | Đọc từ bộ nhớ đệm Firestore SDK trước, cập nhật ngầm khi có mạng.                      |
| **3. Tìm kiếm và Lọc**        | **Rất nhanh (5 - 30ms)**: Dùng SQL `LIKE` quét toàn bộ bảng trong RAM. | **Tức thì (0 - 5ms)** với Client-side in-memory filter; **100 - 300ms** nếu query Firestore.     | Tương đương nhau nếu lọc in-memory trên thiết bị; SQLite linh hoạt hơn với cú pháp LIKE phức tạp.                              | Tải danh sách cá nhân về máy và lọc trong RAM bằng`contains()` của Dart.               |
| **4. Thêm tài liệu mới**      | **Tức thì (< 15ms)**: Chỉ ghi một dòng văn bản vào SQLite.             | **Chậm hơn (500ms - 3s)**: Phải upload file lên Storage rồi ghi Firestore.                       | **Đánh đổi cốt lõi**: Local nhanh vì _chưa lưu file thật_; Cloud chậm hơn vì _phải truyền tải dữ liệu nhị phân thật qua mạng_. | Hiển thị thanh tiến trình Upload (Progress Bar) để người dùng không cảm thấy sốt ruột. |
| **5. Upload file tài liệu**   | _Chưa có chức năng này_ (Không khả dụng).                              | **1 - 5 giây** (tùy thuộc vào dung lượng file 1 - 25MB và tốc độ mạng).                          | Cloud bổ sung chức năng mới hoàn toàn cho hệ thống.                                                                            | Nén file trước khi upload nếu là định dạng hỗ trợ; upload bất đồng bộ chạy nền.        |
| **6. Chỉnh sửa metadata**     | **Tức thì (< 10ms)**: Lệnh SQL UPDATE cục bộ.                          | **Nhanh (50 - 200ms)**: Cập nhật Firestore document qua mạng.                                    | Local nhanh hơn một chút, nhưng Cloud tự động cập nhật ngay lập tức sang các thiết bị khác.                                    | Cập nhật optimistic UI (vẽ lại giao diện trước, đợi server xác nhận sau).              |
| **7. Xóa tài liệu**           | **Tức thì (< 10ms)**: Lệnh SQL DELETE cục bộ.                          | **150 - 500ms**: Phải phát lệnh xóa file Storage và xóa Document Firestore.                      | Local nhanh hơn; Cloud phải dọn dẹp hai tài nguyên phân tán.                                                                   | Xóa file Storage trước, xóa Firestore sau; hiển thị SnackBar ngay khi hoàn tất.        |
| **8. Tải xuống / Mở file**    | _Không thể mở file thật_ (Chỉ hiển thị đường dẫn text).                | **1 - 4 giây** lần đầu (tải từ Storage); **tức thì (< 10ms)** lần sau (đọc từ cache máy).        | Cloud vượt trội vì mang lại trải nghiệm đọc tài liệu thật.                                                                     | Lưu trữ file đã tải vào thư mục Cache tạm thời của ứng dụng (`path_provider`).         |
| **9. Truy cập từ máy khác**   | **Không thể (0%)**: Dữ liệu bị cô lập hoàn toàn trên 1 máy.            | **Tức thì (100%)**: Đăng nhập Google trên bất kỳ máy nào đều thấy đầy đủ tài liệu.               | **Ưu thế tuyệt đối của Cloud**.                                                                                                | Đồng bộ đa nền tảng (Android, iOS, Web, Desktop).                                      |
| **10. Sử dụng khi mất mạng**  | **Hoạt động 100% bình thường**: Không phụ thuộc mạng.                  | **Xem/Sửa metadata bình thường** (nhờ Firestore cache); **không upload/download được file mới**. | Local chiếm ưu thế khi offline hoàn toàn.                                                                                      | Giao diện hiển thị huy hiệu báo trạng thái Offline để người dùng nhận biết.            |

---

## 6. BẢNG SO SÁNH TỔNG HỢP: MÔ HÌNH TRUYỀN THỐNG VS CLOUD

| Tiêu chí so sánh          | Mô hình Truyền thống (Hiện tại)                 | Sau khi tích hợp Cloud (Đề xuất)                                                    | Đánh giá ưu nhược điểm & Sự đánh đổi                                                |
| :------------------------ | :---------------------------------------------- | :---------------------------------------------------------------------------------- | :---------------------------------------------------------------------------------- |
| **Bảo mật & Danh tính**   | Không có xác thực; phụ thuộc khóa màn hình máy. | Đăng nhập Google chuẩn OAuth2; quản lý bằng UID.                                    | **Cloud vượt trội**: Phân định ranh giới sở hữu dữ liệu cá nhân.                    |
| **Kiểm soát truy cập**    | Ai cầm máy đều sửa/xóa được dữ liệu.            | Kiểm soát chặt chẽ bằng Firestore & Storage Rules.                                  | **Cloud vượt trội**: Ngăn chặn truy cập trái phép từ bên ngoài.                     |
| **Lưu trữ Metadata**      | SQLite cục bộ (Drift ORM).                      | Cloud Firestore NoSQL Database.                                                     | **Cân bằng**: SQLite truy vấn LIKE tốt hơn; Firestore hỗ trợ realtime sync tốt hơn. |
| **Lưu trữ File thực tế**  | **Không có** (chỉ lưu chuỗi text giả lập).      | **Có** (Cloud Storage for Firebase).                                                | **Cloud vượt trội**: Lấp đầy khoảng trống chức năng lớn nhất của hệ thống.          |
| **Truy cập từ xa**        | Không thể truy cập từ thiết bị khác.            | Truy cập toàn cầu mọi lúc mọi nơi qua Internet.                                     | **Cloud vượt trội**: Phục vụ việc học tập linh hoạt trên nhiều thiết bị.            |
| **Sao lưu & Phục hồi**    | Mất máy / Gỡ app là mất trắng dữ liệu.          | Tự động sao lưu trên trung tâm dữ liệu Google.                                      | **Cloud vượt trội**: Độ bền dữ liệu (Data Durability) đạt 99.999999999%.            |
| **Hoạt động ngoại tuyến** | Hoạt động 100% không cần mạng.                  | Hoạt động được với metadata đã cache; cần mạng để tải file.                         | **Truyền thống chiếm ưu thế** về tính độc lập mạng tuyệt đối.                       |
| **Hiệu suất đọc/ghi**     | Cực nhanh (< 15ms), độ trễ bằng 0.              | Phụ thuộc độ trễ mạng (50ms - vài giây khi upload).                                 | **Đánh đổi**: Chấp nhận độ trễ mạng để đổi lấy tính sẵn sàng và đồng bộ.            |
| **Chi phí vận hành**      | 0 VNĐ chi phí dịch vụ đám mây.                  | 0 VNĐ cho bài tập cá nhân (nằm trong Free Tier); có thể phát sinh nếu vượt hạn mức. | **Cần kiểm soát**: Cloud đòi hỏi theo dõi hạn mức billing cẩn thận.                 |
| **Bảo trì hệ thống**      | Không tốn công quản trị server.                 | Dễ bảo trì nhờ mô hình BaaS không máy chủ.                                          | **Tương đương**: Không bên nào phải tự vá lỗi hệ điều hành server.                  |
| **Khả năng mở rộng**      | Không thể mở rộng cho nhiều người dùng.         | Tự động co giãn (Auto-scaling) phục vụ hàng nghìn sinh viên.                        | **Cloud vượt trội**: Sẵn sàng mở rộng thành nền tảng chia sẻ học tập chung.         |

---

## 7. CÁC RỦI RO CHÍNH VÀ PHƯƠNG ÁN GIẢM THIỂU (RISK MITIGATION)

1. **Rủi ro phát sinh chi phí ngoài ý muốn do cấu hình Billing:**
   - _Nguyên nhân:_ Nâng cấp lên gói Blaze để dùng Cloud Storage nhưng để lộ API Key hoặc viết vòng lặp tải file liên tục.
   - _Giải pháp:_ Đặt hạn mức cảnh báo ngân sách (Budget Alert) ngay từ mức 1 USD trong Google Cloud Console; thiết lập giới hạn dung lượng tải lên 25MB; cấu hình App Check nếu cần ngăn chặn lạm dụng API.
2. **Rủi ro lộ dữ liệu do cấu hình sai Security Rules:**
   - _Nguyên nhân:_ Để nguyên rules mặc định cho phép đọc/ghi tự do (`allow read, write: if true;`).
   - _Giải pháp:_ Áp dụng nghiêm ngặt các quy tắc bảo vệ phân quyền theo `request.auth.uid == userId` như đã thiết kế ở mục 3.2; viết unit test kiểm tra rules bằng Firebase Emulator Suite.
3. **Rủi ro file mồ côi làm đầy bộ nhớ Cloud Storage:**
   - _Nguyên nhân:_ Upload file lên Storage thành công nhưng mất mạng không ghi được Firestore metadata.
   - _Giải pháp:_ Cài đặt cơ chế bù trừ giao dịch (Compensating Transaction) tự động bắt exception để xóa file Storage ngay lập tức.
4. **Rủi ro trải nghiệm người dùng bị khựng khi mạng chập chờn:**
   - _Nguyên nhân:_ Ứng dụng chờ phản hồi từ server trước khi cập nhật màn hình.
   - _Giải pháp:_ Tận dụng cơ chế Offline Cache của Firestore kết hợp hiển thị các trạng thái chờ thân thiện (Loading indicator, Progress bar, Offline banner).

---

## 8. KẾ HOẠCH KIỂM CHỨNG SAU TRIỂN KHAI (TEST PLAN MATRIX)

Vì hệ thống **chưa được tích hợp mã nguồn Firebase trong Checklist 5**, bảng dưới đây là **Kế hoạch kiểm thử chi tiết** được đề xuất để thực thi và đo đạc sau khi hoàn tất cài đặt ở Checklist 6:

| Mã Test        | Mục tiêu kiểm thử                        | Các bước thực hiện chi tiết                                                                 | Kết quả kỳ vọng đạt được                                                                        | Trạng thái hiện tại          |
| :------------- | :--------------------------------------- | :------------------------------------------------------------------------------------------ | :---------------------------------------------------------------------------------------------- | :--------------------------- |
| **TC-SEC-01**  | Xác thực đăng nhập Google                | Bấm nút "Đăng nhập Google"$\to$ Chọn tài khoản sinh viên.                                   | Đăng nhập thành công, cấp phát`Firebase UID`, chuyển vào màn hình chính.                        | **Chưa thực hiện** (Chờ CL6) |
| **TC-SEC-02**  | Thu hồi phiên đăng xuất                  | Bấm nút "Đăng xuất"$\to$ Thử gọi truy vấn đọc dữ liệu.                                      | Đưa người dùng về màn hình đăng nhập; token bị xóa; không truy cập được dữ liệu.                | **Chưa thực hiện** (Chờ CL6) |
| **TC-SEC-03**  | Bảo vệ dữ liệu cá nhân (Chống xem trộm)  | Đăng nhập bằng User A$\to$ Cố gắng truy vấn dữ liệu tại path `users/{UserB_UID}/documents`. | Firestore chặn đứng với lỗi`permission-denied`. User A không thấy tài liệu của User B.          | **Chưa thực hiện** (Chờ CL6) |
| **TC-SEC-04**  | Bảo vệ tệp tin cá nhân (Chống tải trộm)  | User A cố gắng truy cập đường dẫn tệp của User B trên Storage qua SDK.                      | Storage chặn đứng với lỗi`unauthorized`. User A không tải được file của User B.                 | **Chưa thực hiện** (Chờ CL6) |
| **TC-SEC-05**  | Chặn người dùng ẩn danh (Chưa đăng nhập) | Gửi request đọc/ghi khi chưa xác thực Google.                                               | Toàn bộ request bị từ chối với lỗi`unauthenticated`.                                            | **Chưa thực hiện** (Chờ CL6) |
| **TC-FUNC-01** | Tải danh sách thời gian thực             | User A thêm tài liệu trên thiết bị 1.                                                       | Thiết bị 2 của User A tự động cập nhật danh sách mới qua Stream mà không cần F5/tải lại.        | **Chưa thực hiện** (Chờ CL6) |
| **TC-FUNC-02** | Upload file PDF và ghi metadata          | Chọn file PDF 5MB$\to$ Nhập form $\to$ Bấm Lưu.                                             | File được lưu trên Cloud Storage; metadata được ghi vào Firestore; có downloadUrl.              | **Chưa thực hiện** (Chờ CL6) |
| **TC-FUNC-03** | Xử lý chống file mồ côi                  | Giả lập ngắt kết nối Firestore ngay sau khi upload file lên Storage xong.                   | Controller bắt exception$\to$ Tự động xóa file vừa tải lên Storage $\to$ Storage không bị rác.  | **Chưa thực hiện** (Chờ CL6) |
| **TC-FUNC-04** | Tải về và mở file                        | Bấm vào tài liệu trong danh sách$\to$ Bấm "Mở tệp".                                         | Tải file về thư mục tạm$\to$ Mở nội dung file PDF hiển thị chính xác.                           | **Chưa thực hiện** (Chờ CL6) |
| **TC-PERF-01** | Đo độ trễ khởi động app                  | Mở ứng dụng từ trạng thái tắt hoàn toàn (Cold Start).                                       | Thời gian hiển thị danh sách từ cache dưới**500ms** (Ghi nhận số liệu sau CL6).                 | **Chưa thực hiện** (Chờ CL6) |
| **TC-PERF-02** | Đo thời gian upload file                 | Tải lên file PDF chuẩn 5MB qua mạng WiFi ổn định.                                           | Thời gian upload hoàn tất và cập nhật UI dưới**3 giây** (Ghi nhận số liệu sau CL6).             | **Chưa thực hiện** (Chờ CL6) |
| **TC-OFF-01**  | Kiểm tra chế độ Offline                  | Bật chế độ máy bay$\to$ Mở ứng dụng $\to$ Thêm metadata mới.                                | Ứng dụng hiển thị dữ liệu cũ bình thường; metadata mới được lưu vào queue; tự sync khi có mạng. | **Chưa thực hiện** (Chờ CL6) |

---

## 9. KẾT LUẬN

1. **Về mặt Bảo mật:** Chuyển đổi sang Firebase giúp giải quyết triệt để vấn đề định danh và phân quyền nhờ sự kết hợp giữa **Firebase Authentication (Google Sign-In)** và **Security Rules** trên Firestore và Storage. Dữ liệu được bảo vệ nghiêm ngặt theo mã định danh `ownerUid` của từng cá nhân.
2. **Về mặt Chi phí:** Với quy mô học tập của sinh viên, **chi phí hoàn toàn bằng 0 VNĐ** nhờ hạn mức Free Tier rộng rãi hàng tháng của Firebase. Nguy cơ chi phí chỉ xuất hiện nếu vi phạm chính sách kiểm soát file hoặc query vòng lặp, và hoàn toàn có thể triệt tiêu nhờ hạn mức cảnh báo ngân sách (Budget Alerts) và giới hạn file 25MB.
3. **Về mặt Hiệu suất:** Hệ thống chấp nhận một sự đánh đổi hiển nhiên: **chấp nhận độ trễ mạng vài trăm mili-giây đến vài giây khi truyền file** để đổi lấy những năng lực vượt bậc mà mô hình truyền thống không bao giờ có được: **đồng bộ đa thiết bị, lưu trữ file thật, và sao lưu dữ liệu vĩnh viễn**.
4. Toàn bộ các tiêu chí đánh giá lý thuyết đã hoàn tất và được lượng hóa trong Kế hoạch kiểm thử. Dự án có đủ cơ sở khoa học để bước vào giai đoạn triển khai thực tế mã nguồn ở **Checklist 6**.
