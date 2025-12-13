import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Auth state changes stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign up with email and password
  Future<String?> signUp({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Update display name
      await result.user?.updateDisplayName(name);
      
      return null; // Success
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'weak-password':
          return 'Mật khẩu quá yếu, vui lòng chọn mật khẩu mạnh hơn';
        case 'email-already-in-use':
          return 'Email này đã được sử dụng';
        case 'invalid-email':
          return 'Email không hợp lệ';
        default:
          return 'Đã xảy ra lỗi: ${e.message}';
      }
    } catch (e) {
      return 'Đã xảy ra lỗi không xác định';
    }
  }

  // Sign in with email and password
  Future<String?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return null; // Success
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'user-not-found':
          return 'Không tìm thấy tài khoản với email này';
        case 'wrong-password':
          return 'Mật khẩu không chính xác';
        case 'invalid-email':
          return 'Email không hợp lệ';
        case 'user-disabled':
          return 'Tài khoản đã bị vô hiệu hóa';
        default:
          return 'Đã xảy ra lỗi: ${e.message}';
      }
    } catch (e) {
      return 'Đã xảy ra lỗi không xác định';
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Reset password
  Future<String?> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return null; // Success
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'user-not-found':
          return 'Không tìm thấy tài khoản với email này';
        case 'invalid-email':
          return 'Email không hợp lệ';
        default:
          return 'Đã xảy ra lỗi: ${e.message}';
      }
    } catch (e) {
      return 'Đã xảy ra lỗi không xác định';
    }
  }
}