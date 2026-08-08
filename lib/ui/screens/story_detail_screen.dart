import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../data/models/domain_models.dart';
import '../../state/auth_state.dart';
import '../../state/feed_state.dart';

class StoryDetailScreen extends StatefulWidget {
  final String postId;

  const StoryDetailScreen({super.key, required this.postId});

  @override
  State<StoryDetailScreen> createState() => _StoryDetailScreenState();
}

class _StoryDetailScreenState extends State<StoryDetailScreen> {
  final _commentController = TextEditingController();
  final _reportDescriptionController = TextEditingController();
  String? _replyToCommentId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<FeedState>(context, listen: false).fetchComments(widget.postId);
    });
  }

  @override
  void dispose() {
    _commentController.dispose();
    _reportDescriptionController.dispose();
    super.dispose();
  }

  void _submitComment() {
    final authState = Provider.of<AuthState>(context, listen: false);
    if (!authState.isAuthenticated) {
      _showAuthWarning('comment on stories');
      return;
    }

    final body = _commentController.text.trim();
    if (body.isEmpty) return;

    final feedState = Provider.of<FeedState>(context, listen: false);
    feedState.addComment(
      widget.postId,
      authState.currentUser!.id,
      authState.currentProfile!.displayName,
      body,
      parentCommentId: _replyToCommentId,
    );

    setState(() {
      _commentController.clear();
      _replyToCommentId = null;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Comment posted anonymously.')),
    );
  }

  void _showAuthWarning(String action) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Please sign in or register to $action.'),
        action: SnackBarAction(
          label: 'Sign In',
          onPressed: () => context.push('/login'),
        ),
      ),
    );
  }

  void _showReportDialog(ReportTargetType type, String targetId) {
    final authState = Provider.of<AuthState>(context, listen: false);
    if (!authState.isAuthenticated) {
      _showAuthWarning('report content');
      return;
    }

    String selectedReason = 'Spam';
    final reasons = [
      'Harassment or Doxxing',
      'Reveals Personal Info (PII)',
      'Over-Precise Workplace Details',
      'Spam',
      'Other',
    ];

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Report Content'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Help keep UNSAID safe. Why are you reporting this?',
                      style: TextStyle(fontSize: 12, height: 1.4),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: selectedReason,
                      decoration: const InputDecoration(labelText: 'Reason'),
                      items: reasons.map((r) {
                        return DropdownMenuItem(value: r, child: Text(r, style: const TextStyle(fontSize: 13)));
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setDialogState(() {
                            selectedReason = val;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _reportDescriptionController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: 'Additional Details (Optional)',
                        hintText: 'Provide details to help moderators review...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    _reportDescriptionController.clear();
                    Navigator.pop(context);
                  },
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final feedState = Provider.of<FeedState>(context, listen: false);
                    feedState.reportPostOrComment(
                      reporterId: authState.currentUser!.id,
                      targetType: type,
                      targetId: targetId,
                      reason: selectedReason,
                      description: _reportDescriptionController.text.trim(),
                    );
                    _reportDescriptionController.clear();
                    Navigator.pop(context);
                    
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Report submitted. Moderators will review it shortly.'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  },
                  child: const Text('Submit Report'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthState>();
    final feedState = context.watch<FeedState>();
    final post = feedState.getPostById(widget.postId);

    if (post == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Details')),
        body: const Center(child: Text('Story not found or removed.')),
      );
    }

    final exp = post.experience;
    final bookmarked = feedState.isBookmarked(BookmarkTargetType.post, post.id);

    // Determine current user's reaction
    ReactionType? activeReaction;
    if (authState.isAuthenticated) {
      final userReacts = feedState.userReactions.where((r) => r.postId == post.id);
      if (userReacts.isNotEmpty) {
        activeReaction = userReacts.first.type;
      }
    }

    // Organize comments hierarchy
    final comments = feedState.activePostComments.where((c) => c.parentCommentId == null).toList();
    final replies = feedState.activePostComments.where((c) => c.parentCommentId != null).toList();

    // Initials Config
    final isCurrent = exp?.employmentStatus == 'current';
    final avatarBgColor = isCurrent ? const Color(0xFFD0F2E6) : const Color(0xFFF3D8C8);
    final avatarTextColor = isCurrent ? const Color(0xFF0F5A47) : const Color(0xFFC05C3E);
    
    final avatarInitials = post.authorPseudonym.length >= 2 
        ? post.authorPseudonym.substring(0, 2) 
        : post.authorPseudonym;

    // Experience classification badge
    String experienceClass = 'Mixed experience';
    Color classBg = const Color(0xFFF1EDE8);
    Color classText = const Color(0xFF6A6661);
    
    if (exp != null) {
      if (exp.overallRating >= 3.5) {
        experienceClass = 'Positive experience';
        classBg = const Color(0xFFFDECE7); // Light pinkish-orange
        classText = const Color(0xFFC05C3E); // Terracotta
      } else if (exp.overallRating <= 2.2) {
        experienceClass = 'Negative experience';
        classBg = const Color(0xFFFCE8E6); // Light red
        classText = const Color(0xFFC93B2B);
      }
    }

    // Calculate reading time
    final wordCount = post.body.split(' ').length;
    final readTime = (wordCount / 100).ceil();
    final readTimeStr = '$readTime min read';

    // Get related posts from the same category
    final relatedPosts = feedState.allPosts
        .where((p) => p.id != post.id && p.experience?.companyType == exp?.companyType)
        .take(3)
        .toList();

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: Text(
          exp?.companyType ?? 'Story Details',
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Link copied to clipboard!')),
              );
            },
          ),
          IconButton(
            icon: Icon(
              bookmarked ? Icons.bookmark : Icons.bookmark_border_outlined,
              color: bookmarked ? const Color(0xFFC05C3E) : null,
            ),
            onPressed: () {
              if (!authState.isAuthenticated) {
                _showAuthWarning('bookmark stories');
              } else {
                feedState.toggleBookmark(
                  authState.currentUser!.id,
                  BookmarkTargetType.post,
                  post.id,
                );
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.flag_outlined, color: Colors.grey),
            tooltip: 'Report content',
            onPressed: () => _showReportDialog(ReportTargetType.post, post.id),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Classification Badge (Screenshot 1)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: classBg,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            experienceClass,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: classText,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Large Title
                      Text(
                        post.title,
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          color: Theme.of(context).textTheme.headlineMedium?.color,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Date & Read Time
                      Text(
                        '${_formatDate(post.createdAt)} · $readTimeStr',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF6A6661),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 16),

                      // Author Info Row
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          CircleAvatar(
                            radius: 18,
                            backgroundColor: avatarBgColor,
                            child: Text(
                              avatarInitials,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: avatarTextColor,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      post.authorPseudonym,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13.5,
                                        color: Theme.of(context).textTheme.titleLarge?.color,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    const Icon(
                                      Icons.verified,
                                      size: 14,
                                      color: Color(0xFF0F5A47),
                                    ),
                                  ],
                                ),
                                if (exp != null) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    '${exp.role} · ${exp.experienceDuration} · ${exp.employmentStatus == 'current' ? 'Current employee' : 'Former employee'}',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Color(0xFF6A6661),
                                    ),
                                  ),
                                  const SizedBox(height: 1),
                                  Text(
                                    '${exp.companyType} ${exp.companySize}',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Color(0xFF6A6661),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Role Specs Table Grid (Screenshot 1)
                      if (exp != null) ...[
                        const Divider(),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _buildSpecColumn('Role', exp.role),
                              _buildSpecColumn('Time there', exp.experienceDuration),
                              _buildSpecColumn('Status', exp.employmentStatus == 'current' ? 'Current employee' : 'Former employee'),
                            ],
                          ),
                        ),
                        const Divider(),
                        const SizedBox(height: 24),
                      ],

                      // Story Body
                      Text(
                        post.body,
                        style: TextStyle(
                          fontSize: 14.5,
                          height: 1.6,
                          color: Theme.of(context).textTheme.bodyMedium?.color,
                        ),
                      ),
                      const SizedBox(height: 28),

                      // Why This Happened Section (Screenshot 2)
                      if (exp != null) ...[
                        const Text(
                          'WHY THIS HAPPENED',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF6A6661),
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            if (exp.primaryReason.isNotEmpty)
                              _buildWhyChip(exp.primaryReason),
                            ...exp.reasonTags.map((tag) => _buildWhyChip(tag)),
                          ],
                        ),
                        const SizedBox(height: 24),
                      ],

                      // Flags Section (Screenshot 2)
                      if (exp != null && (exp.greenFlags.isNotEmpty || exp.redFlags.isNotEmpty)) ...[
                        if (exp.greenFlags.isNotEmpty) ...[
                          const Text(
                            'GREEN FLAGS',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF6A6661),
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: exp.greenFlags.map((flag) => _buildDetailFlagChip(flag, true)).toList(),
                          ),
                          const SizedBox(height: 24),
                        ],
                        if (exp.redFlags.isNotEmpty) ...[
                          const Text(
                            'RED FLAGS',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF6A6661),
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: exp.redFlags.map((flag) => _buildDetailFlagChip(flag, false)).toList(),
                          ),
                          const SizedBox(height: 24),
                        ],
                      ],

                      // Ratings Breakdown (Screenshot 2)
                      if (exp != null) ...[
                        const Text(
                          'HOW THEY RATED IT',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF6A6661),
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              exp.overallRating.toStringAsFixed(1),
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).textTheme.headlineMedium?.color,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'out of 5 overall',
                              style: TextStyle(fontSize: 12, color: Color(0xFF6A6661)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildHorizontalRatingRow('Management', exp.managementRating),
                        _buildHorizontalRatingRow('Culture', exp.cultureRating),
                        _buildHorizontalRatingRow('Growth', exp.growthRating),
                        _buildHorizontalRatingRow('Compensation', exp.compensationRating),
                        _buildHorizontalRatingRow('Work-life balance', exp.workLifeRating),
                        const SizedBox(height: 28),
                      ],

                      // Where This Happened Card (Screenshot 2)
                      if (exp != null) ...[
                        const Text(
                          'WHERE THIS HAPPENED',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF6A6661),
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Theme.of(context).dividerColor),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          exp.companyType,
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold,
                                            color: Theme.of(context).textTheme.headlineMedium?.color,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${exp.companySize} employees · ${exp.industry}',
                                          style: const TextStyle(fontSize: 12, color: Color(0xFF6A6661)),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          exp.locationRegion,
                                          style: const TextStyle(fontSize: 12, color: Color(0xFF6A6661)),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        exp.overallRating.toStringAsFixed(1),
                                        style: TextStyle(
                                          fontSize: 22,
                                          fontWeight: FontWeight.bold,
                                          color: Theme.of(context).textTheme.titleLarge?.color,
                                        ),
                                      ),
                                      const Text(
                                        '38 STORIES',
                                        style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF6A6661)),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              const Divider(),
                              const SizedBox(height: 8),
                              InkWell(
                                onTap: () {
                                  context.push('/category-profile?companyType=${Uri.encodeComponent(exp.companyType)}');
                                },
                                child: const Text(
                                  'See all 38 experiences',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFFC05C3E), // Terracotta
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],

                      // Bottom Flat Actions Bar (Screenshot 2)
                      const Divider(),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Wrap(
                          alignment: WrapAlignment.spaceBetween,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            Wrap(
                              spacing: 16,
                              children: [
                                _buildFlatReactionButton(
                                  ReactionType.relatable,
                                  Icons.favorite_border,
                                  Icons.favorite,
                                  Colors.red,
                                  'Relatable',
                                  post.reactionsCount['relatable'] ?? 0,
                                  activeReaction == ReactionType.relatable,
                                ),
                                _buildFlatReactionButton(
                                  ReactionType.interesting,
                                  Icons.lightbulb_outline,
                                  Icons.lightbulb,
                                  Colors.amber,
                                  'Interesting',
                                  post.reactionsCount['interesting'] ?? 0,
                                  activeReaction == ReactionType.interesting,
                                ),
                                _buildFlatReactionButton(
                                  ReactionType.redflag,
                                  Icons.flag_outlined,
                                  Icons.flag,
                                  const Color(0xFFC05C3E),
                                  'Red flag',
                                  post.reactionsCount['redflag'] ?? 0,
                                  activeReaction == ReactionType.redflag,
                                ),
                              ],
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.comment_outlined, size: 16, color: Color(0xFF6A6661)),
                                const SizedBox(width: 4),
                                Text(
                                  '${post.commentCount} comments',
                                  style: const TextStyle(fontSize: 12, color: Color(0xFF6A6661)),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const Divider(),
                      const SizedBox(height: 28),

                      // Discussion Input Card (Screenshot 3)
                      Text(
                        'DISCUSSION · ${post.commentCount}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF6A6661),
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.5)),
                        ),
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            TextField(
                              controller: _commentController,
                              maxLines: 3,
                              decoration: const InputDecoration(
                                hintText: 'Share your perspective. Keep it about the experience.',
                                hintStyle: TextStyle(fontSize: 13, color: Color(0xFF6A6661)),
                                border: InputBorder.none,
                              ),
                              style: const TextStyle(fontSize: 13.5),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Posted as Anonymous',
                                  style: TextStyle(fontSize: 11.5, color: Color(0xFF6A6661)),
                                ),
                                ElevatedButton(
                                  onPressed: _submitComment,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFC05C3E), // Terracotta
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                  child: const Text('Post', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Comments List
                      if (comments.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 24),
                          child: Center(
                            child: Text(
                              'No comments yet. Start the discussion.',
                              style: TextStyle(color: Colors.grey, fontSize: 12),
                            ),
                          ),
                        )
                      else
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: comments.length,
                          itemBuilder: (context, index) {
                            final comment = comments[index];
                            final commentReplies = replies.where((r) => r.parentCommentId == comment.id).toList();
                            return _buildCommentItem(comment, commentReplies);
                          },
                        ),

                      const SizedBox(height: 36),
                      const Divider(),
                      const SizedBox(height: 24),

                      // Related Experiences Section (Screenshot 3)
                      const Text(
                        'RELATED EXPERIENCES',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF6A6661),
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildRelatedExperiences(relatedPosts),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSpecColumn(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Color(0xFF6A6661)),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.titleLarge?.color),
        ),
      ],
    );
  }

  Widget _buildWhyChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF1EDE8),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 12, color: Color(0xFF6A6661)),
      ),
    );
  }

  Widget _buildDetailFlagChip(String label, bool isGreen) {
    final chipColor = isGreen ? const Color(0xFF0F5A47) : const Color(0xFFC05C3E);
    final bg = isGreen ? const Color(0xFFD0F2E6) : const Color(0xFFFDECE7);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(isGreen ? Icons.check : Icons.warning_amber, size: 14, color: chipColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: chipColor, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildHorizontalRatingRow(String label, double rating) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              label,
              style: const TextStyle(fontSize: 13, color: Color(0xFF6A6661)),
            ),
          ),
          Expanded(
            flex: 6,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: rating / 5.0,
                minHeight: 8,
                backgroundColor: const Color(0xFFF1EDE8),
                valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.primary),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Text(
            rating.toStringAsFixed(1),
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.titleLarge?.color),
          ),
        ],
      ),
    );
  }

  Widget _buildRelatedExperiences(List<Post> posts) {
    if (posts.isEmpty) {
      return const Text('No related experiences found.', style: TextStyle(fontSize: 12, color: Colors.grey));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: posts.map((post) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: InkWell(
            onTap: () {
              context.pushReplacement('/posts/${post.id}');
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  post.title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).textTheme.titleLarge?.color,
                  ),
                ),
                const SizedBox(height: 4),
                if (post.experience != null)
                  Text(
                    '${post.experience!.role} · ${post.experience!.experienceDuration}',
                    style: const TextStyle(fontSize: 11.5, color: Color(0xFF6A6661)),
                  ),
                const SizedBox(height: 12),
                const Divider(),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildFlatReactionButton(
    ReactionType type,
    IconData icon,
    IconData activeIcon,
    Color activeColor,
    String label,
    int count,
    bool isSelected,
  ) {
    final authState = Provider.of<AuthState>(context, listen: false);
    final feedState = Provider.of<FeedState>(context, listen: false);

    return InkWell(
      onTap: () {
        if (!authState.isAuthenticated) {
          _showAuthWarning('react to stories');
        } else {
          feedState.toggleReaction(authState.currentUser!.id, widget.postId, type);
        }
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isSelected ? activeIcon : icon,
            size: 16,
            color: isSelected ? activeColor : const Color(0xFF6A6661),
          ),
          const SizedBox(width: 4),
          Text(
            '$count $label',
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? activeColor : const Color(0xFF6A6661),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentItem(Comment comment, List<Comment> commentReplies) {
    // Generate comment initials and background colors
    final initials = comment.authorPseudonym.length >= 2
        ? comment.authorPseudonym.substring(0, 2).toUpperCase()
        : comment.authorPseudonym.toUpperCase();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: const Color(0xFFE5E2DD), // Soft gray-lavender circle
                child: Text(
                  initials,
                  style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF6A6661)),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                comment.authorPseudonym,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Theme.of(context).textTheme.titleLarge?.color),
              ),
              const SizedBox(width: 8),
              Text(
                _formatDate(comment.createdAt),
                style: const TextStyle(fontSize: 11, color: Color(0xFF6A6661)),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(left: 36, top: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  comment.body,
                  style: TextStyle(fontSize: 13.5, color: Theme.of(context).textTheme.bodyMedium?.color, height: 1.4),
                ),
                const SizedBox(height: 8),
                
                // Comment Actions (Heart, Reply, Flag)
                Row(
                  children: [
                    const Icon(Icons.favorite_border, size: 14, color: Color(0xFF6A6661)),
                    const SizedBox(width: 4),
                    const Text('64', style: TextStyle(fontSize: 11, color: Color(0xFF6A6661))),
                    const SizedBox(width: 16),
                    InkWell(
                      onTap: () {
                        setState(() {
                          _replyToCommentId = comment.id;
                        });
                      },
                      child: Row(
                        children: const [
                          Icon(Icons.reply, size: 14, color: Color(0xFF6A6661)),
                          SizedBox(width: 4),
                          Text('Reply', style: TextStyle(fontSize: 11, color: Color(0xFF6A6661))),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    IconButton(
                      icon: const Icon(Icons.flag_outlined, size: 14, color: Color(0xFF6A6661)),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () => _showReportDialog(ReportTargetType.comment, comment.id),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Replies (indented)
          if (commentReplies.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 36, top: 8),
              child: Column(
                children: commentReplies.map((r) => _buildCommentReplyItem(r)).toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCommentReplyItem(Comment reply) {
    final initials = reply.authorPseudonym.length >= 2
        ? reply.authorPseudonym.substring(0, 2).toUpperCase()
        : reply.authorPseudonym.toUpperCase();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 12,
                backgroundColor: const Color(0xFFE5E2DD),
                child: Text(
                  initials,
                  style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Color(0xFF6A6661)),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                reply.authorPseudonym,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Theme.of(context).textTheme.titleLarge?.color),
              ),
              const SizedBox(width: 8),
              Text(
                _formatDate(reply.createdAt),
                style: const TextStyle(fontSize: 10, color: Color(0xFF6A6661)),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(left: 32, top: 2),
            child: Text(
              reply.body,
              style: TextStyle(fontSize: 13, color: Theme.of(context).textTheme.bodyMedium?.color),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${(diff.inDays / 7).floor()}w ago';
  }
}
