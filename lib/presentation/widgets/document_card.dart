import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/utils/file_helper.dart';
import '../../data/models/cloud_document.dart';

class DocumentCard extends StatelessWidget {
  final CloudDocument document;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onToggleFavorite;

  const DocumentCard({
    super.key,
    required this.document,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
    required this.onToggleFavorite,
  });

  @override
  Widget build(BuildContext context) {
    final typeColor = FileHelper.getFileTypeColor(document.fileType);
    final typeIcon = FileHelper.getFileTypeIcon(document.fileType);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasCloudFile =
        document.storagePath != null || document.fileUrl != null;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hàng 1: Icon file, Tiêu đề, Nút Favorite
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Badge icon loại file
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: typeColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Icon(typeIcon, color: typeColor, size: 24),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Tiêu đề & Tên file
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          document.title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            height: 1.25,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            if (hasCloudFile) ...[
                              const Icon(
                                Icons.cloud_done_rounded,
                                size: 14,
                                color: AppColors.primary,
                              ),
                              const SizedBox(width: 4),
                            ],
                            Expanded(
                              child: Text(
                                document.fileName,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Theme.of(context).colorScheme.onSurface
                                      .withValues(alpha: 0.6),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Nút Favorite
                  IconButton(
                    icon: Icon(
                      document.isFavorite
                          ? Icons.star_rounded
                          : Icons.star_border_rounded,
                      color: document.isFavorite
                          ? Colors.amber
                          : Theme.of(context).colorScheme.onSurface
                                .withValues(alpha: 0.3),
                      size: 26,
                    ),
                    onPressed: onToggleFavorite,
                    tooltip: document.isFavorite ? 'Bỏ yêu thích' : 'Yêu thích',
                  ),
                ],
              ),

              if (document.description != null &&
                  document.description!.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  document.description!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    color: Theme.of(context).colorScheme.onSurface
                        .withValues(alpha: 0.7),
                  ),
                ),
              ],

              const SizedBox(height: 12),
              // Hàng 2: Badges môn học, danh mục, dung lượng, trạng thái Cloud
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  _buildBadge(
                    context,
                    label: document.subject,
                    icon: Icons.book_outlined,
                    bgColor: AppColors.primary.withValues(alpha: 0.08),
                    textColor: isDark
                        ? AppColors.primaryLight
                        : AppColors.primaryDark,
                  ),
                  _buildBadge(
                    context,
                    label: document.category,
                    icon: Icons.folder_outlined,
                    bgColor: AppColors.secondary.withValues(alpha: 0.08),
                    textColor: AppColors.secondary,
                  ),
                  _buildBadge(
                    context,
                    label: document.fileType,
                    bgColor: typeColor.withValues(alpha: 0.08),
                    textColor: typeColor,
                  ),
                  if (document.fileSize > 0)
                    _buildBadge(
                      context,
                      label: FileHelper.formatFileSize(document.fileSize),
                      bgColor: Theme.of(context).colorScheme.onSurface
                          .withValues(alpha: 0.05),
                      textColor: Theme.of(context).colorScheme.onSurface
                          .withValues(alpha: 0.6),
                    ),
                  if (hasCloudFile)
                    _buildBadge(
                      context,
                      label: 'Cloud File',
                      icon: Icons.cloud_outlined,
                      bgColor: Colors.teal.withValues(alpha: 0.1),
                      textColor: Colors.teal,
                    ),
                ],
              ),

              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 8),

              // Hàng 3: Thời gian cập nhật và các nút Thao tác (Sửa, Xóa)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.access_time_rounded,
                        size: 14,
                        color: Theme.of(context).colorScheme.onSurface
                            .withValues(alpha: 0.5),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Cập nhật: ${FileHelper.formatDateShort(document.updatedAt)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.onSurface
                              .withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        icon: const Icon(Icons.edit_outlined, size: 20),
                        tooltip: 'Chỉnh sửa tài liệu',
                        color: AppColors.primary,
                        onPressed: onEdit,
                      ),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        icon: const Icon(
                          Icons.delete_outline_rounded,
                          size: 20,
                        ),
                        tooltip: 'Xóa tài liệu',
                        color: AppColors.error,
                        onPressed: onDelete,
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBadge(
    BuildContext context, {
    required String label,
    IconData? icon,
    required Color bgColor,
    required Color textColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: textColor),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}
