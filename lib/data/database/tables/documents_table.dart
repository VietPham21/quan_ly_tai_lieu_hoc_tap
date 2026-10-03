import 'package:drift/drift.dart';

/// Định nghĩa bảng Documents trong SQLite thông qua Drift ORM
/// Tuân thủ quy tắc thiết kế CSDL của Cashew: Local-First, UUID Primary Key,
/// Single Source of Truth và hỗ trợ đầy đủ các trường quản lý tài liệu học tập.
@DataClassName('Document')
class Documents extends Table {
  /// Khóa chính UUID (tương đương documentPk theo quy ước Cashew)
  TextColumn get id => text()();

  /// Tiêu đề tài liệu học tập
  TextColumn get title => text().withLength(min: 1, max: 200)();

  /// Mô tả, tóm tắt hoặc ghi chú học tập
  TextColumn get description => text().nullable()();

  /// Môn học (VD: Lập trình Flutter, CSDL, Mạng máy tính...)
  TextColumn get subject => text().withLength(min: 1, max: 100)();

  /// Danh mục (VD: Giáo trình, Slide, Đề thi, Đồ án...)
  TextColumn get category => text().withLength(min: 1, max: 100)();

  /// Tên tệp tin
  TextColumn get fileName => text().withLength(min: 1, max: 255)();

  /// Đường dẫn tệp tin trên bộ nhớ / URI
  TextColumn get filePath => text().nullable()();

  /// Định dạng tệp tin (PDF, DOCX, PPTX, XLSX, ZIP, CODE...)
  TextColumn get fileType => text().withLength(min: 1, max: 20)();

  /// Dung lượng tệp tin (tính theo byte)
  IntColumn get fileSize => integer().withDefault(const Constant(0))();

  /// Đánh dấu tài liệu yêu thích / quan trọng
  BoolColumn get isFavorite => boolean().withDefault(const Constant(false))();

  /// Thời điểm tạo tài liệu
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  /// Thời điểm cập nhật tài liệu gần nhất
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}
