import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:animations/animations.dart';
import 'models/models.dart';
import 'providers/navigation_provider.dart';
import 'providers/onboarding_provider.dart';
import 'providers/user_provider.dart';
import 'screens/coach_screen.dart';
import 'screens/habits_screen.dart';
import 'screens/home_screen.dart';
import 'screens/onboarding/onboarding_flow.dart';
import 'screens/profile_screen.dart';
import 'theme.dart';
import 'widgets/bottom_nav.dart';

class ZenithApp extends StatelessWidget {
  const ZenithApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Zenith',
      debugShowCheckedModeBanner: false,
      theme: ZenithTheme.themeData(),
      home: const _Root(),
    );
  }
}

/// Root widget — decides onboarding vs main app
class _Root extends ConsumerWidget {
  const _Root();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(userProfileProvider);
    final onboardingState = ref.watch(onboardingProvider);

    return profileAsync.when(
      loading: () => Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [ZenithColors.cream, ZenithColors.creamDark],
            ),
          ),
          child: const Center(
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      ),
      error: (_, __) => const OnboardingFlow(),
      data: (profile) {
        // Show onboarding if no profile or onboarding not complete
        if (profile == null || !profile.onboardingComplete) {
          // Also check if user just completed onboarding
          if (onboardingState.step == OnboardingStep.complete) {
            // Refresh profile and show main app
            ref.invalidate(userProfileProvider);
            return const _Shell();
          }
          return const OnboardingFlow();
        }

        return const _Shell();
      },
    );
  }
}

class _Shell extends ConsumerWidget {
  const _Shell();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final screen = ref.watch(screenProvider);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              ZenithColors.cream,
              ZenithColors.creamMid,
              ZenithColors.creamDark,
            ],
            stops: [0, 0.4, 1],
          ),
        ),
        child: Stack(
          children: [
            PageTransitionSwitcher(
              duration: const Duration(milliseconds: 500),
              transitionBuilder: (child, primaryAnimation, secondaryAnimation) {
                return FadeThroughTransition(
                  animation: primaryAnimation,
                  secondaryAnimation: secondaryAnimation,
                  fillColor: Colors.transparent,
                  child: child,
                );
              },
              child: switch (screen) {
                AppScreen.home => const HomeScreen(key: ValueKey('home')),
                AppScreen.habits => const HabitsScreen(key: ValueKey('habits')),
                AppScreen.coach => const CoachScreen(key: ValueKey('coach')),
                AppScreen.profile => const ProfileScreen(key: ValueKey('profile')),
              },
            ),
            const Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: BottomNav(),
            ),
          ],
        ),
      ),
    );
  }
}
