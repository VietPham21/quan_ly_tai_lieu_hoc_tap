import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:drift/drift.dart';
import 'package:provider/provider.dart';

import 'core/constants/app_constants.dart';
import 'core/theme/app_theme.dart';
import 'data/database/app_database.dart';
import 'data/database/daos/documents_dao.dart';
import 'data/repositories/document_repository.dart';
import 'data/repositories/document_repository_impl.dart';
import 'data/repositories/firestore_document_repository.dart';
import 'firebase_options.dart';
import 'logic/controllers/auth_controller.dart';
import 'logic/controllers/document_controller.dart';
import 'logic/services/auth_service.dart';
import 'logic/services/cloud_storage_service.dart';
import 'presentation/screens/document_list_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Khởi tạo Firebase Đám mây (Authentication, Firestore, Storage)
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Firebase.initializeApp warning: $e');
  }

  // 2. Khởi tạo các Dịch vụ Cloud
  final authService = AuthService();
  final authController = AuthController(authService: authService);
  final firestoreRepository = FirestoreDocumentRepository();
  final storageService = CloudStorageService();

  // 3. Khởi tạo tầng Data Access & Persistence cục bộ (Drift SQLite - Offline/Fallback)
  final database = AppDatabase();
  final documentsDao = DocumentsDao(database);
  final documentRepository = DocumentRepositoryImpl(documentsDao);

  // Nạp seed data nếu CSDL cục bộ rỗng (phục vụ fallback)
  await _seedSampleDataIfEmpty(documentRepository);

  // 4. Khởi tạo DocumentController điều phối Cloud & Local
  final documentController = DocumentController(
    firestoreRepository: firestoreRepository,
    storageService: storageService,
    repository: documentRepository,
    currentUid: authController.currentUid,
  );

  // Lắng nghe thay đổi tài khoản Google để cập nhật luồng tài liệu
  authController.addListener(() {
    documentController.updateUser(authController.currentUid);
  });

  runApp(
    MyApp(
      documentRepository: documentRepository,
      authService: authService,
      authController: authController,
      firestoreRepository: firestoreRepository,
      storageService: storageService,
      documentController: documentController,
    ),
  );
}

/// Nạp một số tài liệu học tập mẫu nếu CSDL chưa có dữ liệu
Future<void> _seedSampleDataIfEmpty(DocumentRepository repository) async {
  try {
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
          filePath: const Value(
            '/docs/flutter/giao_trinh_flutter_nang_cao.pdf',
          ),
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
      ];

      for (final sample in samples) {
        await repository.addDocument(sample);
      }
    }
  } catch (e) {
    debugPrint('Seed data error: $e');
  }
}

class MyApp extends StatelessWidget {
  final DocumentRepository? documentRepository;
  final AuthService? authService;
  final AuthController? authController;
  final FirestoreDocumentRepository? firestoreRepository;
  final CloudStorageService? storageService;
  final DocumentController? documentController;

  const MyApp({
    super.key,
    this.documentRepository,
    this.authService,
    this.authController,
    this.firestoreRepository,
    this.storageService,
    this.documentController,
  });

  @override
  Widget build(BuildContext context) {
    // Tự khởi tạo mock/fallback controller nếu đang chạy test widget không truyền đủ
    final safeAuthService =
        authService ?? (Firebase.apps.isNotEmpty ? AuthService() : null);
    final safeAuthController =
        authController ??
        (firestoreRepository == null && documentRepository != null
            ? AuthController(testUid: 'test-user')
            : AuthController(authService: safeAuthService));
    final safeDocController =
        documentController ??
        DocumentController(
          firestoreRepository: firestoreRepository,
          storageService: storageService,
          repository: documentRepository,
          currentUid: safeAuthController.currentUid,
        );

    return MultiProvider(
      providers: [
        if (safeAuthService != null)
          Provider<AuthService>.value(value: safeAuthService),
        ChangeNotifierProvider<AuthController>.value(value: safeAuthController),
        if (firestoreRepository != null)
          Provider<FirestoreDocumentRepository>.value(
            value: firestoreRepository!,
          ),
        if (storageService != null)
          Provider<CloudStorageService>.value(value: storageService!),
        if (documentRepository != null)
          Provider<DocumentRepository>.value(value: documentRepository!),
        ChangeNotifierProvider<DocumentController>.value(
          value: safeDocController,
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
