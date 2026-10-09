import 'package:flutter_test/flutter_test.dart';
import 'package:quan_ly_tai_lieu_hoc_tap/data/models/cloud_document.dart';
import 'package:quan_ly_tai_lieu_hoc_tap/logic/controllers/auth_controller.dart';

void main() {
  group('CloudDocument Model Tests', () {
    test('1. Chuyển đổi Firestore Map sang CloudDocument và ngược lại', () {
      final now = DateTime.now();
      final map = {
        'title': 'Giáo trình Giải tích 1',
        'description': 'Tài liệu đại cương môn Giải tích',
        'subject': 'Toán cao cấp',
        'category': 'Giáo trình',
        'fileName': 'giai_tich_1.pdf',
        'fileType': 'PDF',
        'fileSize': 1048576,
        'storagePath': 'users/user123/documents/doc1/giai_tich_1.pdf',
        'downloadUrl': 'https://firebasestorage.googleapis.com/...',
        'ownerUid': 'user123',
        'isFavorite': true,
        'createdAt': now.toIso8601String(),
        'updatedAt': now.toIso8601String(),
      };

      final doc = CloudDocument.fromFirestoreMap(map, 'doc1');

      expect(doc.id, 'doc1');
      expect(doc.title, 'Giáo trình Giải tích 1');
      expect(doc.subject, 'Toán cao cấp');
      expect(doc.ownerUid, 'user123');
      expect(doc.fileSize, 1048576);
      expect(doc.storagePath, 'users/user123/documents/doc1/giai_tich_1.pdf');
      expect(doc.isFavorite, isTrue);

      final outMap = doc.toFirestore();
      expect(outMap['title'], 'Giáo trình Giải tích 1');
      expect(outMap['titleLowercase'], 'giáo trình giải tích 1');
      expect(outMap['ownerUid'], 'user123');
      expect(
        outMap['storagePath'],
        'users/user123/documents/doc1/giai_tich_1.pdf',
      );
    });

    test('2. Chuyển đổi qua lại giữa CloudDocument và Drift Companion', () {
      final now = DateTime.now();
      final doc = CloudDocument(
        id: 'doc-sync-1',
        title: 'Slide Thiết kế Kiến trúc',
        subject: 'Kiến trúc Phần mềm',
        category: 'Slide bài giảng',
        fileName: 'architecture.pptx',
        fileType: 'PPTX',
        fileSize: 2048,
        storagePath: 'users/uid1/documents/doc-sync-1/architecture.pptx',
        ownerUid: 'uid1',
        createdAt: now,
        updatedAt: now,
      );

      final companion = doc.toDriftCompanion();
      expect(companion.id.value, 'doc-sync-1');
      expect(companion.title.value, 'Slide Thiết kế Kiến trúc');
      expect(companion.fileType.value, 'PPTX');
      expect(companion.fileName.value, 'architecture.pptx');
    });
  });

  group('AuthController Tests', () {
    test('1. Khởi tạo trạng thái mặc định khi không truyền tham số', () {
      final controller = AuthController();
      expect(controller.isAuthenticated, isFalse);
      expect(controller.isUnauthenticated, isTrue);
      expect(controller.currentUid, isNull);
      expect(controller.status, AuthStatus.unauthenticated);
    });

    test('2. Khởi tạo với testUid cho môi trường thử nghiệm', () {
      final controller = AuthController(testUid: 'test-student-uid');
      expect(controller.isAuthenticated, isTrue);
      expect(controller.isUnauthenticated, isFalse);
      expect(controller.currentUid, 'test-student-uid');
      expect(controller.status, AuthStatus.authenticated);
    });

    test('3. Đăng xuất tài khoản test', () async {
      final controller = AuthController(testUid: 'test-student-uid');
      expect(controller.isAuthenticated, isTrue);

      await controller.signOut();
      expect(controller.isAuthenticated, isFalse);
      expect(controller.currentUid, isNull);
      expect(controller.status, AuthStatus.unauthenticated);
    });
  });
}
