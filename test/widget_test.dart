import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ironpulse/main.dart';

void main() {
  testWidgets('App launches and shows the splash screen', (WidgetTester tester) async {
    await tester.pumpWidget(const IronPulseApp());

    expect(find.text('IRONPULSE'), findsOneWidget);
    expect(find.byIcon(Icons.bolt_rounded), findsOneWidget);
  });
}
