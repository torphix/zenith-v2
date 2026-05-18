import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/archetype.dart';
import '../../models/sub_skill.dart';
import '../../models/wrap_data.dart';
import 'story_wrap_controller.dart';
import 'widgets/story_progress_bar.dart';
import 'pages/opening_page.dart';
import 'pages/completion_page.dart';
import 'pages/xp_drop_page.dart';
import 'pages/photo_montage_page.dart';
import 'pages/archetype_reveal_page.dart';
import 'pages/skills_leveled_page.dart';
import 'pages/highlights_page.dart';
import 'pages/before_after_page.dart';
import 'pages/close_page.dart';

class EpicWrapScreen extends StatefulWidget {
  final WrapData wrap;
  final List<WrapData> dailyWraps; // for weekly wraps, empty for daily
  final List<SubSkill> subSkills;

  const EpicWrapScreen({
    super.key,
    required this.wrap,
    this.dailyWraps = const [],
    required this.subSkills,
  });

  @override
  State<EpicWrapScreen> createState() => _EpicWrapScreenState();
}

class _EpicWrapScreenState extends State<EpicWrapScreen> {
  late final List<Widget> _pages;
  late final StoryWrapController _controller;

  @override
  void initState() {
    super.initState();
    _pages = _buildPages();
    _controller = StoryWrapController(totalPages: _pages.length);
    _controller.addListener(_onControllerChanged);
  }

  void _onControllerChanged() {
    HapticFeedback.selectionClick();
    setState(() {});
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
    _controller.dispose();
    super.dispose();
  }

  Archetype get _archetype => Archetype.all.firstWhere(
        (a) => a.id == widget.wrap.archetypeId,
        orElse: () => Archetype.all.first,
      );

  List<Widget> _buildPages() {
    final wrap = widget.wrap;
    final archetype = _archetype;
    final pages = <Widget>[];

    // Always: Opening
    pages.add(OpeningPage(
      dayNumber: wrap.dayNumber,
      date: wrap.date,
      onAnimationComplete: () => _controller.startAutoAdvance(),
    ));

    // Always: Completion
    pages.add(CompletionPage(
      completionRate: wrap.completionRate,
      habitsCompleted: wrap.habitsCompleted,
      habitsTotal: wrap.habitsTotal,
      onAnimationComplete: () => _controller.startAutoAdvance(),
    ));

    // Always: XP Drop
    pages.add(XpDropPage(
      totalXP: wrap.totalXP,
      statsGained: wrap.statsGained,
      subSkills: widget.subSkills,
      onAnimationComplete: () => _controller.startAutoAdvance(),
    ));

    // Conditional: Photo Montage
    if (wrap.photoEntries.isNotEmpty) {
      pages.add(PhotoMontagePage(
        photos: wrap.photoEntries,
        onAnimationComplete: () => _controller.startAutoAdvance(),
      ));
    }

    // Always: Archetype Reveal
    pages.add(ArchetypeRevealPage(
      archetype: archetype,
      archetypeShift: wrap.archetypeShift,
      onAnimationComplete: () => _controller.startAutoAdvance(),
    ));

    // Always: Skills Leveled
    pages.add(SkillsLeveledPage(
      statsGained: wrap.statsGained,
      subSkills: widget.subSkills,
      onAnimationComplete: () => _controller.startAutoAdvance(),
    ));

    // Always: Highlights
    pages.add(HighlightsPage(
      highlights: wrap.highlights,
      coachNote: wrap.coachNote,
      onAnimationComplete: () => _controller.startAutoAdvance(),
    ));

    // Conditional: Before & After (weekly wraps with previous stats)
    if (wrap.type == 'weekly' && wrap.previousStats != null) {
      pages.add(BeforeAfterPage(
        previousStats: wrap.previousStats,
        currentStats: wrap.statsGained,
        subSkills: widget.subSkills,
        onAnimationComplete: () => _controller.startAutoAdvance(),
      ));
    }

    // Always: Close
    pages.add(ClosePage(
      dayNumber: wrap.dayNumber,
      completionRate: wrap.completionRate,
      totalXP: wrap.totalXP,
      archetype: archetype,
      onDone: () => Navigator.pop(context),
    ));

    return pages;
  }

  void _handleTap(TapUpDetails details) {
    final screenWidth = MediaQuery.of(context).size.width;
    final tapX = details.globalPosition.dx;

    if (tapX < screenWidth * 0.3) {
      _controller.goBack();
    } else {
      if (_controller.isLastPage) {
        Navigator.pop(context);
      } else {
        _controller.advance();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Current page
          _pages[_controller.currentPage],

          // Touch handling
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTapUp: _handleTap,
              onLongPressStart: (_) => _controller.pause(),
              onLongPressEnd: (_) => _controller.resume(),
            ),
          ),

          // Progress bar
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            child: StoryProgressBar(
              totalPages: _pages.length,
              currentPage: _controller.currentPage,
            ),
          ),

          // Close button
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            right: 16,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
