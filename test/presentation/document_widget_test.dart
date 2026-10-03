import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quan_ly_tai_lieu_hoc_tap/data/database/app_database.dart';
import 'package:quan_ly_tai_lieu_hoc_tap/data/database/daos/documents_dao.dart';
import 'package:quan_ly_tai_lieu_hoc_tap/data/repositories/document_repository_impl.dart';
import 'package:quan_ly_tai_lieu_hoc_tap/main.dart';
import 'package:quan_ly_tai_lieu_hoc_tap/presentation/widgets/confirmation_dialog.dart';
import 'package:quan_ly_tai_lieu_hoc_tap/presentation/widgets/empty_state_view.dart';

void main() {
  late AppDatabase db;
  late DocumentsDao dao;
  late DocumentRepositoryImpl repository;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    dao = DocumentsDao(db);
    repository = DocumentRepositoryImpl(dao);

    // Thêm 2 tài liệu để test hiển thị UI
    await repository.addDocument(
      DocumentsCompanion.insert(
        id: 'widget-doc-1',
        title: 'Giáo trình Flutter Cơ Bản',
        subject: 'Lập trình Flutter',
        category: 'Giáo trình',
        fileName: 'flutter_basic.pdf',
        fileType: 'PDF',
      ),
    );
    await repository.addDocument(
      DocumentsCompanion.insert(
        id: 'widget-doc-2',
        title: 'Slide Kiến trúc Cashew',
        subject: 'Kiến trúc Phần mềm',
        category: 'Slide bài giảng',
        fileName: 'cashew_arch.pptx',
        fileType: 'PPTX',
      ),
    );
  });

  tearDown(() async {
    await db.close();
  });

  group('Presentation Layer & Widget Tests', () {
    testWidgets('1. Render màn hình chính DocumentListScreen thành công', (
      tester,
    ) async {
      await tester.pumpWidget(MyApp(documentRepository: repository));
      await tester.pumpAndSettle();

      // Kiểm tra tiêu đề AppBar
      expect(find.text('Tài Liệu Học Tập'), findsOneWidget);

      // Kiểm tra thanh tìm kiếm
      expect(find.byType(TextField), findsOneWidget);

      // Kiểm tra danh mục "Tất cả"
      expect(find.text('Tất cả'), findsOneWidget);

      // Kiểm tra các thẻ tài liệu đã render
      expect(find.text('Giáo trình Flutter Cơ Bản'), findsOneWidget);
      expect(find.text('Slide Kiến trúc Cashew'), findsOneWidget);

      // Cleanup
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 100));
    });

    testWidgets('2. Tương tác tìm kiếm tài liệu trên giao diện', (
      tester,
    ) async {
      await tester.pumpWidget(MyApp(documentRepository: repository));
      await tester.pumpAndSettle();

      // Nhập từ khóa tìm kiếm
      await tester.enterText(find.byType(TextField), 'Flutter');
      await tester.pumpAndSettle();

      // Chỉ tài liệu Flutter hiển thị
      expect(find.text('Giáo trình Flutter Cơ Bản'), findsOneWidget);
      expect(find.text('Slide Kiến trúc Cashew'), findsNothing);

      // Cleanup
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 100));
    });

    testWidgets('3. Kiểm thử ConfirmationDialog xác nhận xóa an toàn', (
      tester,
    ) async {
      bool? isConfirmed;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  isConfirmed = await ConfirmationDialog.show(
                    context: context,
                    title: 'Xóa tài liệu',
                    message: 'Bạn có chắc chắn muốn xóa không?',
                  );
                },
                child: const Text('Mở Dialog'),
              ),
            ),
          ),
        ),
      );

      // Bấm mở Dialog
      await tester.tap(find.text('Mở Dialog'));
      await tester.pumpAndSettle();

      // Kiểm tra Dialog hiển thị
      expect(find.text('Xóa tài liệu'), findsOneWidget);
      expect(find.text('Bạn có chắc chắn muốn xóa không?'), findsOneWidget);
      expect(find.text('Hủy bỏ'), findsOneWidget);
      expect(find.text('Xác nhận xóa'), findsOneWidget);

      // Bấm nút Xác nhận xóa
      await tester.tap(find.text('Xác nhận xóa'));
      await tester.pumpAndSettle();

      expect(isConfirmed, isTrue);

      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 50));
    });

    testWidgets('4. Kiểm thử EmptyStateView hiển thị khi không có dữ liệu', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EmptyStateView(
              icon: Icons.search_off_rounded,
              title: 'Không tìm thấy tài liệu',
              message: 'Vui lòng kiểm tra lại từ khóa tìm kiếm',
              buttonText: 'Xóa bộ lọc',
              onButtonPressed: () {},
            ),
          ),
        ),
      );

      expect(find.text('Không tìm thấy tài liệu'), findsOneWidget);
      expect(
        find.text('Vui lòng kiểm tra lại từ khóa tìm kiếm'),
        findsOneWidget,
      );
      expect(find.text('Xóa bộ lọc'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 50));
    });
  });
}
