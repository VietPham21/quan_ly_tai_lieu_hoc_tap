import 'package:drift/drift.dart';
import 'package:drift/wasm.dart';
import 'package:flutter/foundation.dart';

/// Kết nối CSDL SQLite trên nền tảng Web (Google Chrome, Edge, Firefox, Safari...).
/// Sử dụng Drift WasmDatabase với sqlite3.wasm và drift_worker.js (IndexedDB persistence).
QueryExecutor connect() {
  return DatabaseConnection.delayed(
    Future.sync(() async {
      final result = await WasmDatabase.open(
        databaseName: 'hoc_tap_documents',
        sqlite3Uri: Uri.parse('sqlite3.wasm'),
        driftWorkerUri: Uri.parse('drift_worker.js'),
      );

      if (result.missingFeatures.isNotEmpty) {
        debugPrint(
          'Drift Web: Sử dụng ${result.chosenImplementation} do thiếu tính năng browser: ${result.missingFeatures}',
        );
      }

      return result.resolvedExecutor;
    }),
  );
}
