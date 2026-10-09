import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../services/auth_service.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

/// Controller quản lý trạng thái xác thực người dùng trong toàn ứng dụng
class AuthController extends ChangeNotifier {
  final AuthService? authService;
  final String? testUid;
  StreamSubscription<User?>? _authSubscription;

  AuthStatus _status = AuthStatus.initial;
  User? _user;
  String? _errorMessage;

  AuthController({this.authService, this.testUid}) {
    _init();
  }

  AuthStatus get status => _status;
  User? get user => _user;
  String? get currentUid =>
      _status == AuthStatus.authenticated ? (testUid ?? _user?.uid) : null;
  String? get errorMessage => _errorMessage;

  bool get isLoading => _status == AuthStatus.loading;
  bool get isAuthenticated =>
      _status == AuthStatus.authenticated && (_user != null || testUid != null);
  bool get isUnauthenticated => !isAuthenticated;

  void _init() {
    if (testUid != null) {
      _status = AuthStatus.authenticated;
      notifyListeners();
      return;
    }

    final service = authService;
    if (service != null) {
      _user = service.currentUser;
      _status = _user != null
          ? AuthStatus.authenticated
          : AuthStatus.unauthenticated;
      notifyListeners();

      _authSubscription = service.authStateChanges.listen((firebaseUser) {
        _user = firebaseUser;
        if (firebaseUser != null) {
          _status = AuthStatus.authenticated;
          _errorMessage = null;
        } else {
          _status = AuthStatus.unauthenticated;
        }
        notifyListeners();
      });
    } else {
      _status = AuthStatus.unauthenticated;
      notifyListeners();
    }
  }

  /// Thực hiện đăng nhập Google
  Future<bool> signInWithGoogle() async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();

    final service = authService;
    if (service == null) {
      _errorMessage = 'AuthService chưa được cấu hình';
      _status = AuthStatus.error;
      notifyListeners();
      return false;
    }

    try {
      final credential = await service.signInWithGoogle();
      _user = credential.user;
      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'popup-closed-by-user' || e.code == 'cancelled') {
        _errorMessage = 'Bạn đã hủy hộp thoại đăng nhập Google.';
      } else if (e.code == 'network-request-failed') {
        _errorMessage = 'Lỗi kết nối mạng khi xác thực. Vui lòng thử lại.';
      } else {
        _errorMessage = 'Lỗi đăng nhập Google (${e.code}): ${e.message}';
      }
      _status = _user != null
          ? AuthStatus.authenticated
          : AuthStatus.unauthenticated;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Đã xảy ra lỗi không xác định khi đăng nhập: $e';
      _status = _user != null
          ? AuthStatus.authenticated
          : AuthStatus.unauthenticated;
      notifyListeners();
      return false;
    }
  }

  /// Đăng xuất tài khoản
  Future<void> signOut() async {
    _status = AuthStatus.loading;
    notifyListeners();
    final service = authService;
    if (service == null) {
      _user = null;
      _status = AuthStatus.unauthenticated;
      _errorMessage = null;
      notifyListeners();
      return;
    }
    try {
      await service.signOut();
      _user = null;
      _status = AuthStatus.unauthenticated;
      _errorMessage = null;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Lỗi khi đăng xuất: $e';
      _status = _user != null
          ? AuthStatus.authenticated
          : AuthStatus.unauthenticated;
      notifyListeners();
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}
