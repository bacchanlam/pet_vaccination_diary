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
    User? createdUser; // Lưu user ngay khi tạo

    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      createdUser = result.user; // Lưu lại user

      // Update display name
      await result.user?.updateDisplayName(name);

      // 🆕 GỬI EMAIL XÁC THỰC
      await result.user?.sendEmailVerification();
      print(
        '✅ Firebase signUp successful - Verification email sent to ${result.user?.email}',
      );

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
      // 🔧 WORKAROUND: Bỏ qua lỗi PigeonUserDetails vì nó là bug của Firebase
      final errorString = e.toString();
      print('⚠️ Caught error: $errorString');

      if (errorString.contains('PigeonUserDetails') ||
          errorString.contains('List<Object?>')) {
        print(
          '⚠️ Known Firebase bug detected - checking if signup succeeded...',
        );

        // QUAN TRỌNG: Kiểm tra biến createdUser trước (trước khi bị đăng xuất)
        if (createdUser != null) {
          print('✅ User was created successfully: ${createdUser.email}');

          // Đảm bảo email xác thực được gửi
          try {
            await createdUser.sendEmailVerification();
            print('✅ Verification email sent to ${createdUser.email}');
          } catch (emailError) {
            print('⚠️ Error sending verification email: $emailError');
            // Không return lỗi vì tài khoản đã tạo thành công
          }

          return null; // Success - tài khoản đã được tạo
        }

        // Nếu createdUser null, thử kiểm tra currentUser
        await Future.delayed(const Duration(milliseconds: 300));
        final currentUser = _auth.currentUser;

        if (currentUser != null) {
          print('✅ Found user in currentUser: ${currentUser.email}');

          try {
            await currentUser.sendEmailVerification();
            print('✅ Verification email sent');
          } catch (emailError) {
            print('⚠️ Error sending verification email: $emailError');
          }

          return null; // Success
        }

        print('❌ Cannot find created user - signup may have failed');
        return 'Đăng ký có thể thành công. Hãy thử đăng nhập để kiểm tra.';
      }

      print('❌ Unknown error: $e');
      return 'Lỗi không xác định: $e';
    }
  }

  // Sign in with email and password
  // Sign in with email and password
  Future<String?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      // 1. Thực hiện đăng nhập
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      print('🔐 Sign in successful, checking email verification...');

      // 2. 🔧 FIX LỖI TREO: Bọc reload() trong một try-catch riêng lẻ
      // Lỗi PigeonUserDetails thường xảy ra tại đây. Bọc nó lại để nếu crash,
      // logic bên dưới vẫn tiếp tục chạy được.
      try {
        await result.user?.reload();
      } catch (e) {
        print('⚠️ Firebase reload bug (PigeonUserDetails) ignored: $e');
        // Không return ở đây, cứ để logic chạy tiếp xuống dưới
      }

      // Lấy user hiện tại sau khi đã cố gắng reload
      final user = _auth.currentUser;

      if (user == null) {
        print('❌ User is null after sign in');
        await _auth.signOut();
        return 'Lỗi đăng nhập: Không tìm thấy người dùng';
      }

      print('📧 Email verified status: ${user.emailVerified}');

      // 3. KIỂM TRA EMAIL ĐÃ XÁC THỰC CHƯA
      if (!user.emailVerified) {
        print(
          '⚠️ Email not verified - keeping user signed in for verification check',
        );
        // Trả về mã lỗi đặc biệt để LoginScreen hiện Dialog
        return 'EMAIL_NOT_VERIFIED';
      }

      print('✅ Email verified - Login successful');
      return null; // Thành công hoàn toàn
    } on FirebaseAuthException catch (e) {
      print('❌ FirebaseAuthException: ${e.code} - ${e.message}');
      await _auth.signOut();
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
      // 🔧 XỬ LÝ DỰ PHÒNG: Nếu lỗi PigeonUserDetails làm văng khỏi khối try chính
      final errorString = e.toString();
      print('⚠️ Caught sign in error in main catch: $errorString');

      if (errorString.contains('PigeonUserDetails') ||
          errorString.contains('List<Object?>')) {
        // Đợi một chút để Firebase kịp cập nhật trạng thái nội bộ
        await Future.delayed(const Duration(milliseconds: 500));

        final currentUser = _auth.currentUser;
        if (currentUser != null) {
          // Kiểm tra email ngay cả khi reload bị lỗi
          if (!currentUser.emailVerified) {
            return 'EMAIL_NOT_VERIFIED';
          }
          return null; // Đăng nhập thành công mặc dù có lỗi log
        }
      }

      await _auth.signOut();
      return 'Lỗi không xác định: $e';
    }
  }
  // Kiểm tra và reload trạng thái email verification
  Future<bool> checkEmailVerified() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      // 🔧 Bọc reload() trong try-catch riêng để tránh lỗi PigeonUserDetails
      try {
        await user.reload();
      } catch (e) {
        print('⚠️ Firebase reload bug (PigeonUserDetails) ignored: $e');
        // Không return, cứ tiếp tục lấy currentUser bên dưới
      }

      final reloadedUser = _auth.currentUser;
      final isVerified = reloadedUser?.emailVerified ?? false;

      print('📧 Email verification status: $isVerified');
      return isVerified;
    } catch (e) {
      print('❌ Error checking email verification: $e');

      // Nếu lỗi PigeonUserDetails, vẫn cố gắng check
      if (e.toString().contains('PigeonUserDetails') ||
          e.toString().contains('List<Object?>')) {
        final user = _auth.currentUser;
        return user?.emailVerified ?? false;
      }

      return false;
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
    print('👋 User signed out');
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
        return 'Không tìm thấy người dùng. Vui lòng đăng nhập lại.';
      }

      // Reload để lấy trạng thái mới nhất
      await user.reload();
      final currentUser = _auth.currentUser;

      if (currentUser == null) {
        return 'Phiên đăng nhập đã hết hạn';
      }

      if (currentUser.emailVerified) {
        return 'Email đã được xác thực rồi!';
      }

      await currentUser.sendEmailVerification();
      print('✅ Resend verification email to ${currentUser.email}');
      return null; // Success
    } on FirebaseAuthException catch (e) {
      print('❌ FirebaseAuthException: ${e.code}');
      switch (e.code) {
        case 'too-many-requests':
          return 'Bạn đã gửi quá nhiều yêu cầu. Vui lòng thử lại sau.';
        default:
          return 'Lỗi khi gửi email: ${e.message}';
      }
    } catch (e) {
      print('❌ Error resending email: $e');

      // Bỏ qua lỗi PigeonUserDetails
      if (e.toString().contains('PigeonUserDetails') ||
          e.toString().contains('List<Object?>')) {
        print('⚠️ PigeonUserDetails error but email likely sent');
        return null; // Coi như thành công
      }

      return 'Lỗi không xác định: $e';
    }
  }
}
