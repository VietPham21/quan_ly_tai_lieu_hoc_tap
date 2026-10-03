import 'package:flutter/material.dart';
import 'package:drift/drift.dart';
import 'package:provider/provider.dart';

import 'core/constants/app_constants.dart';
import 'core/theme/app_theme.dart';
import 'data/database/app_database.dart';
import 'data/database/daos/documents_dao.dart';
import 'data/repositories/document_repository.dart';
import 'data/repositories/document_repository_impl.dart';
import 'logic/controllers/document_controller.dart';
import 'presentation/screens/document_list_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Khởi tạo tầng Data Access & Persistence (Cashew Layer 3)
  final database = AppDatabase();
  final documentsDao = DocumentsDao(database);
  final documentRepository = DocumentRepositoryImpl(documentsDao);

  // 2. Nạp dữ liệu mẫu ban đầu nếu cơ sở dữ liệu mới tạo (phục vụ demo và kiểm thử trực quan)
  await _seedSampleDataIfEmpty(documentRepository);

  runApp(MyApp(documentRepository: documentRepository));
}

/// Nạp một số tài liệu học tập mẫu nếu CSDL chưa có dữ liệu
Future<void> _seedSampleDataIfEmpty(DocumentRepository repository) async {
  final currentDocs = await repository.getAllDocuments();
  if (currentDocs.isEmpty) {
    final now = DateTime.now();

    final samples = [
      DocumentsCompanion.insert(
        id: 'seed-flutter-01',
        title: 'Giáo trình Lập trình Flutter & Dart Nâng cao',
        description: const Value(
          'Tài liệu hướng dẫn xây dựng ứng dụng di động đa nền tảng theo kiến trúc phân tầng Cashew, Drift ORM và Reactive Streams.',
        ),
        subject: 'Lập trình Flutter',
        category: 'Giáo trình',
        fileName: 'giao_trinh_flutter_nang_cao.pdf',
        fileType: 'PDF',
        filePath: const Value('/docs/flutter/giao_trinh_flutter_nang_cao.pdf'),
        fileSize: const Value(5242880), // 5 MB
        isFavorite: const Value(true),
        createdAt: Value(now.subtract(const Duration(days: 2))),
        updatedAt: Value(now.subtract(const Duration(days: 2))),
      ),
      DocumentsCompanion.insert(
        id: 'seed-arch-02',
        title: 'Slide Bài giảng Kiến trúc Phần mềm Hiện đại',
        description: const Value(
          'Slide tóm tắt các mẫu kiến trúc: Layered Architecture, Clean Architecture, CQRS và Local-First Database Design.',
        ),
        subject: 'Kiến trúc Phần mềm',
        category: 'Slide bài giảng',
        fileName: 'kien_truc_phan_mem_tuan_4.pptx',
        fileType: 'PPTX',
        filePath: const Value('/docs/architecture/slide_w4.pptx'),
        fileSize: const Value(3145728), // 3 MB
        isFavorite: const Value(false),
        createdAt: Value(now.subtract(const Duration(days: 1))),
        updatedAt: Value(now.subtract(const Duration(days: 1))),
      ),
      DocumentsCompanion.insert(
        id: 'seed-db-03',
        title: 'Đề thi & Đáp án Cơ sở Dữ liệu Quan hệ',
        description: const Value(
          'Bộ đề thi kết thúc học phần Cơ sở dữ liệu, bài tập SQL nâng cao, indexing và tối ưu hóa truy vấn SQLite/Drift.',
        ),
        subject: 'Cơ sở dữ liệu',
        category: 'Đề thi & Đáp án',
        fileName: 'de_thi_csdl_2025.docx',
        fileType: 'DOCX',
        filePath: const Value('/docs/database/de_thi_csdl.docx'),
        fileSize: const Value(1572864), // 1.5 MB
        isFavorite: const Value(true),
        createdAt: Value(now.subtract(const Duration(hours: 5))),
        updatedAt: Value(now.subtract(const Duration(hours: 5))),
      ),
      DocumentsCompanion.insert(
        id: 'seed-project-04',
        title: 'Mã nguồn Bài tập lớn: Ứng dụng Cashew Study Docs',
        description: const Value(
          'Toàn bộ source code project Flutter, các file DAO, Repository, Controller và Unit Test đầy đủ.',
        ),
        subject: 'Lập trình Flutter',
        category: 'Bài tập lớn & Đồ án',
        fileName: 'quan_ly_tai_lieu_hoc_tap.zip',
        fileType: 'ZIP',
        filePath: const Value('/projects/quan_ly_tai_lieu_hoc_tap.zip'),
        fileSize: const Value(10485760), // 10 MB
        isFavorite: const Value(false),
        createdAt: Value(now),
        updatedAt: Value(now),
      ),
    ];

    for (final sample in samples) {
      await repository.addDocument(sample);
    }
  }
}

class MyApp extends StatelessWidget {
  final DocumentRepository documentRepository;

  const MyApp({super.key, required this.documentRepository});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Cung cấp Repository cho cây Widget
        Provider<DocumentRepository>.value(value: documentRepository),
        // Cung cấp Controller quản lý nghiệp vụ và trạng thái (Cashew Layer 2)
        ChangeNotifierProvider<DocumentController>(
          create: (_) => DocumentController(repository: documentRepository),
        ),
      ],
      child: MaterialApp(
        title: AppConstants.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        home: const DocumentListScreen(),
      ),
    );
  }
}
