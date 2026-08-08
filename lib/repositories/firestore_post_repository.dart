import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import '../core/firebase_error_handler.dart';
import '../data/models/domain_models.dart';
import 'post_repository.dart';

class FirestorePostRepository implements PostRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  Future<void> _safeLogEvent(String name, Map<String, Object>? parameters) async {
    try {
      await _analytics.logEvent(name: name, parameters: parameters);
    } catch (e) {
      // Catch and ignore analytics channel/platform exceptions
      print('Analytics error: $e');
    }
  }

  @override
  Future<List<Post>> getPosts({PostStatus? status}) async {
    try {
      final ref = _firestore.collection('posts');
      Query query = ref;
      
      if (status != null) {
        query = query.where('status', isEqualTo: status.name);
      } else {
        query = query.where('status', isEqualTo: PostStatus.published.name);
      }
      
      final snapshot = await query.get();
      final posts = snapshot.docs.map((doc) => Post.fromJson(doc.data() as Map<String, dynamic>)).toList();
      posts.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return posts;
    } catch (e) {
      final msg = FirebaseErrorHandler.handle(e, context: 'getPosts');
      throw Exception(msg);
    }
  }

  @override
  Future<Post?> getPostById(String id) async {
    try {
      final doc = await _firestore.collection('posts').doc(id).get();
      if (doc.exists && doc.data() != null) {
        final post = Post.fromJson(doc.data()!);
        await _safeLogEvent('story_viewed', {'post_id': id});
        return post;
      }
      return null;
    } catch (e) {
      final msg = FirebaseErrorHandler.handle(e, context: 'getPostById');
      throw Exception(msg);
    }
  }

  @override
  Future<Post> createPost(Post post) async {
    try {
      await _firestore.collection('posts').doc(post.id).set(post.toJson());
      
      // Increment profile contributionCount
      final profileRef = _firestore.collection('profiles').doc(post.authorId);
      await _firestore.runTransaction((transaction) async {
        final doc = await transaction.get(profileRef);
        if (doc.exists) {
          final currentCount = doc.data()?['contributionCount'] as int? ?? 0;
          transaction.update(profileRef, {'contributionCount': currentCount + 1});
        }
      });
      
      await _safeLogEvent('story_created', {
        'post_id': post.id,
        'industry': post.experience?.industry ?? '',
      });
      
      return post;
    } catch (e) {
      final msg = FirebaseErrorHandler.handle(e, context: 'createPost');
      throw Exception(msg);
    }
  }

  @override
  Future<List<Comment>> getComments(String postId) async {
    try {
      final snapshot = await _firestore.collection('comments')
          .where('postId', isEqualTo: postId)
          .get();
      final comments = snapshot.docs.map((doc) => Comment.fromJson(doc.data() as Map<String, dynamic>)).toList();
      comments.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      return comments;
    } catch (e) {
      final msg = FirebaseErrorHandler.handle(e, context: 'getComments');
      throw Exception(msg);
    }
  }

  @override
  Future<Comment> createComment(Comment comment) async {
    try {
      await _firestore.collection('comments').doc(comment.id).set(comment.toJson());
      
      // Increment post commentCount
      final postRef = _firestore.collection('posts').doc(comment.postId);
      Post? post;
      await _firestore.runTransaction((transaction) async {
        final doc = await transaction.get(postRef);
        if (doc.exists) {
          post = Post.fromJson(doc.data()!);
          final currentCount = doc.data()?['commentCount'] as int? ?? 0;
          transaction.update(postRef, {'commentCount': currentCount + 1});
        }
      });
      
      // Create notification
      if (post != null && post!.authorId != comment.authorId) {
        final notif = AppNotification(
          id: 'n_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(1000)}',
          userId: post!.authorId,
          type: NotificationType.reply,
          title: 'New Comment',
          body: '${comment.authorPseudonym} commented on your story: "${post!.title}"',
          referenceId: post!.id,
          read: false,
          createdAt: DateTime.now(),
        );
        await _firestore.collection('notifications').doc(notif.id).set(notif.toJson());
      }
      
      await _analytics.logEvent(name: 'comment', parameters: {'post_id': comment.postId});
      
      return comment;
    } catch (e) {
      final msg = FirebaseErrorHandler.handle(e, context: 'createComment');
      throw Exception(msg);
    }
  }

  @override
  Future<void> toggleReaction(String userId, String postId, ReactionType type) async {
    try {
      final querySnapshot = await _firestore.collection('reactions')
          .where('userId', isEqualTo: userId)
          .where('postId', isEqualTo: postId)
          .get();
          
      final postRef = _firestore.collection('posts').doc(postId);
      final postDoc = await postRef.get();
      if (!postDoc.exists || postDoc.data() == null) return;
      
      final post = Post.fromJson(postDoc.data()!);
      final counts = Map<String, int>.from(post.reactionsCount);
      
      if (querySnapshot.docs.isNotEmpty) {
        final doc = querySnapshot.docs.first;
        final existingReaction = Reaction.fromJson(doc.data() as Map<String, dynamic>);
        final oldTypeStr = existingReaction.type.name;
        counts[oldTypeStr] = max(0, (counts[oldTypeStr] ?? 1) - 1);
        
        if (existingReaction.type == type) {
          // Tapped same reaction -> remove it
          await _firestore.collection('reactions').doc(existingReaction.id).delete();
        } else {
          // Tapped different reaction -> change it
          final updatedReaction = Reaction(
            id: existingReaction.id,
            userId: userId,
            postId: postId,
            type: type,
            createdAt: DateTime.now(),
          );
          await _firestore.collection('reactions').doc(existingReaction.id).set(updatedReaction.toJson());
          counts[type.name] = (counts[type.name] ?? 0) + 1;
        }
      } else {
        // New reaction
        final reactionId = 'r_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(1000)}';
        final newReaction = Reaction(
          id: reactionId,
          userId: userId,
          postId: postId,
          type: type,
          createdAt: DateTime.now(),
        );
        await _firestore.collection('reactions').doc(reactionId).set(newReaction.toJson());
        counts[type.name] = (counts[type.name] ?? 0) + 1;
        
        // Create notification for author
        if (post.authorId != userId) {
          final profileDoc = await _firestore.collection('profiles').doc(userId).get();
          final reactorName = profileDoc.exists ? (profileDoc.data()?['displayName'] ?? 'Anonymous') : 'Anonymous';
          
          final notif = AppNotification(
            id: 'n_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(1000)}',
            userId: post.authorId,
            type: NotificationType.reaction,
            title: 'New Reaction',
            body: '$reactorName reacted to your story: "${post.title}"',
            referenceId: postId,
            read: false,
            createdAt: DateTime.now(),
          );
          await _firestore.collection('notifications').doc(notif.id).set(notif.toJson());
        }
      }
      
      await postRef.update({'reactionsCount': counts});
      
      await _analytics.logEvent(name: 'reaction', parameters: {
        'post_id': postId,
        'type': type.name,
      });
    } catch (e) {
      final msg = FirebaseErrorHandler.handle(e, context: 'toggleReaction');
      throw Exception(msg);
    }
  }

  @override
  Future<List<Reaction>> getUserReactions(String userId) async {
    try {
      final snapshot = await _firestore.collection('reactions')
          .where('userId', isEqualTo: userId)
          .get();
      return snapshot.docs.map((doc) => Reaction.fromJson(doc.data() as Map<String, dynamic>)).toList();
    } catch (e) {
      final msg = FirebaseErrorHandler.handle(e, context: 'getUserReactions');
      throw Exception(msg);
    }
  }

  @override
  Future<List<Bookmark>> getUserBookmarks(String userId) async {
    try {
      final snapshot = await _firestore.collection('bookmarks')
          .where('userId', isEqualTo: userId)
          .get();
      return snapshot.docs.map((doc) => Bookmark.fromJson(doc.data() as Map<String, dynamic>)).toList();
    } catch (e) {
      final msg = FirebaseErrorHandler.handle(e, context: 'getUserBookmarks');
      throw Exception(msg);
    }
  }

  @override
  Future<void> toggleBookmark(String userId, BookmarkTargetType targetType, String targetId) async {
    try {
      final snapshot = await _firestore.collection('bookmarks')
          .where('userId', isEqualTo: userId)
          .where('targetType', isEqualTo: targetType.name)
          .where('targetId', isEqualTo: targetId)
          .get();
          
      if (snapshot.docs.isNotEmpty) {
        await _firestore.collection('bookmarks').doc(snapshot.docs.first.id).delete();
      } else {
        final bookmarkId = 'b_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(1000)}';
        final newBookmark = Bookmark(
          id: bookmarkId,
          userId: userId,
          targetType: targetType,
          targetId: targetId,
          createdAt: DateTime.now(),
        );
        await _firestore.collection('bookmarks').doc(bookmarkId).set(newBookmark.toJson());
      }
      
      await _analytics.logEvent(name: 'bookmark', parameters: {
        'target_id': targetId,
        'target_type': targetType.name,
      });
    } catch (e) {
      final msg = FirebaseErrorHandler.handle(e, context: 'toggleBookmark');
      throw Exception(msg);
    }
  }

  @override
  Future<List<AppNotification>> getNotifications(String userId) async {
    try {
      final snapshot = await _firestore.collection('notifications')
          .where('userId', isEqualTo: userId)
          .get();
      final list = snapshot.docs.map((doc) => AppNotification.fromJson(doc.data() as Map<String, dynamic>)).toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    } catch (e) {
      final msg = FirebaseErrorHandler.handle(e, context: 'getNotifications');
      throw Exception(msg);
    }
  }

  @override
  Future<void> markNotificationRead(String id) async {
    try {
      await _firestore.collection('notifications').doc(id).update({'read': true});
    } catch (e) {
      final msg = FirebaseErrorHandler.handle(e, context: 'markNotificationRead');
      throw Exception(msg);
    }
  }

  @override
  Future<void> reportContent(Report report) async {
    try {
      await _firestore.collection('reports').doc(report.id).set(report.toJson());
      
      await _safeLogEvent('report', {
        'target_id': report.targetId,
        'target_type': report.targetType.name,
        'reason': report.reason,
      });
    } catch (e) {
      final msg = FirebaseErrorHandler.handle(e, context: 'reportContent');
      throw Exception(msg);
    }
  }

  @override
  Future<void> updatePostExperience(String postId, Experience experience) async {
    try {
      await _firestore.collection('posts').doc(postId).update({
        'experience': experience.toJson(),
      });
    } catch (e) {
      final msg = FirebaseErrorHandler.handle(e, context: 'updatePostExperience');
      throw Exception(msg);
    }
  }
}
