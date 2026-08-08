import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../state/auth_state.dart';
import '../../state/story_creator_state.dart';
import '../../state/feed_state.dart';

class CreateStoryScreen extends StatefulWidget {
  const CreateStoryScreen({super.key});

  @override
  State<CreateStoryScreen> createState() => _CreateStoryScreenState();
}

class _CreateStoryScreenState extends State<CreateStoryScreen> {
  final _formKeyDetails = GlobalKey<FormState>();
  final _roleController = TextEditingController();
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  
  String? _publishedPostId;
  bool _isSavingContext = false;
  int _promptIndex = 0;

  final List<String> _writingPrompts = [
    "What's something nobody warned you about?",
    "Why did you finally say I'm done?",
    "What happened behind the scenes?",
    "How did leadership handle tough situations?",
    "What is the day-to-day culture really like?",
  ];

  final List<String> _hooks = [
    'I quit',
    'Toxic workplace',
    'Burned out',
    'Great growth',
    'Great workplace',
    'Something else',
  ];

  final List<String> _roleSuggestions = [
    'Software Engineer',
    'Product Manager',
    'Consultant',
    'Designer',
    'HR Specialist',
    'Sales Executive',
  ];

  final List<String> _industries = ['IT & Software', 'Finance', 'Healthcare', 'Consulting', 'Manufacturing', 'Education'];
  final List<String> _regions = ['India-North', 'India-South', 'India-West', 'India-East', 'Remote'];
  final List<String> _tenures = ['< 1 year', '1-2 years', '3-5 years', '5+ years'];

  final List<String> _reasonOptions = ['Toxic Work Culture', 'Underpaid', 'Burnt Out', 'Poor Leadership', 'Lack of Growth', 'Better Opportunity', 'Relocation'];
  final List<String> _redFlagsOptions = ['Micromanagement', 'Unpaid Overtime', 'High Turnover', 'Toxic Leadership', 'No Growth Paths'];
  final List<String> _greenFlagsOptions = ['Flexible Hours', 'Mentorship', 'Fair Pay', 'Transparent Management', 'Healthy Work Culture'];

