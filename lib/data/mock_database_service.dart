import 'dart:convert';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import 'models/domain_models.dart';

class MockDatabaseService {
  static final MockDatabaseService _instance = MockDatabaseService._internal();
  factory MockDatabaseService() => _instance;
  MockDatabaseService._internal();

  late SharedPreferences _prefs;
  bool _initialized = false;

  // Lists in memory
  List<AppUser> _users = [];
  List<PublicProfile> _profiles = [];
  List<Post> _posts = [];
  List<Comment> _comments = [];
  List<Reaction> _reactions = [];
  List<Bookmark> _bookmarks = [];
  List<Report> _reports = [];
  List<AppNotification> _notifications = [];
  List<ModerationLog> _moderationLogs = [];
  String? _currentUserId;

  Future<void> init() async {
    if (_initialized) return;
    _prefs = await SharedPreferences.getInstance();
    
    // Load lists from SharedPreferences or seed them if not found
    _loadOrSeedUsers();
    _loadOrSeedProfiles();
    _loadOrSeedPosts();
    _loadOrSeedComments();
    _loadOrSeedReactions();
    _loadOrSeedBookmarks();
    _loadOrSeedReports();
    _loadOrSeedNotifications();
    _loadOrSeedModerationLogs();
    
    _currentUserId = _prefs.getString('current_user_id');
    _initialized = true;
  }

  // --- Persistence Helpers ---
  void _saveList(String key, List<dynamic> list) {
    final jsonList = list.map((item) => item.toJson()).toList();
    _prefs.setString(key, jsonEncode(jsonList));
  }

  // --- Load or Seed functions ---
  void _loadOrSeedUsers() {
    final data = _prefs.getString('unsaid_users');
    if (data != null) {
      final List decoded = jsonDecode(data);
      _users = decoded.map((e) => AppUser.fromJson(e)).toList();
    } else {
      // Seed default accounts
      _users = [
        AppUser(
          id: 'user_1',
          email: 'user@unsaid.app',
          role: UserRole.user,
          status: UserStatus.active,
          createdAt: DateTime.now().subtract(const Duration(days: 30)),
        ),
        AppUser(
          id: 'user_2',
          email: 'mod@unsaid.app',
          role: UserRole.moderator,
          status: UserStatus.active,
          createdAt: DateTime.now().subtract(const Duration(days: 30)),
        ),
        AppUser(
          id: 'user_admin',
          email: 'admin@unsaid.app',
          role: UserRole.admin,
          status: UserStatus.active,
          createdAt: DateTime.now().subtract(const Duration(days: 30)),
        ),
      ];
      _saveList('unsaid_users', _users);
    }
  }

  void _loadOrSeedProfiles() {
    final data = _prefs.getString('unsaid_profiles');
    if (data != null) {
      final List decoded = jsonDecode(data);
      _profiles = decoded.map((e) => PublicProfile.fromJson(e)).toList();
    } else {
      _profiles = [
        PublicProfile(
          userId: 'user_1',
          displayName: 'QuietBuilder-78',
          avatarSeed: 'seed1',
          badges: ['Early Contributor'],
          contributionCount: 2,
          createdAt: DateTime.now().subtract(const Duration(days: 30)),
        ),
        PublicProfile(
          userId: 'user_2',
          displayName: 'CandidStrategist-12',
          avatarSeed: 'seed2',
          badges: ['Moderator'],
          contributionCount: 1,
          createdAt: DateTime.now().subtract(const Duration(days: 30)),
        ),
        PublicProfile(
          userId: 'user_admin',
          displayName: 'SystemAdmin',
          avatarSeed: 'seedadmin',
          badges: ['Admin'],
          contributionCount: 0,
          createdAt: DateTime.now().subtract(const Duration(days: 30)),
        ),
      ];
      _saveList('unsaid_profiles', _profiles);
    }
  }

