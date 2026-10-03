import 'package:drift/drift.dart';

import 'connection/connection.dart' as impl;
import 'daos/documents_dao.dart';
import 'tables/documents_table.dart';

part 'app_database.g.dart';

/// Cơ sở dữ liệu chính của ứng dụng Quản lý Tài liệu Học tập.
/// Quản lý bởi Drift ORM trên SQLite theo triết lý Local-First của Cashew.
/// Hỗ trợ đa nền tảng (Native SQLite và Web SQLite WASM) thông qua lớp trừu tượng connection.
@DriftDatabase(tables: [Documents], daos: [DocumentsDao])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? e]) : super(e ?? impl.connect());

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (Migrator m) async {
      await m.createAll();
    },
    onUpgrade: (Migrator m, int from, int to) async {
      // Sẵn sàng hỗ trợ migration khi nâng cấp phiên bản
    },
  );
}
