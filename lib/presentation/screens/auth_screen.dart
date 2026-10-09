import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../logic/controllers/auth_controller.dart';

/// Màn hình đăng nhập tài khoản sinh viên qua Google Sign-In
class AuthScreen extends StatelessWidget {
  const AuthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authController = context.watch<AuthController>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 450),
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 36,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Icon ứng dụng
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.school_rounded,
                          size: 44,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Tiêu đề
                    Text(
                      AppConstants.appName,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),

                    Text(
                      'Hệ thống Quản lý Tài liệu Học tập Tích hợp Cloud\n(Firebase Authentication & Firestore)',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: Theme.of(context).colorScheme.onSurface
                            .withValues(alpha: 0.7),
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 28),

                    const Divider(),
                    const SizedBox(height: 20),

                    // Thông báo lỗi nếu có
                    if (authController.errorMessage != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.error.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.error.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.error_outline_rounded,
                              color: AppColors.error,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                authController.errorMessage!,
                                style: const TextStyle(
                                  color: AppColors.error,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],

                    // Nút Đăng nhập bằng Google
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: isDark
                              ? Colors.white
                              : Colors.black87,
                          foregroundColor: isDark
                              ? Colors.black87
                              : Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 2,
                        ),
                        onPressed: authController.isLoading
                            ? null
                            : () async {
                                await authController.signInWithGoogle();
                              },
                        icon: authController.isLoading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Image.network(
                                'https://www.gstatic.com/firebasejs/ui/2.0.0/images/auth/google.svg',
                                width: 22,
                                height: 22,
                                errorBuilder: (context, error, stackTrace) =>
                                    const Icon(
                                      Icons.account_circle_rounded,
                                      size: 24,
                                    ),
                              ),
                        label: Text(
                          authController.isLoading
                              ? 'Đang kết nối Google...'
                              : 'ĐĂNG NHẬP BẰNG GOOGLE',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Chú thích an toàn
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.lock_outline_rounded,
                          size: 14,
                          color: Theme.of(context).colorScheme.onSurface
                              .withValues(alpha: 0.5),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Xác thực an toàn qua Google OAuth 2.0',
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).colorScheme.onSurface
                                .withValues(alpha: 0.5),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
