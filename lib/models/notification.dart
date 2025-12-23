// lib/models/notification.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart'; // 🆕 THÊM DÒNG NÀY

class AppNotification {
  final String? id;
  final String userId; // Người nhận thông báo
  final String fromUserId; // Người gửi (like/comment)
  final String fromUserName;
  final String? fromUserAvatar;
  final String type; // 'like' hoặc 'comment'
  final String postId;
  final String? commentContent; // Nội dung comment nếu type là 'comment'
  final bool isRead;
  final DateTime createdAt;

  AppNotification({
    this.id,
    required this.userId,
    required this.fromUserId,
    required this.fromUserName,
    this.fromUserAvatar,
    required this.type,
    required this.postId,
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
      fromUserName: data['fromUserName'] ?? 'Unknown',
      fromUserAvatar: data['fromUserAvatar'],
      type: data['type'] ?? 'like',
      postId: data['postId'] ?? '',
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
    }
    return 'Thông báo mới';
  }

  IconData getIcon() {
    return type == 'like' ? Icons.favorite : Icons.comment;
  }

  Color getIconColor() {
    return type == 'like' ? Colors.red : Colors.blue;
  }
}