  @override
  void dispose() {
    _roleController.dispose();
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  void _onHookSelected(String hook, StoryCreatorState state) {
    state.hookPrompt = hook;
    if (hook != 'Something else') {
      String defaultTitle = '';
      switch (hook) {
        case 'I quit':
          defaultTitle = 'Why I finally decided to quit';
          break;
        case 'Toxic workplace':
          defaultTitle = 'Dealing with a toxic work culture';
          break;
        case 'Burned out':
          defaultTitle = 'Struggling with extreme burnout';
          break;
        case 'Great growth':
          defaultTitle = 'Incredible learning and growth opportunities';
          break;
        case 'Great workplace':
          defaultTitle = 'A healthy and supportive work environment';
          break;
      }
      state.title = defaultTitle;
      _titleController.text = defaultTitle;
    }
    state.nextStep();
  }

  void _onRoleSuggestionSelected(String roleTitle, StoryCreatorState state) {
    state.role = roleTitle;
    _roleController.text = roleTitle;
    setState(() {});
  }

  void _cyclePrompt() {
    setState(() {
      _promptIndex = (_promptIndex + 1) % _writingPrompts.length;
    });
  }

  Future<void> _handlePublish(StoryCreatorState state, AuthState authState) async {
    state.title = _titleController.text.trim();
    state.body = _bodyController.text.trim();
    state.role = _roleController.text.trim();

    if (state.title.isEmpty || state.body.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a title and description for your story.')),
      );
      return;
    }

    if (!state.acceptedCautionReminder) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please accept the privacy warning checklist before sharing.')),
      );
      return;
    }

    // Combinatorial identification warning
    if (state.hasCombinatorialRisk) {
      final proceed = await showDialog<bool>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Anonymity Warning'),
            content: const Text(
              'Your combination of Role, Region, and Startup size is highly specific. '
              'Colleagues might be able to identify you. Are you sure you want to proceed?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Edit Details'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Publish Anyway'),
              ),
            ],
          );
        },
      );
      if (proceed != true) return;
    }

    final post = await state.submitStory(authState.currentUser!.id, authState.currentProfile!.displayName);
    if (!mounted) return;
    if (post != null) {
      setState(() {
        _publishedPostId = post.id;
      });
      // Trigger feed refresh in background
      Provider.of<FeedState>(context, listen: false).fetchPosts();
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Submission failed. Please check your connectivity and try again.')),
        );
      }
    }
  }

  Future<void> _handleSaveContext(StoryCreatorState state) async {
    if (_publishedPostId == null) return;
    setState(() {
      _isSavingContext = true;
    });

    final success = await state.updateStoryContext(_publishedPostId!);
    setState(() {
      _isSavingContext = false;
    });

    if (success) {
      // Refresh main feed
      if (mounted) {
        Provider.of<FeedState>(context, listen: false).fetchPosts();
        state.reset();
        context.go('/home');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Optional context saved successfully!')),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update context.')),
        );
      }
    }
  }

  void _handleSkipContext(StoryCreatorState state) {
    state.reset();
    context.go('/home');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Story published anonymously!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthState>();
    final creatorState = context.watch<StoryCreatorState>();

    if (!authState.isAuthenticated) {
      return Scaffold(
        appBar: AppBar(title: const Text('Share Anonymous Story')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.lock_person_outlined, size: 64, color: Colors.grey.shade400),
                const SizedBox(height: 16),
                const Text(
                  'Authentication Required',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'You must sign in to publish an anonymous workplace experience.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => context.push('/login'),
                  child: const Text('Sign In / Register'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Success intermediate screen for optional details
    if (_publishedPostId != null) {
      return _buildPostPublishingContextScreen(creatorState);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Share story'),
        actions: [
          TextButton(
            onPressed: () {
              creatorState.reset();
              context.go('/home');
            },
            child: const Text('Cancel'),
          ),
        ],
      ),
      body: Column(
        children: [
          // Simplified progress bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Theme.of(context).dividerColor.withValues(alpha: 0.02),
            child: Row(
              children: [
                _buildStepIndicator(0, 'Hook', creatorState.currentStep),
                _buildStepDivider(),
                _buildStepIndicator(1, 'Context', creatorState.currentStep),
                _buildStepDivider(),
                _buildStepIndicator(2, 'Confession', creatorState.currentStep),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: _buildActiveStepContent(creatorState, authState),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepIndicator(int step, String label, int currentStep) {
    final isActive = currentStep == step;
    final isDone = currentStep > step;
    final color = isDone
        ? Colors.green
        : (isActive ? Theme.of(context).colorScheme.primary : Colors.grey);

    return Expanded(
      child: Column(
        children: [
          CircleAvatar(
            radius: 10,
            backgroundColor: color.withValues(alpha: 0.15),
            child: isDone
                ? const Icon(Icons.check, size: 10, color: Colors.green)
                : Text(
                    '${step + 1}',
                    style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: color),
                  ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepDivider() {
    return Container(
      width: 32,
      height: 1,
      color: Colors.grey.shade300,
      margin: const EdgeInsets.symmetric(horizontal: 4),
    );
  }

  Widget _buildActiveStepContent(StoryCreatorState state, AuthState auth) {
    switch (state.currentStep) {
      case 0:
        return _buildHookStep(state);
      case 1:
        return _buildContextStep(state);
      case 2:
        return _buildStoryComposerStep(state, auth);
      default:
        return const SizedBox();
    }
  }

  // --- Step 0: Hook Selection ---
  Widget _buildHookStep(StoryCreatorState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'What happened? 👀',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        const Text(
          'Select a quick category to start your confession.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey, fontSize: 13),
        ),
        const SizedBox(height: 24),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.6,
          ),
          itemCount: _hooks.length,
          itemBuilder: (context, index) {
            final hook = _hooks[index];
            return OutlinedButton(
              onPressed: () => _onHookSelected(hook, state),
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                side: BorderSide(color: Theme.of(context).dividerColor),
                padding: const EdgeInsets.all(12),
              ),
              child: Text(
                hook,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
                textAlign: TextAlign.center,
              ),
            );
          },
        ),
      ],
    );
  }

  // --- Step 1: Context Metadata ---
  Widget _buildContextStep(StoryCreatorState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Add company context',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        const Text(
          'All details here are completely optional. Select quick chips or skip.',
          style: TextStyle(color: Colors.grey, fontSize: 12),
        ),
        const SizedBox(height: 24),

        // Role title input
        TextFormField(
          controller: _roleController,
          decoration: const InputDecoration(
            labelText: 'Job Role / Title',
            hintText: 'e.g. Software Engineer, Associate Consultant',
          ),
          onChanged: (val) => state.role = val,
        ),
        const SizedBox(height: 10),
        
        // Role suggestions chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: _roleSuggestions.map((roleTitle) {
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ActionChip(
                  label: Text(roleTitle, style: const TextStyle(fontSize: 11)),
                  onPressed: () => _onRoleSuggestionSelected(roleTitle, state),
                  backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 20),

        // Tenure Row selection
        const Text('Tenure (Duration)*', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: _tenures.map((tenure) {
            final isSelected = state.experienceDuration == tenure;
            return ChoiceChip(
              label: Text(tenure, style: const TextStyle(fontSize: 11)),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  state.experienceDuration = selected ? tenure : null;
                });
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 20),

        // Industry Row selection
        const Text('Industry', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: _industries.map((ind) {
            final isSelected = state.industry == ind;
            return ChoiceChip(
              label: Text(ind, style: const TextStyle(fontSize: 11)),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  state.industry = selected ? ind : null;
                });
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 20),

        // Region Row selection
        const Text('Region / Location', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: _regions.map((reg) {
            final isSelected = state.locationRegion == reg;
            return ChoiceChip(
              label: Text(reg, style: const TextStyle(fontSize: 11)),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  state.locationRegion = selected ? reg : null;
                });
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 20),

        // Employment Status
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Employment status', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
            ChoiceChip(
              label: Text(state.employmentStatus == 'current' ? 'Current Employee' : 'Former Employee'),
              selected: state.employmentStatus == 'former',
              onSelected: (selected) {
                setState(() {
                  state.employmentStatus = selected ? 'former' : 'current';
                });
              },
            ),
          ],
        ),

        const SizedBox(height: 32),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            OutlinedButton(
              onPressed: state.prevStep,
              child: const Text('Back'),
            ),
            ElevatedButton(
              onPressed: state.nextStep,
              child: const Text('Next / Skip'),
            ),
          ],
        ),
      ],
    );
  }

  // --- Step 2: Story Composer ---
  Widget _buildStoryComposerStep(StoryCreatorState state, AuthState auth) {
    return Form(
      key: _formKeyDetails,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Okay... spill it. 👀',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 4),
          const Text(
            'Share what happened at your workplace.',
            style: TextStyle(color: Colors.grey, fontSize: 13),
          ),
          const SizedBox(height: 20),

          // Writing prompt suggestion panel
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.15)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Writing Prompt Suggestion:', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                    TextButton(
                      onPressed: _cyclePrompt,
                      style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                      child: const Text('Show another', style: TextStyle(fontSize: 10)),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                InkWell(
                  onTap: () {
                    // Prepopulate body
                    _bodyController.text = "${_writingPrompts[_promptIndex]}\n\n";
                    state.body = _bodyController.text;
                  },
                  child: Text(
                    '"${_writingPrompts[_promptIndex]}"',
                    style: TextStyle(fontSize: 12.5, fontStyle: FontStyle.italic, color: Theme.of(context).colorScheme.primary),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          TextFormField(
            controller: _titleController,
            decoration: const InputDecoration(
              labelText: 'Story Title *',
              hintText: 'Sum up your experience in one sentence',
            ),
            validator: (val) => val == null || val.trim().isEmpty ? 'Please enter a title' : null,
          ),
          const SizedBox(height: 16),

          TextFormField(
            controller: _bodyController,
            maxLines: 8,
            decoration: const InputDecoration(
              labelText: 'Confession / Experience details *',
              hintText: 'Type your experience details anonymously. Keep names private.',
              alignLabelWithHint: true,
            ),
            validator: (val) => val == null || val.trim().isEmpty ? 'Please enter details' : null,
          ),
          const SizedBox(height: 20),

          // Privacy Confirmation Checkbox
          CheckboxListTile(
            title: const Text(
              'I confirm that this contains no names, personal references, or identifiable information.',
              style: TextStyle(fontSize: 12),
            ),
            value: state.acceptedCautionReminder,
            onChanged: (val) {
              setState(() {
                state.acceptedCautionReminder = val ?? false;
              });
            },
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
          ),
          
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              OutlinedButton(
                onPressed: state.prevStep,
                child: const Text('Back'),
              ),
              ElevatedButton(
                onPressed: () => _handlePublish(state, auth),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Share anonymously'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- Step 3: Intermediate success optional context ---
  Widget _buildPostPublishingContextScreen(StoryCreatorState state) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Success!'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => _handleSkipContext(state),
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Center(
              child: Icon(Icons.check_circle_outline, size: 72, color: Colors.green),
            ),
            const SizedBox(height: 16),
            const Text(
              'Published anonymously! 🎉',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text(
              'Your story is now visible. If you have 30 more seconds, adding ratings helps other users search and filter workplace metrics.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 32),

            const Divider(),
            const SizedBox(height: 24),
            const Text(
              'Want to add more context? (Optional)',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            // Ratings Sliders
            _buildRatingSlider('Overall Rating', state.overallRating, (val) => setState(() => state.overallRating = val)),
            _buildRatingSlider('Culture', state.cultureRating, (val) => setState(() => state.cultureRating = val)),
            _buildRatingSlider('Management Quality', state.managementRating, (val) => setState(() => state.managementRating = val)),
            _buildRatingSlider('Growth & Career Paths', state.growthRating, (val) => setState(() => state.growthRating = val)),
            _buildRatingSlider('Compensation & Hikes', state.compensationRating, (val) => setState(() => state.compensationRating = val)),
            _buildRatingSlider('Work-Life Balance', state.workLifeRating, (val) => setState(() => state.workLifeRating = val)),

            const SizedBox(height: 20),
            
            // Reasons Tags (If former employee)
            if (state.employmentStatus == 'former') ...[
              const Text('Primary Reason for Leaving', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: _reasonOptions.map((tag) {
                  final isSelected = state.selectedReasonTags.contains(tag);
                  return ChoiceChip(
                    label: Text(tag, style: const TextStyle(fontSize: 11)),
                    selected: isSelected,
                    onSelected: (_) => state.toggleReasonTag(tag),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
            ],

            // Red Flags Checklist
            const Text('Red Flags Identified', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.red)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: _redFlagsOptions.map((flag) {
                final isSelected = state.selectedRedFlags.contains(flag);
                return FilterChip(
                  label: Text(flag, style: const TextStyle(fontSize: 11)),
                  selected: isSelected,
                  onSelected: (_) => state.toggleRedFlag(flag),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // Green Flags Checklist
            const Text('Green Flags Identified', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.green)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: _greenFlagsOptions.map((flag) {
                final isSelected = state.selectedGreenFlags.contains(flag);
                return FilterChip(
                  label: Text(flag, style: const TextStyle(fontSize: 11)),
                  selected: isSelected,
                  onSelected: (_) => state.toggleGreenFlag(flag),
                );
              }).toList(),
            ),
            const SizedBox(height: 36),

            ElevatedButton(
              onPressed: _isSavingContext ? null : () => _handleSaveContext(state),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: _isSavingContext
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Save details', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => _handleSkipContext(state),
              child: const Text('Maybe later / Skip', style: TextStyle(color: Colors.grey)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRatingSlider(String label, double rating, ValueChanged<double> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(fontSize: 12.5)),
              Text(rating.toStringAsFixed(1), style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold)),
            ],
          ),
          Slider(
            value: rating,
            min: 1.0,
            max: 5.0,
            divisions: 8,
            label: rating.toStringAsFixed(1),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
