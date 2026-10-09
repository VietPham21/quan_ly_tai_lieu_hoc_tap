import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

/// Kết quả của thao tác upload tệp lên Cloud Storage
class StorageUploadResult {
  final String storagePath;
  final String downloadUrl;

  const StorageUploadResult({
    required this.storagePath,
    required this.downloadUrl,
  });
}

/// Dịch vụ tải lên, tải về và xóa tệp tin trên Cloud Storage for Firebase.
/// Tương thích 100% với Web (sử dụng Uint8List bytes và putData).
class CloudStorageService {
  final FirebaseStorage _storage;

  CloudStorageService({FirebaseStorage? storage})
    : _storage = storage ?? FirebaseStorage.instance;

  FirebaseStorage get storage => _storage;

  /// Tải tệp tin lên Cloud Storage với đường dẫn phân cấp theo người dùng:
  /// users/{uid}/documents/{documentId}/{fileName}
  Future<StorageUploadResult> uploadDocumentFile({
    required String uid,
    required String documentId,
    required String fileName,
    required Uint8List bytes,
    String? mimeType,
    void Function(double progress)? onProgress,
  }) async {
    final sanitizedFileName = fileName.trim().replaceAll(
      RegExp(r'[^\w\.-]'),
      '_',
    );
    final storagePath = 'users/$uid/documents/$documentId/$sanitizedFileName';
    final ref = _storage.ref(storagePath);

    final metadata = SettableMetadata(
      contentType: mimeType ?? _guessMimeType(fileName),
      customMetadata: {
        'ownerUid': uid,
        'documentId': documentId,
        'originalFileName': fileName,
      },
    );

    try {
      final uploadTask = ref.putData(bytes, metadata);

      if (onProgress != null) {
        uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
          if (snapshot.totalBytes > 0) {
            final progress = snapshot.bytesTransferred / snapshot.totalBytes;
            onProgress(progress);
          }
        });
      }

      await uploadTask;
      final downloadUrl = await ref.getDownloadURL();

      return StorageUploadResult(
        storagePath: storagePath,
        downloadUrl: downloadUrl,
      );
    } on FirebaseException catch (e) {
      debugPrint(
        'CloudStorageService.uploadDocumentFile FirebaseException: [${e.code}] ${e.message}',
      );
      if (e.code == 'bucket-not-found' || e.code == 'project-not-found') {
        throw Exception(
          'Cloud Storage bucket chưa được khởi tạo trên Firebase Console. '
          'Vui lòng kích hoạt Storage tại Firebase Console (yêu cầu gói Blaze). Chi tiết lỗi: ${e.message}',
        );
      } else if (e.code == 'unauthorized' || e.code == 'permission-denied') {
        throw Exception(
          'Không có quyền truy cập Cloud Storage. Vui lòng kiểm tra Storage Security Rules. Chi tiết lỗi: ${e.message}',
        );
      }
      rethrow;
    } catch (e) {
      debugPrint('CloudStorageService.uploadDocumentFile Error: $e');
      rethrow;
    }
  }

  /// Xóa tệp tin trên Cloud Storage theo storagePath
  Future<void> deleteDocumentFile(String storagePath) async {
    if (storagePath.trim().isEmpty) return;
    try {
      final ref = _storage.ref(storagePath);
      await ref.delete();
    } on FirebaseException catch (e) {
      if (e.code == 'object-not-found') {
        // Nếu file không tồn tại trên storage thì coi như đã xóa xong
        debugPrint('File $storagePath không tồn tại trên Storage, bỏ qua.');
        return;
      }
      debugPrint(
        'CloudStorageService.deleteDocumentFile Error: [${e.code}] ${e.message}',
      );
      rethrow;
    } catch (e) {
      debugPrint('CloudStorageService.deleteDocumentFile Error: $e');
      rethrow;
    }
  }

  static String _guessMimeType(String fileName) {
    final ext = fileName.split('.').last.toLowerCase();
    switch (ext) {
      case 'pdf':
        return 'application/pdf';
      case 'doc':
      case 'docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case 'ppt':
      case 'pptx':
        return 'application/vnd.openxmlformats-officedocument.presentationml.presentation';
      case 'xls':
      case 'xlsx':
        return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
      case 'zip':
        return 'application/zip';
      case 'txt':
        return 'text/plain';
      default:
        return 'application/octet-stream';
    }
  }
}
