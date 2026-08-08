import 'dart:convert';

// User Roles
enum UserRole { user, moderator, admin }

// User Account Status
enum UserStatus { active, suspended, banned }

// AppUser model (internal use)
class AppUser {
  final String id;
  final String email;
  final UserRole role;
  final UserStatus status;
  final DateTime createdAt;

  AppUser({
    required this.id,
    required this.email,
    required this.role,
    required this.status,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'role': role.name,
        'status': status.name,
        'createdAt': createdAt.toIso8601String(),
      };

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
        id: json['id'],
        email: json['email'],
        role: UserRole.values.byName(json['role']),
        status: UserStatus.values.byName(json['status']),
        createdAt: DateTime.parse(json['createdAt']),
      );
}

// PublicProfile model (pseudonymous identity)
class PublicProfile {
  final String userId;
  final String displayName; // Pseudonym
  final String avatarSeed; // Used to generate geometric shapes or colors
  final List<String> badges;
  final int contributionCount;
  final DateTime createdAt;

  PublicProfile({
    required this.userId,
    required this.displayName,
    required this.avatarSeed,
    required this.badges,
    required this.contributionCount,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'displayName': displayName,
        'avatarSeed': avatarSeed,
        'badges': badges,
        'contributionCount': contributionCount,
        'createdAt': createdAt.toIso8601String(),
      };

  factory PublicProfile.fromJson(Map<String, dynamic> json) => PublicProfile(
        userId: json['userId'],
        displayName: json['displayName'],
        avatarSeed: json['avatarSeed'],
        badges: List<String>.from(json['badges'] ?? []),
        contributionCount: json['contributionCount'] ?? 0,
        createdAt: DateTime.parse(json['createdAt']),
      );
}

// Post Types
enum PostType { experience, question, poll } // MVP is STYLED/EXPERIENCE only

// Post Status
enum PostStatus { pending, published, removed }

// Base Post model
class Post {
  final String id;
  final String authorId;
  final String authorPseudonym;
  final PostType type;
  final String title;
  final String body;
  final Experience? experience; // Context payload for EXPERIENCE subtype
  final List<String> tags;
  final Map<String, int> reactionsCount;
  final int commentCount;
  final PostStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;

