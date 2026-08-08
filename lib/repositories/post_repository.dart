import '../data/models/domain_models.dart';
import '../data/mock_database_service.dart';

abstract class PostRepository {
  Future<List<Post>> getPosts({PostStatus? status});
  Future<Post?> getPostById(String id);
  Future<Post> createPost(Post post);
  Future<List<Comment>> getComments(String postId);
  Future<Comment> createComment(Comment comment);
  Future<void> toggleReaction(String userId, String postId, ReactionType type);
  Future<List<Reaction>> getUserReactions(String userId);
  Future<List<Bookmark>> getUserBookmarks(String userId);
  Future<void> toggleBookmark(String userId, BookmarkTargetType targetType, String targetId);
  Future<List<AppNotification>> getNotifications(String userId);
  Future<void> markNotificationRead(String id);
  Future<void> reportContent(Report report);
  Future<void> updatePostExperience(String postId, Experience experience);
}

class MockPostRepository implements PostRepository {
  final MockDatabaseService _db = MockDatabaseService();

  @override
  Future<List<Post>> getPosts({PostStatus? status}) async {
    await _db.init();
    return _db.getPosts(status: status);
  }

  @override
  Future<Post?> getPostById(String id) async {
    await _db.init();
    return _db.getPostById(id);
  }

  @override
  Future<Post> createPost(Post post) async {
    await _db.init();
    return _db.createPost(post);
  }

  @override
  Future<List<Comment>> getComments(String postId) async {
    await _db.init();
    return _db.getCommentsForPost(postId);
  }

  @override
  Future<Comment> createComment(Comment comment) async {
    await _db.init();
    return _db.createComment(comment);
  }

  @override
  Future<void> toggleReaction(String userId, String postId, ReactionType type) async {
    await _db.init();
    await _db.toggleReaction(userId, postId, type);
  }

  @override
  Future<List<Reaction>> getUserReactions(String userId) async {
    await _db.init();
    return _db.getUserReactions(userId);
  }

  @override
  Future<List<Bookmark>> getUserBookmarks(String userId) async {
    await _db.init();
    return _db.getUserBookmarks(userId);
  }

  @override
  Future<void> toggleBookmark(String userId, BookmarkTargetType targetType, String targetId) async {
    await _db.init();
    await _db.toggleBookmark(userId, targetType, targetId);
  }

  @override
  Future<List<AppNotification>> getNotifications(String userId) async {
    await _db.init();
    return _db.getUserNotifications(userId);
  }

  @override
  Future<void> markNotificationRead(String id) async {
    await _db.init();
    await _db.markNotificationRead(id);
  }

  @override
  Future<void> reportContent(Report report) async {
    await _db.init();
    await _db.createReport(report);
  }

  @override
  Future<void> updatePostExperience(String postId, Experience experience) async {
    await _db.init();
    await _db.updatePostExperience(postId, experience);
  }
}
