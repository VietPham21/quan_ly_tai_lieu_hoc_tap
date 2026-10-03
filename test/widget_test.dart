import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quan_ly_tai_lieu_hoc_tap/data/database/app_database.dart';
import 'package:quan_ly_tai_lieu_hoc_tap/data/database/daos/documents_dao.dart';
import 'package:quan_ly_tai_lieu_hoc_tap/data/repositories/document_repository_impl.dart';
import 'package:quan_ly_tai_lieu_hoc_tap/main.dart';

void main() {
  testWidgets('App smoke test - Khởi chạy ứng dụng thành công', (
    WidgetTester tester,
  ) async {
    final db = AppDatabase(NativeDatabase.memory());
    final dao = DocumentsDao(db);
    final repository = DocumentRepositoryImpl(dao);

    await tester.pumpWidget(MyApp(documentRepository: repository));
    await tester.pumpAndSettle();

    expect(find.text('Tài Liệu Học Tập'), findsOneWidget);

    // Dọn dẹp widget tree và flush timer pending từ Drift stream
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 100));
    await db.close();
  });
}