  Post({
    required this.id,
    required this.authorId,
    required this.authorPseudonym,
    required this.type,
    required this.title,
    required this.body,
    this.experience,
    required this.tags,
    required this.reactionsCount,
    required this.commentCount,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'authorId': authorId,
        'authorPseudonym': authorPseudonym,
        'type': type.name,
        'title': title,
        'body': body,
        'experience': experience?.toJson(),
        'tags': tags,
        'reactionsCount': reactionsCount,
        'commentCount': commentCount,
        'status': status.name,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory Post.fromJson(Map<String, dynamic> json) => Post(
        id: json['id'],
        authorId: json['authorId'],
        authorPseudonym: json['authorPseudonym'],
        type: PostType.values.byName(json['type']),
        title: json['title'],
        body: json['body'],
        experience: json['experience'] != null
            ? Experience.fromJson(json['experience'])
            : null,
        tags: List<String>.from(json['tags'] ?? []),
        reactionsCount: Map<String, int>.from(json['reactionsCount'] ?? {}),
        commentCount: json['commentCount'] ?? 0,
        status: PostStatus.values.byName(json['status']),
        createdAt: DateTime.parse(json['createdAt']),
        updatedAt: DateTime.parse(json['updatedAt']),
      );

  Post copyWith({
    String? title,
    String? body,
    Experience? experience,
    List<String>? tags,
    Map<String, int>? reactionsCount,
    int? commentCount,
    PostStatus? status,
    DateTime? updatedAt,
  }) =>
      Post(
        id: id,
        authorId: authorId,
        authorPseudonym: authorPseudonym,
        type: type,
        title: title ?? this.title,
        body: body ?? this.body,
        experience: experience ?? this.experience,
        tags: tags ?? this.tags,
        reactionsCount: reactionsCount ?? this.reactionsCount,
        commentCount: commentCount ?? this.commentCount,
        status: status ?? this.status,
        createdAt: createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
}

// Experience details (specific context for workplace stories)
class Experience {
  final String industry;
  final String companySize;
  final String companyType;
  final String locationRegion;
  final String employmentStatus; // 'current' | 'former'
  final String role;
  final String experienceDuration; // tenure band
  final double overallRating;
  final double managementRating;
  final double cultureRating;
  final double growthRating;
  final double compensationRating;
  final double workLifeRating;
  final List<String> reasonTags;
  final List<String> redFlags;
  final List<String> greenFlags;
  final String primaryReason;

  Experience({
    required this.industry,
    required this.companySize,
    required this.companyType,
    required this.locationRegion,
    required this.employmentStatus,
    required this.role,
    required this.experienceDuration,
    required this.overallRating,
    required this.managementRating,
    required this.cultureRating,
    required this.growthRating,
    required this.compensationRating,
    required this.workLifeRating,
    required this.reasonTags,
    required this.redFlags,
    required this.greenFlags,
    required this.primaryReason,
  });

  Map<String, dynamic> toJson() => {
        'industry': industry,
        'companySize': companySize,
        'companyType': companyType,
        'locationRegion': locationRegion,
        'employmentStatus': employmentStatus,
        'role': role,
        'experienceDuration': experienceDuration,
        'overallRating': overallRating,
        'managementRating': managementRating,
        'cultureRating': cultureRating,
        'growthRating': growthRating,
        'compensationRating': compensationRating,
        'workLifeRating': workLifeRating,
        'reasonTags': reasonTags,
        'redFlags': redFlags,
        'greenFlags': greenFlags,
        'primaryReason': primaryReason,
      };

  factory Experience.fromJson(Map<String, dynamic> json) => Experience(
        industry: json['industry'],
        companySize: json['companySize'],
        companyType: json['companyType'],
        locationRegion: json['locationRegion'],
        employmentStatus: json['employmentStatus'],
        role: json['role'],
        experienceDuration: json['experienceDuration'],
        overallRating: (json['overallRating'] as num).toDouble(),
        managementRating: (json['managementRating'] as num).toDouble(),
        cultureRating: (json['cultureRating'] as num).toDouble(),
        growthRating: (json['growthRating'] as num).toDouble(),
        compensationRating: (json['compensationRating'] as num).toDouble(),
        workLifeRating: (json['workLifeRating'] as num).toDouble(),
        reasonTags: List<String>.from(json['reasonTags'] ?? []),
        redFlags: List<String>.from(json['redFlags'] ?? []),
        greenFlags: List<String>.from(json['greenFlags'] ?? []),
        primaryReason: json['primaryReason'] ?? '',
      );
}

// Comment model (single-level reply hierarchy)
class Comment {
  final String id;
  final String postId;
  final String authorId;
  final String authorPseudonym;
  final String? parentCommentId; // For 1 level of nesting (reply)
  final String body;
  final bool isRemoved; // Moderation flag
  final DateTime createdAt;

  Comment({
    required this.id,
    required this.postId,
    required this.authorId,
    required this.authorPseudonym,
    this.parentCommentId,
    required this.body,
    required this.isRemoved,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'postId': postId,
        'authorId': authorId,
        'authorPseudonym': authorPseudonym,
        'parentCommentId': parentCommentId,
        'body': body,
        'isRemoved': isRemoved,
        'createdAt': createdAt.toIso8601String(),
      };

  factory Comment.fromJson(Map<String, dynamic> json) => Comment(
        id: json['id'],
        postId: json['postId'],
        authorId: json['authorId'],
        authorPseudonym: json['authorPseudonym'],
        parentCommentId: json['parentCommentId'],
        body: json['body'],
        isRemoved: json['isRemoved'] ?? false,
        createdAt: DateTime.parse(json['createdAt']),
      );

  Comment copyWith({
    bool? isRemoved,
    String? body,
  }) =>
      Comment(
        id: id,
        postId: postId,
        authorId: authorId,
        authorPseudonym: authorPseudonym,
        parentCommentId: parentCommentId,
        body: body ?? this.body,
        isRemoved: isRemoved ?? this.isRemoved,
        createdAt: createdAt,
      );
}

// Reaction model
enum ReactionType { relatable, interesting, redflag, goodsign }

class Reaction {
  final String id;
  final String userId;
  final String postId;
  final ReactionType type;
  final DateTime createdAt;

  Reaction({
    required this.id,
    required this.userId,
    required this.postId,
    required this.type,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'postId': postId,
        'type': type.name,
        'createdAt': createdAt.toIso8601String(),
      };

  factory Reaction.fromJson(Map<String, dynamic> json) => Reaction(
        id: json['id'],
        userId: json['userId'],
        postId: json['postId'],
        type: ReactionType.values.byName(json['type']),
        createdAt: DateTime.parse(json['createdAt']),
      );
}

// Bookmark model (post or category)
enum BookmarkTargetType { post, category }

class Bookmark {
  final String id;
  final String userId;
  final BookmarkTargetType targetType;
  final String targetId; // Post ID or serialized category string
  final DateTime createdAt;

  Bookmark({
    required this.id,
    required this.userId,
    required this.targetType,
    required this.targetId,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'targetType': targetType.name,
        'targetId': targetId,
        'createdAt': createdAt.toIso8601String(),
      };

  factory Bookmark.fromJson(Map<String, dynamic> json) => Bookmark(
        id: json['id'],
        userId: json['userId'],
        targetType: BookmarkTargetType.values.byName(json['targetType']),
        targetId: json['targetId'],
        createdAt: DateTime.parse(json['createdAt']),
      );
}

// Report model (trust & safety flags)
enum ReportTargetType { post, comment }

enum ReportStatus { open, resolved }

class Report {
  final String id;
  final String reporterId;
  final ReportTargetType targetType;
  final String targetId;
  final String reason;
  final String description;
  final ReportStatus status;
  final String? moderatorId;
  final DateTime createdAt;
  final DateTime? resolvedAt;

  Report({
    required this.id,
    required this.reporterId,
    required this.targetType,
    required this.targetId,
    required this.reason,
    required this.description,
    required this.status,
    this.moderatorId,
    required this.createdAt,
    this.resolvedAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'reporterId': reporterId,
        'targetType': targetType.name,
        'targetId': targetId,
        'reason': reason,
        'description': description,
        'status': status.name,
        'moderatorId': moderatorId,
        'createdAt': createdAt.toIso8601String(),
        'resolvedAt': resolvedAt?.toIso8601String(),
      };

  factory Report.fromJson(Map<String, dynamic> json) => Report(
        id: json['id'],
        reporterId: json['reporterId'],
        targetType: ReportTargetType.values.byName(json['targetType']),
        targetId: json['targetId'],
        reason: json['reason'],
        description: json['description'] ?? '',
        status: ReportStatus.values.byName(json['status']),
        moderatorId: json['moderatorId'],
        createdAt: DateTime.parse(json['createdAt']),
        resolvedAt: json['resolvedAt'] != null
            ? DateTime.parse(json['resolvedAt'])
            : null,
      );

  Report copyWith({
    ReportStatus? status,
    String? moderatorId,
    DateTime? resolvedAt,
  }) =>
      Report(
        id: id,
        reporterId: reporterId,
        targetType: targetType,
        targetId: targetId,
        reason: reason,
        description: description,
        status: status ?? this.status,
        moderatorId: moderatorId ?? this.moderatorId,
        createdAt: createdAt,
        resolvedAt: resolvedAt ?? this.resolvedAt,
      );
}

// Notification model
enum NotificationType { reply, reaction, system }

class AppNotification {
  final String id;
  final String userId;
  final NotificationType type;
  final String title;
  final String body;
  final String referenceId; // e.g., post ID or action reference
  final bool read;
  final DateTime createdAt;

  AppNotification({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.body,
    required this.referenceId,
    required this.read,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'type': type.name,
        'title': title,
        'body': body,
        'referenceId': referenceId,
        'read': read,
        'createdAt': createdAt.toIso8601String(),
      };

  factory AppNotification.fromJson(Map<String, dynamic> json) => AppNotification(
        id: json['id'],
        userId: json['userId'],
        type: NotificationType.values.byName(json['type']),
        title: json['title'],
        body: json['body'],
        referenceId: json['referenceId'] ?? '',
        read: json['read'] ?? false,
        createdAt: DateTime.parse(json['createdAt']),
      );

  AppNotification copyWith({
    bool? read,
  }) =>
      AppNotification(
        id: id,
        userId: userId,
        type: type,
        title: title,
        body: body,
        referenceId: referenceId,
        read: read ?? this.read,
        createdAt: createdAt,
      );
}

// Moderation Log (audit trails)
class ModerationLog {
  final String id;
  final String moderatorId;
  final String targetType; // 'post' | 'comment' | 'user'
  final String targetId;
  final String action; // 'approve' | 'remove' | 'restore' | 'suspend' | 'ban'
  final String reason;
  final DateTime createdAt;

  ModerationLog({
    required this.id,
    required this.moderatorId,
    required this.targetType,
    required this.targetId,
    required this.action,
    required this.reason,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'moderatorId': moderatorId,
        'targetType': targetType,
        'targetId': targetId,
        'action': action,
        'reason': reason,
        'createdAt': createdAt.toIso8601String(),
      };

  factory ModerationLog.fromJson(Map<String, dynamic> json) => ModerationLog(
        id: json['id'],
        moderatorId: json['moderatorId'],
        targetType: json['targetType'],
        targetId: json['targetId'],
        action: json['action'],
        reason: json['reason'],
        createdAt: DateTime.parse(json['createdAt']),
      );
}
