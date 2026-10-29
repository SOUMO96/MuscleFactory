import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/navigation/main_shell.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/user_repository.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_theme_controller.dart';
import '../../shared/models/app_user.dart';
import '../auth/login_screen.dart';
import '../auth/reset_password_screen.dart';
import '../onboarding/onboarding_screen.dart';
import '../survey/survey_screen.dart';

/// Boot screen: brand mark, tagline, then routes by auth state. Waits for
/// Supabase's first auth event before trusting [AuthService.currentUser], which
/// covers both a Google sign-in redirect and a restored session.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _connectionFailed = false;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  /// Supabase redirects here with `?error=...` when an email link is expired or
  /// already used. This turns that into a message the user can act on.
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
    // Wrapped in try/catch with a guaranteed fallback navigation so the user is
    // never stuck on this screen.
    try {
      final urlError = _authErrorFromUrl();
      final minSplashTime = Future<void>.delayed(const Duration(milliseconds: 1800));

      // Listen to every auth event, not just the first: a password-recovery link
      // usually fires a generic session event first and the passwordRecovery event
      // after the token has been parsed.
      var sawPasswordRecovery = false;
      final subscription = AuthService.instance.authStateEvents.listen(
        (state) {
          if (state.event == AuthChangeEvent.passwordRecovery) {
            sawPasswordRecovery = true;
          }
        },
        onError: (_) {},
      );

      final authReady = AuthService.instance.currentUser != null
          ? Future<void>.value()
          : AuthService.instance.authStateChanges.first
              .then((_) {})
              .timeout(const Duration(seconds: 6), onTimeout: () {})
              .catchError((_) {});

      await Future.wait([minSplashTime, authReady]);
      await subscription.cancel();

      if (!mounted) return;

      if (urlError != null) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => LoginScreen(initialErrorMessage: urlError)),
        );
        return;
      }

      // A reset link signs the user in, but they still need a working password,
      // so show the new-password screen instead of the app.
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

      // A failed profile fetch must not be read as "survey not done": it's
      // indistinguishable from the backend being briefly unreachable (e.g. a paused
      // free-tier project waking up). Retry a few times, then let the user retry
      // rather than guess.
      AppUser? profile;
      Object? lastError;
      for (var attempt = 0; attempt < 4; attempt++) {
        if (attempt > 0) await Future.delayed(const Duration(milliseconds: 700));
        try {
          profile = await UserRepository.instance.getUserProfile(user.id);
          lastError = null;
          break;
        } catch (e) {
          lastError = e;
        }
      }

      if (lastError != null) {
        debugPrint('SplashScreen: profile fetch failed after retries: $lastError');
        if (!mounted) return;
        setState(() => _connectionFailed = true);
        return;
      }

      if (profile != null) {
        AppThemeController.instance.setMode(switch (profile.themePreference) {
          ThemePreference.light => ThemeMode.light,
          ThemePreference.dark => ThemeMode.dark,
          ThemePreference.system => ThemeMode.system,
        });
      }
      final surveyDone = profile?.surveyCompleted ?? false;
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => surveyDone ? const MainShell() : const SurveyScreen(),
        ),
      );
    } catch (e, st) {
      debugPrint('SplashScreen bootstrap failed: $e\n$st');
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const OnboardingScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
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
                gradient: LinearGradient(colors: AppColors.primaryGradient),
                boxShadow: [
                  BoxShadow(color: AppColors.primary.withValues(alpha: 0.4), blurRadius: 30, offset: const Offset(0, 12)),
                ],
              ),
              child: Icon(Icons.bolt_rounded, color: AppColors.background, size: 52),
            ),
            const SizedBox(height: 24),
            Text('MUSCLE FACTORY', style: AppTextStyles.display.copyWith(letterSpacing: 2, fontSize: 28)),
            const SizedBox(height: 8),
            Text(
              'TRAIN. TRACK. TRANSFORM.',
              style: AppTextStyles.bodySmall.copyWith(letterSpacing: 3, color: AppColors.textMuted),
            ),
            const SizedBox(height: 56),
            if (_connectionFailed) ...[
              Text(
                "Couldn't reach the server. Check your connection.",
                textAlign: TextAlign.center,
                style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted),
              ),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: () {
                  setState(() => _connectionFailed = false);
                  _bootstrap();
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: BorderSide(color: AppColors.primary),
                ),
                child: const Text('Retry'),
              ),
            ] else
              SizedBox(
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
