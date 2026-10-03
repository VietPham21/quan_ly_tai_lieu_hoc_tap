import 'dart:async';

import 'package:drift/drift.dart' as drift;
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../../data/database/app_database.dart';
import '../../data/repositories/document_repository.dart';
import '../states/document_state.dart';

/// Business Logic & State Controller cho Quản lý Tài liệu Học tập.
/// Chịu trách nhiệm:
/// 1. Điều phối dữ liệu giữa Presentation Layer và Data Access Layer.
/// 2. Lắng nghe Reactive Stream từ Drift CSDL và tự động cập nhật State.
/// 3. Thẩm định quy tắc nghiệp vụ (Validation) trước khi ghi vào CSDL.
/// 4. Xử lý lỗi tập trung và cung cấp phản hồi trạng thái thân thiện.
class DocumentController extends ChangeNotifier {
  final DocumentRepository repository;
  final Uuid _uuid;

  DocumentState _state = const DocumentState(status: DocumentStatus.loading);
  StreamSubscription<List<Document>>? _subscription;

  DocumentController({required this.repository, Uuid? uuid})
    : _uuid = uuid ?? const Uuid() {
    _initStream();
  }

  DocumentState get state => _state;
  List<Document> get documents => _state.documents;
  bool get isLoading => _state.isLoading;
  bool get hasError => _state.hasError;
  String? get errorMessage => _state.errorMessage;
  String? get successMessage => _state.successMessage;

  void _initStream() {
    _subscription?.cancel();
    _subscription = repository
        .watchSearchDocuments(
          query: _state.searchQuery,
          category: _state.selectedCategory,
          subject: _state.selectedSubject,
          ascending: _state.isAscending,
        )
        .listen(
          (docs) {
            _state = _state.copyWith(
              status: DocumentStatus.success,
              documents: docs,
              clearError: true,
            );
            notifyListeners();
          },
          onError: (e) {
            _state = _state.copyWith(
              status: DocumentStatus.error,
              errorMessage: 'Lỗi tải luồng dữ liệu tài liệu: $e',
            );
            notifyListeners();
          },
        );
  }

  /// Cập nhật từ khóa tìm kiếm (Realtime Reactive Search)
  void setSearchQuery(String query) {
    if (_state.searchQuery == query) return;
    _state = _state.copyWith(searchQuery: query);
    notifyListeners();
    _initStream();
  }

  /// Chọn bộ lọc Danh mục
  void setSelectedCategory(String? category) {
    final cat = (category == null || category == 'Tất cả') ? null : category;
    if (_state.selectedCategory == cat) return;
    _state = _state.copyWith(selectedCategory: cat, clearCategory: cat == null);
    notifyListeners();
    _initStream();
  }

  /// Chọn bộ lọc Môn học
  void setSelectedSubject(String? subject) {
    final subj = (subject == null || subject == 'Tất cả') ? null : subject;
    if (_state.selectedSubject == subj) return;
    _state = _state.copyWith(selectedSubject: subj, clearSubject: subj == null);
    notifyListeners();
    _initStream();
  }

  /// Đảo chiều sắp xếp
  void toggleSortOrder() {
    _state = _state.copyWith(isAscending: !_state.isAscending);
    notifyListeners();
    _initStream();
  }

  /// Xóa toàn bộ bộ lọc
  void clearFilters() {
    _state = _state.copyWith(
      searchQuery: '',
      clearCategory: true,
      clearSubject: true,
      isAscending: false,
    );
    notifyListeners();
    _initStream();
  }

  // ==========================================
  // THẨM ĐỊNH TÍNH HỢP LỆ (VALIDATION)
  // ==========================================

