import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/theme/app_colors.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/app_theme_controller.dart';
import 'features/splash/splash_screen.dart';
import 'supabase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: SupabaseOptions.url,
    publishableKey: SupabaseOptions.publishableKey,
  );
  runApp(const MuscleFactoryApp());
}

class MuscleFactoryApp extends StatefulWidget {
  const MuscleFactoryApp({super.key});

  @override
  State<MuscleFactoryApp> createState() => _MuscleFactoryAppState();
}

class _MuscleFactoryAppState extends State<MuscleFactoryApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    AppThemeController.instance.addListener(_onThemeChanged);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    AppThemeController.instance.removeListener(_onThemeChanged);
    super.dispose();
  }

  void _onThemeChanged() => setState(() {});

  @override
  void didChangePlatformBrightness() {
    if (AppThemeController.instance.mode == ThemeMode.system) setState(() {});
  }

  Brightness get _brightness {
    switch (AppThemeController.instance.mode) {
      case ThemeMode.light:
        return Brightness.light;
      case ThemeMode.dark:
        return Brightness.dark;
      case ThemeMode.system:
        return WidgetsBinding.instance.platformDispatcher.platformBrightness;
    }
  }

  @override
  Widget build(BuildContext context) {
    final brightness = _brightness;
    // Sets the AppColors.* static values every existing screen reads
    // directly -- must happen before MaterialApp (and everything under it)
    // builds, since Flutter builds top-down.
    AppColors.apply(brightness);

    return MaterialApp(
      title: 'Muscle Factory',
      debugShowCheckedModeBanner: false,
      theme: brightness == Brightness.dark ? AppTheme.darkTheme : AppTheme.lightTheme,
      home: const SplashScreen(),
    );
  }
}
