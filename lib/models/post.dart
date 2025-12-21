import 'package:cloud_firestore/cloud_firestore.dart';

class Post {
  final String? id;
  final String userId;
  final String userName;
  final String? userAvatar;
  final String content;
  final String? imageUrl;
  final List<String> likes; // Danh sách userId đã like
  final int commentCount;
  final DateTime createdAt;

  Post({
    this.id,
    required this.userId,
    required this.userName,
    this.userAvatar,
    required this.content,
    this.imageUrl,
    List<String>? likes,
    this.commentCount = 0,
    DateTime? createdAt,
  })  : likes = likes ?? [],
        createdAt = createdAt ?? DateTime.now();

  // Convert to Map
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      'userAvatar': userAvatar,
      'content': content,
      'imageUrl': imageUrl,
      'likes': likes,
      'commentCount': commentCount,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  // Create from Firestore
  factory Post.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Post(
      id: doc.id,
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? 'Unknown',
      userAvatar: data['userAvatar'],
      content: data['content'] ?? '',
      imageUrl: data['imageUrl'],
      likes: List<String>.from(data['likes'] ?? []),
      commentCount: data['commentCount'] ?? 0,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  // Check if user liked
  bool isLikedBy(String userId) {
    return likes.contains(userId);
  }

  // Get like count
  int get likeCount => likes.length;
}