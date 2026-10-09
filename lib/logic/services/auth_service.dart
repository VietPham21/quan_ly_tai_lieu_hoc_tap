import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Dịch vụ quản lý xác thực người dùng thông qua Firebase Authentication.
/// Hỗ trợ Google Sign-In trên Web (qua Popup) và quản lý phiên làm việc.
class AuthService {
  final FirebaseAuth _auth;

  AuthService({FirebaseAuth? auth}) : _auth = auth ?? FirebaseAuth.instance;

  FirebaseAuth get auth => _auth;
  User? get currentUser => _auth.currentUser;
  String? get currentUid => _auth.currentUser?.uid;
  bool get isAuthenticated => _auth.currentUser != null;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Đăng nhập bằng Google qua Firebase Authentication
  /// Tương thích đặc biệt với Flutter Web qua `signInWithPopup`
  Future<UserCredential> signInWithGoogle() async {
    try {
      final googleProvider = GoogleAuthProvider();
      googleProvider.addScope('email');
      googleProvider.addScope('profile');
      googleProvider.setCustomParameters({'prompt': 'select_account'});

      if (kIsWeb) {
        return await _auth.signInWithPopup(googleProvider);
      } else {
        // Hỗ trợ trên các nền tảng khác nếu có cấu hình
        return await _auth.signInWithProvider(googleProvider);
      }
    } on FirebaseAuthException catch (e) {
      debugPrint(
        'AuthService.signInWithGoogle FirebaseAuthException: ${e.code} - ${e.message}',
      );
      rethrow;
    } catch (e) {
      debugPrint('AuthService.signInWithGoogle Error: $e');
      rethrow;
    }
  }

  /// Đăng xuất khỏi hệ thống và xóa phiên làm việc
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      debugPrint('AuthService.signOut Error: $e');
      rethrow;
    }
  }
}
