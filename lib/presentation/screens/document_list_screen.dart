import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../data/models/cloud_document.dart';
import '../../logic/controllers/auth_controller.dart';
import '../../logic/controllers/document_controller.dart';
import '../widgets/category_chip_selector.dart';
import '../widgets/confirmation_dialog.dart';
import '../widgets/document_card.dart';
import '../widgets/document_search_bar.dart';
import '../widgets/empty_state_view.dart';
import 'auth_screen.dart';
import 'document_detail_screen.dart';
import 'document_form_screen.dart';

class DocumentListScreen extends StatelessWidget {
  const DocumentListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authController = context.watch<AuthController>();

    // Nếu chưa đăng nhập: Hiển thị AuthScreen
    if (!authController.isAuthenticated) {
      return const AuthScreen();
    }

    final controller = context.watch<DocumentController>();
    final state = controller.state;
    final docs = state.documents;
    final favCount = docs.where((d) => d.isFavorite).length;
    final user = authController.user;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.school_rounded,
                color: AppColors.primary,
                size: 22,
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Tài Liệu Học Tập',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  user?.email ?? 'Cloud Firestore • Storage',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
                    color: AppColors.secondary,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          if (state.isFiltering)
            IconButton(
              tooltip: 'Đặt lại bộ lọc',
              icon: const Icon(
                Icons.filter_alt_off_rounded,
                color: AppColors.primary,
              ),
              onPressed: controller.clearFilters,
            ),

          // Menu tài khoản người dùng & Đăng xuất
          PopupMenuButton<String>(
            tooltip: 'Tài khoản người dùng',
            icon: CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.primary.withValues(alpha: 0.15),
              backgroundImage: user?.photoURL != null
                  ? NetworkImage(user!.photoURL!)
                  : null,
              child: user?.photoURL == null
                  ? const Icon(
                      Icons.person_rounded,
                      size: 20,
                      color: AppColors.primary,
                    )
                  : null,
            ),
            onSelected: (val) async {
              if (val == 'logout') {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Đăng xuất'),
                    content: const Text(
                      'Bạn có chắc chắn muốn đăng xuất khỏi tài khoản Google?',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(false),
                        child: const Text('Hủy'),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.of(ctx).pop(true),
                        child: const Text('Đăng xuất'),
                      ),
                    ],
                  ),
                );
                if (confirm == true) {
                  await authController.signOut();
                }
              }
            },
            itemBuilder: (ctx) => [
              PopupMenuItem(
                enabled: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user?.displayName ?? 'Sinh viên',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      user?.email ?? '',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const Divider(),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(
                      Icons.logout_rounded,
                      color: AppColors.error,
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Text('Đăng xuất', style: TextStyle(color: AppColors.error)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // 1. Thanh tìm kiếm thời gian thực
          DocumentSearchBar(
            initialQuery: state.searchQuery,
            onQueryChanged: controller.setSearchQuery,
            onClear: () => controller.setSearchQuery(''),
            isAscending: state.isAscending,
            onToggleSort: controller.toggleSortOrder,
          ),

          // 2. Bộ lọc danh mục dạng thẻ trượt ngang
          CategoryChipSelector(
            selectedCategory: state.selectedCategory,
            onCategorySelected: controller.setSelectedCategory,
          ),

          // 3. Thanh thống kê ngắn gọn
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Tổng: ${docs.length} tài liệu ${state.isFiltering ? "(đã lọc)" : ""}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface
                        .withValues(alpha: 0.6),
                  ),
                ),
                if (favCount > 0)
                  Row(
                    children: [
                      const Icon(
                        Icons.star_rounded,
                        size: 14,
                        color: Colors.amber,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$favCount yêu thích',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onSurface
                              .withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),

          const SizedBox(height: 4),

          // 4. Danh sách tài liệu phản ứng (Reactive Stream từ Firestore)
          Expanded(child: _buildBody(context, controller)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const DocumentFormScreen()));
        },
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'Thêm tài liệu',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, DocumentController controller) {
    final state = controller.state;

    if (state.isLoading && state.documents.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.hasError && state.documents.isEmpty) {
      return EmptyStateView(
        icon: Icons.error_outline_rounded,
        title: 'Đã xảy ra lỗi',
        message: state.errorMessage ?? 'Không thể tải danh sách tài liệu',
        buttonText: 'Thử lại',
        onButtonPressed: controller.clearFilters,
      );
    }

    if (state.isEmpty) {
      if (state.isFiltering) {
        return EmptyStateView(
          icon: Icons.search_off_rounded,
          title: 'Không tìm thấy tài liệu phù hợp',
          message: 'Hãy thử tìm bằng từ khóa khác hoặc xóa bộ lọc danh mục.',
          buttonText: 'Xóa bộ lọc',
          onButtonPressed: controller.clearFilters,
        );
      } else {
        return EmptyStateView(
          icon: Icons.cloud_queue_rounded,
          title: 'Chưa có tài liệu học tập nào',
          message: 'Bắt đầu lưu trữ tài liệu lên Cloud bằng cách bấm nút "Thêm tài liệu" bên dưới.',
          buttonText: 'Thêm tài liệu ngay',
          onButtonPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const DocumentFormScreen()),
            );
          },
        );
      }
    }

    final docs = state.documents;

    return ListView.builder(
      padding: const EdgeInsets.only(top: 4, bottom: 88),
      itemCount: docs.length,
      itemBuilder: (context, index) {
        final doc = docs[index];
        return DocumentCard(
          key: ValueKey(doc.id),
          document: doc,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => DocumentDetailScreen(documentId: doc.id),
              ),
            );
          },
          onEdit: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => DocumentFormScreen(document: doc),
              ),
            );
          },
          onDelete: () => _handleDelete(context, controller, doc),
          onToggleFavorite: () =>
              controller.toggleFavorite(doc.id, doc.isFavorite),
        );
      },
    );
  }

  Future<void> _handleDelete(
    BuildContext context,
    DocumentController controller,
    CloudDocument doc,
  ) async {
    final confirmed = await ConfirmationDialog.show(
      context: context,
      title: 'Xác nhận xóa tài liệu',
      message:
          'Bạn có chắc chắn muốn xóa "${doc.title}"? Dữ liệu và file đính kèm trên Cloud sẽ bị xóa hoàn toàn.',
    );

    if (confirmed == true && context.mounted) {
      final success = await controller.deleteDocument(
        doc.id,
        storagePath: doc.storagePath,
      );
      if (success && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã xóa "${doc.title}" thành công!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    }
  }
}
