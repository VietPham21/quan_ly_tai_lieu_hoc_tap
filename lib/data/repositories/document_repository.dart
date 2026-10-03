import '../database/app_database.dart';

/// Repository interface định nghĩa các phương thức thao tác với dữ liệu Document.
/// Đóng vai trò là cầu nối giữa Business Logic Layer và Data Persistence Layer,
/// bảo đảm tầng Logic không bị phụ thuộc trực tiếp vào chi tiết triển khai của Drift hay SQLite.
abstract class DocumentRepository {
  /// Lắng nghe toàn bộ tài liệu học tập theo thời gian thực
  Stream<List<Document>> watchAllDocuments({
    bool sortByCreated = false,
    bool ascending = false,
  });

  /// Lắng nghe danh sách tài liệu tìm kiếm và lọc đa tiêu chí
  Stream<List<Document>> watchSearchDocuments({
    String query = '',
    String? category,
    String? subject,
    bool ascending = false,
  });

  /// Lấy snapshot toàn bộ tài liệu
  Future<List<Document>> getAllDocuments();

  /// Lấy chi tiết tài liệu theo ID
  Future<Document?> getDocumentById(String id);

  /// Thêm tài liệu mới vào cơ sở dữ liệu
  Future<void> addDocument(DocumentsCompanion companion);

  /// Cập nhật thông tin tài liệu hiện có
  Future<bool> updateDocument(DocumentsCompanion companion);

  /// Xóa tài liệu khỏi cơ sở dữ liệu
  Future<bool> deleteDocument(String id);

  /// Đánh dấu hoặc hủy đánh dấu yêu thích
  Future<void> toggleFavorite(String id, bool currentStatus);

  /// Lấy danh sách các môn học hiện có
  Future<List<String>> getDistinctSubjects();

  /// Lấy danh sách các danh mục hiện có
  Future<List<String>> getDistinctCategories();
}
