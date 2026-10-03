import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quan_ly_tai_lieu_hoc_tap/data/database/app_database.dart';
import 'package:quan_ly_tai_lieu_hoc_tap/data/database/daos/documents_dao.dart';

void main() {
  late AppDatabase database;
  late DocumentsDao dao;

  setUp(() {
    // Sử dụng in-memory database để test cô lập, độc lập với file CSDL thật
    database = AppDatabase(NativeDatabase.memory());
    dao = DocumentsDao(database);
  });

  tearDown(() async {
    await database.close();
  });

  group('Data Access & Persistence Layer Tests (DocumentsDao)', () {
    test('1. Thêm tài liệu mới vào SQLite thành công (INSERT)', () async {
      final doc = DocumentsCompanion.insert(
        id: 'test-doc-01',
        title: 'Giáo trình Kiến trúc Phần mềm',
        subject: 'Kiến trúc Phần mềm',
        category: 'Giáo trình',
        fileName: 'ktpm.pdf',
        fileType: 'PDF',
        fileSize: const drift.Value(2048),
      );

      final rowId = await dao.insertDocument(doc);
      expect(rowId, greaterThan(0));

      final fetched = await dao.getDocumentById('test-doc-01');
      expect(fetched, isNotNull);
      expect(fetched!.title, 'Giáo trình Kiến trúc Phần mềm');
      expect(fetched.subject, 'Kiến trúc Phần mềm');
      expect(fetched.fileType, 'PDF');
      expect(fetched.fileSize, 2048);
    });

    test('2. Lấy danh sách toàn bộ tài liệu (SELECT ALL)', () async {
      await dao.insertDocument(
        DocumentsCompanion.insert(
          id: 'doc-1',
          title: 'Toán rời rạc',
          subject: 'Toán',
          category: 'Giáo trình',
          fileName: 'toan.pdf',
          fileType: 'PDF',
        ),
      );
      await dao.insertDocument(
        DocumentsCompanion.insert(
          id: 'doc-2',
          title: 'Vật lý đại cương',
          subject: 'Vật lý',
          category: 'Slide',
          fileName: 'vatly.pptx',
          fileType: 'PPTX',
        ),
      );

      final allDocs = await dao.getAllDocuments();
      expect(allDocs.length, 2);
    });

    test('3. Cập nhật thông tin tài liệu (UPDATE)', () async {
      final now = DateTime.now();
      await dao.insertDocument(
        DocumentsCompanion.insert(
          id: 'doc-update',
          title: 'Tiêu đề cũ',
          subject: 'Flutter',
          category: 'Giáo trình',
          fileName: 'flutter_old.pdf',
          fileType: 'PDF',
          createdAt: drift.Value(now),
          updatedAt: drift.Value(now),
        ),
      );

      final updatedDoc = DocumentsCompanion(
        id: const drift.Value('doc-update'),
        title: const drift.Value('Tiêu đề mới đã chỉnh sửa'),
        subject: const drift.Value('Flutter Nâng cao'),
        category: const drift.Value('Slide bài giảng'),
        fileName: const drift.Value('flutter_new.pptx'),
        fileType: const drift.Value('PPTX'),
        fileSize: const drift.Value(4096),
        isFavorite: const drift.Value(true),
        createdAt: drift.Value(now),
        updatedAt: drift.Value(now.add(const Duration(minutes: 5))),
      );

      final success = await dao.updateDocument(updatedDoc);
      expect(success, isTrue);

      final fetched = await dao.getDocumentById('doc-update');
      expect(fetched!.title, 'Tiêu đề mới đã chỉnh sửa');
      expect(fetched.subject, 'Flutter Nâng cao');
      expect(fetched.category, 'Slide bài giảng');
      expect(fetched.isFavorite, isTrue);
    });

    test('4. Xóa tài liệu khỏi CSDL (DELETE)', () async {
      await dao.insertDocument(
        DocumentsCompanion.insert(
          id: 'doc-delete',
          title: 'Tài liệu cần xóa',
          subject: 'Lịch sử',
          category: 'Tham khảo',
          fileName: 'lich_su.pdf',
          fileType: 'PDF',
        ),
      );

      final deleteCount = await dao.deleteDocument('doc-delete');
      expect(deleteCount, 1);

      final fetched = await dao.getDocumentById('doc-delete');
      expect(fetched, isNull);
    });

    test(
      '5. Tìm kiếm tài liệu theo từ khóa và bộ lọc (SEARCH & FILTER)',
      () async {
        await dao.insertDocument(
          DocumentsCompanion.insert(
            id: 's-1',
            title: 'Lập trình ứng dụng Android với Flutter',
            subject: 'Lập trình Di động',
            category: 'Giáo trình',
            fileName: 'flutter_android.pdf',
            fileType: 'PDF',
          ),
        );
        await dao.insertDocument(
          DocumentsCompanion.insert(
            id: 's-2',
            title: 'Nhập môn Cơ sở Dữ liệu SQL Server',
            subject: 'Cơ sở Dữ liệu',
            category: 'Giáo trình',
            fileName: 'csdl_sql.pdf',
            fileType: 'PDF',
          ),
        );
        await dao.insertDocument(
          DocumentsCompanion.insert(
            id: 's-3',
            title: 'Đề thi Kết thúc học phần Di động',
            subject: 'Lập trình Di động',
            category: 'Đề thi & Đáp án',
            fileName: 'de_thi_dd.docx',
            fileType: 'DOCX',
          ),
        );

        // Tìm theo từ khóa "Flutter"
        final searchResult1 = await dao
            .watchSearchDocuments(query: 'Flutter')
            .first;
        expect(searchResult1.length, 1);
        expect(searchResult1.first.title, contains('Flutter'));

        // Tìm theo môn học "Lập trình Di động"
        final searchResult2 = await dao
            .watchSearchDocuments(subject: 'Lập trình Di động')
            .first;
        expect(searchResult2.length, 2);

        // Tìm kết hợp từ khóa "Đề thi" và danh mục "Đề thi & Đáp án"
        final searchResult3 = await dao
            .watchSearchDocuments(query: 'Đề thi', category: 'Đề thi & Đáp án')
            .first;
        expect(searchResult3.length, 1);
        expect(searchResult3.first.id, 's-3');

        // Tìm kiếm với từ khóa không tồn tại
        final searchResult4 = await dao
            .watchSearchDocuments(query: 'Từ khóa không có')
            .first;
        expect(searchResult4, isEmpty);
      },
    );

    test(
      '6. Kiểm tra luồng phản ứng tự động (REACTIVE STREAM WATCH)',
      () async {
        final history = <List<Document>>[];
        final subscription = dao.watchAllDocuments().listen(history.add);

        // Chờ stream phát ra giá trị ban đầu (CSDL rỗng)
        await Future<void>.delayed(const Duration(milliseconds: 50));
        expect(history.isNotEmpty, isTrue);
        expect(history.last, isEmpty);

        // Thêm bản ghi mới -> Stream tự động phát lại
        await dao.insertDocument(
          DocumentsCompanion.insert(
            id: 'stream-test-01',
            title: 'Tài liệu Reactive Test',
            subject: 'Kiến trúc Phần mềm',
            category: 'Giáo trình',
            fileName: 'reactive.pdf',
            fileType: 'PDF',
          ),
        );
        await Future<void>.delayed(const Duration(milliseconds: 50));
        expect(history.length, greaterThanOrEqualTo(2));
        expect(history.last.length, 1);
        expect(history.last.first.id, 'stream-test-01');

        // Xóa bản ghi -> Stream tự động phát lại danh sách rỗng
        await dao.deleteDocument('stream-test-01');
        await Future<void>.delayed(const Duration(milliseconds: 50));
        expect(history.length, greaterThanOrEqualTo(3));
        expect(history.last, isEmpty);

        await subscription.cancel();
      },
    );
  });
}
