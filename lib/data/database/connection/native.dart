import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Kết nối CSDL SQLite trên các nền tảng Native (Android, iOS, Windows, macOS, Linux).
/// Sử dụng NativeDatabase và sqlite3_flutter_libs.
QueryExecutor connect() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'hoc_tap_documents.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
