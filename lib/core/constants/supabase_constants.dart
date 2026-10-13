/// Cấu hình thông số kết nối Supabase Cloud.
///
/// Để kết nối ứng dụng với CSDL Supabase:
/// 1. Đăng nhập https://supabase.com và mở Project của bạn.
/// 2. Vào Project Settings -> API.
/// 3. Sao chép Project URL và anon/public Key dán vào dưới đây.
class SupabaseConstants {
  SupabaseConstants._();

  /// URL của Supabase Project (Ví dụ: 'https://abcdefghijklmn.supabase.co')
  static const String url = 'https://macwgisvzpakbmoiyufl.supabase.co';

  /// Khóa công khai anon key của Supabase Project
  static const String anonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1hY3dnaXN2enBha2Jtb2l5dWZsIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTE4OTI4NTEsImV4cCI6MjEwNzQ2ODg1MX0.4mVfLYJafePWDfWhePgJrgvc4y_zOcLGg60pLBnz6b0';

  /// Kiểm tra xem người dùng đã cấu hình thông số Supabase thật hay chưa
  static bool get isConfigured =>
      url.isNotEmpty &&
      anonKey.isNotEmpty &&
      !url.contains('YOUR_PROJECT_ID') &&
      !anonKey.contains('YOUR_SUPABASE_ANON_KEY');
}
