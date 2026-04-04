import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/app_provider.dart';
import 'screens/main_shell.dart';
import 'screens/onboarding/onboarding_flow.dart';
import 'theme.dart';

class ZenithApp extends StatelessWidget {
  const ZenithApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Zenith',
      debugShowCheckedModeBanner: false,
      theme: ZenithTheme.themeData(),
      home: Consumer<AppProvider>(
        builder: (context, app, _) {
          if (app.isLoading) {
            return const _SplashScreen();
          }
          if (!app.hasCompletedOnboarding) {
            return const OnboardingFlow();
          }
          return const MainShell();
        },
      ),
    );
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ZenithColors.bg,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'ZENITH',
              style: ZenithTheme.cormorant(
                fontSize: 48,
                fontWeight: FontWeight.w300,
                letterSpacing: 12,
                color: ZenithColors.primary,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: ZenithColors.primary.withValues(alpha: 0.4),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
