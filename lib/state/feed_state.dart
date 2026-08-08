import 'package:flutter/material.dart';
import '../data/models/domain_models.dart';
import '../repositories/post_repository.dart';

class FeedState extends ChangeNotifier {
  final PostRepository _postRepo;

  List<Post> _allPosts = [];
  List<Comment> _activePostComments = [];
  List<Bookmark> _userBookmarks = [];
  List<Reaction> _userReactions = [];
  List<AppNotification> _userNotifications = [];
  bool _isLoading = false;
  String? _errorMessage;

  FeedState(this._postRepo);

  List<Post> get allPosts => _allPosts;
  List<Comment> get activePostComments => _activePostComments;
  List<Bookmark> get userBookmarks => _userBookmarks;
  List<Reaction> get userReactions => _userReactions;
  List<AppNotification> get userNotifications => _userNotifications;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchPosts() async {
    _isLoading = true;
    notifyListeners();
    try {
      _allPosts = await _postRepo.getPosts();
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // --- Filtering / Sorting Feed Tabs ---
  List<Post> getTrendingPosts({String? filterIndustry, String? filterCompanySize, String? filterCompanyType, String? filterRegion}) {
    var posts = _filterByContext(_allPosts, filterIndustry, filterCompanySize, filterCompanyType, filterRegion);
    posts.sort((a, b) {
      final aScore = (a.reactionsCount.values.fold(0, (sum, v) => sum + v)) + (a.commentCount * 2);
      final bScore = (b.reactionsCount.values.fold(0, (sum, v) => sum + v)) + (b.commentCount * 2);
      return bScore.compareTo(aScore);
    });
    return posts;
  }

  List<Post> getRecentPosts({String? filterIndustry, String? filterCompanySize, String? filterCompanyType, String? filterRegion}) {
    var posts = _filterByContext(_allPosts, filterIndustry, filterCompanySize, filterCompanyType, filterRegion);
    posts.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return posts;
  }

  List<Post> getMostDiscussedPosts({String? filterIndustry, String? filterCompanySize, String? filterCompanyType, String? filterRegion}) {
    var posts = _filterByContext(_allPosts, filterIndustry, filterCompanySize, filterCompanyType, filterRegion);
    posts.sort((a, b) => b.commentCount.compareTo(a.commentCount));
    return posts;
  }

  List<Post> getRedFlagsPosts({String? filterIndustry, String? filterCompanySize, String? filterCompanyType, String? filterRegion}) {
    var posts = _filterByContext(_allPosts, filterIndustry, filterCompanySize, filterCompanyType, filterRegion);
    posts = posts.where((p) => p.experience != null && p.experience!.redFlags.isNotEmpty).toList();
    posts.sort((a, b) {
      final aFlags = a.experience!.redFlags.length;
      final bFlags = b.experience!.redFlags.length;
      return bFlags.compareTo(aFlags);
    });
    return posts;
  }

  List<Post> getGoodExperiencesPosts({String? filterIndustry, String? filterCompanySize, String? filterCompanyType, String? filterRegion}) {
    var posts = _filterByContext(_allPosts, filterIndustry, filterCompanySize, filterCompanyType, filterRegion);
    posts = posts.where((p) => p.experience != null && (p.experience!.overallRating >= 3.5 || p.experience!.greenFlags.isNotEmpty)).toList();
    posts.sort((a, b) => (b.experience?.overallRating ?? 0.0).compareTo(a.experience?.overallRating ?? 0.0));
    return posts;
  }

  List<Post> _filterByContext(List<Post> list, String? ind, String? size, String? type, String? reg) {
    var result = List<Post>.from(list);
    if (ind != null && ind.isNotEmpty) {
      result = result.where((p) => p.experience?.industry == ind).toList();
    }
    if (size != null && size.isNotEmpty) {
      result = result.where((p) => p.experience?.companySize == size).toList();
    }
    if (type != null && type.isNotEmpty) {
      result = result.where((p) => p.experience?.companyType == type).toList();
    }
    if (reg != null && reg.isNotEmpty) {
      result = result.where((p) => p.experience?.locationRegion == reg).toList();
    }
    return result;
  }

  // --- Category Search / Filters ---
  List<Post> searchPosts(String query) {
    if (query.isEmpty) return _allPosts;
    final lowerQuery = query.toLowerCase();
    return _allPosts.where((p) {
      final matchTitle = p.title.toLowerCase().contains(lowerQuery);
      final matchBody = p.body.toLowerCase().contains(lowerQuery);
      final matchRole = p.experience?.role.toLowerCase().contains(lowerQuery) ?? false;
      final matchIndustry = p.experience?.industry.toLowerCase().contains(lowerQuery) ?? false;
      return matchTitle || matchBody || matchRole || matchIndustry;
    }).toList();
  }

  // --- Category Aggregated Score Calculations (PRD §9.4) ---
  Map<String, dynamic> getCategoryMetrics({String? industry, String? companySize, String? companyType, String? locationRegion}) {
    final filtered = _filterByContext(_allPosts, industry, companySize, companyType, locationRegion);
    if (filtered.isEmpty) {
      return {
        'totalCount': 0,
        'overall': 0.0,
        'culture': 0.0,
        'management': 0.0,
        'compensation': 0.0,
        'growth': 0.0,
        'workLife': 0.0,
        'whyPeopleLeave': <String, int>{},
        'redFlags': <String, int>{},
        'greenFlags': <String, int>{},
      };
    }

    double sumOverall = 0;
    double sumCulture = 0;
    double sumMgmt = 0;
    double sumComp = 0;
    double sumGrowth = 0;
    double sumWorkLife = 0;

    final leaveMap = <String, int>{};
    final redMap = <String, int>{};
    final greenMap = <String, int>{};

    int expCount = 0;

    for (var post in filtered) {
      final exp = post.experience;
      if (exp == null) continue;
      expCount++;

      sumOverall += exp.overallRating;
      sumCulture += exp.cultureRating;
      sumMgmt += exp.managementRating;
      sumComp += exp.compensationRating;
      sumGrowth += exp.growthRating;
      sumWorkLife += exp.workLifeRating;

      for (var reason in exp.reasonTags) {
        leaveMap[reason] = (leaveMap[reason] ?? 0) + 1;
      }
      for (var flag in exp.redFlags) {
        redMap[flag] = (redMap[flag] ?? 0) + 1;
      }
      for (var flag in exp.greenFlags) {
        greenMap[flag] = (greenMap[flag] ?? 0) + 1;
      }
    }

    if (expCount == 0) return getCategoryMetrics(); // fallback empty

    return {
      'totalCount': expCount,
      'overall': sumOverall / expCount,
      'culture': sumCulture / expCount,
      'management': sumMgmt / expCount,
      'compensation': sumComp / expCount,
      'growth': sumGrowth / expCount,
      'workLife': sumWorkLife / expCount,
      'whyPeopleLeave': leaveMap,
      'redFlags': redMap,
      'greenFlags': greenMap,
    };
  }

  // --- Comments ---
  Future<void> fetchComments(String postId) async {
    _activePostComments = await _postRepo.getComments(postId);
    notifyListeners();
  }

  Future<void> addComment(String postId, String authorId, String authorPseudonym, String body, {String? parentCommentId}) async {
    final comment = Comment(
      id: 'c_${DateTime.now().millisecondsSinceEpoch}',
      postId: postId,
      authorId: authorId,
      authorPseudonym: authorPseudonym,
      parentCommentId: parentCommentId,
      body: body,
      isRemoved: false,
      createdAt: DateTime.now(),
    );
    await _postRepo.createComment(comment);
    await fetchComments(postId); // reload comments
    
    // increment local comment count in feed post to avoid full reload
    final index = _allPosts.indexWhere((p) => p.id == postId);
    if (index != -1) {
      _allPosts[index] = _allPosts[index].copyWith(commentCount: _allPosts[index].commentCount + 1);
    }
    notifyListeners();
  }

  // --- Reactions ---
  Future<void> fetchUserReactions(String userId) async {
    _userReactions = await _postRepo.getUserReactions(userId);
    notifyListeners();
  }

  Future<void> toggleReaction(String userId, String postId, ReactionType type) async {
    await _postRepo.toggleReaction(userId, postId, type);
    // Reload data locally to keep screen states synchronized
    await fetchPosts();
    await fetchUserReactions(userId);
  }

  // --- Bookmarks ---
  Future<void> fetchUserBookmarks(String userId) async {
    _userBookmarks = await _postRepo.getUserBookmarks(userId);
    notifyListeners();
  }

  Future<void> toggleBookmark(String userId, BookmarkTargetType targetType, String targetId) async {
    await _postRepo.toggleBookmark(userId, targetType, targetId);
    await fetchUserBookmarks(userId);
  }

  bool isBookmarked(BookmarkTargetType targetType, String targetId) {
    return _userBookmarks.any((b) => b.targetType == targetType && b.targetId == targetId);
  }

  Post? getPostById(String id) {
    try {
      return _allPosts.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  // --- Notifications ---
  Future<void> fetchNotifications(String userId) async {
    _userNotifications = await _postRepo.getNotifications(userId);
    notifyListeners();
  }

  Future<void> markNotificationRead(String notificationId, String userId) async {
    await _postRepo.markNotificationRead(notificationId);
    await fetchNotifications(userId);
  }

  // --- Reporting ---
  Future<void> reportPostOrComment({
    required String reporterId,
    required ReportTargetType targetType,
    required String targetId,
    required String reason,
    required String description,
  }) async {
    final report = Report(
      id: 'rep_${DateTime.now().millisecondsSinceEpoch}',
      reporterId: reporterId,
      targetType: targetType,
      targetId: targetId,
      reason: reason,
      description: description,
      status: ReportStatus.open,
      createdAt: DateTime.now(),
    );
    await _postRepo.reportContent(report);
  }
}
