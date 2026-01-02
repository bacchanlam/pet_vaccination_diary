import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/post.dart';
import '../models/comment.dart';
import 'notification_provider.dart';

class PostProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<Post> _posts = [];
  bool _isLoading = false;

  List<Post> get posts => _posts;
  bool get isLoading => _isLoading;

  // Load all posts
  Future<void> loadPosts() async {
    _isLoading = true;
    notifyListeners();

    try {
      final snapshot = await _firestore
          .collection('posts')
          .orderBy('createdAt', descending: true)
          .limit(50)
          .get();

      _posts = snapshot.docs.map((doc) => Post.fromFirestore(doc)).toList();
      print('✅ Loaded ${_posts.length} posts');
    } catch (e) {
      print('❌ Error loading posts: $e');
      _posts = [];
    }

    _isLoading = false;
    notifyListeners();
  }

  // Create new post
  Future<bool> createPost({
    required String content,
    String? imageUrl,
    required String userName,
    String? userAvatar,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return false;

    try {
      final post = Post(
        userId: user.uid,
        userName: userName,
        userAvatar: userAvatar,
        content: content,
        imageUrl: imageUrl,
      );

      await _firestore.collection('posts').add(post.toMap());
      print('✅ Post created');

      await loadPosts();
      return true;
    } catch (e) {
      print('❌ Error creating post: $e');
      return false;
    }
  }

  // Toggle like
  Future<bool> toggleLike(
    String postId,
    NotificationProvider notificationProvider,
    String userName,
    String? userAvatar,
  ) async {
    final user = _auth.currentUser;
    if (user == null) return false;

    try {
      final postDoc = _firestore.collection('posts').doc(postId);
      final post = await postDoc.get();

      if (!post.exists) return false;

      final postData = Post.fromFirestore(post);
      List<String> likes = List.from(postData.likes);

      bool isLiking = false;

      if (likes.contains(user.uid)) {
        // Unlike
        likes.remove(user.uid);
        print('👎 User unliked post');

        // Xóa thông báo
        await notificationProvider.deleteLikeNotification(
          postOwnerId: postData.userId,
          postId: postId,
        );
      } else {
        // Like
        likes.add(user.uid);
        isLiking = true;
        print('👍 User liked post');
      }

      await postDoc.update({'likes': likes});

      // Update local state
      final index = _posts.indexWhere((p) => p.id == postId);
      if (index != -1) {
        _posts[index] = Post(
          id: postData.id,
          userId: postData.userId,
          userName: postData.userName,
          userAvatar: postData.userAvatar,
          content: postData.content,
          imageUrl: postData.imageUrl,
          likes: likes,
          commentCount: postData.commentCount,
          createdAt: postData.createdAt,
        );
        notifyListeners();
      }

      // 🔔 TẠO THÔNG BÁO KHI LIKE
      if (isLiking) {
        print(
          '🔔 Creating like notification for post owner: ${postData.userId}',
        );
        await notificationProvider.createLikeNotification(
          postOwnerId: postData.userId,
          postId: postId,
          fromUserName: userName,
          fromUserAvatar: userAvatar,
        );
      }

      return true;
    } catch (e) {
      print('❌ Error toggling like: $e');
      return false;
    }
  }

  // Add comment
  Future<bool> addComment({
    required String postId,
    required String content,
    required String userName,
    String? userAvatar,
    required NotificationProvider notificationProvider, // 🆕 THÊM THAM SỐ
  }) async {
    final user = _auth.currentUser;
    if (user == null) return false;

    try {
      final comment = Comment(
        postId: postId,
        userId: user.uid,
        userName: userName,
        userAvatar: userAvatar,
        content: content,
      );

      await _firestore.collection('comments').add(comment.toMap());

      // Tăng commentCount
      final postDoc = await _firestore.collection('posts').doc(postId).get();
      final post = Post.fromFirestore(postDoc);

      await _firestore.collection('posts').doc(postId).update({
        'commentCount': FieldValue.increment(1),
      });

      // 🆕 Tạo thông báo
      await notificationProvider.createCommentNotification(
        postOwnerId: post.userId,
        postId: postId,
        fromUserName: userName,
        fromUserAvatar: userAvatar,
        commentContent: content,
      );

      await loadPosts();
      return true;
    } catch (e) {
      print('❌ Error adding comment: $e');
      return false;
    }
  }

  // Delete comment (chỉ chủ comment mới xóa được)
  Future<bool> deleteComment(String commentId, String userId) async {
    final user = _auth.currentUser;
    if (user == null || user.uid != userId) {
      print('❌ Permission denied: Not comment owner');
      return false;
    }

    try {
      // Get comment để lấy postId
      final commentDoc = await _firestore
          .collection('comments')
          .doc(commentId)
          .get();
      if (!commentDoc.exists) return false;

      final postId = commentDoc.data()?['postId'];

      // Xóa comment
      await _firestore.collection('comments').doc(commentId).delete();

      // Giảm commentCount
      if (postId != null) {
        await _firestore.collection('posts').doc(postId).update({
          'commentCount': FieldValue.increment(-1),
        });
      }

      print('✅ Comment deleted successfully');
      return true;
    } catch (e) {
      print('❌ Error deleting comment: $e');
      return false;
    }
  }

  // Get comments for post
  Future<List<Comment>> getComments(String postId) async {
    try {
      final snapshot = await _firestore
          .collection('comments')
          .where('postId', isEqualTo: postId)
          .orderBy('createdAt', descending: false)
          .get();

      return snapshot.docs.map((doc) => Comment.fromFirestore(doc)).toList();
    } catch (e) {
      print('❌ Error loading comments: $e');
      return [];
    }
  }

  // Delete post
  Future<bool> deletePost(String postId, String userId) async {
    final user = _auth.currentUser;
    if (user == null || user.uid != userId) return false;

    try {
      await _firestore.collection('posts').doc(postId).delete();

      // Delete all comments
      final comments = await _firestore
          .collection('comments')
          .where('postId', isEqualTo: postId)
          .get();

      for (var doc in comments.docs) {
        await doc.reference.delete();
      }

      await loadPosts();
      return true;
    } catch (e) {
      print('❌ Error deleting post: $e');
      return false;
    }
  }

  // Search users
  Future<List<Map<String, dynamic>>> searchUsers(String query) async {
    if (query.isEmpty) return [];

    try {
      final snapshot = await _firestore
          .collection('users')
          .where('name', isGreaterThanOrEqualTo: query)
          .where('name', isLessThanOrEqualTo: query + '\uf8ff')
          .limit(10)
          .get();

      return snapshot.docs
          .map(
            (doc) => {
              'uid': doc.id,
              'name': doc.data()['name'] ?? '',
              'email': doc.data()['email'] ?? '',
              'avatarUrl': doc.data()['avatarUrl'],
            },
          )
          .toList();
    } catch (e) {
      print('❌ Error searching users: $e');
      return [];
    }
  }
}
