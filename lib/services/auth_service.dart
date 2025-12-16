import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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
      await result.user?.reload();

      print('✅ Firebase signUp successful');
      return null; // Success
    } on FirebaseAuthException catch (e) {
      print('❌ FirebaseAuthException: ${e.code} - ${e.message}');
      switch (e.code) {
        case 'weak-password':
          return 'Mật khẩu quá yếu, vui lòng chọn mật khẩu mạnh hơn';
        case 'email-already-in-use':
          return 'Email này đã được sử dụng';
        case 'invalid-email':
          return 'Email không hợp lệ';
        default:
          return 'Đăng ký thất bại: ${e.message}';
      }
    } catch (e) {
      // Workaround: Ignore lỗi PigeonUserDetails vì auth vẫn thành công
      if (e.toString().contains('PigeonUserDetails')) {
        print('⚠️ PigeonUserDetails error (known bug) - but auth still works');
        // Check xem user đã đăng nhập chưa
        await Future.delayed(const Duration(milliseconds: 500));
        if (_auth.currentUser != null) {
          print('✅ User registered despite error');
          return null; // Actually successful
        }
      }
      print('❌ Unknown error: $e');
      return 'Lỗi không xác định: $e';
    }
  }

  // Sign in with email and password
  Future<String?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      print('✅ Firebase signIn successful');
      return null; // Success
    } on FirebaseAuthException catch (e) {
      print('❌ FirebaseAuthException: ${e.code} - ${e.message}');
      switch (e.code) {
        case 'user-not-found':
          return 'Không tìm thấy tài khoản với email này';
        case 'wrong-password':
          return 'Mật khẩu không chính xác';
        case 'invalid-email':
          return 'Email không hợp lệ';
        case 'user-disabled':
          return 'Tài khoản đã bị vô hiệu hóa';
        case 'invalid-credential':
          return 'Email hoặc mật khẩu không chính xác';
        default:
          return 'Đăng nhập thất bại: ${e.message}';
      }
    } catch (e) {
      // Workaround: Ignore lỗi PigeonUserDetails vì auth vẫn thành công
      if (e.toString().contains('PigeonUserDetails')) {
        print('⚠️ PigeonUserDetails error (known bug) - but auth still works');
        // Check xem user đã đăng nhập chưa
        await Future.delayed(const Duration(milliseconds: 500));
        if (_auth.currentUser != null) {
          print('✅ User logged in despite error');
          return null; // Actually successful
        }
      }
      print('❌ Unknown error: $e');
      return 'Lỗi không xác định: $e';
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

  // Gửi lại email xác thực
  Future<String?> resendVerificationEmail() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return 'Không tìm thấy người dùng';
      }

      if (user.emailVerified) {
        return 'Email đã được xác thực';
      }

      await user.sendEmailVerification();
      print('✅ Resend verification email to ${user.email}');
      return null; // Success
    } catch (e) {
      print('❌ Error resending email: $e');
      return 'Lỗi khi gửi email: $e';
    }
  }
}
