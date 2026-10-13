import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../data/models/cloud_document.dart';
import '../../data/models/document_permission.dart';
import '../../logic/controllers/document_controller.dart';

/// Hộp thoại chia sẻ tài liệu học tập cho người dùng khác qua Email & phân quyền
class ShareDocumentDialog extends StatefulWidget {
  final CloudDocument document;

  const ShareDocumentDialog({super.key, required this.document});

  static Future<void> show(BuildContext context, CloudDocument document) {
    return showDialog(
      context: context,
      builder: (_) => ShareDocumentDialog(document: document),
    );
  }

  @override
  State<ShareDocumentDialog> createState() => _ShareDocumentDialogState();
}

class _ShareDocumentDialogState extends State<ShareDocumentDialog> {
  final _emailController = TextEditingController();
  String _selectedRole = 'editor'; // 'editor' hoặc 'viewer'
  bool _isLoading = false;
  bool _isLoadingPermissions = true;
  List<DocumentPermission> _permissions = [];
  List<Map<String, dynamic>> _registeredUsers = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoadingPermissions = true);
    final controller = context.read<DocumentController>();

    final perms = await controller.getDocumentPermissions(widget.document.id);
    final users = await controller.getAllRegisteredUsers();

    if (mounted) {
      setState(() {
        _permissions = perms;
        _registeredUsers = users;
        _isLoadingPermissions = false;
      });
    }
  }

  Future<void> _handleShare() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng nhập hoặc chọn email người nhận'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    final controller = context.read<DocumentController>();

    final success = await controller.shareDocument(
      documentId: widget.document.id,
      targetEmail: email,
      role: _selectedRole,
    );

    if (mounted) {
      setState(() => _isLoading = false);
      if (success) {
        _emailController.clear();
        await _loadData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Đã chia sẻ thành công cho $email!'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(controller.errorMessage ?? 'Chia sẻ thất bại'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _handleRevoke(DocumentPermission perm) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Thu hồi quyền'),
        content: Text('Bạn có chắc chắn muốn thu hồi quyền của ${perm.sharedEmail}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Thu hồi'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final controller = context.read<DocumentController>();
      await controller.revokePermission(perm.id);
      await _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520, maxHeight: 650),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.share_rounded,
                      color: AppColors.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Chia Sẻ Tài Liệu',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          widget.document.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            color: Theme.of(context).colorScheme.onSurface
                                .withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Form nhập email và chọn quyền
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: 'Email người nhận',
                        hintText: 'sinhvien@gmail.com',
                        prefixIcon: const Icon(Icons.email_outlined, size: 20),
                        isDense: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Theme.of(context).colorScheme.outline
                            .withValues(alpha: 0.5),
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedRole,
                        items: const [
                          DropdownMenuItem(
                            value: 'editor',
                            child: Text('Chỉnh sửa'),
                          ),
                          DropdownMenuItem(
                            value: 'viewer',
                            child: Text('Chỉ xem'),
                          ),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _selectedRole = val);
                          }
                        },
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Gợi ý nhanh các tài khoản đã đăng ký trên hệ thống
              if (_registeredUsers.isNotEmpty) ...[
                Text(
                  'Gợi ý tài khoản trong hệ thống:',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurface
                        .withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: _registeredUsers.take(4).map((u) {
                    final email = u['email'] as String? ?? '';
                    return ActionChip(
                      avatar: const Icon(Icons.person_outline, size: 14),
                      label: Text(
                        email,
                        style: const TextStyle(fontSize: 11),
                      ),
                      onPressed: () {
                        setState(() {
                          _emailController.text = email;
                        });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
              ],

              // Nút Chia sẻ
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _isLoading ? null : _handleShare,
                  icon: _isLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.send_rounded, size: 18),
                  label: Text(_isLoading ? 'Đang cấp quyền...' : 'CẤP QUYỀN TRUY CẬP'),
                ),
              ),

              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),

              // Danh sách những người đang có quyền
              const Text(
                'Danh sách người có quyền truy cập',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),

              Expanded(
                child: _isLoadingPermissions
                    ? const Center(child: CircularProgressIndicator())
                    : ListView(
                        shrinkWrap: true,
                        children: [
                          // Chủ sở hữu
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: const CircleAvatar(
                              backgroundColor: AppColors.primary,
                              child: Icon(Icons.admin_panel_settings, color: Colors.white, size: 20),
                            ),
                            title: const Text('Bạn (Chủ sở hữu)'),
                            subtitle: Text(
                              'Toàn quyền (Đọc, Ghi, Xóa, Chia sẻ)',
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(context).colorScheme.onSurface
                                    .withValues(alpha: 0.6),
                              ),
                            ),
                            trailing: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'Owner',
                                style: TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ),

                          // Những người được chia sẻ
                          if (_permissions.isEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              child: Center(
                                child: Text(
                                  'Tài liệu này chưa được chia sẻ cho ai.',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Theme.of(context).colorScheme.onSurface
                                        .withValues(alpha: 0.5),
                                  ),
                                ),
                              ),
                            )
                          else
                            ..._permissions.map((perm) {
                              final isEditor = perm.isEditor;
                              return ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: CircleAvatar(
                                  backgroundColor: isEditor
                                      ? Colors.orange.withValues(alpha: 0.15)
                                      : Colors.blue.withValues(alpha: 0.15),
                                  child: Icon(
                                    isEditor ? Icons.edit_rounded : Icons.visibility_rounded,
                                    color: isEditor ? Colors.orange : Colors.blue,
                                    size: 18,
                                  ),
                                ),
                                title: Text(
                                  perm.sharedEmail,
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                                ),
                                subtitle: Text(
                                  isEditor ? 'Quyền chỉnh sửa (Editor)' : 'Quyền chỉ xem (Viewer)',
                                  style: const TextStyle(fontSize: 11),
                                ),
                                trailing: IconButton(
                                  tooltip: 'Thu hồi quyền',
                                  icon: const Icon(
                                    Icons.delete_outline_rounded,
                                    color: AppColors.error,
                                    size: 20,
                                  ),
                                  onPressed: () => _handleRevoke(perm),
                                ),
                              );
                            }),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
