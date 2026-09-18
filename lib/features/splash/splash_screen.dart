import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/navigation/main_shell.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/user_repository.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../auth/reset_password_screen.dart';
import '../onboarding/onboarding_screen.dart';
import '../survey/survey_screen.dart';

/// App boot screen: brand mark, tagline, then routes based on auth state.
///
/// Waits for Supabase's first auth-state event before trusting
/// [AuthService.currentUser] -- this covers both a user returning from a
/// Google sign-in redirect and a returning user whose session was simply
/// restored from local persistence (auto login).
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

    // Guarded with a timeout: some browser contexts (private/incognito
    // browsing with storage restrictions) can leave auth initialization
    // hanging indefinitely. Better to fall through to the logged-out flow
    // than get the user stuck on this screen forever.
    AuthChangeEvent? lastEvent;
    final authReady = AuthService.instance.authStateEvents.first.then((state) {
      lastEvent = state.event;
    }).timeout(const Duration(seconds: 6), onTimeout: () {});

    await Future.wait([minSplashTime, authReady]);

    if (!mounted) return;

    // A "forgot password" email link signs the user in (it proves email
    // ownership) but they still don't know a working password -- show the
    // set-new-password screen instead of just letting them into the app.
    if (lastEvent == AuthChangeEvent.passwordRecovery) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const ResetPasswordScreen()),
      );
      return;
    }

    final user = AuthService.instance.currentUser;
    if (user == null) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const OnboardingScreen()),
      );
      return;
    }

    final surveyDone = await UserRepository.instance.ensureProfile(user.id);
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
