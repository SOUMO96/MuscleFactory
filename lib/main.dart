import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'features/splash/splash_screen.dart';

void main() {
  runApp(const IronPulseApp());
}

class IronPulseApp extends StatelessWidget {
  const IronPulseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'IronPulse',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark,
      home: const SplashScreen(),
    );
  }
}
