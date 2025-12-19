import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfile {
  final String uid;
  final String name;
  final String email;
  final String? avatarUrl; // 🆕 Thêm trường avatar
  final DateTime createdAt;

  UserProfile({
    required this.uid,
    required this.name,
    required this.email,
    this.avatarUrl, // 🆕 Avatar có thể null
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'avatarUrl': avatarUrl, // 🆕 Lưu avatar URL
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  // Create from Firestore
  factory UserProfile.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return UserProfile(
      uid: doc.id,
      name: data['name'] ?? 'Người dùng',
      email: data['email'] ?? '',
      avatarUrl: data['avatarUrl'], // 🆕 Lấy avatar URL
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }
}