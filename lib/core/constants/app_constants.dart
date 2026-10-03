class AppConstants {
  AppConstants._();

  static const String appName = 'Quản Lý Tài Liệu Học Tập';
  static const String appVersion = '1.0.0';

  // Danh mục tài liệu học tập phổ biến
  static const List<String> defaultCategories = [
    'Tất cả',
    'Giáo trình',
    'Slide bài giảng',
    'Đề thi & Đáp án',
    'Bài tập lớn & Đồ án',
    'Tài liệu tham khảo',
    'Ghi chú ôn tập',
  ];

  // Danh sách môn học gợi ý
  static const List<String> defaultSubjects = [
    'Lập trình Flutter',
    'Kiến trúc Phần mềm',
    'Cơ sở dữ liệu',
    'Mạng máy tính',
    'Cấu trúc dữ liệu & Giải thuật',
    'Trí tuệ nhân tạo',
    'Hệ điều hành',
    'An toàn thông tin',
  ];

  // Định dạng file hỗ trợ
  static const List<String> supportedFileTypes = [
    'PDF',
    'DOCX',
    'PPTX',
    'XLSX',
    'ZIP',
    'CODE',
    'TXT',
  ];
}
