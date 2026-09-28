import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../survey/survey_screen.dart';

/// Direct copy of the design handoff's "Auth Verified" screen
/// (MF Auth.dc.html) -- the moment between a successful signup
/// verification and starting the onboarding survey.
class VerifiedScreen extends StatelessWidget {
  const VerifiedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 40, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 64,
                height: 64,
                alignment: Alignment.center,
                color: AppColors.background,
                child: Icon(Icons.check_rounded, color: AppColors.primary, size: 32),
              ),
              const Spacer(),
              Text(
                "You're\nin.",
                style: AppTextStyles.h1.copyWith(color: AppColors.background, fontSize: 56, height: 0.88, letterSpacing: -2),
              ),
              const SizedBox(height: 18),
              Text(
                "Email verified. Now a few quick questions so we can build your first plan — about a minute.",
                style: AppTextStyles.bodyLarge.copyWith(color: AppColors.background, fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              Material(
                color: AppColors.background,
                child: InkWell(
                  onTap: () => Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const SurveyScreen()),
                    (route) => false,
                  ),
                  child: Container(
                    height: 56,
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    alignment: Alignment.center,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("Let's go", style: AppTextStyles.button.copyWith(color: AppColors.primary)),
                        Icon(Icons.arrow_forward_rounded, color: AppColors.primary, size: 20),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
