// ignore_for_file: prefer_initializing_formals

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../../data/models/cloud_document.dart';
import '../../data/models/document_permission.dart';
import '../../data/repositories/document_repository.dart';
import '../../data/repositories/firestore_document_repository.dart';
import '../../data/repositories/supabase_document_repository.dart';
import '../services/cloud_storage_service.dart';
import '../states/document_state.dart';

/// Business Logic & State Controller cho Quản lý Tài liệu Học tập.
/// Tích hợp Supabase (CSDL & Permissions) + Firebase Storage (Tệp tin vật lý) + Offline Local.
class DocumentController extends ChangeNotifier {
  final SupabaseDocumentRepository? _supabaseRepository;
  final FirestoreDocumentRepository? _firestoreRepository;
  final CloudStorageService? _storageService;
  final DocumentRepository? _localRepository;
  final Uuid _uuid;

  String? _currentUid;
  DocumentState _state = const DocumentState(status: DocumentStatus.loading);
  StreamSubscription<List<dynamic>>? _subscription;

  DocumentController({
    SupabaseDocumentRepository? supabaseRepository,
    FirestoreDocumentRepository? firestoreRepository,
    CloudStorageService? storageService,
    DocumentRepository? repository,
    String? currentUid,
    Uuid? uuid,
  }) : _supabaseRepository = supabaseRepository,
       _firestoreRepository = firestoreRepository,
       _storageService = storageService,
       _localRepository = repository,
       _currentUid = currentUid,
       _uuid = uuid ?? const Uuid() {
    _initStream();
  }

  DocumentState get state => _state;
  List<CloudDocument> get documents => _state.documents;
  bool get isLoading => _state.isLoading;
  bool get hasError => _state.hasError;
  String? get errorMessage => _state.errorMessage;
  String? get successMessage => _state.successMessage;
  double? get uploadProgress => _state.uploadProgress;
  String? get currentUid => _currentUid;

  /// Cập nhật người dùng hiện tại khi trạng thái đăng nhập thay đổi
  void updateUser(String? uid) {
    if (_currentUid == uid) return;
    _currentUid = uid;
    _initStream();
  }

