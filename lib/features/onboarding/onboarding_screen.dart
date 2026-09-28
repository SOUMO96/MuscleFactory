import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/primary_button.dart';
import '../auth/login_screen.dart';

class _OnboardPage {
  const _OnboardPage({required this.icon, required this.title, required this.subtitle, required this.gradient, required this.iconColor});
  final IconData icon;
  final String title;
  final String subtitle;
  final List<Color> gradient;
  final Color iconColor;
}

// A getter, not a const list: the gradients/colors read the current
// AppColors values, which change at runtime when the theme switches (see
// AppColors.apply).
List<_OnboardPage> get _pages => [
      _OnboardPage(
        icon: Icons.fitness_center_rounded,
        title: 'Personalized\nWorkout Plans',
        subtitle: 'Follow programs tailored to your goals — strength, cardio, or flexibility.',
        gradient: AppColors.primaryGradient,
        iconColor: AppColors.background,
      ),
      _OnboardPage(
        icon: Icons.show_chart_rounded,
        title: 'Track Every\nRep & Result',
        subtitle: 'Log workouts and watch your stats, streaks and PRs climb over time.',
        gradient: AppColors.orangeGradient,
        iconColor: AppColors.background,
      ),
      _OnboardPage(
        icon: Icons.emoji_events_rounded,
        title: 'Stay Motivated,\nHit Your Goals',
        subtitle: 'Earn achievements and build streaks that keep you coming back.',
        gradient: AppColors.heroGradient,
        iconColor: AppColors.primary,
      ),
    ];

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _finish() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLast = _page == _pages.length - 1;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(0, 8, 20, 0),
                child: TextButton(
                  onPressed: _finish,
                  child: Text('Skip', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)),
                ),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _pages.length,
                onPageChanged: (i) => setState(() => _page = i),
                itemBuilder: (context, index) {
                  final page = _pages[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 160,
                          height: 160,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(colors: page.gradient, begin: Alignment.topLeft, end: Alignment.bottomRight),
                            boxShadow: [
                              BoxShadow(color: page.gradient.first.withValues(alpha: 0.35), blurRadius: 36, offset: const Offset(0, 16)),
                            ],
                          ),
                          child: Icon(page.icon, size: 68, color: page.iconColor),
                        ),
                        const SizedBox(height: 48),
                        Text(page.title, textAlign: TextAlign.center, style: AppTextStyles.h1.copyWith(fontSize: 26)),
                        const SizedBox(height: 14),
                        Text(
                          page.subtitle,
                          textAlign: TextAlign.center,
                          style: AppTextStyles.bodyLarge.copyWith(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_pages.length, (i) {
                final active = i == _page;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: active ? 22 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: active ? AppColors.primary : AppColors.divider,
                  ),
                );
              }),
            ),
            const SizedBox(height: 32),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: PrimaryButton(
                label: isLast ? 'Get Started' : 'Next',
                icon: isLast ? Icons.arrow_forward_rounded : null,
                onPressed: () {
                  if (isLast) {
                    _finish();
                  } else {
                    _controller.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
                  }
                },
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
