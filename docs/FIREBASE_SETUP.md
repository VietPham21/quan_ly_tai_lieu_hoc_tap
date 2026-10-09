# HƯỚNG DẪN THIẾT LẬP VÀ VẬN HÀNH FIREBASE
## DỰ ÁN QUẢN LÝ TÀI LIỆU HỌC TẬP TÍCH HỢP CLOUD (CHECKLIST 6)

* **Tên dự án:** Ứng dụng Quản lý Tài liệu Học tập
* **Firebase Project ID:** `quan-ly-tai-lieu-hoc-tap`
* **Người thực hiện:** Senior Flutter & Firebase Architecture Team
* **Ngày cập nhật:** 10/10/2026

---

## 1. TỔNG QUAN VÀ TRẠNG THÁI TRIỂN KHAI THỰC TẾ

| Thành phần kỹ thuật | Trạng thái trong Source Code | Trạng thái trên Firebase Console | Ghi chú & Thao tác cần thiết |
| :--- | :--- | :--- | :--- |
| **Cấu hình FlutterFire (`firebase_options.dart`)** | **ĐÃ CẤU HÌNH** | Đã đăng ký Web, Android, iOS, Windows | Cấu hình tự động bởi CLI. |
| **Khởi tạo Firebase Core** | **ĐÃ TRIỂN KHAI** trong `main.dart` | Hoạt động bình thường | Gọi `Firebase.initializeApp(...)` ngay khi mở app. |
| **Google Authentication** | **ĐÃ TRIỂN KHAI** qua `signInWithPopup` | **CẦN BẬT TRÊN CONSOLE** | Cần bật provider Google trong mục Authentication. |
| **Cloud Firestore (Metadata)** | **ĐÃ TRIỂN KHAI** qua `FirestoreDocumentRepository` | **CẦN TẠO DATABASE** | Cần bấm "Create Database" trên Firebase Console. |
| **Cloud Storage (File Upload/Download)** | **ĐÃ TRIỂN KHAI** qua `CloudStorageService` | **CẦN BẬT GÓI BLAZE** | Bucket yêu cầu nâng cấp gói Blaze trước khi kích hoạt. |
| **Security Rules** | **ĐÃ TẠO FILE** `firestore.rules` & `storage.rules` | **CẦN COPY VÀO CONSOLE** | Cần dán nội dung vào tab Rules trên Console. |

---

## 2. CÁC THAO TÁC CẦN THỰC HIỆN TRÊN FIREBASE CONSOLE

