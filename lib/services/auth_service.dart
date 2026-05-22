import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  AuthService._();

  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final GoogleSignIn _googleSignIn = GoogleSignIn();

  static bool get isGoogleSignInSupported {
    if (kIsWeb) return true;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        return true;
      default:
        return false;
    }
  }

  static bool get _usesGoogleSignInPlugin {
    if (kIsWeb) return false;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        return true;
      default:
        return false;
    }
  }

  /// Stream trạng thái đăng nhập
  static Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Người dùng hiện tại
  static User? get currentUser => _auth.currentUser;

  // ─── ĐĂNG KÝ bằng Email/Password ───────────────────────────────────────────
  static Future<UserCredential> registerWithEmail({
    required String email,
    required String password,
    String? displayName,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    if (displayName != null && displayName.isNotEmpty) {
      await credential.user?.updateDisplayName(displayName.trim());
      await credential.user?.reload();
    }
    return credential;
  }

  // ─── ĐĂNG NHẬP bằng Email/Password ─────────────────────────────────────────
  static Future<UserCredential> signInWithEmail({
    required String email,
    required String password,
  }) async {
    return await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  // ─── ĐĂNG NHẬP bằng Google ──────────────────────────────────────────────────
  static Future<UserCredential?> signInWithGoogle() async {
    if (!isGoogleSignInSupported) {
      throw UnsupportedError(
        'Google Sign-In hiện chưa hỗ trợ trên nền tảng này. '
        'Vui lòng đăng nhập bằng Email/Mật khẩu.',
      );
    }

    try {
      if (kIsWeb) {
        final provider = GoogleAuthProvider();
        return await _auth.signInWithPopup(provider);
      }

      if (_usesGoogleSignInPlugin) {
        final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
        if (googleUser == null) return null; // Người dùng hủy

        final GoogleSignInAuthentication googleAuth =
            await googleUser.authentication;

        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        return await _auth.signInWithCredential(credential);
      }
    } on MissingPluginException {
      throw UnsupportedError(
        'Google Sign-In plugin chưa khả dụng trên thiết bị này. '
        'Vui lòng đăng nhập bằng Email/Mật khẩu.',
      );
    }
    return null;
  }

  // ─── QUÊN MẬT KHẨU ──────────────────────────────────────────────────────────
  static Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email.trim());
  }

  // ─── ĐĂNG XUẤT ──────────────────────────────────────────────────────────────
  static Future<void> signOut() async {
    await _auth.signOut();
    if (_usesGoogleSignInPlugin) {
      try {
        await _googleSignIn.signOut();
      } on MissingPluginException {
        // Ignore when plugin is unavailable on current platform.
      }
    }
  }

  // ─── Chuyển lỗi Firebase sang tiếng Việt ───────────────────────────────────
  static String getErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'Không tìm thấy tài khoản với email này.';
      case 'wrong-password':
        return 'Mật khẩu không đúng.';
      case 'email-already-in-use':
        return 'Email này đã được sử dụng.';
      case 'weak-password':
        return 'Mật khẩu quá yếu (tối thiểu 6 ký tự).';
      case 'invalid-email':
        return 'Địa chỉ email không hợp lệ.';
      case 'user-disabled':
        return 'Tài khoản đã bị vô hiệu hóa.';
      case 'too-many-requests':
        return 'Quá nhiều lần thử. Vui lòng thử lại sau.';
      case 'network-request-failed':
        return 'Lỗi kết nối mạng. Vui lòng kiểm tra internet.';
      case 'invalid-credential':
        return 'Thông tin đăng nhập không hợp lệ.';
      case 'operation-not-supported':
        return 'Đăng nhập Google chưa hỗ trợ trên nền tảng desktop native. '
            'Bạn có thể dùng Email/Mật khẩu hoặc chạy bản web.';
      default:
        return 'Đã xảy ra lỗi: ${e.message}';
    }
  }
}
