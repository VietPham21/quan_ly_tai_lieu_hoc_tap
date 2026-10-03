import '../database/app_database.dart';
import '../database/daos/documents_dao.dart';
import 'document_repository.dart';

/// Triển khai cụ thể của DocumentRepository sử dụng DocumentsDao và Drift ORM.
class DocumentRepositoryImpl implements DocumentRepository {
  final DocumentsDao _documentsDao;

  DocumentRepositoryImpl(this._documentsDao);

  @override
  Stream<List<Document>> watchAllDocuments({
    bool sortByCreated = false,
    bool ascending = false,
  }) {
    return _documentsDao.watchAllDocuments(
      sortByCreated: sortByCreated,
      ascending: ascending,
    );
  }

  @override
  Stream<List<Document>> watchSearchDocuments({
    String query = '',
    String? category,
    String? subject,
    bool ascending = false,
  }) {
    return _documentsDao.watchSearchDocuments(
      query: query,
      category: category,
      subject: subject,
      ascending: ascending,
    );
  }

  @override
  Future<List<Document>> getAllDocuments() {
    return _documentsDao.getAllDocuments();
  }

  @override
  Future<Document?> getDocumentById(String id) {
    return _documentsDao.getDocumentById(id);
  }

  @override
  Future<void> addDocument(DocumentsCompanion companion) async {
    await _documentsDao.insertDocument(companion);
  }

  @override
  Future<bool> updateDocument(DocumentsCompanion companion) {
    return _documentsDao.updateDocument(companion);
  }

  @override
  Future<bool> deleteDocument(String id) async {
    final rowsAffected = await _documentsDao.deleteDocument(id);
    return rowsAffected > 0;
  }

  @override
  Future<void> toggleFavorite(String id, bool currentStatus) async {
    await _documentsDao.toggleFavorite(id, currentStatus);
  }

  @override
  Future<List<String>> getDistinctSubjects() {
    return _documentsDao.getAllDistinctSubjects();
  }

  @override
  Future<List<String>> getDistinctCategories() {
    return _documentsDao.getAllDistinctCategories();
  }
}
