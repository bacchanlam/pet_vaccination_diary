import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/notification.dart';
import '../services/vaccination_notification_service.dart';

class NotificationProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<AppNotification> _notifications = [];
  bool _isLoading = false;
  int _unreadCount = 0;

  List<AppNotification> get notifications => _notifications;
  bool get isLoading => _isLoading;
  int get unreadCount => _unreadCount;

  // Load notifications for current user
  Future<void> loadNotifications() async {
    final user = _auth.currentUser;
    if (user == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      final snapshot = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: user.uid)
          .orderBy('createdAt', descending: true)
          .limit(50)
          .get();

      _notifications = snapshot.docs
          .map((doc) => AppNotification.fromFirestore(doc))
          .toList();

      _unreadCount = _notifications.where((n) => !n.isRead).length;

      print(
        '✅ Loaded ${_notifications.length} notifications, unread: $_unreadCount',
      );
    } catch (e) {
      print('❌ Error loading notifications: $e');
      _notifications = [];
      _unreadCount = 0;
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> checkVaccinationReminders() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final service = VaccinationNotificationService();

      // Cleanup expired reminders
      await service.cleanupExpiredVaccinationReminders();

      // Create new reminders
      await service.checkAndCreateVaccinationReminders();

      // Reload notifications
      await loadNotifications();
    } catch (e) {
      print('❌ Error checking vaccination reminders: $e');
    }
  }

  // Create notification when someone likes a post
  Future<void> createLikeNotification({
    required String postOwnerId,
    required String postId,
    required String fromUserName,
    String? fromUserAvatar,
  }) async {
    final user = _auth.currentUser;
    if (user == null || user.uid == postOwnerId) {
      print('⚠️ Skip notification: user is null or liking own post');
      return;
    }

    try {
      print('🔔 Creating like notification...');

      final existingNotification = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: postOwnerId)
          .where('fromUserId', isEqualTo: user.uid)
          .where('postId', isEqualTo: postId)
          .where('type', isEqualTo: 'like')
          .limit(1)
          .get();

      if (existingNotification.docs.isNotEmpty) {
        print('⚠️ Like notification already exists, skipping...');
        return;
      }

      final notification = AppNotification(
        userId: postOwnerId,
        fromUserId: user.uid,
        fromUserName: fromUserName,
        fromUserAvatar: fromUserAvatar,
        type: 'like',
        postId: postId,
      );

      await _firestore.collection('notifications').add(notification.toMap());
      print('✅ Like notification created successfully!');
    } catch (e) {
      print('❌ Error creating like notification: $e');
    }
  }

  // Delete like notification when someone unlikes
  Future<void> deleteLikeNotification({
    required String postOwnerId,
    required String postId,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      print('🗑️ Deleting like notification...');

      final snapshot = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: postOwnerId)
          .where('fromUserId', isEqualTo: user.uid)
          .where('postId', isEqualTo: postId)
          .where('type', isEqualTo: 'like')
          .limit(1)
          .get();

      for (var doc in snapshot.docs) {
        await doc.reference.delete();
        print('✅ Deleted notification: ${doc.id}');
      }

      if (snapshot.docs.isEmpty) {
        print('⚠️ No like notification found to delete');
      }
    } catch (e) {
      print('❌ Error deleting like notification: $e');
    }
  }

  // Create notification when someone comments
  Future<void> createCommentNotification({
    required String postOwnerId,
    required String postId,
    required String fromUserName,
    String? fromUserAvatar,
    required String commentContent,
  }) async {
    final user = _auth.currentUser;
    if (user == null || user.uid == postOwnerId) {
      return;
    }

    try {
      final notification = AppNotification(
        userId: postOwnerId,
        fromUserId: user.uid,
        fromUserName: fromUserName,
        fromUserAvatar: fromUserAvatar,
        type: 'comment',
        postId: postId,
        commentContent: commentContent.length > 50
            ? '${commentContent.substring(0, 50)}...'
            : commentContent,
      );

      await _firestore.collection('notifications').add(notification.toMap());
      print('✅ Comment notification created');
    } catch (e) {
      print('❌ Error creating comment notification: $e');
    }
  }

  Future<void> markAsRead(String notificationId) async {
    try {
      await _firestore.collection('notifications').doc(notificationId).update({
        'isRead': true,
      });

      final index = _notifications.indexWhere((n) => n.id == notificationId);
      if (index != -1) {
        final oldNotification = _notifications[index];

        _notifications[index] = AppNotification(
          id: oldNotification.id,
          userId: oldNotification.userId,
          fromUserId: oldNotification.fromUserId,
          fromUserName: oldNotification.fromUserName,
          fromUserAvatar: oldNotification.fromUserAvatar,
          type: oldNotification.type,
          postId: oldNotification.postId,
          vaccinationId: oldNotification.vaccinationId,
          petId: oldNotification.petId,
          petName: oldNotification.petName,
          vaccineName: oldNotification.vaccineName,
          daysRemaining: oldNotification.daysRemaining,
          nextVaccinationDate: oldNotification.nextVaccinationDate,
          commentContent: oldNotification.commentContent,
          isRead: true,
          createdAt: oldNotification.createdAt,
        );

        // Recalculate unread count
        _unreadCount = _notifications.where((n) => !n.isRead).length;

        print('✅ Notification marked as read - Unread count: $_unreadCount');
        notifyListeners();
      }
    } catch (e) {
      print('❌ Error marking notification as read: $e');
    }
  }

  // Mark all as read
  Future<void> markAllAsRead() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final unreadNotifs = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: user.uid)
          .where('isRead', isEqualTo: false)
          .get();

      for (var doc in unreadNotifs.docs) {
        await doc.reference.update({'isRead': true});
      }

      // Update local state
      for (var i = 0; i < _notifications.length; i++) {
        if (!_notifications[i].isRead) {
          final oldNotification = _notifications[i];
          _notifications[i] = AppNotification(
            id: oldNotification.id,
            userId: oldNotification.userId,
            fromUserId: oldNotification.fromUserId,
            fromUserName: oldNotification.fromUserName,
            fromUserAvatar: oldNotification.fromUserAvatar,
            type: oldNotification.type,
            postId: oldNotification.postId,
            vaccinationId: oldNotification.vaccinationId,
            petId: oldNotification.petId,
            petName: oldNotification.petName,
            vaccineName: oldNotification.vaccineName,
            daysRemaining: oldNotification.daysRemaining,
            nextVaccinationDate: oldNotification.nextVaccinationDate,
            commentContent: oldNotification.commentContent,
            isRead: true,
            createdAt: oldNotification.createdAt,
          );
        }
      }

      _unreadCount = 0;
      notifyListeners();

      print('✅ All notifications marked as read');
    } catch (e) {
      print('❌ Error marking all as read: $e');
    }
  }

  // Delete notification
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _firestore.collection('notifications').doc(notificationId).delete();

      _notifications.removeWhere((n) => n.id == notificationId);
      _unreadCount = _notifications.where((n) => !n.isRead).length;
      notifyListeners();

      print('✅ Notification deleted');
    } catch (e) {
      print('❌ Error deleting notification: $e');
    }
  }

  // Listen to real-time notifications
  Stream<int> getUnreadCountStream() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value(0);

    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: user.uid)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }
}
