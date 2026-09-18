import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/theme/app_theme.dart';
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

class MuscleFactoryApp extends StatelessWidget {
  const MuscleFactoryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Muscle Factory',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark,
      home: const SplashScreen(),
    );
  }
}
