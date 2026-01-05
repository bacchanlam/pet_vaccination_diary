// lib/services/vaccination_notification_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/vaccination.dart';
import '../models/pet.dart';

class VaccinationNotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Check và tạo thông báo cho tất cả vaccinations sắp đến hạn
  Future<void> checkAndCreateVaccinationReminders() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      print('🔍 Checking vaccination reminders for user: ${user.uid}');

      // Lấy tất cả pets của user
      final petsSnapshot = await _firestore
          .collection('pets')
          .where('userId', isEqualTo: user.uid)
          .get();

      if (petsSnapshot.docs.isEmpty) {
        print('📭 No pets found');
        return;
      }

      final petIds = petsSnapshot.docs.map((doc) => doc.id).toList();
      
      // Tạo map petId -> petName
      final petMap = <String, String>{};
      for (var doc in petsSnapshot.docs) {
        final pet = Pet.fromFirestore(doc);
        petMap[pet.id!] = pet.name;
      }

      // 🔥 FIX: Load tất cả reminders hiện có TRƯỚC để check duplicate
      final existingReminders = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: user.uid)
          .where('type', isEqualTo: 'vaccine_reminder')
          .get();

      // Tạo Set để check nhanh: vaccinationId-nextDate
      final existingKeys = <String>{};
      for (var doc in existingReminders.docs) {
        final data = doc.data();
        final vaccinationId = data['vaccinationId'] as String?;
        final nextDate = data['nextVaccinationDate'] as Timestamp?;
        
        if (vaccinationId != null && nextDate != null) {
          final dateStr = _formatDate(nextDate.toDate());
          existingKeys.add('$vaccinationId-$dateStr');
        }
      }

      print('📌 Found ${existingKeys.length} existing reminders');

      // Lấy tất cả vaccinations
      final vaccinationsSnapshot = await _firestore
          .collection('vaccinations')
          .where('petId', whereIn: petIds)
          .get();

      int createdCount = 0;
      int skippedCount = 0;

      for (var doc in vaccinationsSnapshot.docs) {
        final vaccination = Vaccination.fromFirestore(doc);
        
        if (vaccination.nextDate == null) continue;

        final nextDate = DateTime(
          vaccination.nextDate!.year,
          vaccination.nextDate!.month,
          vaccination.nextDate!.day,
        );
        final today = DateTime.now();
        final todayOnly = DateTime(today.year, today.month, today.day);
        final daysRemaining = nextDate.difference(todayOnly).inDays;

        // Chỉ xử lý nếu còn 0-3 ngày
        if (daysRemaining >= 0 && daysRemaining <= 3) {
          final key = '${vaccination.id}-${_formatDate(nextDate)}';
          
          // 🔥 FIX: Kiểm tra trong Set đã load sẵn
          if (existingKeys.contains(key)) {
            print('⏭️  Skip: ${vaccination.vaccineName} (already exists)');
            skippedCount++;
            continue;
          }

          // Tạo mới
          await _createVaccinationReminder(
            vaccination: vaccination,
            petName: petMap[vaccination.petId] ?? 'Thú cưng',
            daysRemaining: daysRemaining,
          );
          
          createdCount++;
          existingKeys.add(key); // Thêm vào Set để tránh duplicate trong cùng 1 lần check
        }
      }

      print('✅ Vaccination check completed: Created $createdCount, Skipped $skippedCount');
    } catch (e) {
      print('❌ Error checking vaccination reminders: $e');
    }
  }

  /// Tạo thông báo vaccine reminder (không kiểm tra duplicate nữa - đã check ở trên)
  Future<void> _createVaccinationReminder({
    required Vaccination vaccination,
    required String petName,
    required int daysRemaining,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final nextDateOnly = DateTime(
        vaccination.nextDate!.year,
        vaccination.nextDate!.month,
        vaccination.nextDate!.day,
      );

      final notification = {
        'userId': user.uid,
        'fromUserId': 'system',
        'fromUserName': 'Hệ thống',
        'fromUserAvatar': null,
        'type': 'vaccine_reminder',
        'postId': null,
        'vaccinationId': vaccination.id,
        'petId': vaccination.petId,
        'petName': petName,
        'vaccineName': vaccination.vaccineName,
        'daysRemaining': daysRemaining,
        'nextVaccinationDate': Timestamp.fromDate(nextDateOnly),
        'commentContent': null,
        'isRead': false,
        'createdAt': Timestamp.fromDate(DateTime.now()),
      };

      await _firestore.collection('notifications').add(notification);

      print('✅ Created: ${vaccination.vaccineName} - $daysRemaining days');
    } catch (e) {
      print('❌ Error creating reminder: $e');
    }
  }

  /// Helper: Format date to string (yyyy-MM-dd)
  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  /// Xóa thông báo vaccine đã qua ngày tiêm
  Future<void> cleanupExpiredVaccinationReminders() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      
      final expiredNotifications = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: user.uid)
          .where('type', isEqualTo: 'vaccine_reminder')
          .where('nextVaccinationDate', isLessThan: Timestamp.fromDate(today))
          .get();

      for (var doc in expiredNotifications.docs) {
        await doc.reference.delete();
      }

      if (expiredNotifications.docs.isNotEmpty) {
        print('🗑️ Cleaned up ${expiredNotifications.docs.length} expired reminders');
      }
    } catch (e) {
      print('❌ Error cleaning expired reminders: $e');
    }
  }

  /// Xóa tất cả duplicate notifications
  Future<void> cleanupDuplicateReminders() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      print('🧹 Cleaning up duplicate reminders...');
      
      final allReminders = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: user.uid)
          .where('type', isEqualTo: 'vaccine_reminder')
          .orderBy('createdAt', descending: false)
          .get();

      // Group by vaccinationId + nextVaccinationDate
      final Map<String, List<QueryDocumentSnapshot>> grouped = {};
      
      for (var doc in allReminders.docs) {
        final data = doc.data();
        final vaccinationId = data['vaccinationId'] as String?;
        final nextDate = data['nextVaccinationDate'] as Timestamp?;
        
        if (vaccinationId != null && nextDate != null) {
          final key = '$vaccinationId-${_formatDate(nextDate.toDate())}';
          if (!grouped.containsKey(key)) {
            grouped[key] = [];
          }
          grouped[key]!.add(doc);
        }
      }

      // Xóa duplicates (giữ lại cái đầu tiên)
      int deletedCount = 0;
      for (var group in grouped.values) {
        if (group.length > 1) {
          // Giữ cái đầu tiên, xóa các cái còn lại
          for (var i = 1; i < group.length; i++) {
            await group[i].reference.delete();
            deletedCount++;
          }
        }
      }

      print('✅ Cleaned up $deletedCount duplicate reminders');
    } catch (e) {
      print('❌ Error cleaning duplicates: $e');
    }
  }
}