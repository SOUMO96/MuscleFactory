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
    // Everything in here is wrapped in try/catch with a guaranteed
    // fallback navigation: whatever goes wrong (a stream error, an RLS
    // hiccup on the profile read, anything), the user must never be left
    // stuck on this screen forever with no way forward.
    try {
      final urlError = _authErrorFromUrl();
      final minSplashTime = Future<void>.delayed(const Duration(milliseconds: 1800));

      // Watch every auth event for the whole splash duration, not just
      // the first one: when arriving from a password-recovery email
      // link, Supabase's web SDK typically fires a generic session event
      // first and only then a distinct passwordRecovery event once it
      // finishes parsing the recovery token from the URL.
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

      // A "forgot password" email link signs the user in (it proves
      // email ownership) but they still don't know a working password --
      // show the set-new-password screen instead of just letting them
      // into the app.
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

      var surveyDone = false;
      try {
        final profile = await UserRepository.instance.getUserProfile(user.id);
        surveyDone = profile?.surveyCompleted ?? false;
        if (profile != null) {
          AppThemeController.instance.setMode(switch (profile.themePreference) {
            ThemePreference.light => ThemeMode.light,
            ThemePreference.dark => ThemeMode.dark,
            ThemePreference.system => ThemeMode.system,
          });
        }
      } catch (_) {
        surveyDone = false;
      }
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
                borderRadius: BorderRadius.circular(28),
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