  void _loadOrSeedPosts() {
    final data = _prefs.getString('unsaid_posts');
    if (data != null) {
      final List decoded = jsonDecode(data);
      _posts = decoded.map((e) => Post.fromJson(e)).toList();
    } else {
      _posts = [
        Post(
          id: 'post_1',
          authorId: 'user_1',
          authorPseudonym: 'QuietBuilder-78',
          type: PostType.experience,
          title: 'The "unlimited leaves" policy is a total trap here',
          body: 'When they hired me, the recruiter boasted about their modern "unlimited vacation" policy. The reality is that if you take more than 12 days in a year, you get marked down in performance reviews. My manager literally asked me "how committed are you to the team?" when I requested a 4-day weekend to visit my family.',
          experience: Experience(
            industry: 'IT & Software',
            companySize: 'Mid-size Product Company',
            companyType: 'Private',
            locationRegion: 'India-South',
            employmentStatus: 'current',
            role: 'Software Engineer',
            experienceDuration: '1-2 years',
            overallRating: 2.0,
            managementRating: 1.5,
            cultureRating: 2.0,
            growthRating: 3.0,
            compensationRating: 3.5,
            workLifeRating: 1.0,
            reasonTags: ['Toxic Work Culture', 'Poor Leadership'],
            redFlags: ['Micromanagement', 'Unpaid Overtime', 'No Growth Paths'],
            greenFlags: ['Fair Pay'],
            primaryReason: 'Work Life Balance was non-existent. Leadership micro-manages every single minute.',
          ),
          tags: ['IT & Software', 'Mid-size Product Company', 'Software Engineer'],
          reactionsCount: {'relatable': 28, 'interesting': 12, 'redflag': 45, 'goodsign': 0},
          commentCount: 2,
          status: PostStatus.published,
          createdAt: DateTime.now().subtract(const Duration(days: 5)),
          updatedAt: DateTime.now().subtract(const Duration(days: 5)),
        ),
        Post(
          id: 'post_2',
          authorId: 'user_2',
          authorPseudonym: 'CandidStrategist-12',
          type: PostType.experience,
          title: 'Great mentorship, but you will be underpaid by 30%',
          body: 'This is the perfect place to start your career. The seniors are incredibly supportive and you will learn more in 6 months than in 2 years elsewhere. But once you gain experience, leave. They do not adjust pay to market standards, and internal promotions come with minor hikes.',
          experience: Experience(
            industry: 'Consulting',
            companySize: 'Large IT Services Company',
            companyType: 'Public',
            locationRegion: 'India-North',
            employmentStatus: 'former',
            role: 'Associate Consultant',
            experienceDuration: '3-5 years',
            overallRating: 3.5,
            managementRating: 4.0,
            cultureRating: 4.5,
            growthRating: 4.0,
            compensationRating: 2.0,
            workLifeRating: 3.0,
            reasonTags: ['Underpaid', 'Better Opportunity'],
            redFlags: ['No Growth Paths'],
            greenFlags: ['Mentorship', 'Healthy Work Culture', 'Flexible Hours'],
            primaryReason: 'Left for a 50% raise at a product firm. Loved the team but could not ignore the pay gap.',
          ),
          tags: ['Consulting', 'Large IT Services Company', 'Associate Consultant'],
          reactionsCount: {'relatable': 48, 'interesting': 30, 'redflag': 5, 'goodsign': 35},
          commentCount: 1,
          status: PostStatus.published,
          createdAt: DateTime.now().subtract(const Duration(days: 3)),
          updatedAt: DateTime.now().subtract(const Duration(days: 3)),
        ),
        Post(
          id: 'post_3',
          authorId: 'user_1',
          authorPseudonym: 'QuietBuilder-78',
          type: PostType.experience,
          title: 'Constant weekend pings and high leadership turnover',
          body: 'In my team, we have changed three directors in less than a year. Every new leader brings their own philosophy, cancels previous projects, and makes us start over. Expect Slack messages on Saturday nights expecting instant replies.',
          experience: Experience(
            industry: 'Finance',
            companySize: 'Conglomerate',
            companyType: 'Public',
            locationRegion: 'India-West',
            employmentStatus: 'current',
            role: 'Product Manager',
            experienceDuration: '5+ years',
            overallRating: 1.8,
            managementRating: 1.0,
            cultureRating: 1.5,
            growthRating: 2.0,
            compensationRating: 4.0,
            workLifeRating: 1.0,
            reasonTags: ['Burnt Out', 'Poor Leadership'],
            redFlags: ['High Turnover', 'Unpaid Overtime', 'Toxic Leadership'],
            greenFlags: ['Fair Pay'],
            primaryReason: 'Exhausted by constant misalignment. Compensations are high but my health is failing.',
          ),
          tags: ['Finance', 'Conglomerate', 'Product Manager'],
          reactionsCount: {'relatable': 15, 'interesting': 25, 'redflag': 30, 'goodsign': 1},
          commentCount: 0,
          status: PostStatus.published,
          createdAt: DateTime.now().subtract(const Duration(days: 10)),
          updatedAt: DateTime.now().subtract(const Duration(days: 10)),
        ),
      ];
      _saveList('unsaid_posts', _posts);
    }
  }

