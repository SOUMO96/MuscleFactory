import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:muscle_factory/core/theme/app_theme.dart';
import 'package:muscle_factory/features/onboarding/onboarding_screen.dart';

void main() {
  testWidgets('Onboarding screen renders the welcome poster', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: const OnboardingScreen(),
      ),
    );

    expect(find.text('MUSCLE\nFACTORY'), findsOneWidget);
    expect(find.text('Continue with Google'), findsOneWidget);
    expect(find.text('Sign up with email'), findsOneWidget);
  });
}
