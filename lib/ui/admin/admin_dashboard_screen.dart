import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../state/auth_state.dart';
import '../../state/moderation_state.dart';
import '../../state/feed_state.dart';
import '../../data/models/domain_models.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Map<String, dynamic> _metrics = {
    'totalPosts': 0,
    'removedPosts': 0,
    'openReportsCount': 0,
    'totalReportsCount': 0,
    'moderatorActionsCount': 0,
  };

  final _reasonController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchDashboardData();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _fetchDashboardData() async {
    final modState = Provider.of<ModerationState>(context, listen: false);
    await modState.fetchReportsAndLogs();
    final newMetrics = await modState.getDashboardMetrics();
    setState(() {
      _metrics = newMetrics;
    });
  }

  void _showActionSheet(Report report, AppUser moderator) {
    final feedState = Provider.of<FeedState>(context, listen: false);
    final modState = Provider.of<ModerationState>(context, listen: false);

    // Look up reported target object
    String targetContentText = '';
    String authorId = '';
    String authorPseudonym = '';

    if (report.targetType == ReportTargetType.post) {
      final post = feedState.getPostById(report.targetId);
      if (post != null) {
        targetContentText = 'Title: ${post.title}\n\nBody: ${post.body}';
        authorId = post.authorId;
        authorPseudonym = post.authorPseudonym;
      } else {
        targetContentText = '[Story details unavailable — may already be deleted]';
      }
    } else {
      // comment
      final comment = feedState.activePostComments.isEmpty 
          ? null 
          : feedState.activePostComments.firstWhere((c) => c.id == report.targetId, orElse: () => Comment(id: '', postId: '', authorId: '', authorPseudonym: '', body: '', isRemoved: false, createdAt: DateTime.now()));
      if (comment != null && comment.id.isNotEmpty) {
        targetContentText = 'Comment: ${comment.body}';
        authorId = comment.authorId;
        authorPseudonym = comment.authorPseudonym;
      } else {
        targetContentText = '[Comment details unavailable — may already be deleted]';
      }
    }

    _reasonController.clear();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Manage Content - ${report.targetType == ReportTargetType.post ? "Post" : "Comment"}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                
                // Reported Content preview
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).dividerColor.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.1)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Author: $authorPseudonym (ID: $authorId)',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.blueGrey),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        targetContentText,
                        style: const TextStyle(fontSize: 12.5),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Report Details
                Text(
                  'Report Reason: ${report.reason}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.red),
                ),
                if (report.description.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text('Reporter Note: "${report.description}"', style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic)),
                ],
                const SizedBox(height: 16),

                // Action Reason Input
                TextField(
                  controller: _reasonController,
                  decoration: const InputDecoration(
                    labelText: 'Moderation Reason / Explanation *',
                    hintText: 'e.g. Violates guideline against naming managers.',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 20),

                // Action Buttons Grid
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                        icon: const Icon(Icons.check, size: 16),
                        label: const Text('Approve', style: TextStyle(fontSize: 11)),
                        onPressed: () => _executeAction(
                          () => modState.approveContent(report.id, moderator.id, _reasonController.text.trim()),
                          'Content approved and marked resolved.',
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                        icon: const Icon(Icons.delete, size: 16),
                        label: const Text('Remove', style: TextStyle(fontSize: 11)),
                        onPressed: () => _executeAction(
                          () => modState.removeContent(report.id, moderator.id, _reasonController.text.trim()),
                          'Content removed and marked resolved.',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(foregroundColor: Colors.amber, side: const BorderSide(color: Colors.amber)),
                        icon: const Icon(Icons.pause_circle_outline, size: 16),
                        label: const Text('Suspend Author', style: TextStyle(fontSize: 11)),
                        onPressed: () {
                          if (authorId.isEmpty) return;
                          _executeAction(
                            () => modState.suspendUser(authorId, moderator.id, _reasonController.text.trim()),
                            'Author account suspended.',
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(foregroundColor: Colors.redAccent, side: const BorderSide(color: Colors.redAccent)),
                        icon: const Icon(Icons.block, size: 16),
                        label: const Text('Ban Author', style: TextStyle(fontSize: 11)),
                        onPressed: () {
                          if (authorId.isEmpty) return;
                          _executeAction(
                            () => modState.banUser(authorId, moderator.id, _reasonController.text.trim()),
                            'Author account banned.',
                          );
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        );
      },
    );
  }

  void _executeAction(Future<void> Function() action, String successMsg) async {
    final reason = _reasonController.text.trim();
    if (reason.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a moderation explanation reason.'), backgroundColor: Colors.red),
      );
      return;
    }

    final feedState = Provider.of<FeedState>(context, listen: false);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    Navigator.pop(context); // close bottom sheet
    await action();
    _fetchDashboardData();
    
    // Refresh main feeds
    feedState.fetchPosts();

    scaffoldMessenger.showSnackBar(
      SnackBar(content: Text(successMsg), backgroundColor: Colors.green),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthState>();
    final modState = context.watch<ModerationState>();

    // Route access guard: Enforce mod/admin auth
    if (!authState.isAuthenticated || !authState.isModerator) {
      return Scaffold(
        appBar: AppBar(title: const Text('Access Denied')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              const Text('Moderator Authentication Required'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => context.go('/admin/login'),
                child: const Text('Open Moderator Portal'),
              ),
            ],
          ),
        ),
      );
    }

    final openReports = modState.openReports;
    final logs = modState.logs;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Moderation Dashboard'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/home'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchDashboardData,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await authState.logout();
              if (context.mounted) {
                context.go('/welcome');
              }
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'Reported Queue (${openReports.length})'),
            Tab(text: 'Audit Moderation Log (${logs.length})'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Statistics Banner
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
            color: Theme.of(context).dividerColor.withValues(alpha: 0.02),
            child: Row(
              children: [
                _buildStatCard('Total Stories', '${_metrics['totalPosts']}'),
                _buildStatCard('Removed Stories', '${_metrics['removedPosts']}', color: Colors.red),
                _buildStatCard('Open Reports', '${_metrics['openReportsCount']}', color: Colors.amber),
                _buildStatCard('Mod Actions', '${_metrics['moderatorActionsCount']}'),
              ],
            ),
          ),
          
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildReportsQueue(openReports, authState.currentUser!),
                _buildAuditLogs(logs),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String val, {Color? color}) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Text(
                val,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color ?? Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 9, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReportsQueue(List<Report> list, AppUser moderator) {
    if (list.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline, size: 48, color: Colors.green),
            SizedBox(height: 16),
            Text('No pending reports. All clear!'),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final r = list[index];
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: r.targetType == ReportTargetType.post ? Colors.blue.withValues(alpha: 0.1) : Colors.purple.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        r.targetType == ReportTargetType.post ? 'POST' : 'COMMENT',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: r.targetType == ReportTargetType.post ? Colors.blue : Colors.purple,
                        ),
                      ),
                    ),
                    Text(
                      _formatDate(r.createdAt),
                      style: const TextStyle(color: Colors.grey, fontSize: 10),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Reason: ${r.reason}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.red),
                ),
                if (r.description.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Notes: "${r.description}"',
                    style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                  ),
                ],
                const Divider(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Target ID: ${r.targetId}', style: const TextStyle(fontSize: 10, color: Colors.grey)),
                    ElevatedButton.icon(
                      onPressed: () => _showActionSheet(r, moderator),
                      icon: const Icon(Icons.gavel, size: 14),
                      label: const Text('Moderate', style: TextStyle(fontSize: 11)),
                      style: ElevatedButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAuditLogs(List<ModerationLog> list) {
    if (list.isEmpty) {
      return const Center(
        child: Text('No moderation actions logged yet.', style: TextStyle(color: Colors.grey)),
      );
    }

    final sorted = List<ModerationLog>.from(list)..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: sorted.length,
      itemBuilder: (context, index) {
        final l = sorted[index];
        final actionColor = l.action == 'remove' 
            ? Colors.red 
            : (l.action == 'approve' ? Colors.green : Colors.amber);

        return Card(
          child: ListTile(
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Action: ${l.action.toUpperCase()}',
                  style: TextStyle(fontWeight: FontWeight.bold, color: actionColor, fontSize: 12),
                ),
                Text(
                  _formatDate(l.createdAt),
                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                ),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text('Target: ${l.targetType.toUpperCase()} (${l.targetId})', style: const TextStyle(fontSize: 11)),
                const SizedBox(height: 2),
                Text('Reason: "${l.reason}"', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                Text('Moderator: ${l.moderatorId}', style: const TextStyle(fontSize: 9, color: Colors.grey)),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