  void _loadOrSeedComments() {
    final data = _prefs.getString('unsaid_comments');
    if (data != null) {
      final List decoded = jsonDecode(data);
      _comments = decoded.map((e) => Comment.fromJson(e)).toList();
    } else {
      _comments = [
        Comment(
          id: 'c_1',
          postId: 'post_1',
          authorId: 'user_2',
          authorPseudonym: 'CandidStrategist-12',
          body: 'This is standard practice at almost all mid-size firms. Unlimited leave is code for "feel guilty taking any leave".',
          isRemoved: false,
          createdAt: DateTime.now().subtract(const Duration(days: 4)),
        ),
        Comment(
          id: 'c_2',
          postId: 'post_1',
          authorId: 'user_1',
          authorPseudonym: 'QuietBuilder-78',
          parentCommentId: 'c_1',
          body: 'Agreed, definitely learned it the hard way. Sticking to defined leave structure in future jobs.',
          isRemoved: false,
          createdAt: DateTime.now().subtract(const Duration(days: 4)),
        ),
        Comment(
          id: 'c_3',
          postId: 'post_2',
          authorId: 'user_1',
          authorPseudonym: 'QuietBuilder-78',
          body: 'Can verify this. I worked in Consulting and learned a lot, but salary hikes are capped. Good entry point but bad long-term terminal value.',
          isRemoved: false,
          createdAt: DateTime.now().subtract(const Duration(days: 2)),
        ),
      ];
      _saveList('unsaid_comments', _comments);
    }
  }

  void _loadOrSeedReactions() {
    final data = _prefs.getString('unsaid_reactions');
    if (data != null) {
      final List decoded = jsonDecode(data);
      _reactions = decoded.map((e) => Reaction.fromJson(e)).toList();
    } else {
      _reactions = [];
    }
  }

  void _loadOrSeedBookmarks() {
    final data = _prefs.getString('unsaid_bookmarks');
    if (data != null) {
      final List decoded = jsonDecode(data);
      _bookmarks = decoded.map((e) => Bookmark.fromJson(e)).toList();
    } else {
      _bookmarks = [];
    }
  }

  void _loadOrSeedReports() {
    final data = _prefs.getString('unsaid_reports');
    if (data != null) {
      final List decoded = jsonDecode(data);
      _reports = decoded.map((e) => Report.fromJson(e)).toList();
    } else {
      // Seed a report for moderator demonstration
      _reports = [
        Report(
          id: 'rep_1',
          reporterId: 'user_2',
          targetType: ReportTargetType.post,
          targetId: 'post_3',
          reason: 'Harassment or Doxxing',
          description: 'This post might make a specific director easily identifiable based on the turnover detail.',
          status: ReportStatus.open,
          createdAt: DateTime.now().subtract(const Duration(days: 1)),
        )
      ];
      _saveList('unsaid_reports', _reports);
    }
  }

