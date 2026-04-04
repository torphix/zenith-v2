import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../models/assessment.dart';
import '../../providers/app_provider.dart';
import '../../theme.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/selectable_chip_grid.dart';
import '../../widgets/typewriter_text.dart';
import '../main_shell.dart';

class OnboardingFlow extends StatefulWidget {
  const OnboardingFlow({super.key});

  @override
  State<OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends State<OnboardingFlow> {
  final _pageController = PageController();
  int _currentPage = 0;

  // Collected data
  String _name = '';
  final Map<String, int> _assessmentScores = {
    for (final p in Assessment.pillars) p: 5,
  };
  final Set<String> _problems = {};
  final Set<String> _goals = {};
  String _northStar = '';
  String _commitmentLevel = '30';
  String _energyPreference = 'balanced';

  bool _isGenerating = false;

  void _nextPage() {
    if (_currentPage < 8) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _finishOnboarding() async {
    setState(() => _isGenerating = true);
    _nextPage(); // Go to generating screen

    final app = context.read<AppProvider>();
    await app.saveOnboardingProfile(
      name: _name.trim().isEmpty ? 'Seeker' : _name.trim(),
      problems: _problems.toList(),
      goals: _goals.toList(),
      commitmentLevel: _commitmentLevel,
      energyPreference: _energyPreference,
      northStarVision: _northStar.isEmpty ? null : _northStar,
      assessmentScores: _assessmentScores,
    );

    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const MainShell()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ZenithColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            // Progress bar
            if (_currentPage < 8)
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                child: Row(
                  children: List.generate(8, (i) {
                    return Expanded(
                      child: Container(
                        height: 3,
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        decoration: BoxDecoration(
                          color: i <= _currentPage
                              ? ZenithColors.primary
                              : ZenithColors.primaryPale.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    );
                  }),
                ),
              ),

            // Pages
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (i) => setState(() => _currentPage = i),
                children: [
                  _WelcomePage(onNext: _nextPage),
                  _NamePage(
                    name: _name,
                    onChanged: (v) => setState(() => _name = v),
                    onNext: _nextPage,
                  ),
                  _AssessmentPage(
                    scores: _assessmentScores,
                    onChanged: (k, v) =>
                        setState(() => _assessmentScores[k] = v),
                    onNext: _nextPage,
                  ),
                  _ProblemsPage(
                    selected: _problems,
                    onToggle: (v) => setState(() {
                      _problems.contains(v)
                          ? _problems.remove(v)
                          : _problems.add(v);
                    }),
                    onNext: _nextPage,
                  ),
                  _GoalsPage(
                    selected: _goals,
                    onToggle: (v) => setState(() {
                      _goals.contains(v)
                          ? _goals.remove(v)
                          : _goals.add(v);
                    }),
                    onNext: _nextPage,
                  ),
                  _NorthStarPage(
                    value: _northStar,
                    onChanged: (v) => setState(() => _northStar = v),
                    onNext: _nextPage,
                  ),
                  _CommitmentPage(
                    value: _commitmentLevel,
                    onChanged: (v) =>
                        setState(() => _commitmentLevel = v),
                    onNext: _nextPage,
                  ),
                  _EnergyPage(
                    value: _energyPreference,
                    onChanged: (v) =>
                        setState(() => _energyPreference = v),
                    onNext: _finishOnboarding,
                  ),
                  _GeneratingPage(isGenerating: _isGenerating),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Page 1: Welcome ──

class _WelcomePage extends StatelessWidget {
  final VoidCallback onNext;
  const _WelcomePage({required this.onNext});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'ZENITH',
            style: ZenithTheme.cormorant(
              fontSize: 56,
              fontWeight: FontWeight.w300,
              letterSpacing: 16,
              color: ZenithColors.primary,
            ),
          )
              .animate()
              .fadeIn(duration: 800.ms)
              .slideY(begin: -0.2, end: 0),
          const SizedBox(height: 16),
          Text(
            'Your journey to the peak begins here.',
            textAlign: TextAlign.center,
            style: ZenithTheme.dmSans(
              fontSize: 16,
              color: ZenithColors.textLight,
              height: 1.5,
            ),
          ).animate().fadeIn(delay: 400.ms, duration: 600.ms),
          const SizedBox(height: 8),
          Text(
            '30 days. Real change. No shortcuts.',
            textAlign: TextAlign.center,
            style: ZenithTheme.dmSans(
              fontSize: 14,
              color: ZenithColors.textMuted,
            ),
          ).animate().fadeIn(delay: 600.ms, duration: 600.ms),
          const SizedBox(height: 48),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onNext,
              child: const Text('Begin'),
            ),
          ).animate().fadeIn(delay: 800.ms, duration: 400.ms),
        ],
      ),
    );
  }
}

// ── Page 2: Name ──

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
          TypewriterText(
            text: 'What should we call you?',
          ),
          const SizedBox(height: 32),
          TextField(
            onChanged: onChanged,
            style: ZenithTheme.dmSans(fontSize: 18),
            decoration: const InputDecoration(
              hintText: 'Your name',
            ),
            textCapitalization: TextCapitalization.words,
          ).animate().fadeIn(delay: 800.ms),
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

