import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quan_ly_tai_lieu_hoc_tap/data/database/app_database.dart';
import 'package:quan_ly_tai_lieu_hoc_tap/data/database/daos/documents_dao.dart';
import 'package:quan_ly_tai_lieu_hoc_tap/data/repositories/document_repository_impl.dart';
import 'package:quan_ly_tai_lieu_hoc_tap/logic/controllers/document_controller.dart';

void main() {
  late AppDatabase db;
  late DocumentsDao dao;
  late DocumentRepositoryImpl repository;
  late DocumentController controller;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    dao = DocumentsDao(db);
    repository = DocumentRepositoryImpl(dao);
    controller = DocumentController(repository: repository);
  });

  tearDown(() async {
    controller.dispose();
    await db.close();
  });

  group('Business Logic & State Layer Tests (DocumentController)', () {
    test('1. Thẩm định quy tắc nghiệp vụ dữ liệu đầu vào (Validation)', () {
      // Test validateTitle
      expect(controller.validateTitle(null), isNotNull);
      expect(controller.validateTitle(''), isNotNull);
      expect(controller.validateTitle('   '), isNotNull);
      expect(controller.validateTitle('A'), isNotNull); // < 2 ký tự
      expect(controller.validateTitle('Giáo trình Flutter'), isNull); // Hợp lệ

      // Test validateSubject
      expect(controller.validateSubject(null), isNotNull);
      expect(controller.validateSubject(''), isNotNull);
      expect(controller.validateSubject('Lập trình Di động'), isNull);

      // Test validateCategory
      expect(controller.validateCategory(null), isNotNull);
      expect(controller.validateCategory(''), isNotNull);
      expect(controller.validateCategory('Giáo trình'), isNull);

      // Test validateFileName
      expect(controller.validateFileName(null), isNotNull);
      expect(controller.validateFileName(''), isNotNull);
      expect(controller.validateFileName('tailieu.pdf'), isNull);
    });

    test(
      '2. Thêm tài liệu mới qua Controller và tự động cập nhật State',
      () async {
        final success = await controller.createDocument(
          title: 'Giáo trình Cơ sở Dữ liệu',
          description: 'Tài liệu học tập CSDL quan hệ',
          subject: 'Cơ sở Dữ liệu',
          category: 'Giáo trình',
          fileName: 'csdl.pdf',
          fileType: 'PDF',
          fileSize: 2048000,
          isFavorite: true,
        );

        expect(success, isTrue);
        expect(controller.errorMessage, isNull);
        expect(controller.successMessage, contains('thành công'));

        // Đợi reactive stream cập nhật
        await Future<void>.delayed(const Duration(milliseconds: 100));

        expect(controller.documents.length, 1);
        final doc = controller.documents.first;
        expect(doc.title, 'Giáo trình Cơ sở Dữ liệu');
        expect(doc.subject, 'Cơ sở Dữ liệu');
        expect(doc.isFavorite, isTrue);
      },
    );

    test(
      '3. Từ chối thêm tài liệu khi dữ liệu không hợp lệ (Validation Guard)',
      () async {
        final success = await controller.createDocument(
          title: '', // Lỗi: rỗng
          subject: 'Môn học',
          category: 'Danh mục',
          fileName: 'file.pdf',
          fileType: 'PDF',
        );

        expect(success, isFalse);
        expect(controller.errorMessage, isNotNull);
        expect(controller.documents, isEmpty);
      },
    );

    test('4. Sửa tài liệu qua Controller (Update Flow)', () async {
      await controller.createDocument(
        title: 'Tên gốc',
        subject: 'Môn học 1',
        category: 'Giáo trình',
        fileName: 'file1.pdf',
        fileType: 'PDF',
      );

      await Future<void>.delayed(const Duration(milliseconds: 100));
      final original = controller.documents.first;

      final updateSuccess = await controller.updateDocument(
        id: original.id,
        title: 'Tên đã cập nhật',
        subject: 'Môn học 2',
        category: 'Slide',
        fileName: 'file_updated.pptx',
        fileType: 'PPTX',
        createdAt: original.createdAt,
      );

      expect(updateSuccess, isTrue);

      await Future<void>.delayed(const Duration(milliseconds: 100));
      final updated = controller.documents.first;
      expect(updated.title, 'Tên đã cập nhật');
      expect(updated.subject, 'Môn học 2');
      expect(updated.category, 'Slide');
      expect(updated.fileType, 'PPTX');
    });

    test('5. Xóa tài liệu qua Controller (Delete Flow)', () async {
      await controller.createDocument(
        title: 'Tài liệu sẽ bị xóa',
        subject: 'Môn học',
        category: 'Giáo trình',
        fileName: 'delete.pdf',
        fileType: 'PDF',
      );

      await Future<void>.delayed(const Duration(milliseconds: 100));
      expect(controller.documents.length, 1);
      final docId = controller.documents.first.id;

      final deleteSuccess = await controller.deleteDocument(docId);
      expect(deleteSuccess, isTrue);

      await Future<void>.delayed(const Duration(milliseconds: 100));
      expect(controller.documents, isEmpty);
    });

    test('6. Tìm kiếm và Lọc qua Controller (Filter & Search State)', () async {
      await controller.createDocument(
        title: 'Flutter Cơ bản',
        subject: 'Lập trình Flutter',
        category: 'Giáo trình',
        fileName: 'flutter_basic.pdf',
        fileType: 'PDF',
      );
      await controller.createDocument(
        title: 'Kiến trúc Phần mềm Nâng cao',
        subject: 'Kiến trúc Phần mềm',
        category: 'Slide bài giảng',
        fileName: 'arch_adv.pptx',
        fileType: 'PPTX',
      );

      await Future<void>.delayed(const Duration(milliseconds: 100));
      expect(controller.documents.length, 2);

      // Tìm kiếm theo từ khóa
      controller.setSearchQuery('Flutter');
      await Future<void>.delayed(const Duration(milliseconds: 100));
      expect(controller.documents.length, 1);
      expect(controller.documents.first.title, contains('Flutter'));

      // Đặt lại bộ lọc
      controller.clearFilters();
      await Future<void>.delayed(const Duration(milliseconds: 100));
      expect(controller.documents.length, 2);

      // Lọc theo danh mục
      controller.setSelectedCategory('Slide bài giảng');
      await Future<void>.delayed(const Duration(milliseconds: 100));
      expect(controller.documents.length, 1);
      expect(controller.documents.first.category, 'Slide bài giảng');
    });
  });
}
