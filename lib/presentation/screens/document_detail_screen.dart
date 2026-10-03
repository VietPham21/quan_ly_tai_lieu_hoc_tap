import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/utils/file_helper.dart';
import '../../logic/controllers/document_controller.dart';
import '../widgets/confirmation_dialog.dart';
import 'document_form_screen.dart';

class DocumentDetailScreen extends StatelessWidget {
  final String documentId;

  const DocumentDetailScreen({super.key, required this.documentId});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<DocumentController>();
    // Lấy document mới nhất từ Reactive State của Controller
    final docList = controller.documents;
    final docIndex = docList.indexWhere((d) => d.id == documentId);

    if (docIndex == -1) {
      // Tài liệu đã bị xóa khỏi CSDL, tự động pop nếu màn hình đang hiển thị
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final doc = docList[docIndex];
    final typeColor = FileHelper.getFileTypeColor(doc.fileType);
    final typeIcon = FileHelper.getFileTypeIcon(doc.fileType);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Chi tiết tài liệu',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          IconButton(
            tooltip: doc.isFavorite ? 'Bỏ yêu thích' : 'Yêu thích',
            icon: Icon(
              doc.isFavorite ? Icons.star_rounded : Icons.star_border_rounded,
              color: doc.isFavorite ? Colors.amber : null,
              size: 26,
            ),
            onPressed: () => controller.toggleFavorite(doc.id, doc.isFavorite),
          ),
          IconButton(
            tooltip: 'Chỉnh sửa tài liệu',
            icon: const Icon(Icons.edit_outlined),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => DocumentFormScreen(document: doc),
                ),
              );
            },
          ),
          IconButton(
            tooltip: 'Xóa tài liệu',
            icon: const Icon(
              Icons.delete_outline_rounded,
              color: AppColors.error,
            ),
            onPressed: () async {
              final confirmed = await ConfirmationDialog.show(
                context: context,
                title: 'Xóa tài liệu',
                message:
                    'Bạn có chắc chắn muốn xóa "${doc.title}"? Hành động này không thể hoàn tác.',
              );
              if (confirmed == true && context.mounted) {
                final success = await controller.deleteDocument(doc.id);
                if (success && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Đã xóa tài liệu thành công!'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                  Navigator.of(context).pop();
                }
              }
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Header Card: Icon lớn, Tiêu đề, Môn học & Danh mục
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Theme.of(context).dividerColor.withValues(alpha: 0.3),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: typeColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Center(
                        child: Icon(typeIcon, color: typeColor, size: 32),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            doc.title,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              height: 1.3,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              doc.subject,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildMetaItem(
                      context,
                      icon: Icons.category_outlined,
                      label: 'Danh mục',
                      value: doc.category,
                    ),
                    _buildMetaItem(
                      context,
                      icon: Icons.insert_drive_file_outlined,
                      label: 'Định dạng',
                      value: doc.fileType,
                    ),
                    if (doc.fileSize > 0)
                      _buildMetaItem(
                        context,
                        icon: Icons.data_usage_rounded,
                        label: 'Dung lượng',
                        value: FileHelper.formatFileSize(doc.fileSize),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Mô tả / Ghi chú học tập
          if (doc.description != null && doc.description!.isNotEmpty) ...[
            const Text(
              'GHI CHÚ HỌC TẬP & MÔ TẢ',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceDark : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: Theme.of(context).dividerColor.withValues(alpha: 0.3),
                ),
              ),
              child: Text(
                doc.description!,
                style: const TextStyle(fontSize: 14, height: 1.5),
              ),
            ),
            const SizedBox(height: 24),
          ],

          // Thông tin tệp tin & Hệ thống
          const Text(
            'THÔNG TIN TỆP & HỆ THỐNG',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: Theme.of(context).dividerColor.withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              children: [
                _buildDetailRow(
                  context,
                  'Tên tệp tin:',
                  doc.fileName,
                  isCode: true,
                ),
                const Divider(height: 20),
                _buildDetailRow(
                  context,
                  'Đường dẫn tệp:',
                  doc.filePath ?? 'Lưu trữ cục bộ ứng dụng',
                  isCode: doc.filePath != null,
                ),
                const Divider(height: 20),
                _buildDetailRow(
                  context,
                  'Mã định danh (UUID):',
                  doc.id,
                  isCode: true,
                ),
                const Divider(height: 20),
                _buildDetailRow(
                  context,
                  'Thời gian tạo:',
                  FileHelper.formatDate(doc.createdAt),
                ),
                const Divider(height: 20),
                _buildDetailRow(
                  context,
                  'Cập nhật gần nhất:',
                  FileHelper.formatDate(doc.updatedAt),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetaItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 14,
                color: Theme.of(context).colorScheme.onSurface
                    .withValues(alpha: 0.5),
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: Theme.of(context).colorScheme.onSurface
                      .withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(
    BuildContext context,
    String label,
    String value, {
    bool isCode = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 140,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: Theme.of(context).colorScheme.onSurface
                  .withValues(alpha: 0.6),
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isCode ? FontWeight.w500 : FontWeight.w600,
              fontFamily: isCode ? 'monospace' : null,
            ),
          ),
        ),
      ],
    );
  }
}