Để ứng dụng kết nối thành công với tài khoản Cloud của bạn, hãy thực hiện các bước sau trên trình duyệt tại [https://console.firebase.google.com/](https://console.firebase.google.com/):

### Bước 1: Kích hoạt Google Sign-In (Bắt buộc)
1. Truy cập dự án **quan-ly-tai-lieu-hoc-tap**.
2. Chọn menu **Build** $\to$ **Authentication** $\to$ Bấm **Get Started**.
3. Tại tab **Sign-in method**, chọn nhà cung cấp **Google**.
4. Bật công tắc **Enable**.
5. Nhập tên hiển thị dự án và chọn **Project support email** (email Google của bạn).
6. Bấm **Save**.

### Bước 2: Kích hoạt Cloud Firestore Database (Bắt buộc)
1. Trong menu **Build**, chọn **Firestore Database** $\to$ Bấm **Create database**.
2. Chọn vị trí lưu trữ (Location): khuyến nghị `asia-southeast1` (Singapore) hoặc `asia-east1` để có tốc độ kết nối nhanh nhất từ Việt Nam.
3. Chọn chế độ bảo mật: chọn **Start in test mode** hoặc dán nội dung từ file [firestore.rules](file:///f:/FlutterProjects/quan_ly_tai_lieu_hoc_tap/firestore.rules).
4. Bấm **Create** để hoàn tất.

### Bước 3: Kích hoạt Cloud Storage for Firebase (Lưu ý về Billing)
> [!WARNING]
> **ĐIỀU KIỆN BILLING CỦA CLOUD STORAGE:**  
> Theo chính sách của Google, tạo Cloud Storage bucket mới yêu cầu dự án chuyển sang **gói Blaze (Pay-as-you-go - yêu cầu liên kết thẻ tín dụng/ghi nợ)**.  
> Tuy nhiên, **Google vẫn cung cấp hạn mức 5GB lưu trữ và 1GB tải về/ngày hoàn toàn miễn phí mỗi tháng**.

* **Nếu bạn muốn sử dụng Cloud Storage thật trên đám mây:**
  1. Nâng cấp dự án sang gói Blaze trong mục **Usage and billing**.
  2. Chọn **Build** $\to$ **Storage** $\to$ Bấm **Get started**.
  3. Chọn vị trí bucket tương tự Firestore (`asia-southeast1`).
  4. Dán quy tắc bảo mật từ [storage.rules](file:///f:/FlutterProjects/quan_ly_tai_lieu_hoc_tap/storage.rules).
* **Nếu bạn chưa muốn bật billing:**
  * Ứng dụng vẫn cho phép đăng nhập Google và quản lý metadata tài liệu trên Cloud Firestore bình thường.
  * Khi lưu tài liệu mà không chọn file nhị phân, metadata sẽ lưu trực tiếp vào Firestore mà không gây lỗi Storage.

---

## 3. NỘI DUNG VÀ Ý NGHĨA CỦA SECURITY RULES

### 3.1. Firestore Security Rules ([firestore.rules](file:///f:/FlutterProjects/quan_ly_tai_lieu_hoc_tap/firestore.rules))
* **Bảo vệ theo User UID:** Dữ liệu nằm trong `users/{userId}/documents/{documentId}`.
* Chỉ sinh viên có `request.auth.uid == userId` mới được đọc và xóa tài liệu của mình.
* Thao tác tạo mới bắt buộc phải gắn đúng `ownerUid == userId` và tiêu đề từ 2 đến 200 ký tự.
* Tuyệt đối không cho phép người khác ghi đè `ownerUid` để chiếm quyền tài liệu.

### 3.2. Storage Security Rules ([storage.rules](file:///f:/FlutterProjects/quan_ly_tai_lieu_hoc_tap/storage.rules))
* **Phân cấp thư mục:** `users/{userId}/documents/{documentId}/{fileName}`.
* Chỉ chủ sở hữu (`request.auth.uid == userId`) mới được upload và download tệp.
* Giới hạn trần dung lượng tệp: tối đa **25 MB** (`request.resource.size <= 25 * 1024 * 1024`).

---

## 4. HƯỚNG DẪN KHỞI CHẠY ỨNG DỤNG TRÊN CHROME / WEB

Chạy lệnh sau tại thư mục gốc của dự án:

```bash
# 1. Cập nhật dependencies
flutter pub get

# 2. Kiểm tra lỗi cú pháp
flutter analyze

# 3. Chạy ứng dụng trên trình duyệt Google Chrome
flutter run -d chrome
```

---

## 5. CÁC LỖI THƯỜNG GẶP VÀ CÁCH XỬ LÝ (TROUBLESHOOTING)

1. **Lỗi `popup-closed-by-user` khi đăng nhập Google:**
   * *Nguyên nhân:* Người dùng tắt popup trước khi chọn tài khoản Google.
   * *Khắc phục:* Bấm lại nút Đăng nhập và hoàn tất việc chọn email.
2. **Lỗi `FirebaseException: [storage/bucket-not-found]`:**
   * *Nguyên nhân:* Cloud Storage bucket chưa được kích hoạt trên Firebase Console do chưa nâng cấp gói Blaze.
   * *Khắc phục:* Kích hoạt Storage trên Console hoặc tạo tài liệu chỉ với metadata (không chọn file nhị phân đính kèm).
3. **Lỗi `Cross-Origin-Opener-Policy (COOP)` trên Chrome Web:**
   * *Nguyên nhân:* Trình duyệt chặn popup giao tiếp qua iframe.
   * *Khắc phục:* `signInWithPopup` của FlutterFire đã xử lý tự động; nếu gặp lỗi, hãy đảm bảo mở trang web trên cổng localhost tiêu chuẩn của Flutter.
