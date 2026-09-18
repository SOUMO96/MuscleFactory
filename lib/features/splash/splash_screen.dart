import 'package:flutter/material.dart';

import '../../core/navigation/main_shell.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/user_repository.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../onboarding/onboarding_screen.dart';
import '../survey/survey_screen.dart';

/// App boot screen: brand mark, tagline, then routes based on auth state.
///
/// First resolves any pending signInWithRedirect result (Google sign-in
/// uses a full-page redirect rather than a popup, since popups get
/// blocked inside embedded browser panels/webviews) before trusting
/// [AuthService.currentUser] — the redirect reloads the whole page, and
/// Firebase needs a moment after boot to finish processing the returning
/// auth result.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final minSplashTime = Future<void>.delayed(const Duration(milliseconds: 1800));

    // Resolve any pending OAuth redirect first, then wait for Firebase's
    // first auth-state event. This covers both cases: a user returning
    // from Google sign-in, and a returning user whose previous session
    // was simply restored from local persistence (auto login).
    final authReady = () async {
      await AuthService.instance.resolvePendingRedirect();
      await AuthService.instance.authStateChanges.first;
    }();

    await Future.wait([minSplashTime, authReady]);

    if (!mounted) return;
    final user = AuthService.instance.currentUser;
    if (user == null) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const OnboardingScreen()),
      );
      return;
    }

    final surveyDone = await UserRepository.instance.ensureProfile(user);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => surveyDone ? const MainShell() : const SurveyScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: AppColors.heroGradient,
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: AppColors.primaryGradient),
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(color: AppColors.primary.withValues(alpha: 0.4), blurRadius: 30, offset: const Offset(0, 12)),
                ],
              ),
              child: const Icon(Icons.bolt_rounded, color: AppColors.background, size: 52),
            ),
            const SizedBox(height: 24),
            Text('MUSCLE FACTORY', style: AppTextStyles.display.copyWith(letterSpacing: 2, fontSize: 28)),
            const SizedBox(height: 8),
            Text(
              'TRAIN. TRACK. TRANSFORM.',
              style: AppTextStyles.bodySmall.copyWith(letterSpacing: 3, color: AppColors.textMuted),
            ),
            const SizedBox(height: 56),
            const SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation(AppColors.primary),
                backgroundColor: AppColors.divider,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
