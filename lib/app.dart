import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'views/splash/splash_screen.dart';

class SoundSphereApp extends StatelessWidget {
  const SoundSphereApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SoundSphere',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const SplashScreen(),
    );
  }
}
