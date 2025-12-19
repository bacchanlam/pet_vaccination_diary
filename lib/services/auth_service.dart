import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Auth state changes stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // 🆕 Lưu thông tin user vào Firestore
  Future<void> _saveUserToFirestore(User user, String name) async {
    try {
      final userProfile = UserProfile(
        uid: user.uid,
        name: name,
        email: user.email ?? '',
        avatarUrl: null, // Ban đầu chưa có avatar
      );

      await _firestore
          .collection('users')
          .doc(user.uid)
          .set(userProfile.toMap());

      print('✅ User profile saved to Firestore');
    } catch (e) {
      print('❌ Error saving user to Firestore: $e');
    }
  }

  // Sign up with email and password
  Future<String?> signUp({
    required String email,
    required String password,
    required String name,
  }) async {
    User? createdUser;

    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      createdUser = result.user;

      // Update display name
      await result.user?.updateDisplayName(name);

      // 🆕 Lưu thông tin user vào Firestore
      if (createdUser != null) {
        await _saveUserToFirestore(createdUser, name);
      }

      // Gửi email xác thực
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
      final errorString = e.toString();
      print('⚠️ Caught error: $errorString');

      if (errorString.contains('PigeonUserDetails') ||
          errorString.contains('List<Object?>')) {
        print(
          '⚠️ Known Firebase bug detected - checking if signup succeeded...',
        );

        if (createdUser != null) {
          print('✅ User was created successfully: ${createdUser.email}');

          // Lưu vào Firestore
          await _saveUserToFirestore(createdUser, name);

          try {
            await createdUser.sendEmailVerification();
            print('✅ Verification email sent to ${createdUser.email}');
          } catch (emailError) {
            print('⚠️ Error sending verification email: $emailError');
          }

          return null;
        }

        await Future.delayed(const Duration(milliseconds: 300));
        final currentUser = _auth.currentUser;

        if (currentUser != null) {
          print('✅ Found user in currentUser: ${currentUser.email}');

          await _saveUserToFirestore(currentUser, name);

          try {
            await currentUser.sendEmailVerification();
            print('✅ Verification email sent');
          } catch (emailError) {
            print('⚠️ Error sending verification email: $emailError');
          }

          return null;
        }

        print('❌ Cannot find created user - signup may have failed');
        return 'Đăng ký có thể thành công. Hãy thử đăng nhập để kiểm tra.';
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
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      print('🔐 Sign in successful, checking email verification...');

      try {
        await result.user?.reload();
      } catch (e) {
        print('⚠️ Firebase reload bug (PigeonUserDetails) ignored: $e');
      }

      final user = _auth.currentUser;

      if (user == null) {
        print('❌ User is null after sign in');
        await _auth.signOut();
        return 'Lỗi đăng nhập: Không tìm thấy người dùng';
      }

      print('📧 Email verified status: ${user.emailVerified}');

      if (!user.emailVerified) {
        print(
          '⚠️ Email not verified - keeping user signed in for verification check',
        );
        return 'EMAIL_NOT_VERIFIED';
      }

      print('✅ Email verified - Login successful');
      return null;
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
      final errorString = e.toString();
      print('⚠️ Caught sign in error in main catch: $errorString');

      if (errorString.contains('PigeonUserDetails') ||
          errorString.contains('List<Object?>')) {
        await Future.delayed(const Duration(milliseconds: 500));

        final currentUser = _auth.currentUser;
        if (currentUser != null) {
          if (!currentUser.emailVerified) {
            return 'EMAIL_NOT_VERIFIED';
          }
          return null;
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

      try {
        await user.reload();
      } catch (e) {
        print('⚠️ Firebase reload bug (PigeonUserDetails) ignored: $e');
      }

      final reloadedUser = _auth.currentUser;
      final isVerified = reloadedUser?.emailVerified ?? false;

      print('📧 Email verification status: $isVerified');
      return isVerified;
    } catch (e) {
      print('❌ Error checking email verification: $e');

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
      return null;
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
      return null;
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

      if (e.toString().contains('PigeonUserDetails') ||
          e.toString().contains('List<Object?>')) {
        print('⚠️ PigeonUserDetails error but email likely sent');
        return null;
      }

      return 'Lỗi không xác định: $e';
    }
  }

  // 🆕 Cập nhật thông tin user profile
  Future<String?> updateUserProfile({
    required String uid,
    String? name,
    String? avatarUrl,
  }) async {
    try {
      final Map<String, dynamic> updates = {};

      if (name != null) {
        updates['name'] = name;
        try {
          // Đây là dòng gây lỗi Pigeon trên Android
          await _auth.currentUser?.updateDisplayName(name);
        } catch (e) {
          print('⚠️ Firebase updateDisplayName bug ignored: $e');
          // Nếu là lỗi Pigeon, ta vẫn tiếp tục vì Firestore quan trọng hơn
        }
      }

      if (avatarUrl != null) {
        updates['avatarUrl'] = avatarUrl;
      }

      if (updates.isNotEmpty) {
        await _firestore.collection('users').doc(uid).update(updates);

        print('✅ User profile updated successfully in Firestore');
      }

      return null;
    } catch (e) {
      final errorString = e.toString();
      // Kiểm tra nếu là lỗi Pigeon thì vẫn coi như thành công nếu Firestore đã xong
      if (errorString.contains('Pigeon') ||
          errorString.contains('List<Object?>')) {
        print('⚠️ Ignored Pigeon error during profile update');
        return null;
      }

      print('❌ Error updating user profile: $e');
      return 'Lỗi cập nhật thông tin: $e';
    }
  }

  // 🆕 Lấy thông tin user profile từ Firestore
  Future<UserProfile?> getUserProfile(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();

      if (doc.exists) {
        return UserProfile.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('❌ Error getting user profile: $e');
      return null;
    }
  }
}
