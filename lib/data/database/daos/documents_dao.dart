import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/documents_table.dart';

part 'documents_dao.g.dart';

/// Data Access Object cho bảng Documents.
/// Cung cấp các thao tác CRUD và các truy vấn phản ứng (Reactive Stream queries `watch()`)
/// chuẩn theo kiến trúc Cashew.
@DriftAccessor(tables: [Documents])
class DocumentsDao extends DatabaseAccessor<AppDatabase>
    with _$DocumentsDaoMixin {
  DocumentsDao(super.db);

  /// Lắng nghe toàn bộ tài liệu theo thời gian thực (Reactive Stream)
  Stream<List<Document>> watchAllDocuments({
    bool sortByCreated = false,
    bool ascending = false,
  }) {
    final query = select(documents);
    query.orderBy([
      (t) => OrderingTerm(
        expression: sortByCreated ? t.createdAt : t.updatedAt,
        mode: ascending ? OrderingMode.asc : OrderingMode.desc,
      ),
    ]);
    return query.watch();
  }

  /// Lắng nghe kết quả tìm kiếm và lọc tài liệu đa tiêu chí (Reactive Stream)
  /// Tự động cập nhật khi dữ liệu bên dưới thay đổi.
  Stream<List<Document>> watchSearchDocuments({
    String query = '',
    String? category,
    String? subject,
    bool ascending = false,
  }) {
    final selectQuery = select(documents);
    selectQuery.where((tbl) {
      final List<Expression<bool>> predicates = [];

      final cleanQuery = query.trim();
      if (cleanQuery.isNotEmpty) {
        final pattern = '%$cleanQuery%';
        predicates.add(
          tbl.title.like(pattern) |
              tbl.subject.like(pattern) |
              tbl.category.like(pattern) |
              tbl.fileName.like(pattern) |
              tbl.description.like(pattern),
        );
      }

      if (category != null && category.isNotEmpty && category != 'Tất cả') {
        predicates.add(tbl.category.equals(category));
      }

      if (subject != null && subject.isNotEmpty && subject != 'Tất cả') {
        predicates.add(tbl.subject.equals(subject));
      }

      if (predicates.isEmpty) {
        return const Constant(true);
      } else {
        return predicates.reduce((a, b) => a & b);
      }
    });

    selectQuery.orderBy([
      (t) => OrderingTerm(
        expression: t.updatedAt,
        mode: ascending ? OrderingMode.asc : OrderingMode.desc,
      ),
    ]);

    return selectQuery.watch();
  }

  /// Lấy toàn bộ tài liệu (Snapshot đơn lẻ)
  Future<List<Document>> getAllDocuments() => select(documents).get();

  /// Lấy chi tiết tài liệu theo ID
  Future<Document?> getDocumentById(String id) {
    return (select(
      documents,
    )..where((tbl) => tbl.id.equals(id))).getSingleOrNull();
  }

  /// Thêm tài liệu mới vào SQLite
  Future<int> insertDocument(DocumentsCompanion document) {
    return into(documents).insert(document);
  }

  /// Cập nhật thông tin tài liệu
  Future<bool> updateDocument(DocumentsCompanion document) {
    return update(documents).replace(document);
  }

  /// Xóa tài liệu theo ID
  Future<int> deleteDocument(String id) {
    return (delete(documents)..where((tbl) => tbl.id.equals(id))).go();
  }

  /// Bật/tắt trạng thái yêu thích
  Future<int> toggleFavorite(String id, bool currentStatus) {
    return (update(documents)..where((tbl) => tbl.id.equals(id))).write(
      DocumentsCompanion(
        isFavorite: Value(!currentStatus),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Lấy danh sách các môn học hiện có trong CSDL
  Future<List<String>> getAllDistinctSubjects() async {
    final query = selectOnly(documents, distinct: true)
      ..addColumns([documents.subject]);
    final rows = await query.get();
    return rows.map((row) => row.read(documents.subject)!).toList();
  }

  /// Lấy danh sách các danh mục hiện có trong CSDL
  Future<List<String>> getAllDistinctCategories() async {
    final query = selectOnly(documents, distinct: true)
      ..addColumns([documents.category]);
    final rows = await query.get();
    return rows.map((row) => row.read(documents.category)!).toList();
  }
}
