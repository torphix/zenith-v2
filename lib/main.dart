import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'firebase_options.dart';
import 'providers/app_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  if (FirebaseAuth.instance.currentUser == null) {
    try {
      await FirebaseAuth.instance.signInAnonymously();
    } catch (e, st) {
      debugPrint('Anonymous sign-in failed: $e');
      debugPrint('$st');
    }
  }

  runApp(
    ChangeNotifierProvider(
      create: (_) => AppProvider()..init(),
      child: const ZenithApp(),
    ),
  );
}
