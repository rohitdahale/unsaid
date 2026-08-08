import 'package:flutter/material.dart';
import '../data/models/domain_models.dart';
import '../repositories/post_repository.dart';

class StoryCreatorState extends ChangeNotifier {
  final PostRepository _postRepo;

  StoryCreatorState(this._postRepo);

  int _currentStep = 0;
  int get currentStep => _currentStep;

  // Step 0: Hook Selection
  String? hookPrompt;

  // Step 1: Context & Metadata (Essential)
  String? industry;
  String? companySize; // defaulted/optional
  String? companyType; // defaulted/optional
  String? locationRegion;
  String role = '';
  String? experienceDuration;
  String employmentStatus = 'current'; // 'current' | 'former'

  // Optional: Ratings & Reasons (Post-publishing context)
  double overallRating = 3.0;
  double cultureRating = 3.0;
  double managementRating = 3.0;
  double compensationRating = 3.0;
  double growthRating = 3.0;
  double workLifeRating = 3.0;
  String primaryReason = '';
  List<String> selectedReasonTags = [];
  List<String> selectedRedFlags = [];
  List<String> selectedGreenFlags = [];

  // Step 2: Text content
  String title = '';
  String body = '';
  bool acceptedCautionReminder = false;

  // Validation warning
  bool get hasCombinatorialRisk {
    return (role.toLowerCase().contains('director') || role.toLowerCase().contains('vp') || role.toLowerCase().contains('founder')) &&
        (companySize == 'Early-stage Startup' || locationRegion == 'Remote');
  }

  void setStep(int step) {
    if (step >= 0 && step <= 2) {
      _currentStep = step;
      notifyListeners();
    }
  }

  void nextStep() {
    if (_currentStep < 2) {
      _currentStep++;
      notifyListeners();
    }
  }

  void prevStep() {
    if (_currentStep > 0) {
      _currentStep--;
      notifyListeners();
    }
  }

  void reset() {
    _currentStep = 0;
    hookPrompt = null;
    industry = null;
    companySize = null;
    companyType = null;
    locationRegion = null;
    role = '';
    experienceDuration = null;
    employmentStatus = 'current';
    overallRating = 3.0;
    cultureRating = 3.0;
    managementRating = 3.0;
    compensationRating = 3.0;
    growthRating = 3.0;
    workLifeRating = 3.0;
    primaryReason = '';
    selectedReasonTags.clear();
    selectedRedFlags.clear();
    selectedGreenFlags.clear();
    title = '';
    body = '';
    acceptedCautionReminder = false;
    notifyListeners();
  }

  Future<Post?> submitStory(String authorId, String authorPseudonym) async {
    if (title.trim().isEmpty || body.trim().isEmpty || !acceptedCautionReminder) return null;

    final exp = Experience(
      industry: industry ?? 'Not specified',
      companySize: companySize ?? 'Not specified',
      companyType: companyType ?? 'Not specified',
      locationRegion: locationRegion ?? 'Not specified',
      employmentStatus: employmentStatus,
      role: role.trim().isEmpty ? 'Not specified' : role.trim(),
      experienceDuration: experienceDuration ?? 'Not specified',
      overallRating: overallRating,
      managementRating: managementRating,
      cultureRating: cultureRating,
      growthRating: growthRating,
      compensationRating: compensationRating,
      workLifeRating: workLifeRating,
      reasonTags: List<String>.from(selectedReasonTags),
      redFlags: List<String>.from(selectedRedFlags),
      greenFlags: List<String>.from(selectedGreenFlags),
      primaryReason: primaryReason.trim(),
    );

    final post = Post(
      id: 'post_${DateTime.now().millisecondsSinceEpoch}',
      authorId: authorId,
      authorPseudonym: authorPseudonym,
      type: PostType.experience,
      title: title.trim(),
      body: body.trim(),
      experience: exp,
      tags: [
        industry ?? 'Not specified',
        companySize ?? 'Not specified',
        role.trim().isEmpty ? 'Not specified' : role.trim()
      ],
      reactionsCount: {'relatable': 0, 'interesting': 0, 'redflag': 0, 'goodsign': 0},
      commentCount: 0,
      status: PostStatus.published,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    try {
      final savedPost = await _postRepo.createPost(post);
      // We do NOT call reset() here, as the user can optionally add context (ratings/flags) right after publishing
      return savedPost;
    } catch (_) {
      return null;
    }
  }

  Future<bool> updateStoryContext(String postId) async {
    final exp = Experience(
      industry: industry ?? 'Not specified',
      companySize: companySize ?? 'Not specified',
      companyType: companyType ?? 'Not specified',
      locationRegion: locationRegion ?? 'Not specified',
      employmentStatus: employmentStatus,
      role: role.trim().isEmpty ? 'Not specified' : role.trim(),
      experienceDuration: experienceDuration ?? 'Not specified',
      overallRating: overallRating,
      managementRating: managementRating,
      cultureRating: cultureRating,
      growthRating: growthRating,
      compensationRating: compensationRating,
      workLifeRating: workLifeRating,
      reasonTags: List<String>.from(selectedReasonTags),
      redFlags: List<String>.from(selectedRedFlags),
      greenFlags: List<String>.from(selectedGreenFlags),
      primaryReason: primaryReason.trim(),
    );

    try {
      await _postRepo.updatePostExperience(postId, exp);
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }

  // --- Multi-select helpers ---
  void toggleReasonTag(String tag) {
    if (selectedReasonTags.contains(tag)) {
      selectedReasonTags.remove(tag);
    } else {
      selectedReasonTags.add(tag);
    }
    notifyListeners();
  }

  void toggleRedFlag(String flag) {
    if (selectedRedFlags.contains(flag)) {
      selectedRedFlags.remove(flag);
    } else {
      selectedRedFlags.add(flag);
    }
    notifyListeners();
  }

  void toggleGreenFlag(String flag) {
    if (selectedGreenFlags.contains(flag)) {
      selectedGreenFlags.remove(flag);
    } else {
      selectedGreenFlags.add(flag);
    }
    notifyListeners();
  }
}
