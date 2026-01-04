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
      
      // Tạo map petId -> petName để dễ lookup
      final petMap = <String, String>{};
      for (var doc in petsSnapshot.docs) {
        final pet = Pet.fromFirestore(doc);
        petMap[pet.id!] = pet.name;
      }

      // Lấy tất cả vaccinations có nextDate trong 3 ngày tới
      final now = DateTime.now();
      final threeDaysLater = now.add(const Duration(days: 3));

      final vaccinationsSnapshot = await _firestore
          .collection('vaccinations')
          .where('petId', whereIn: petIds)
          .get();

      for (var doc in vaccinationsSnapshot.docs) {
        final vaccination = Vaccination.fromFirestore(doc);
        
        // Chỉ xử lý nếu có nextDate
        if (vaccination.nextDate == null) continue;

        // Tính số ngày còn lại (bỏ qua giờ)
        final nextDate = DateTime(
          vaccination.nextDate!.year,
          vaccination.nextDate!.month,
          vaccination.nextDate!.day,
        );
        final today = DateTime(now.year, now.month, now.day);
        final daysRemaining = nextDate.difference(today).inDays;

        print('📋 Vaccination: ${vaccination.vaccineName}, Days remaining: $daysRemaining');

        // Chỉ tạo thông báo nếu còn 0-3 ngày
        if (daysRemaining >= 0 && daysRemaining <= 3) {
          await _createOrUpdateVaccinationReminder(
            vaccination: vaccination,
            petName: petMap[vaccination.petId] ?? 'Thú cưng',
            daysRemaining: daysRemaining,
          );
        }
      }

      print('✅ Vaccination reminders check completed');
    } catch (e) {
      print('❌ Error checking vaccination reminders: $e');
    }
  }

  /// Tạo hoặc update thông báo vaccine reminder
  Future<void> _createOrUpdateVaccinationReminder({
    required Vaccination vaccination,
    required String petName,
    required int daysRemaining,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      // Tạo unique identifier cho thông báo này (để tránh duplicate mỗi ngày)
      // Format: vaccine_{vaccinationId}_{date}
      final today = DateTime.now();
      final dateKey = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
      
      // Kiểm tra xem đã có thông báo cho vaccination này hôm nay chưa
      final existingNotification = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: user.uid)
          .where('type', isEqualTo: 'vaccine_reminder')
          .where('vaccinationId', isEqualTo: vaccination.id)
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(
            DateTime(today.year, today.month, today.day),
          ))
          .limit(1)
          .get();

      if (existingNotification.docs.isNotEmpty) {
        print('⚠️ Reminder already exists for today: ${vaccination.vaccineName}');
        return;
      }

      // Tạo thông báo mới
      final notification = {
        'userId': user.uid,
        'fromUserId': 'system', // System notification
        'fromUserName': 'Hệ thống',
        'fromUserAvatar': null,
        'type': 'vaccine_reminder',
        'postId': null,
        'vaccinationId': vaccination.id,
        'petId': vaccination.petId,
        'petName': petName,
        'vaccineName': vaccination.vaccineName,
        'daysRemaining': daysRemaining,
        'nextVaccinationDate': Timestamp.fromDate(vaccination.nextDate!),
        'commentContent': null,
        'isRead': false,
        'createdAt': Timestamp.fromDate(DateTime.now()),
      };

      await _firestore.collection('notifications').add(notification);

      print('✅ Created vaccine reminder: ${vaccination.vaccineName} - $daysRemaining days');
    } catch (e) {
      print('❌ Error creating vaccination reminder: $e');
    }
  }

  /// Xóa tất cả thông báo vaccine đã qua ngày tiêm
  Future<void> cleanupExpiredVaccinationReminders() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final now = DateTime.now();
      
      final expiredNotifications = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: user.uid)
          .where('type', isEqualTo: 'vaccine_reminder')
          .where('nextVaccinationDate', isLessThan: Timestamp.fromDate(now))
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
}