import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../data/database/app_database.dart';
import '../../logic/controllers/document_controller.dart';
import '../widgets/category_chip_selector.dart';
import '../widgets/confirmation_dialog.dart';
import '../widgets/document_card.dart';
import '../widgets/document_search_bar.dart';
import '../widgets/empty_state_view.dart';
import 'document_detail_screen.dart';
import 'document_form_screen.dart';

class DocumentListScreen extends StatelessWidget {
  const DocumentListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<DocumentController>();
    final state = controller.state;
    final docs = state.documents;
    final favCount = docs.where((d) => d.isFavorite).length;

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
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tài Liệu Học Tập',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  'Kiến trúc phân tầng Cashew • Drift SQLite',
                  style: TextStyle(
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

          // 4. Danh sách tài liệu phản ứng (Reactive Stream)
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
          icon: Icons.library_books_rounded,
          title: 'Chưa có tài liệu học tập nào',
          message: 'Bắt đầu quản lý tài liệu học tập của bạn bằng cách bấm nút "Thêm tài liệu" bên dưới.',
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
    Document doc,
  ) async {
    final confirmed = await ConfirmationDialog.show(
      context: context,
      title: 'Xác nhận xóa tài liệu',
      message:
          'Bạn có chắc chắn muốn xóa "${doc.title}"? Dữ liệu sẽ bị xóa khỏi SQLite cục bộ.',
    );

    if (confirmed == true && context.mounted) {
      final success = await controller.deleteDocument(doc.id);
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
