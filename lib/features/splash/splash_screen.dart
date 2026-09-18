import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/navigation/main_shell.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/user_repository.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../auth/login_screen.dart';
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

  /// Supabase redirects back here with `?error=...` query params (instead
  /// of a working session) when an email link -- password reset, signup
  /// confirmation, etc. -- is expired or was already used. Turns that
  /// into copy a user can actually act on.
  String? _authErrorFromUrl() {
    final params = Uri.base.queryParameters;
    final errorCode = params['error_code'];
    if (errorCode == null) return null;
    if (errorCode == 'otp_expired') {
      return 'That link has expired or was already used. Please request a new one.';
    }
    return params['error_description']?.replaceAll('+', ' ') ?? 'That link is no longer valid.';
  }

  Future<void> _bootstrap() async {
    final urlError = _authErrorFromUrl();
    final minSplashTime = Future<void>.delayed(const Duration(milliseconds: 1800));

    // Watch every auth event for the whole splash duration, not just the
    // first one: when arriving from a password-recovery email link,
    // Supabase's web SDK typically fires a generic session event first
    // and only then a distinct passwordRecovery event once it finishes
    // parsing the recovery token from the URL. Stopping at the first
    // event missed this.
    var sawPasswordRecovery = false;
    final subscription = AuthService.instance.authStateEvents.listen((state) {
      if (state.event == AuthChangeEvent.passwordRecovery) {
        sawPasswordRecovery = true;
      }
    });

    // Still guarded with a timeout so a browser context that never
    // settles (e.g. storage-restricted private browsing) can't strand
    // the user on this screen forever.
    final authReady = AuthService.instance.currentUser != null
        ? Future<void>.value()
        : AuthService.instance.authStateChanges.first.timeout(
            const Duration(seconds: 6),
            onTimeout: () => null,
          );

    await Future.wait([minSplashTime, authReady]);
    await subscription.cancel();

    if (!mounted) return;

    if (urlError != null) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => LoginScreen(initialErrorMessage: urlError)),
      );
      return;
    }

    // A "forgot password" email link signs the user in (it proves email
    // ownership) but they still don't know a working password -- show the
    // set-new-password screen instead of just letting them into the app.
    if (sawPasswordRecovery) {
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
