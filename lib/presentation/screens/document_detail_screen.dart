import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants/app_colors.dart';
import '../../core/utils/file_helper.dart';
import '../../logic/controllers/auth_controller.dart';
import '../../logic/controllers/document_controller.dart';
import '../widgets/confirmation_dialog.dart';
import '../widgets/share_document_dialog.dart';
import 'document_form_screen.dart';

class DocumentDetailScreen extends StatelessWidget {
  final String documentId;

  const DocumentDetailScreen({super.key, required this.documentId});

  @override
  Widget build(BuildContext context) {
    final authController = context.watch<AuthController>();
    final controller = context.watch<DocumentController>();
    final docList = controller.documents;
    final docIndex = docList.indexWhere((d) => d.id == documentId);

    if (docIndex == -1) {
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
    final hasCloudUrl = doc.fileUrl != null && doc.fileUrl!.isNotEmpty;

    final currentUid = authController.currentUid ?? '';
    final isOwner = doc.ownerUid.isEmpty || doc.ownerUid == currentUid;

    return FutureBuilder<String>(
      future: controller.getUserRoleForDocument(doc),
      initialData: isOwner ? 'owner' : 'viewer',
      builder: (context, snapshot) {
        final role = snapshot.data ?? (isOwner ? 'owner' : 'viewer');
        final canEdit = role == 'owner' || role == 'editor';
        final canDelete = role == 'owner';
        final canShare = role == 'owner';

        return Scaffold(
          appBar: AppBar(
            title: const Text(
              'Chi tiết tài liệu',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            actions: [
              // Nút Yêu thích
              IconButton(
                tooltip: doc.isFavorite ? 'Bỏ yêu thích' : 'Yêu thích',
                icon: Icon(
                  doc.isFavorite ? Icons.star_rounded : Icons.star_border_rounded,
                  color: doc.isFavorite ? Colors.amber : null,
                  size: 26,
                ),
                onPressed: () => controller.toggleFavorite(doc.id, doc.isFavorite),
              ),

              // Nút Chia sẻ (chỉ chủ sở hữu mới có quyền phân quyền chia sẻ)
              if (canShare)
                IconButton(
                  tooltip: 'Chia sẻ tài liệu',
                  icon: const Icon(Icons.share_rounded, color: AppColors.primary),
                  onPressed: () => ShareDocumentDialog.show(context, doc),
                ),

              // Nút Chỉnh sửa (chủ sở hữu hoặc người được cấp quyền Editor)
              if (canEdit)
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

              // Nút Xóa (chỉ chủ sở hữu mới có quyền xóa)
              if (canDelete)
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
                          'Bạn có chắc chắn muốn xóa "${doc.title}"? Dữ liệu và file đính kèm trên Cloud sẽ bị xóa hoàn toàn.',
                    );
                    if (confirmed == true && context.mounted) {
                      final success = await controller.deleteDocument(
                        doc.id,
                        storagePath: doc.storagePath,
                      );
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
              // Banner thông báo nếu đây là tài liệu được chia sẻ
              if (!isOwner)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: (role == 'editor' ? Colors.orange : Colors.blue).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: (role == 'editor' ? Colors.orange : Colors.blue).withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        role == 'editor' ? Icons.edit_note_rounded : Icons.visibility_rounded,
                        color: role == 'editor' ? Colors.orange : Colors.blue,
                        size: 26,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              role == 'editor'
                                  ? 'Tài liệu được chia sẻ (Quyền Chỉnh sửa)'
                                  : 'Tài liệu được chia sẻ (Quyền Chỉ xem)',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: role == 'editor' ? Colors.orange : Colors.blue,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              role == 'editor'
                                  ? 'Bạn có quyền xem file và chỉnh sửa thông tin tài liệu này.'
                                  : 'Bạn chỉ có quyền xem và tải file, không thể sửa hoặc xóa.',
                              style: TextStyle(
                                fontSize: 11,
                                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
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
          const SizedBox(height: 20),

          // NÚT MỞ HOẶC TẢI FILE TỪ CLOUD STORAGE
          if (hasCloudUrl) ...[
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.teal.shade700,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: const Icon(Icons.open_in_browser_rounded),
              label: const Text(
                'MỞ / TẢI TỆP ĐÍNH KÈM (CLOUD STORAGE)',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              onPressed: () async {
                final uri = Uri.parse(doc.fileUrl!);
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                } else {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Không thể mở liên kết tệp tin.'),
                        backgroundColor: AppColors.error,
                      ),
                    );
                  }
                }
              },
            ),
            const SizedBox(height: 20),
          ],

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

          // Thông tin tệp tin & Hệ thống Cloud
          const Text(
            'THÔNG TIN TỆP & HỆ THỐNG CLOUD',
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
                  'Mã tài liệu (ID):',
                  doc.id,
                  isCode: true,
                ),
                if (doc.storagePath != null) ...[
                  const Divider(height: 20),
                  _buildDetailRow(
                    context,
                    'Cloud Storage Path:',
                    doc.storagePath!,
                    isCode: true,
                  ),
                ],
                if (doc.ownerUid.isNotEmpty) ...[
                  const Divider(height: 20),
                  _buildDetailRow(
                    context,
                    'Owner UID:',
                    doc.ownerUid,
                    isCode: true,
                  ),
                ],
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
  },
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
