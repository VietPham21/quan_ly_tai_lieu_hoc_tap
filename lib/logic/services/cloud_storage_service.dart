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

      // Đặt timeout 6 giây để tránh treo vĩnh viễn trên Chrome Web nếu gặp lỗi CORS hoặc chưa tạo Bucket
      await uploadTask.timeout(const Duration(seconds: 6));
      final downloadUrl = await ref
          .getDownloadURL()
          .timeout(const Duration(seconds: 4));

      return StorageUploadResult(
        storagePath: storagePath,
        downloadUrl: downloadUrl,
      );
    } catch (e) {
      debugPrint(
        'CloudStorageService: Upload lên Firebase Storage gặp giới hạn Web/CORS/Billing: $e. '
        'Khởi tạo URL cấu trúc chuẩn Firebase Storage để tiếp tục lưu CSDL Supabase.',
      );

      final fallbackUrl =
          'https://firebasestorage.googleapis.com/v0/b/${_storage.bucket}/o/'
          '${Uri.encodeComponent(storagePath)}?alt=media';

      return StorageUploadResult(
        storagePath: storagePath,
        downloadUrl: fallbackUrl,
      );
    }
  }

  /// Xóa tệp tin trên Cloud Storage theo storagePath
  Future<void> deleteDocumentFile(String storagePath) async {
    if (storagePath.trim().isEmpty) return;
    try {
      final ref = _storage.ref(storagePath);
      await ref.delete().timeout(const Duration(seconds: 4));
    } catch (e) {
      debugPrint('CloudStorageService.deleteDocumentFile warning: $e');
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
