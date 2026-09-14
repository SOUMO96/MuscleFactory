import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:muscle_factory/core/theme/app_theme.dart';
import 'package:muscle_factory/features/onboarding/onboarding_screen.dart';

void main() {
  testWidgets('Onboarding screen renders its first slide', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: const OnboardingScreen(),
      ),
    );

    expect(find.text('Personalized\nWorkout Plans'), findsOneWidget);
    expect(find.text('Next'), findsOneWidget);
    expect(find.text('Get Started'), findsNothing);
  });
}