  void _loadOrSeedNotifications() {
    final data = _prefs.getString('unsaid_notifications');
    if (data != null) {
      final List decoded = jsonDecode(data);
      _notifications = decoded.map((e) => AppNotification.fromJson(e)).toList();
    } else {
      _notifications = [
        AppNotification(
          id: 'not_1',
          userId: 'user_1',
          type: NotificationType.reply,
          title: 'New Reply',
          body: 'CandidStrategist-12 replied to your story "The unlimited leaves policy is a total trap..."',
          referenceId: 'post_1',
          read: false,
          createdAt: DateTime.now().subtract(const Duration(days: 4)),
        ),
      ];
      _saveList('unsaid_notifications', _notifications);
    }
  }

  void _loadOrSeedModerationLogs() {
    final data = _prefs.getString('unsaid_moderation_logs');
    if (data != null) {
      final List decoded = jsonDecode(data);
      _moderationLogs = decoded.map((e) => ModerationLog.fromJson(e)).toList();
    } else {
      _moderationLogs = [];
    }
  }

  // --- Auth Operations ---
  AppUser? getCurrentUser() {
    if (_currentUserId == null) return null;
    return _users.firstWhere((u) => u.id == _currentUserId);
  }

  PublicProfile? getProfile(String userId) {
    try {
      return _profiles.firstWhere((p) => p.userId == userId);
    } catch (_) {
      return null;
    }
  }

  Future<void> setCurrentUser(String? userId) async {
    _currentUserId = userId;
    if (userId != null) {
      await _prefs.setString('current_user_id', userId);
    } else {
      await _prefs.remove('current_user_id');
    }
  }

  Future<AppUser> registerUser(String email, String password, String roleString) async {
    // Generate new User
    final userId = 'user_${DateTime.now().millisecondsSinceEpoch}';
    final role = roleString == 'admin' 
        ? UserRole.admin 
        : (roleString == 'moderator' ? UserRole.moderator : UserRole.user);
        
    final newUser = AppUser(
      id: userId,
      email: email,
      role: role,
      status: UserStatus.active,
      createdAt: DateTime.now(),
    );

    // Generate public profile pseudonym
    final pseudonym = _generatePseudonym();
    final newProfile = PublicProfile(
      userId: userId,
      displayName: pseudonym,
      avatarSeed: 'seed_${Random().nextInt(1000)}',
      badges: role == UserRole.moderator ? ['Moderator'] : (role == UserRole.admin ? ['Admin'] : []),
      contributionCount: 0,
      createdAt: DateTime.now(),
    );

    _users.add(newUser);
    _profiles.add(newProfile);

    _saveList('unsaid_users', _users);
    _saveList('unsaid_profiles', _profiles);

    return newUser;
  }

  Future<AppUser?> loginUser(String email, String password) async {
    try {
      // In a mock DB, we just search for matching email
      final user = _users.firstWhere((u) => u.email.toLowerCase() == email.toLowerCase());
      // Handle simple credentials check for security isolation
      // Admin: admin@unsaid.app -> admin123
      // Moderator: mod@unsaid.app -> mod123
      // User: user@unsaid.app -> user123
      return user;
    } catch (_) {
      return null;
    }
  }

  String _generatePseudonym() {
    final adjectives = ['Silent', 'Candid', 'Quiet', 'Frank', 'Honest', 'Open', 'Brave', 'Curious', 'Bold', 'Observant'];
    final nouns = ['Builder', 'Coder', 'Thinker', 'Designer', 'Strategist', 'Writer', 'Analyst', 'Planner', 'Engineer', 'Specialist'];
    final rand = Random();
    final adj = adjectives[rand.nextInt(adjectives.length)];
    final noun = nouns[rand.nextInt(nouns.length)];
    final num = rand.nextInt(90) + 10; // 10 to 99
    return '$adj$noun-$num';
  }

  // --- Posts & Experiences ---
  List<Post> getPosts({PostStatus? status}) {
    var list = _posts;
    if (status != null) {
      list = list.where((p) => p.status == status).toList();
    } else {
      // By default show only published posts
      list = list.where((p) => p.status == PostStatus.published).toList();
    }
    return list;
  }

