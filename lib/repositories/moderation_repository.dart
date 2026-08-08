import '../data/models/domain_models.dart';
import '../data/mock_database_service.dart';

abstract class ModerationRepository {
  Future<List<Report>> getReports();
  Future<void> updateReportStatus(String reportId, ReportStatus status, String moderatorId);
  Future<void> updatePostStatus(String postId, PostStatus status, String moderatorId, String reason);
  Future<void> removeComment(String commentId, String moderatorId, String reason);
  Future<void> restoreComment(String commentId, String moderatorId, String reason);
  Future<void> updateUserStatus(String userId, UserStatus status, String moderatorId, String reason);
  Future<List<ModerationLog>> getModerationLogs();
}

class MockModerationRepository implements ModerationRepository {
  final MockDatabaseService _db = MockDatabaseService();

  @override
  Future<List<Report>> getReports() async {
    await _db.init();
    return _db.getReports();
  }

  @override
  Future<void> updateReportStatus(String reportId, ReportStatus status, String moderatorId) async {
    await _db.init();
    await _db.updateReportStatus(reportId, status, moderatorId);
  }

  @override
  Future<void> updatePostStatus(String postId, PostStatus status, String moderatorId, String reason) async {
    await _db.init();
    await _db.updatePostStatus(postId, status);
    
    // Log the moderation action
    await _db.addModerationLog(ModerationLog(
      id: 'ml_${DateTime.now().millisecondsSinceEpoch}',
      moderatorId: moderatorId,
      targetType: 'post',
      targetId: postId,
      action: status == PostStatus.published ? 'restore' : 'remove',
      reason: reason,
      createdAt: DateTime.now(),
    ));

    // Notify post author
    final post = _db.getPostById(postId);
    if (post != null) {
      final title = status == PostStatus.published ? 'Post Restored' : 'Post Removed';
      final body = status == PostStatus.published
          ? 'Your story "${post.title}" has been restored by a moderator.'
          : 'Your story "${post.title}" was removed due to violating community guidelines: $reason';
      await _db.addNotification(
        userId: post.authorId,
        type: NotificationType.system,
        title: title,
        body: body,
        referenceId: postId,
      );
    }
  }

  @override
  Future<void> removeComment(String commentId, String moderatorId, String reason) async {
    await _db.init();
    await _db.removeComment(commentId);
    
    await _db.addModerationLog(ModerationLog(
      id: 'ml_${DateTime.now().millisecondsSinceEpoch}',
      moderatorId: moderatorId,
      targetType: 'comment',
      targetId: commentId,
      action: 'remove',
      reason: reason,
      createdAt: DateTime.now(),
    ));
  }

  @override
  Future<void> restoreComment(String commentId, String moderatorId, String reason) async {
    await _db.init();
    await _db.restoreComment(commentId);
    
    await _db.addModerationLog(ModerationLog(
      id: 'ml_${DateTime.now().millisecondsSinceEpoch}',
      moderatorId: moderatorId,
      targetType: 'comment',
      targetId: commentId,
      action: 'restore',
      reason: reason,
      createdAt: DateTime.now(),
    ));
  }

  @override
  Future<void> updateUserStatus(String userId, UserStatus status, String moderatorId, String reason) async {
    await _db.init();
    await _db.updateUserStatus(userId, status);
    
    await _db.addModerationLog(ModerationLog(
      id: 'ml_${DateTime.now().millisecondsSinceEpoch}',
      moderatorId: moderatorId,
      targetType: 'user',
      targetId: userId,
      action: status == UserStatus.suspended ? 'suspend' : (status == UserStatus.banned ? 'ban' : 'approve'),
      reason: reason,
      createdAt: DateTime.now(),
    ));
  }

  @override
  Future<List<ModerationLog>> getModerationLogs() async {
    await _db.init();
    return _db.getModerationLogs();
  }
}