  String? validateTitle(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Tiêu đề tài liệu không được để trống';
    }
    if (value.trim().length < 2) {
      return 'Tiêu đề phải có tối thiểu 2 ký tự';
    }
    if (value.trim().length > 200) {
      return 'Tiêu đề không được vượt quá 200 ký tự';
    }
    return null;
  }

  String? validateSubject(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Môn học không được để trống';
    }
    return null;
  }

  String? validateCategory(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Danh mục không được để trống';
    }
    return null;
  }

  String? validateFileName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Tên tệp tin không được để trống';
    }
    return null;
  }

  String? validateFileType(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Loại tệp không được để trống';
    }
    return null;
  }

  // ==========================================
  // CÁC THAO TÁC CRUD NGHIỆP VỤ
  // ==========================================

  /// Thêm tài liệu mới
  Future<bool> createDocument({
    required String title,
    String? description,
    required String subject,
    required String category,
    required String fileName,
    String? filePath,
    required String fileType,
    int fileSize = 0,
    bool isFavorite = false,
  }) async {
    // 1. Thẩm định dữ liệu đầu vào
    final titleErr = validateTitle(title);
    if (titleErr != null) {
      _setErrorMessage(titleErr);
      return false;
    }
    final subjectErr = validateSubject(subject);
    if (subjectErr != null) {
      _setErrorMessage(subjectErr);
      return false;
    }
    final categoryErr = validateCategory(category);
    if (categoryErr != null) {
      _setErrorMessage(categoryErr);
      return false;
    }
    final fileErr = validateFileName(fileName);
    if (fileErr != null) {
      _setErrorMessage(fileErr);
      return false;
    }

    try {
      final now = DateTime.now();
      final newDoc = DocumentsCompanion(
        id: drift.Value(_uuid.v4()),
        title: drift.Value(title.trim()),
        description: drift.Value(description?.trim()),
        subject: drift.Value(subject.trim()),
        category: drift.Value(category.trim()),
        fileName: drift.Value(fileName.trim()),
        filePath: drift.Value(filePath?.trim()),
        fileType: drift.Value(fileType.trim().toUpperCase()),
        fileSize: drift.Value(fileSize),
        isFavorite: drift.Value(isFavorite),
        createdAt: drift.Value(now),
        updatedAt: drift.Value(now),
      );

      await repository.addDocument(newDoc);
      _setSuccessMessage('Thêm tài liệu "$title" thành công!');
      return true;
    } catch (e) {
      _setErrorMessage('Lỗi khi thêm tài liệu: $e');
      return false;
    }
  }

  /// Sửa thông tin tài liệu hiện có
  Future<bool> updateDocument({
    required String id,
    required String title,
    String? description,
    required String subject,
    required String category,
    required String fileName,
    String? filePath,
    required String fileType,
    int fileSize = 0,
    bool isFavorite = false,
    required DateTime createdAt,
  }) async {
    final titleErr = validateTitle(title);
    if (titleErr != null) {
      _setErrorMessage(titleErr);
      return false;
    }
    final subjectErr = validateSubject(subject);
    if (subjectErr != null) {
      _setErrorMessage(subjectErr);
      return false;
    }
    final categoryErr = validateCategory(category);
    if (categoryErr != null) {
      _setErrorMessage(categoryErr);
      return false;
    }
    final fileErr = validateFileName(fileName);
    if (fileErr != null) {
      _setErrorMessage(fileErr);
      return false;
    }

    try {
      final updatedDoc = DocumentsCompanion(
        id: drift.Value(id),
        title: drift.Value(title.trim()),
        description: drift.Value(description?.trim()),
        subject: drift.Value(subject.trim()),
        category: drift.Value(category.trim()),
        fileName: drift.Value(fileName.trim()),
        filePath: drift.Value(filePath?.trim()),
        fileType: drift.Value(fileType.trim().toUpperCase()),
        fileSize: drift.Value(fileSize),
        isFavorite: drift.Value(isFavorite),
        createdAt: drift.Value(createdAt),
        updatedAt: drift.Value(DateTime.now()),
      );

      final success = await repository.updateDocument(updatedDoc);
      if (success) {
        _setSuccessMessage('Cập nhật tài liệu "$title" thành công!');
        return true;
      } else {
        _setErrorMessage('Không tìm thấy tài liệu để cập nhật');
        return false;
      }
    } catch (e) {
      _setErrorMessage('Lỗi khi cập nhật tài liệu: $e');
      return false;
    }
  }

  /// Xóa tài liệu
  Future<bool> deleteDocument(String id) async {
    try {
      final success = await repository.deleteDocument(id);
      if (success) {
        _setSuccessMessage('Đã xóa tài liệu thành công!');
        return true;
      } else {
        _setErrorMessage('Không thể xóa tài liệu');
        return false;
      }
    } catch (e) {
      _setErrorMessage('Lỗi khi xóa tài liệu: $e');
      return false;
    }
  }

  /// Đánh dấu yêu thích / quan trọng
  Future<void> toggleFavorite(String id, bool currentStatus) async {
    try {
      await repository.toggleFavorite(id, currentStatus);
    } catch (e) {
      _setErrorMessage('Lỗi khi cập nhật yêu thích: $e');
    }
  }

  void _setErrorMessage(String message) {
    _state = _state.copyWith(errorMessage: message, clearSuccess: true);
    notifyListeners();
  }

  void _setSuccessMessage(String message) {
    _state = _state.copyWith(successMessage: message, clearError: true);
    notifyListeners();
  }

  void clearMessages() {
    _state = _state.copyWith(clearError: true, clearSuccess: true);
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
