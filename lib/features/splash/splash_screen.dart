import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../onboarding/onboarding_screen.dart';

/// App boot screen: brand mark, tagline, then auto-advances to onboarding.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Timer(const Duration(milliseconds: 1800), () {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const OnboardingScreen()),
      );
    });
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
            Text('IRONPULSE', style: AppTextStyles.display.copyWith(letterSpacing: 2)),
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
                valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                backgroundColor: AppColors.divider,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
