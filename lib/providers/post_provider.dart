import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/post.dart';
import '../models/comment.dart';

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
  Future<bool> toggleLike(String postId) async {
    final user = _auth.currentUser;
    if (user == null) return false;

    try {
      final postDoc = _firestore.collection('posts').doc(postId);
      final post = await postDoc.get();
      
      if (!post.exists) return false;

      final postData = Post.fromFirestore(post);
      List<String> likes = List.from(postData.likes);

      if (likes.contains(user.uid)) {
        likes.remove(user.uid);
      } else {
        likes.add(user.uid);
      }

      await postDoc.update({'likes': likes});
      
      // Update local
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
      await _firestore.collection('posts').doc(postId).update({
        'commentCount': FieldValue.increment(1),
      });

      await loadPosts();
      return true;
    } catch (e) {
      print('❌ Error adding comment: $e');
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
          .map((doc) => {
                'uid': doc.id,
                'name': doc.data()['name'] ?? '',
                'email': doc.data()['email'] ?? '',
                'avatarUrl': doc.data()['avatarUrl'],
              })
          .toList();
    } catch (e) {
      print('❌ Error searching users: $e');
      return [];
    }
  }
}