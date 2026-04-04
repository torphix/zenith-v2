import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../models/archetype.dart';
import '../../models/stat_snapshot.dart';
import '../../models/wrap_data.dart';
import '../../theme.dart';


class DailyWrapScreen extends StatefulWidget {
  final WrapData wrap;
  const DailyWrapScreen({super.key, required this.wrap});

  @override
  State<DailyWrapScreen> createState() => _DailyWrapScreenState();
}

class _DailyWrapScreenState extends State<DailyWrapScreen> {
  final _pageController = PageController();
  int _currentPage = 0;

  @override
  Widget build(BuildContext context) {
    final wrap = widget.wrap;
    final archetype =
        Archetype.all.firstWhere((a) => a.id == wrap.archetypeId,
            orElse: () => Archetype.all.first);

    return Scaffold(
      backgroundColor: ZenithColors.text,
      body: Stack(
        children: [
          PageView(
            controller: _pageController,
            onPageChanged: (i) {
              setState(() => _currentPage = i);
              HapticFeedback.selectionClick();
            },
            children: [
              // Page 1: Completion Rate
              _WrapPage(
                gradient: [
                  ZenithColors.primaryDeep,
                  ZenithColors.primary,
                ],
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'YOUR DAY',
                      style: ZenithTheme.dmSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 4,
                        color: Colors.white.withValues(alpha: 0.6),
                      ),
                    ),
                    const SizedBox(height: 32),
                    Text(
                      '${(wrap.completionRate * 100).toInt()}%',
                      style: ZenithTheme.mono(
                        fontSize: 80,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    )
                        .animate()
                        .fadeIn(duration: 600.ms)
                        .scale(
                            begin: const Offset(0.5, 0.5),
                            end: const Offset(1, 1),
                            duration: 600.ms,
                            curve: Curves.easeOut),
                    Text(
                      'completed',
                      style: ZenithTheme.cormorant(
                        fontSize: 24,
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '${wrap.habitsCompleted} of ${wrap.habitsTotal} habits',
                      style: ZenithTheme.dmSans(
                        fontSize: 14,
                        color: Colors.white.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),

              // Page 2: XP Gained
              _WrapPage(
                gradient: [
                  const Color(0xFF2D2B55),
                  const Color(0xFF4B3F72),
                ],
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'XP EARNED',
                      style: ZenithTheme.dmSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 4,
                        color: Colors.white.withValues(alpha: 0.6),
                      ),
                    ),
                    const SizedBox(height: 32),
                    Text(
                      '+${wrap.totalXP}',
                      style: ZenithTheme.mono(
                        fontSize: 64,
                        fontWeight: FontWeight.w700,
                        color: ZenithColors.gold,
                      ),
                    ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.3),
                    const SizedBox(height: 32),
                    ...wrap.statsGained.entries.map((entry) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              StatSnapshot.statIcons[entry.key] ?? '',
                              style: const TextStyle(fontSize: 20),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              StatSnapshot.statLabels[entry.key] ?? entry.key,
                              style: ZenithTheme.dmSans(
                                fontSize: 16,
                                color: Colors.white.withValues(alpha: 0.8),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              '+${entry.value}',
                              style: ZenithTheme.mono(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: ZenithColors.gold,
                              ),
                            ),
                          ],
                        ),
                      )
                          .animate()
                          .fadeIn(
                            delay: (200 +
                                    wrap.statsGained.keys
                                            .toList()
                                            .indexOf(entry.key) *
                                        150)
                                .ms,
                          )
                          .slideX(begin: 0.2, end: 0);
                    }),
                  ],
                ),
              ),

              // Page 3: Archetype
              _WrapPage(
                gradient: [
                  Color.lerp(archetype.color, Colors.black, 0.6)!,
                  archetype.color.withValues(alpha: 0.8),
                ],
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'ARCHETYPE',
                      style: ZenithTheme.dmSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 4,
                        color: Colors.white.withValues(alpha: 0.6),
                      ),
                    ),
                    const SizedBox(height: 32),
                    Text(
                      archetype.icon,
                      style: const TextStyle(fontSize: 64),
                    )
                        .animate()
                        .fadeIn(duration: 400.ms)
                        .scale(
                            begin: const Offset(0.5, 0.5),
                            duration: 500.ms,
                            curve: Curves.easeOut),
                    const SizedBox(height: 16),
                    Text(
                      archetype.title,
                      style: ZenithTheme.cormorant(
                        fontSize: 36,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ).animate().fadeIn(delay: 300.ms, duration: 400.ms),
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 40),
                      child: Text(
                        archetype.description,
                        textAlign: TextAlign.center,
                        style: ZenithTheme.dmSans(
                          fontSize: 14,
                          color: Colors.white.withValues(alpha: 0.7),
                          height: 1.5,
                        ),
                      ),
                    ).animate().fadeIn(delay: 500.ms, duration: 400.ms),
                  ],
                ),
              ),

              // Page 4: Highlights
              _WrapPage(
                gradient: [
                  const Color(0xFF1A1A2E),
                  ZenithColors.primaryDeep,
                ],
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'HIGHLIGHTS',
                      style: ZenithTheme.dmSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 4,
                        color: Colors.white.withValues(alpha: 0.6),
                      ),
                    ),
                    const SizedBox(height: 32),
                    ...wrap.highlights.asMap().entries.map((entry) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: ZenithColors.gold,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              entry.value,
                              style: ZenithTheme.dmSans(
                                fontSize: 16,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      )
                          .animate()
                          .fadeIn(delay: (200 + entry.key * 200).ms)
                          .slideX(begin: 0.15, end: 0);
                    }),
                    const SizedBox(height: 40),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 32, vertical: 14),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Text(
                          'Close',
                          style: ZenithTheme.dmSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ).animate().fadeIn(delay: 800.ms),
                  ],
                ),
              ),
            ],
          ),

          // Page indicators
          Positioned(
            bottom: 60,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(4, (i) {
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _currentPage == i ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _currentPage == i
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              }),
            ),
          ),

          // Close button
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            right: 16,
            child: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.close_rounded, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

class _WrapPage extends StatelessWidget {
  final List<Color> gradient;
  final Widget child;

  const _WrapPage({required this.gradient, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradient,
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: child,
        ),
      ),
    );
  }
}
