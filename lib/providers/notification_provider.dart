import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/notification.dart';

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
      return; // Không tạo thông báo cho chính mình
    }

    try {
      print('🔔 Creating like notification...');
      print('   Post owner: $postOwnerId');
      print('   From user: ${user.uid} ($fromUserName)');
      print('   Post ID: $postId');

      // Tạo thông báo trực tiếp, không kiểm tra duplicate
      // (Firestore sẽ tự động lưu nhiều thông báo nếu like nhiều lần)
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
      print('   Post owner: $postOwnerId');
      print('   From user: ${user.uid}');

      final snapshot = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: postOwnerId)
          .where('fromUserId', isEqualTo: user.uid)
          .where('postId', isEqualTo: postId)
          .where('type', isEqualTo: 'like')
          .limit(1) // Chỉ xóa 1 thông báo
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
    if (user == null || user.uid == postOwnerId)
      return; // Không tạo thông báo cho chính mình

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

  // Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      await _firestore.collection('notifications').doc(notificationId).update({
        'isRead': true,
      });

      // Update local state
      final index = _notifications.indexWhere((n) => n.id == notificationId);
      if (index != -1) {
        _notifications[index] = AppNotification(
          id: _notifications[index].id,
          userId: _notifications[index].userId,
          fromUserId: _notifications[index].fromUserId,
          fromUserName: _notifications[index].fromUserName,
          fromUserAvatar: _notifications[index].fromUserAvatar,
          type: _notifications[index].type,
          postId: _notifications[index].postId,
          commentContent: _notifications[index].commentContent,
          isRead: true,
          createdAt: _notifications[index].createdAt,
        );

        _unreadCount = _notifications.where((n) => !n.isRead).length;
        notifyListeners();
      }

      print('✅ Notification marked as read');
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
          _notifications[i] = AppNotification(
            id: _notifications[i].id,
            userId: _notifications[i].userId,
            fromUserId: _notifications[i].fromUserId,
            fromUserName: _notifications[i].fromUserName,
            fromUserAvatar: _notifications[i].fromUserAvatar,
            type: _notifications[i].type,
            postId: _notifications[i].postId,
            commentContent: _notifications[i].commentContent,
            isRead: true,
            createdAt: _notifications[i].createdAt,
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
