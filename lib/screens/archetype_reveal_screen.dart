import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../models/archetype.dart';
import '../theme.dart';

/// Full-screen archetype reveal with dramatic animations.
/// Used after onboarding, from profile, and in the wrap flow.
class ArchetypeRevealScreen extends StatefulWidget {
  final Archetype archetype;
  final VoidCallback onDone;

  /// If true, shows a "Continue" button. If false, auto-dismiss after delay.
  final bool showButton;

  const ArchetypeRevealScreen({
    super.key,
    required this.archetype,
    required this.onDone,
    this.showButton = true,
  });

  @override
  State<ArchetypeRevealScreen> createState() => _ArchetypeRevealScreenState();
}

class _ArchetypeRevealScreenState extends State<ArchetypeRevealScreen>
    with TickerProviderStateMixin {
  late final AnimationController _glowController;
  late final AnimationController _pulseController;
  bool _showContent = false;
  bool _showDetails = false;
  bool _showButton = false;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    // Staggered reveal
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() => _showContent = true);
        _glowController.forward();
        HapticFeedback.mediumImpact();
      }
    });
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) setState(() => _showDetails = true);
    });
    Future.delayed(const Duration(milliseconds: 2000), () {
      if (mounted) setState(() => _showButton = true);
    });
  }

  @override
  void dispose() {
    _glowController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final arch = widget.archetype;
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Background gradient
          AnimatedContainer(
            duration: const Duration(milliseconds: 1500),
            curve: Curves.easeOut,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: _showContent
                    ? [
                        Color.lerp(arch.color, Colors.black, 0.8)!,
                        Color.lerp(arch.color, Colors.black, 0.6)!,
                        Colors.black,
                      ]
                    : [Colors.black, Colors.black, Colors.black],
              ),
            ),
          ),

          // Content
          SafeArea(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // "YOUR ARCHETYPE" label
                  if (_showContent)
                    Text(
                      'YOUR ARCHETYPE',
                      style: ZenithTheme.dmSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 6,
                        color: Colors.white.withValues(alpha: 0.5),
                      ),
                    ).animate().fadeIn(duration: 600.ms),

                  const SizedBox(height: 40),

                  // Archetype image with glow
                  if (_showContent)
                    AnimatedBuilder(
                      animation: Listenable.merge(
                          [_glowController, _pulseController]),
                      builder: (context, child) {
                        final glowSize =
                            _glowController.value * 200 + 100;
                        final pulseScale =
                            1.0 + (_pulseController.value * 0.03);
                        return SizedBox(
                          width: 240,
                          height: 240,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // Glow ring
                              Container(
                                width: glowSize,
                                height: glowSize,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: arch.color
                                          .withValues(alpha: 0.3),
                                      blurRadius: 60,
                                      spreadRadius: 20,
                                    ),
                                  ],
                                ),
                              ),
                              // Image
                              Transform.scale(
                                scale: pulseScale,
                                child: ClipRRect(
                                  borderRadius:
                                      BorderRadius.circular(24),
                                  child: Image.asset(
                                    arch.imagePath,
                                    width: 180,
                                    height: 180,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Text(
                                      arch.icon,
                                      style: const TextStyle(
                                          fontSize: 80),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    )
                        .animate()
                        .fadeIn(duration: 800.ms)
                        .scale(
                          begin: const Offset(0.3, 0.3),
                          end: const Offset(1, 1),
                          duration: 800.ms,
                          curve: Curves.elasticOut,
                        ),

                  const SizedBox(height: 32),

                  // Archetype title
                  if (_showDetails)
                    Text(
                      arch.title,
                      style: ZenithTheme.cormorant(
                        fontSize: 40,
                        fontWeight: FontWeight.w600,
                        color: arch.color,
                      ),
                    )
                        .animate()
                        .fadeIn(duration: 600.ms)
                        .slideY(begin: 0.2, end: 0),

                  const SizedBox(height: 16),

                  // Description
                  if (_showDetails)
                    Padding(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 40),
                      child: Text(
                        arch.description,
                        textAlign: TextAlign.center,
                        style: ZenithTheme.dmSans(
                          fontSize: 15,
                          color:
                              Colors.white.withValues(alpha: 0.7),
                          height: 1.6,
                        ),
                      ),
                    )
                        .animate()
                        .fadeIn(
                            delay: 300.ms, duration: 600.ms)
                        .slideY(begin: 0.1, end: 0),

                  const SizedBox(height: 48),

                  // Continue button
                  if (_showButton && widget.showButton)
                    GestureDetector(
                      onTap: widget.onDone,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 40, vertical: 16),
                        decoration: BoxDecoration(
                          color: arch.color.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(
                            color: arch.color.withValues(alpha: 0.4),
                          ),
                        ),
                        child: Text(
                          'Continue',
                          style: ZenithTheme.dmSans(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ).animate().fadeIn(duration: 400.ms),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
