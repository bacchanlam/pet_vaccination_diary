// lib/models/notification.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AppNotification {
  final String? id;
  final String userId; // Người nhận thông báo
  final String fromUserId; // Người gửi (like/comment) hoặc system cho vaccine
  final String fromUserName;
  final String? fromUserAvatar;
  final String type; // 'like', 'comment', 'vaccine_reminder'
  final String? postId; // Cho like/comment
  final String? vaccinationId; // 🆕 Cho vaccine reminder
  final String? petId; // 🆕 Cho vaccine reminder
  final String? petName; // 🆕 Tên thú cưng
  final String? vaccineName; // 🆕 Tên vaccine
  final int? daysRemaining; // 🆕 Số ngày còn lại
  final DateTime? nextVaccinationDate; // 🆕 Ngày tiêm tiếp theo
  final String? commentContent;
  final bool isRead;
  final DateTime createdAt;

  AppNotification({
    this.id,
    required this.userId,
    required this.fromUserId,
    required this.fromUserName,
    this.fromUserAvatar,
    required this.type,
    this.postId,
    this.vaccinationId, // 🆕
    this.petId, // 🆕
    this.petName, // 🆕
    this.vaccineName, // 🆕
    this.daysRemaining, // 🆕
    this.nextVaccinationDate, // 🆕
    this.commentContent,
    this.isRead = false,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'fromUserId': fromUserId,
      'fromUserName': fromUserName,
      'fromUserAvatar': fromUserAvatar,
      'type': type,
      'postId': postId,
      'vaccinationId': vaccinationId, // 🆕
      'petId': petId, // 🆕
      'petName': petName, // 🆕
      'vaccineName': vaccineName, // 🆕
      'daysRemaining': daysRemaining, // 🆕
      'nextVaccinationDate': nextVaccinationDate != null 
          ? Timestamp.fromDate(nextVaccinationDate!) 
          : null, // 🆕
      'commentContent': commentContent,
      'isRead': isRead,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory AppNotification.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return AppNotification(
      id: doc.id,
      userId: data['userId'] ?? '',
      fromUserId: data['fromUserId'] ?? '',
      fromUserName: data['fromUserName'] ?? 'System',
      fromUserAvatar: data['fromUserAvatar'],
      type: data['type'] ?? 'like',
      postId: data['postId'],
      vaccinationId: data['vaccinationId'], // 🆕
      petId: data['petId'], // 🆕
      petName: data['petName'], // 🆕
      vaccineName: data['vaccineName'], // 🆕
      daysRemaining: data['daysRemaining'], // 🆕
      nextVaccinationDate: data['nextVaccinationDate'] != null
          ? (data['nextVaccinationDate'] as Timestamp).toDate()
          : null, // 🆕
      commentContent: data['commentContent'],
      isRead: data['isRead'] ?? false,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  String getMessage() {
    if (type == 'like') {
      return '$fromUserName đã thích bài viết của bạn';
    } else if (type == 'comment') {
      return '$fromUserName đã bình luận: "${commentContent ?? ""}"';
    } else if (type == 'vaccine_reminder') {
      // 🆕 Message cho vaccine reminder
      if (daysRemaining == 0) {
        return '🔔 Hôm nay là ngày tiêm "$vaccineName" cho $petName!';
      } else if (daysRemaining == 1) {
        return '⏰ Còn 1 ngày nữa là đến lịch tiêm "$vaccineName" cho $petName';
      } else {
        return '📅 Còn $daysRemaining ngày nữa là đến lịch tiêm "$vaccineName" cho $petName';
      }
    }
    return 'Thông báo mới';
  }

  IconData getIcon() {
    if (type == 'like') return Icons.favorite;
    if (type == 'comment') return Icons.comment;
    if (type == 'vaccine_reminder') return Icons.vaccines; // 🆕
    return Icons.notifications;
  }

  Color getIconColor() {
    if (type == 'like') return Colors.red;
    if (type == 'comment') return Colors.blue;
    if (type == 'vaccine_reminder') return Colors.orange; // 🆕
    return Colors.grey;
  }
}