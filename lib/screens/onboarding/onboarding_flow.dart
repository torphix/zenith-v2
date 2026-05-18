import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/app_provider.dart';
import '../../theme.dart';
import '../../widgets/snackbar_helper.dart';
import '../main_shell.dart';
import 'onboarding_data.dart';
import 'screens/ai_conversation_screen.dart';
import 'screens/goal_screen.dart';
import 'screens/mic_permission_screen.dart';
import 'screens/pain_points_screen.dart';
import 'screens/paywall_screen.dart';
import 'screens/preferences_screen.dart';
import 'screens/processing_screen.dart';
import 'screens/solution_screen.dart';
import 'screens/tinder_cards_screen.dart';
import 'screens/value_delivery_screen.dart';
import 'screens/welcome_screen.dart';
import 'widgets/progress_bar.dart';
import '../archetype_reveal_screen.dart';

/// Total number of screens in the onboarding flow.
/// 0: Welcome, 1: Name, 2: Goals, 3: Pain Points, 4: Tinder Cards,
/// 5: Solution, 6: Preferences, 7: Mic+AI Conversation, 8: Processing,
/// 9: Archetype Reveal, 10: Value Delivery, 11: Paywall
const _totalScreens = 12;

class OnboardingFlow extends StatefulWidget {
  const OnboardingFlow({super.key});

  @override
  State<OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends State<OnboardingFlow> {
  final _pageController = PageController();
  final _data = OnboardingData();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goToPage(int page) {
    FocusScope.of(context).unfocus();
    _pageController.animateToPage(
      page,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
  }

  void _nextPage() => _goToPage(_currentPage + 1);

  void _toggleGoal(String goal) {
    setState(() {
      if (_data.selectedGoals.contains(goal)) {
        _data.selectedGoals.remove(goal);
      } else {
        _data.selectedGoals.add(goal);
      }
    });
  }

  void _togglePainPoint(String point) {
    setState(() {
      if (_data.selectedPainPoints.contains(point)) {
        _data.selectedPainPoints.remove(point);
      } else {
        _data.selectedPainPoints.add(point);
      }
    });
  }

  void _togglePreference(String pref) {
    setState(() {
      if (_data.selectedPreferences.contains(pref)) {
        _data.selectedPreferences.remove(pref);
      } else {
        _data.selectedPreferences.add(pref);
      }
    });
  }

  /// Called after AI conversation is done — generate the programme.
  Future<void> _generateProgramme() async {
    _goToPage(8); // Processing screen

    final app = context.read<AppProvider>();
    await app.completeOnboardingWithData(
      name: _data.name.trim().isEmpty ? 'Seeker' : _data.name.trim(),
      selectedGoals: _data.selectedGoals,
      painPoints: _data.selectedPainPoints,
      preferences: _data.selectedPreferences,
      commitmentLevel: _data.commitmentLevel,
      energyPreference: _data.energyPreference,
      conversationHistory: _data.conversationHistory,
    );

    if (!mounted) return;

    final error = app.consumeError();
    if (error != null) {
      showErrorSnackbar(context, error);
      _goToPage(7); // Back to AI conversation
      return;
    }

    _goToPage(9); // Archetype reveal
  }

  /// Finish onboarding and go to main app.
  void _finishOnboarding() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const MainShell()),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Show progress bar on all screens except welcome (0), processing (10),
    // and paywall (12)
    final showProgress =
        _currentPage > 0 && _currentPage != 8 && _currentPage != 9 && _currentPage != 11;

    return Scaffold(
      backgroundColor: ZenithColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            if (showProgress)
              OnboardingProgressBar(
                currentStep: _currentPage,
                totalSteps: _totalScreens,
              ),

            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (i) => setState(() => _currentPage = i),
                children: [
                  // 0: Welcome
                  WelcomeScreen(onNext: _nextPage),

                  // 1: Name entry
                  _NamePage(
                    name: _data.name,
                    onChanged: (v) => setState(() => _data.name = v),
                    onNext: _nextPage,
                  ),

                  // 2: Goals (multi-select)
                  GoalScreen(
                    selectedGoals: _data.selectedGoals,
                    onToggle: _toggleGoal,
                    onNext: _nextPage,
                  ),

                  // 3: Pain points
                  PainPointsScreen(
                    selectedPainPoints: _data.selectedPainPoints,
                    onToggle: _togglePainPoint,
                    onNext: _nextPage,
                  ),

                  // 4: Tinder cards
                  TinderCardsScreen(onComplete: _nextPage),

                  // 5: Solution
                  SolutionScreen(onNext: _nextPage),

                  // 6: Preferences
                  PreferencesScreen(
                    selectedPreferences: _data.selectedPreferences,
                    onToggle: _togglePreference,
                    onNext: _nextPage,
                  ),

                  // 7: Mic permission + AI conversation
                  _MicThenConversation(
                    data: _data,
                    onComplete: _generateProgramme,
                  ),

                  // 8: Processing
                  const ProcessingScreen(),

                  // 9: Archetype Reveal
                  Builder(
                    builder: (context) {
                      final app = context.watch<AppProvider>();
                      return ArchetypeRevealScreen(
                        archetype: app.archetype,
                        onDone: _nextPage,
                      );
                    },
                  ),

                  // 10: Value delivery
                  Builder(
                    builder: (context) {
                      final app = context.watch<AppProvider>();
                      return ValueDeliveryScreen(
                        programme: app.programme,
                        habits: app.habits,
                        subSkills: app.subSkills,
                        archetype: app.archetype,
                        onNext: _nextPage,
                      );
                    },
                  ),

                  // 11: Paywall
                  PaywallScreen(
                    onStartTrial: _finishOnboarding,
                    onSkip: _finishOnboarding,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Name Page ──

class _NamePage extends StatelessWidget {
  final String name;
  final ValueChanged<String> onChanged;
  final VoidCallback onNext;

  const _NamePage({
    required this.name,
    required this.onChanged,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 48),
          Text(
            'What should we call you?',
            style: ZenithTheme.cormorant(
              fontSize: 26,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 32),
          TextField(
            onChanged: onChanged,
            style: ZenithTheme.dmSans(fontSize: 18),
            decoration: const InputDecoration(hintText: 'Your name'),
            textCapitalization: TextCapitalization.words,
            onSubmitted: (_) {
              if (name.trim().isNotEmpty) onNext();
            },
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: name.trim().isNotEmpty ? onNext : null,
              child: const Text('Continue'),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

// ── Mic Permission + AI Conversation ──

class _MicThenConversation extends StatefulWidget {
  final OnboardingData data;
  final VoidCallback onComplete;

  const _MicThenConversation({
    required this.data,
    required this.onComplete,
  });

  @override
  State<_MicThenConversation> createState() => _MicThenConversationState();
}

class _MicThenConversationState extends State<_MicThenConversation> {
  bool _micHandled = false;

  void _onMicDone() {
    setState(() => _micHandled = true);
  }

  @override
  Widget build(BuildContext context) {
    if (!_micHandled) {
      return MicPermissionScreen(
        onGranted: _onMicDone,
        onSkip: _onMicDone,
      );
    }

    return AIConversationScreen(
      data: widget.data,
      onComplete: widget.onComplete,
    );
  }
}
