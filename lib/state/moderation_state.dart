import 'package:flutter/material.dart';
import '../data/models/domain_models.dart';
import '../repositories/moderation_repository.dart';
import '../repositories/post_repository.dart';

class ModerationState extends ChangeNotifier {
  final ModerationRepository _modRepo;
  final PostRepository _postRepo;

  List<Report> _reports = [];
  List<ModerationLog> _logs = [];
  bool _isLoading = false;
  String? _errorMessage;

  ModerationState(this._modRepo, this._postRepo);

  List<Report> get reports => _reports;
  List<ModerationLog> get logs => _logs;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  List<Report> get openReports => _reports.where((r) => r.status == ReportStatus.open).toList();
  List<Report> get resolvedReports => _reports.where((r) => r.status == ReportStatus.resolved).toList();

  Future<void> fetchReportsAndLogs() async {
    _isLoading = true;
    notifyListeners();
    try {
      _reports = await _modRepo.getReports();
      _logs = await _modRepo.getModerationLogs();
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // --- Admin Moderation Actions (PRD §9.12 / User Correction 8) ---
  
  Future<void> approveContent(String reportId, String moderatorId, String reason) async {
    _isLoading = true;
    notifyListeners();
    try {
      final report = _reports.firstWhere((r) => r.id == reportId);
      await _modRepo.updateReportStatus(reportId, ReportStatus.resolved, moderatorId);
      
      // Log action
      await _modRepo.updatePostStatus(report.targetId, PostStatus.published, moderatorId, 'Approved after review: $reason');
      
      await fetchReportsAndLogs();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> removeContent(String reportId, String moderatorId, String reason) async {
    _isLoading = true;
    notifyListeners();
    try {
      final report = _reports.firstWhere((r) => r.id == reportId);
      await _modRepo.updateReportStatus(reportId, ReportStatus.resolved, moderatorId);

      if (report.targetType == ReportTargetType.post) {
        await _modRepo.updatePostStatus(report.targetId, PostStatus.removed, moderatorId, reason);
      } else {
        await _modRepo.removeComment(report.targetId, moderatorId, reason);
      }
      
      await fetchReportsAndLogs();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> restoreContent(String targetId, String targetType, String moderatorId, String reason) async {
    _isLoading = true;
    notifyListeners();
    try {
      if (targetType == 'post') {
        await _modRepo.updatePostStatus(targetId, PostStatus.published, moderatorId, 'Restored: $reason');
      } else {
        await _modRepo.restoreComment(targetId, moderatorId, reason);
      }
      await fetchReportsAndLogs();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> suspendUser(String userId, String moderatorId, String reason) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _modRepo.updateUserStatus(userId, UserStatus.suspended, moderatorId, reason);
      await fetchReportsAndLogs();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> banUser(String userId, String moderatorId, String reason) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _modRepo.updateUserStatus(userId, UserStatus.banned, moderatorId, reason);
      await fetchReportsAndLogs();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // --- Admin Dashboard Metrics (PRD §25 / §17) ---
  Future<Map<String, dynamic>> getDashboardMetrics() async {
    final posts = await _postRepo.getPosts(status: PostStatus.published);
    final allPosts = await _postRepo.getPosts(status: PostStatus.removed) + posts;
    final totalPosts = allPosts.length;
    final removedPosts = allPosts.where((p) => p.status == PostStatus.removed).length;
    
    return {
      'totalPosts': totalPosts,
      'removedPosts': removedPosts,
      'openReportsCount': openReports.length,
      'totalReportsCount': _reports.length,
      'moderatorActionsCount': _logs.length,
    };
  }
}
