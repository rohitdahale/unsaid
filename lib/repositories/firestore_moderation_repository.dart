import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/firebase_error_handler.dart';
import '../data/models/domain_models.dart';
import 'moderation_repository.dart';

class FirestoreModerationRepository implements ModerationRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Future<List<Report>> getReports() async {
    try {
      final snapshot = await _firestore.collection('reports').get();
      return snapshot.docs.map((doc) => Report.fromJson(doc.data() as Map<String, dynamic>)).toList();
    } catch (e) {
      final msg = FirebaseErrorHandler.handle(e, context: 'getReports');
      throw Exception(msg);
    }
  }

  @override
  Future<void> updateReportStatus(String reportId, ReportStatus status, String moderatorId) async {
    try {
      await _firestore.collection('reports').doc(reportId).update({
        'status': status.name,
        'moderatorId': moderatorId,
        'resolvedAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      final msg = FirebaseErrorHandler.handle(e, context: 'updateReportStatus');
      throw Exception(msg);
    }
  }

  @override
  Future<void> updatePostStatus(String postId, PostStatus status, String moderatorId, String reason) async {
    try {
      await _firestore.collection('posts').doc(postId).update({
        'status': status.name,
        'updatedAt': DateTime.now().toIso8601String(),
      });

      // Create log
      final logId = 'ml_${DateTime.now().millisecondsSinceEpoch}';
      final log = ModerationLog(
        id: logId,
        moderatorId: moderatorId,
        targetType: 'post',
        targetId: postId,
        action: status == PostStatus.published ? 'restore' : 'remove',
        reason: reason,
        createdAt: DateTime.now(),
      );
      await _firestore.collection('moderationLogs').doc(logId).set(log.toJson());

      // Create notification
      final postDoc = await _firestore.collection('posts').doc(postId).get();
      if (postDoc.exists && postDoc.data() != null) {
        final post = Post.fromJson(postDoc.data()!);
        final title = status == PostStatus.published ? 'Post Restored' : 'Post Removed';
        final body = status == PostStatus.published
            ? 'Your story "${post.title}" has been restored by a moderator.'
            : 'Your story "${post.title}" was removed due to violating community guidelines: $reason';

        final notifId = 'n_${DateTime.now().millisecondsSinceEpoch}';
        final notif = AppNotification(
          id: notifId,
          userId: post.authorId,
          type: NotificationType.system,
          title: title,
          body: body,
          referenceId: postId,
          read: false,
          createdAt: DateTime.now(),
        );
        await _firestore.collection('notifications').doc(notifId).set(notif.toJson());
      }
    } catch (e) {
      final msg = FirebaseErrorHandler.handle(e, context: 'updatePostStatus');
      throw Exception(msg);
    }
  }

  @override
  Future<void> removeComment(String commentId, String moderatorId, String reason) async {
    try {
      await _firestore.collection('comments').doc(commentId).update({'isRemoved': true});

      final logId = 'ml_${DateTime.now().millisecondsSinceEpoch}';
      final log = ModerationLog(
        id: logId,
        moderatorId: moderatorId,
        targetType: 'comment',
        targetId: commentId,
        action: 'remove',
        reason: reason,
        createdAt: DateTime.now(),
      );
      await _firestore.collection('moderationLogs').doc(logId).set(log.toJson());
    } catch (e) {
      final msg = FirebaseErrorHandler.handle(e, context: 'removeComment');
      throw Exception(msg);
    }
  }

  @override
  Future<void> restoreComment(String commentId, String moderatorId, String reason) async {
    try {
      await _firestore.collection('comments').doc(commentId).update({'isRemoved': false});

      final logId = 'ml_${DateTime.now().millisecondsSinceEpoch}';
      final log = ModerationLog(
        id: logId,
        moderatorId: moderatorId,
        targetType: 'comment',
        targetId: commentId,
        action: 'restore',
        reason: reason,
        createdAt: DateTime.now(),
      );
      await _firestore.collection('moderationLogs').doc(logId).set(log.toJson());
    } catch (e) {
      final msg = FirebaseErrorHandler.handle(e, context: 'restoreComment');
      throw Exception(msg);
    }
  }

  @override
  Future<void> updateUserStatus(String userId, UserStatus status, String moderatorId, String reason) async {
    try {
      await _firestore.collection('users').doc(userId).update({'status': status.name});

      final logId = 'ml_${DateTime.now().millisecondsSinceEpoch}';
      final log = ModerationLog(
        id: logId,
        moderatorId: moderatorId,
        targetType: 'user',
        targetId: userId,
        action: status == UserStatus.suspended ? 'suspend' : (status == UserStatus.banned ? 'ban' : 'approve'),
        reason: reason,
        createdAt: DateTime.now(),
      );
      await _firestore.collection('moderationLogs').doc(logId).set(log.toJson());
    } catch (e) {
      final msg = FirebaseErrorHandler.handle(e, context: 'updateUserStatus');
      throw Exception(msg);
    }
  }

  @override
  Future<List<ModerationLog>> getModerationLogs() async {
    try {
      final snapshot = await _firestore.collection('moderationLogs').get();
      final list = snapshot.docs.map((doc) => ModerationLog.fromJson(doc.data() as Map<String, dynamic>)).toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    } catch (e) {
      final msg = FirebaseErrorHandler.handle(e, context: 'getModerationLogs');
      throw Exception(msg);
    }
  }
}