  Post? getPostById(String id) {
    try {
      return _posts.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<Post> createPost(Post post) async {
    _posts.add(post);
    
    // Update profile contribution count
    final index = _profiles.indexWhere((p) => p.userId == post.authorId);
    if (index != -1) {
      final p = _profiles[index];
      _profiles[index] = PublicProfile(
        userId: p.userId,
        displayName: p.displayName,
        avatarSeed: p.avatarSeed,
        badges: p.badges,
        contributionCount: p.contributionCount + 1,
        createdAt: p.createdAt,
      );
      _saveList('unsaid_profiles', _profiles);
    }

    _saveList('unsaid_posts', _posts);
    return post;
  }

  Future<void> updatePostStatus(String postId, PostStatus status) async {
    final index = _posts.indexWhere((p) => p.id == postId);
    if (index != -1) {
      _posts[index] = _posts[index].copyWith(
        status: status,
        updatedAt: DateTime.now(),
      );
      _saveList('unsaid_posts', _posts);
    }
  }

  Future<void> updatePostExperience(String postId, Experience experience) async {
    final index = _posts.indexWhere((p) => p.id == postId);
    if (index != -1) {
      _posts[index] = Post(
        id: _posts[index].id,
        authorId: _posts[index].authorId,
        authorPseudonym: _posts[index].authorPseudonym,
        type: _posts[index].type,
        title: _posts[index].title,
        body: _posts[index].body,
        experience: experience,
        tags: _posts[index].tags,
        reactionsCount: _posts[index].reactionsCount,
        commentCount: _posts[index].commentCount,
        status: _posts[index].status,
        createdAt: _posts[index].createdAt,
        updatedAt: DateTime.now(),
      );
      _saveList('unsaid_posts', _posts);
    }
  }

  // --- Reactions ---
  List<Reaction> getUserReactions(String userId) {
    return _reactions.where((r) => r.userId == userId).toList();
  }

  Future<void> toggleReaction(String userId, String postId, ReactionType type) async {
    final existingIndex = _reactions.indexWhere((r) => r.userId == userId && r.postId == postId);
    final postIndex = _posts.indexWhere((p) => p.id == postId);

    if (postIndex == -1) return;
    final post = _posts[postIndex];
    final counts = Map<String, int>.from(post.reactionsCount);

    if (existingIndex != -1) {
      final existingReaction = _reactions[existingIndex];
      // Remove existing reaction count
      final oldTypeStr = existingReaction.type.name;
      counts[oldTypeStr] = max(0, (counts[oldTypeStr] ?? 1) - 1);

      if (existingReaction.type == type) {
        // Tapped same reaction -> remove it
        _reactions.removeAt(existingIndex);
      } else {
        // Tapped different reaction -> change it
        _reactions[existingIndex] = Reaction(
          id: existingReaction.id,
          userId: userId,
          postId: postId,
          type: type,
          createdAt: DateTime.now(),
        );
        counts[type.name] = (counts[type.name] ?? 0) + 1;
      }
    } else {
      // New reaction
      final newReaction = Reaction(
        id: 'r_${DateTime.now().millisecondsSinceEpoch}',
        userId: userId,
        postId: postId,
        type: type,
        createdAt: DateTime.now(),
      );
      _reactions.add(newReaction);
      counts[type.name] = (counts[type.name] ?? 0) + 1;
    }

    _posts[postIndex] = post.copyWith(reactionsCount: counts);
    
    _saveList('unsaid_reactions', _reactions);
    _saveList('unsaid_posts', _posts);

    // Create notifications for author if it's not author reacting
    if (post.authorId != userId) {
      final author = post.authorId;
      final reactorName = getProfile(userId)?.displayName ?? 'Anonymous';
      await addNotification(
        userId: author,
        type: NotificationType.reaction,
        title: 'New Reaction',
        body: '$reactorName reacted to your story: "${post.title}"',
        referenceId: postId,
      );
    }
  }

  // --- Comments ---
  List<Comment> getCommentsForPost(String postId) {
    return _comments.where((c) => c.postId == postId).toList();
  }

  Future<Comment> createComment(Comment comment) async {
    _comments.add(comment);
    _saveList('unsaid_comments', _comments);

    // Increment comment count on post
    final postIndex = _posts.indexWhere((p) => p.id == comment.postId);
    if (postIndex != -1) {
      final post = _posts[postIndex];
      _posts[postIndex] = post.copyWith(commentCount: post.commentCount + 1);
      _saveList('unsaid_posts', _posts);

      // Create notification for author
      if (post.authorId != comment.authorId) {
        await addNotification(
          userId: post.authorId,
          type: NotificationType.reply,
          title: 'New Comment',
          body: '${comment.authorPseudonym} commented on your story: "${post.title}"',
          referenceId: post.id,
        );
      }
    }
    return comment;
  }

  Future<void> removeComment(String commentId) async {
    final index = _comments.indexWhere((c) => c.id == commentId);
    if (index != -1) {
      _comments[index] = _comments[index].copyWith(isRemoved: true);
      _saveList('unsaid_comments', _comments);
    }
  }

  Future<void> restoreComment(String commentId) async {
    final index = _comments.indexWhere((c) => c.id == commentId);
    if (index != -1) {
      _comments[index] = _comments[index].copyWith(isRemoved: false);
      _saveList('unsaid_comments', _comments);
    }
  }

  // --- Bookmarks ---
  List<Bookmark> getUserBookmarks(String userId) {
    return _bookmarks.where((b) => b.userId == userId).toList();
  }

  Future<void> toggleBookmark(String userId, BookmarkTargetType targetType, String targetId) async {
    final existingIndex = _bookmarks.indexWhere((b) => b.userId == userId && b.targetType == targetType && b.targetId == targetId);
    if (existingIndex != -1) {
      _bookmarks.removeAt(existingIndex);
    } else {
      _bookmarks.add(Bookmark(
        id: 'b_${DateTime.now().millisecondsSinceEpoch}',
        userId: userId,
        targetType: targetType,
        targetId: targetId,
        createdAt: DateTime.now(),
      ));
    }
    _saveList('unsaid_bookmarks', _bookmarks);
  }

  // --- Reports ---
  List<Report> getReports() {
    return _reports;
  }

  Future<Report> createReport(Report report) async {
    _reports.add(report);
    _saveList('unsaid_reports', _reports);
    return report;
  }

  Future<void> updateReportStatus(String reportId, ReportStatus status, String? moderatorId) async {
    final index = _reports.indexWhere((r) => r.id == reportId);
    if (index != -1) {
      _reports[index] = _reports[index].copyWith(
        status: status,
        moderatorId: moderatorId,
        resolvedAt: DateTime.now(),
      );
      _saveList('unsaid_reports', _reports);
    }
  }

  // --- Notifications ---
  List<AppNotification> getUserNotifications(String userId) {
    return _notifications.where((n) => n.userId == userId).toList();
  }

  Future<void> markNotificationRead(String id) async {
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index != -1) {
      _notifications[index] = _notifications[index].copyWith(read: true);
      _saveList('unsaid_notifications', _notifications);
    }
  }

  Future<void> addNotification({
    required String userId,
    required NotificationType type,
    required String title,
    required String body,
    required String referenceId,
  }) async {
    _notifications.add(AppNotification(
      id: 'n_${DateTime.now().millisecondsSinceEpoch}',
      userId: userId,
      type: type,
      title: title,
      body: body,
      referenceId: referenceId,
      read: false,
      createdAt: DateTime.now(),
    ));
    _saveList('unsaid_notifications', _notifications);
  }

  // --- Moderation Logs ---
  List<ModerationLog> getModerationLogs() {
    return _moderationLogs;
  }

  Future<void> addModerationLog(ModerationLog log) async {
    _moderationLogs.add(log);
    _saveList('unsaid_moderation_logs', _moderationLogs);
  }

  // --- Admin Moderation Actions (Approve, Remove, Restore, Suspend, Ban) ---
  Future<void> updateUserStatus(String userId, UserStatus status) async {
    final index = _users.indexWhere((u) => u.id == userId);
    if (index != -1) {
      _users[index] = AppUser(
        id: _users[index].id,
        email: _users[index].email,
        role: _users[index].role,
        status: status,
        createdAt: _users[index].createdAt,
      );
      _saveList('unsaid_users', _users);
    }
  }
}