// ── Page 3: Life Assessment ──

class _AssessmentPage extends StatelessWidget {
  final Map<String, int> scores;
  final void Function(String, int) onChanged;
  final VoidCallback onNext;

  const _AssessmentPage({
    required this.scores,
    required this.onChanged,
    required this.onNext,
  });

  static const _pillarLabels = {
    'body': 'Body & Health',
    'mind': 'Mental Wellbeing',
    'relationships': 'Relationships',
    'career': 'Career & Purpose',
    'finances': 'Finances',
    'growth': 'Personal Growth',
  };

  static const _pillarIcons = {
    'body': Icons.fitness_center_rounded,
    'mind': Icons.psychology_rounded,
    'relationships': Icons.favorite_rounded,
    'career': Icons.work_rounded,
    'finances': Icons.savings_rounded,
    'growth': Icons.trending_up_rounded,
  };

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 32),
          TypewriterText(
            text: 'Rate your life right now.',
          ),
          const SizedBox(height: 8),
          Text(
            'Be honest. This is where growth begins.',
            style: ZenithTheme.dmSans(
              fontSize: 14,
              color: ZenithColors.textLight,
            ),
          ),
          const SizedBox(height: 32),
          ...Assessment.pillars.map((pillar) {
            final score = scores[pillar] ?? 5;
            return Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: GlassCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _pillarIcons[pillar],
                          size: 20,
                          color: ZenithColors.primary,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          _pillarLabels[pillar] ?? pillar,
                          style: ZenithTheme.dmSans(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '$score',
                          style: ZenithTheme.mono(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: ZenithColors.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SliderTheme(
                      data: SliderThemeData(
                        activeTrackColor: ZenithColors.primary,
                        inactiveTrackColor:
                            ZenithColors.primaryPale.withValues(alpha: 0.3),
                        thumbColor: ZenithColors.primary,
                        overlayColor:
                            ZenithColors.primary.withValues(alpha: 0.1),
                        trackHeight: 4,
                        thumbShape: const RoundSliderThumbShape(
                          enabledThumbRadius: 8,
                        ),
                      ),
                      child: Slider(
                        value: score.toDouble(),
                        min: 1,
                        max: 10,
                        divisions: 9,
                        onChanged: (v) => onChanged(pillar, v.round()),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Struggling',
                          style: ZenithTheme.dmSans(
                            fontSize: 11,
                            color: ZenithColors.textMuted,
                          ),
                        ),
                        Text(
                          'Thriving',
                          style: ZenithTheme.dmSans(
                            fontSize: 11,
                            color: ZenithColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onNext,
              child: const Text('Continue'),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

// ── Page 4: Problems ──

class _ProblemsPage extends StatelessWidget {
  final Set<String> selected;
  final ValueChanged<String> onToggle;
  final VoidCallback onNext;

  const _ProblemsPage({
    required this.selected,
    required this.onToggle,
    required this.onNext,
  });

  static const _options = [
    'Procrastination',
    'Lack of discipline',
    'Poor fitness',
    'Bad diet',
    'Porn addiction',
    'Social media addiction',
    'Phone addiction',
    'Low confidence',
    'Poor sleep',
    'Anxiety',
    'Loneliness',
    'Lack of focus',
    'No routine',
    'Financial stress',
    'Career stagnation',
    'Relationship issues',
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 32),
          TypewriterText(
            text: 'What are you struggling with?',
          ),
          const SizedBox(height: 8),
          Text(
            'Select all that apply. No judgement.',
            style: ZenithTheme.dmSans(
              fontSize: 14,
              color: ZenithColors.textLight,
            ),
          ),
          const SizedBox(height: 28),
          SelectableChipGrid(
            options: _options,
            selected: selected,
            onToggle: onToggle,
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: selected.isNotEmpty ? onNext : null,
              child: const Text('Continue'),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

// ── Page 5: Goals ──

class _GoalsPage extends StatelessWidget {
  final Set<String> selected;
  final ValueChanged<String> onToggle;
  final VoidCallback onNext;

  const _GoalsPage({
    required this.selected,
    required this.onToggle,
    required this.onNext,
  });

  static const _options = [
    'Build muscle',
    'Lose weight',
    'Read more',
    'Meditate daily',
    'Wake up early',
    'Quit porn',
    'Cold showers',
    'Journal daily',
    'Learn a skill',
    'Build a business',
    'Improve finances',
    'Better relationships',
    'Master discipline',
    'Improve confidence',
    'Code every day',
    'Run a marathon',
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 32),
          TypewriterText(
            text: 'What do you want to achieve?',
          ),
          const SizedBox(height: 8),
          Text(
            'Pick the goals that fire you up.',
            style: ZenithTheme.dmSans(
              fontSize: 14,
              color: ZenithColors.textLight,
            ),
          ),
          const SizedBox(height: 28),
          SelectableChipGrid(
            options: _options,
            selected: selected,
            onToggle: onToggle,
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: selected.isNotEmpty ? onNext : null,
              child: const Text('Continue'),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

// ── Page 6: North Star Vision ──

class _NorthStarPage extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;
  final VoidCallback onNext;

  const _NorthStarPage({
    required this.value,
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
          TypewriterText(
            text: 'Describe your ideal self in one year.',
          ),
          const SizedBox(height: 8),
          Text(
            'Close your eyes. Who do you see?',
            style: ZenithTheme.dmSans(
              fontSize: 14,
              color: ZenithColors.textLight,
            ),
          ),
          const SizedBox(height: 32),
          TextField(
            onChanged: onChanged,
            maxLines: 5,
            style: ZenithTheme.dmSans(fontSize: 15, height: 1.6),
            decoration: const InputDecoration(
              hintText:
                  'I am disciplined, strong, and calm. I wake at 5am, train hard, and build things that matter...',
              alignLabelWithHint: true,
            ),
          ).animate().fadeIn(delay: 800.ms),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onNext,
              child: Text(value.isEmpty ? 'Skip' : 'Continue'),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

// ── Page 7: Commitment Level ──

class _CommitmentPage extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;
  final VoidCallback onNext;

  const _CommitmentPage({
    required this.value,
    required this.onChanged,
    required this.onNext,
  });

  static const _options = [
    {'value': '15', 'label': '15 min', 'sub': 'Light touch'},
    {'value': '30', 'label': '30 min', 'sub': 'Solid foundation'},
    {'value': '45', 'label': '45 min', 'sub': 'Committed'},
    {'value': '60', 'label': '60 min', 'sub': 'All in'},
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 48),
          TypewriterText(
            text: 'How much time can you commit daily?',
          ),
          const SizedBox(height: 32),
          ..._options.map((opt) {
            final isSelected = value == opt['value'];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: GlassCard(
                onTap: () => onChanged(opt['value']!),
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                color: isSelected
                    ? ZenithColors.primary.withValues(alpha: 0.12)
                    : null,
                child: Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected
                              ? ZenithColors.primary
                              : ZenithColors.textMuted,
                          width: isSelected ? 7 : 2,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          opt['label']!,
                          style: ZenithTheme.dmSans(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          opt['sub']!,
                          style: ZenithTheme.dmSans(
                            fontSize: 13,
                            color: ZenithColors.textLight,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onNext,
              child: const Text('Continue'),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

// ── Page 8: Energy Preference ──

class _EnergyPage extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;
  final VoidCallback onNext;

  const _EnergyPage({
    required this.value,
    required this.onChanged,
    required this.onNext,
  });

  static const _options = [
    {
      'value': 'gentle',
      'label': 'Gentle Guide',
      'sub': 'Encouraging, warm, supportive'
    },
    {
      'value': 'balanced',
      'label': 'Balanced Coach',
      'sub': 'Honest but kind'
    },
    {
      'value': 'intense',
      'label': 'Drill Sergeant',
      'sub': 'No excuses, hard truth'
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 48),
          TypewriterText(
            text: 'What coaching style suits you?',
          ),
          const SizedBox(height: 32),
          ..._options.map((opt) {
            final isSelected = value == opt['value'];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: GlassCard(
                onTap: () => onChanged(opt['value']!),
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                color: isSelected
                    ? ZenithColors.primary.withValues(alpha: 0.12)
                    : null,
                child: Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected
                              ? ZenithColors.primary
                              : ZenithColors.textMuted,
                          width: isSelected ? 7 : 2,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          opt['label']!,
                          style: ZenithTheme.dmSans(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          opt['sub']!,
                          style: ZenithTheme.dmSans(
                            fontSize: 13,
                            color: ZenithColors.textLight,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onNext,
              child: const Text('Generate My Programme'),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

// ── Page 9: Generating ──

class _GeneratingPage extends StatelessWidget {
  final bool isGenerating;
  const _GeneratingPage({required this.isGenerating});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 64,
              height: 64,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: ZenithColors.primary.withValues(alpha: 0.6),
              ),
            )
                .animate(onPlay: (c) => c.repeat())
                .shimmer(duration: 2000.ms, color: ZenithColors.primaryLight),
            const SizedBox(height: 32),
            Text(
              'Crafting your programme',
              style: ZenithTheme.cormorant(
                fontSize: 24,
                fontWeight: FontWeight.w500,
              ),
            ).animate().fadeIn(duration: 600.ms),
            const SizedBox(height: 12),
            Text(
              'Our AI is analyzing your goals and building a personalized 30-day transformation plan.',
              textAlign: TextAlign.center,
              style: ZenithTheme.dmSans(
                fontSize: 14,
                color: ZenithColors.textLight,
                height: 1.6,
              ),
            ).animate().fadeIn(delay: 300.ms, duration: 600.ms),
          ],
        ),
      ),
    );
  }
}