  void _initStream() {
    _subscription?.cancel();

    final uid = _currentUid;
    final supabaseRepo = _supabaseRepository;
    final firestoreRepo = _firestoreRepository;
    final localRepo = _localRepository;

    // 1. Chế độ Supabase Cloud: Khi đã cấu hình Supabase và đăng nhập
    if (uid != null && uid.isNotEmpty && supabaseRepo != null && supabaseRepo.isAvailable) {
      _subscription = supabaseRepo
          .watchUserDocuments(
            uid: uid,
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
                errorMessage: 'Lỗi đồng bộ dữ liệu Supabase: $e',
              );
              notifyListeners();
            },
          );
      return;
    }

    // 2. Chế độ Firebase Firestore Cloud
    if (uid != null && uid.isNotEmpty && firestoreRepo != null) {
      _subscription = firestoreRepo
          .watchUserDocuments(
            uid: uid,
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
                errorMessage: 'Lỗi đồng bộ dữ liệu Cloud Firestore: $e',
              );
              notifyListeners();
            },
          );
      return;
    }

    // 2. Chế độ Local: Khi có Local Repository (Drift SQLite) phục vụ kiểm thử / offline
    if (localRepo != null) {
      _subscription = localRepo
          .watchSearchDocuments(
            query: _state.searchQuery,
            category: _state.selectedCategory,
            subject: _state.selectedSubject,
            ascending: _state.isAscending,
          )
          .listen(
            (driftDocs) {
              final cloudDocs = driftDocs
                  .map((d) => CloudDocument.fromDrift(d))
                  .toList();
              _state = _state.copyWith(
                status: DocumentStatus.success,
                documents: cloudDocs,
                clearError: true,
              );
              notifyListeners();
            },
            onError: (e) {
              _state = _state.copyWith(
                status: DocumentStatus.error,
                errorMessage: 'Lỗi tải luồng dữ liệu cục bộ: $e',
              );
              notifyListeners();
            },
          );
      return;
    }

    // 3. Chưa đăng nhập và không có Local Repo
    _state = _state.copyWith(
      status: DocumentStatus.success,
      documents: const [],
      clearError: true,
    );
    notifyListeners();
  }

  /// Cập nhật từ khóa tìm kiếm
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
  // CÁC THAO TÁC CRUD NGHIỆP VỤ (CLOUD & LOCAL)
  // ==========================================

  /// Thêm tài liệu mới (Hỗ trợ upload file nhị phân lên Cloud Storage nếu có)
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
    Uint8List? fileBytes,
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

    final docId = _uuid.v4();
    final now = DateTime.now();
    String? storagePath;
    String? fileUrl;

    _state = _state.copyWith(uploadProgress: 0.0);
    notifyListeners();

    final uid = _currentUid;
    final supabaseRepo = _supabaseRepository;
    final firestoreRepo = _firestoreRepository;
    final storageSvc = _storageService;
    final localRepo = _localRepository;

    // 1. Thao tác trên Cloud (khi đã đăng nhập)
    if (uid != null && uid.isNotEmpty && ((supabaseRepo != null && supabaseRepo.isAvailable) || firestoreRepo != null)) {
      try {
        // Bước 1: Upload file lên Firebase Storage nếu người dùng đã chọn file
        if (fileBytes != null && storageSvc != null) {
          _state = _state.copyWith(uploadProgress: 0.3);
          notifyListeners();

          final uploadResult = await storageSvc.uploadDocumentFile(
            uid: uid,
            documentId: docId,
            fileName: fileName,
            bytes: fileBytes,
            onProgress: (progress) {
              _state = _state.copyWith(uploadProgress: progress);
              notifyListeners();
            },
          );
          storagePath = uploadResult.storagePath;
          fileUrl = uploadResult.downloadUrl;

          _state = _state.copyWith(uploadProgress: 1.0);
          notifyListeners();
        }

        // Bước 2: Tạo đối tượng CloudDocument
        final newDoc = CloudDocument(
          id: docId,
          title: title.trim(),
          description: description?.trim(),
          subject: subject.trim(),
          category: category.trim(),
          fileName: fileName.trim(),
          filePath: filePath?.trim(),
          fileType: fileType.trim().toUpperCase(),
          fileSize: fileBytes != null ? fileBytes.lengthInBytes : fileSize,
          storagePath: storagePath,
          fileUrl: fileUrl,
          ownerUid: uid,
          isFavorite: isFavorite,
          createdAt: now,
          updatedAt: now,
        );

        // Bước 3: Ghi Metadata vào Supabase (hoặc Firestore fallback)
        try {
          if (supabaseRepo != null && supabaseRepo.isAvailable) {
            await supabaseRepo.addDocument(newDoc);
          } else if (firestoreRepo != null) {
            await firestoreRepo.addDocument(newDoc);
          }
        } catch (dbError) {
          // CƠ CHẾ BÙ TRỪ: Nếu ghi CSDL thất bại, tự động dọn dẹp file Storage vừa tải lên
          if (storagePath != null && storageSvc != null) {
            await storageSvc.deleteDocumentFile(storagePath);
          }
          rethrow;
        }

        _state = _state.copyWith(clearUploadProgress: true);
        _setSuccessMessage('Đã thêm tài liệu "$title" lên Cloud thành công!');
        return true;
      } catch (e) {
        _state = _state.copyWith(clearUploadProgress: true);
        _setErrorMessage('Lỗi khi lưu tài liệu Cloud: $e');
        return false;
      }
    }

    // 2. Chế độ Fallback Local SQLite (cho Unit Test hoặc khi không có Cloud)
    if (localRepo != null) {
      try {
        final newDoc = CloudDocument(
          id: docId,
          title: title.trim(),
          description: description?.trim(),
          subject: subject.trim(),
          category: category.trim(),
          fileName: fileName.trim(),
          filePath: filePath?.trim(),
          fileType: fileType.trim().toUpperCase(),
          fileSize: fileBytes != null ? fileBytes.lengthInBytes : fileSize,
          ownerUid: '',
          isFavorite: isFavorite,
          createdAt: now,
          updatedAt: now,
        );

        await localRepo.addDocument(newDoc.toDriftCompanion());
        _state = _state.copyWith(clearUploadProgress: true);
        _setSuccessMessage('Thêm tài liệu "$title" thành công!');
        return true;
      } catch (e) {
        _state = _state.copyWith(clearUploadProgress: true);
        _setErrorMessage('Lỗi khi thêm tài liệu: $e');
        return false;
      }
    }

    _state = _state.copyWith(clearUploadProgress: true);
    _setErrorMessage(
      'Vui lòng đăng nhập bằng Google để lưu tài liệu lên Cloud.',
    );
    return false;
  }

  /// Sửa thông tin tài liệu hiện có (Hỗ trợ thay file mới nếu có)
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
    String? ownerUid,
    String? oldStoragePath,
    String? existingFileUrl,
    Uint8List? newFileBytes,
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

    String? storagePath = oldStoragePath;
    String? fileUrl = existingFileUrl;
    final now = DateTime.now();

    final uid = _currentUid;
    final supabaseRepo = _supabaseRepository;
    final firestoreRepo = _firestoreRepository;
    final storageSvc = _storageService;
    final localRepo = _localRepository;

    // 1. Thao tác Cloud
    if (uid != null && uid.isNotEmpty && ((supabaseRepo != null && supabaseRepo.isAvailable) || firestoreRepo != null)) {
      try {
        // Nếu người dùng chọn file mới: Upload file mới trước lên Firebase Storage
        if (newFileBytes != null && storageSvc != null) {
          _state = _state.copyWith(uploadProgress: 0.0);
          notifyListeners();

          final uploadResult = await storageSvc.uploadDocumentFile(
            uid: uid,
            documentId: id,
            fileName: fileName,
            bytes: newFileBytes,
            onProgress: (p) {
              _state = _state.copyWith(uploadProgress: p);
              notifyListeners();
            },
          );
          storagePath = uploadResult.storagePath;
          fileUrl = uploadResult.downloadUrl;
        }

        final updatedDoc = CloudDocument(
          id: id,
          title: title.trim(),
          description: description?.trim(),
          subject: subject.trim(),
          category: category.trim(),
          fileName: fileName.trim(),
          filePath: filePath?.trim(),
          fileType: fileType.trim().toUpperCase(),
          fileSize: newFileBytes != null
              ? newFileBytes.lengthInBytes
              : fileSize,
          storagePath: storagePath,
          fileUrl: fileUrl,
          ownerUid: (ownerUid != null && ownerUid.isNotEmpty) ? ownerUid : uid,
          isFavorite: isFavorite,
          createdAt: createdAt,
          updatedAt: now,
        );

        if (supabaseRepo != null && supabaseRepo.isAvailable) {
          await supabaseRepo.updateDocument(updatedDoc);
        } else if (firestoreRepo != null) {
          await firestoreRepo.updateDocument(updatedDoc);
        }

        // Sau khi cập nhật CSDL thành công, xóa file cũ trên Storage nếu đã upload file mới
        if (newFileBytes != null &&
            oldStoragePath != null &&
            oldStoragePath != storagePath &&
            storageSvc != null) {
          await storageSvc.deleteDocumentFile(oldStoragePath);
        }

        _state = _state.copyWith(clearUploadProgress: true);
        _setSuccessMessage('Cập nhật tài liệu "$title" thành công!');
        return true;
      } catch (e) {
        _state = _state.copyWith(clearUploadProgress: true);
        _setErrorMessage('Lỗi khi cập nhật tài liệu Cloud: $e');
        return false;
      }
    }

    // 2. Chế độ Local Fallback
    if (localRepo != null) {
      try {
        final updatedDoc = CloudDocument(
          id: id,
          title: title.trim(),
          description: description?.trim(),
          subject: subject.trim(),
          category: category.trim(),
          fileName: fileName.trim(),
          filePath: filePath?.trim(),
          fileType: fileType.trim().toUpperCase(),
          fileSize: newFileBytes != null
              ? newFileBytes.lengthInBytes
              : fileSize,
          ownerUid: '',
          isFavorite: isFavorite,
          createdAt: createdAt,
          updatedAt: now,
        );

        final success = await localRepo.updateDocument(
          updatedDoc.toDriftCompanion(),
        );
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

    _setErrorMessage('Vui lòng đăng nhập để cập nhật tài liệu.');
    return false;
  }

  /// Xóa tài liệu (Xóa cả file Storage và metadata Supabase/Firestore)
  Future<bool> deleteDocument(String id, {String? storagePath}) async {
    final uid = _currentUid;
    final supabaseRepo = _supabaseRepository;
    final firestoreRepo = _firestoreRepository;
    final storageSvc = _storageService;
    final localRepo = _localRepository;

    // 1. Thao tác Cloud
    if (uid != null && uid.isNotEmpty && ((supabaseRepo != null && supabaseRepo.isAvailable) || firestoreRepo != null)) {
      try {
        // Xóa file trên Firebase Storage nếu có
        if (storagePath != null &&
            storagePath.isNotEmpty &&
            storageSvc != null) {
          try {
            await storageSvc.deleteDocumentFile(storagePath);
          } catch (storageErr) {
            debugPrint(
              'Cảnh báo: Không thể xóa file trên Storage ($storagePath): $storageErr',
            );
          }
        }

        // Xóa metadata trong Supabase hoặc Firestore
        if (supabaseRepo != null && supabaseRepo.isAvailable) {
          await supabaseRepo.deleteDocument(docId: id);
        } else if (firestoreRepo != null) {
          await firestoreRepo.deleteDocument(uid: uid, docId: id);
        }
        _setSuccessMessage('Đã xóa tài liệu thành công!');
        return true;
      } catch (e) {
        _setErrorMessage('Lỗi khi xóa tài liệu trên Cloud: $e');
        return false;
      }
    }

    // 2. Chế độ Local Fallback
    if (localRepo != null) {
      try {
        final success = await localRepo.deleteDocument(id);
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

    _setErrorMessage('Không thể thực hiện xóa tài liệu.');
    return false;
  }

  /// Đổi trạng thái yêu thích
  Future<void> toggleFavorite(String id, bool currentStatus) async {
    final uid = _currentUid;
    final supabaseRepo = _supabaseRepository;
    final firestoreRepo = _firestoreRepository;
    final localRepo = _localRepository;

    if (uid != null && uid.isNotEmpty && ((supabaseRepo != null && supabaseRepo.isAvailable) || firestoreRepo != null)) {
      try {
        if (supabaseRepo != null && supabaseRepo.isAvailable) {
          await supabaseRepo.toggleFavorite(
            docId: id,
            currentStatus: currentStatus,
          );
        } else if (firestoreRepo != null) {
          await firestoreRepo.toggleFavorite(
            uid: uid,
            docId: id,
            currentStatus: currentStatus,
          );
        }
      } catch (e) {
        _setErrorMessage('Lỗi khi cập nhật yêu thích: $e');
      }
      return;
    }

    if (localRepo != null) {
      try {
        await localRepo.toggleFavorite(id, currentStatus);
      } catch (e) {
        _setErrorMessage('Lỗi khi cập nhật yêu thích: $e');
      }
    }
  }

  // ==========================================
  // QUẢN LÝ PHÂN QUYỀN & CHIA SẺ (SUPABASE PERMISSIONS)
  // ==========================================

  /// Cấp quyền chia sẻ tài liệu cho người dùng khác qua Email
  Future<bool> shareDocument({
    required String documentId,
    required String targetEmail,
    required String role, // 'viewer' hoặc 'editor'
  }) async {
    final supabaseRepo = _supabaseRepository;
    if (supabaseRepo == null || !supabaseRepo.isAvailable) {
      _setErrorMessage('Tính năng chia sẻ tài liệu yêu cầu kết nối Supabase.');
      return false;
    }

    try {
      await supabaseRepo.shareDocument(
        documentId: documentId,
        targetEmail: targetEmail,
        role: role,
      );
      _setSuccessMessage('Đã chia sẻ tài liệu thành công cho $targetEmail ($role)!');
      return true;
    } catch (e) {
      _setErrorMessage('Lỗi khi chia sẻ tài liệu: $e');
      return false;
    }
  }

  /// Lấy danh sách các quyền chia sẻ của một tài liệu
  Future<List<DocumentPermission>> getDocumentPermissions(
    String documentId,
  ) async {
    final supabaseRepo = _supabaseRepository;
    if (supabaseRepo == null || !supabaseRepo.isAvailable) {
      return [];
    }
    return await supabaseRepo.getDocumentPermissions(documentId);
  }

  /// Thu hồi quyền chia sẻ tài liệu
  Future<bool> revokePermission(String permissionId) async {
    final supabaseRepo = _supabaseRepository;
    if (supabaseRepo == null || !supabaseRepo.isAvailable) {
      return false;
    }

    try {
      await supabaseRepo.revokePermission(permissionId);
      _setSuccessMessage('Đã thu hồi quyền chia sẻ.');
      return true;
    } catch (e) {
      _setErrorMessage('Lỗi khi thu hồi quyền: $e');
      return false;
    }
  }

  /// Lấy danh sách người dùng trong hệ thống để chọn email chia sẻ
  Future<List<Map<String, dynamic>>> getAllRegisteredUsers() async {
    final supabaseRepo = _supabaseRepository;
    if (supabaseRepo == null || !supabaseRepo.isAvailable) {
      return [];
    }
    return await supabaseRepo.getAllUsers(excludeUid: _currentUid);
  }

  /// Lấy vai trò của user hiện tại đối với tài liệu ('owner', 'editor', 'viewer')
  Future<String> getUserRoleForDocument(CloudDocument doc) async {
    final uid = _currentUid;
    if (uid == null || uid.isEmpty) return 'viewer';
    if (doc.ownerUid == uid) return 'owner';

    final supabaseRepo = _supabaseRepository;
    if (supabaseRepo != null && supabaseRepo.isAvailable) {
      return await supabaseRepo.getUserRoleForDocument(
        documentId: doc.id,
        uid: uid,
        ownerUid: doc.ownerUid,
      );
    }
    return 'viewer';
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
