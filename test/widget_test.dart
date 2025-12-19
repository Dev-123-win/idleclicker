// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package.

import 'package:flutter_test/flutter_test.dart';

import 'package:idleminer/main.dart';

void main() {
  testWidgets('App loads correctly', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const TapMineApp());

    // Verify that app starts (splash screen should be shown)
    await tester.pump();

    // Basic smoke test - app should build without errors
    expect(tester.hasRunningAnimations, isTrue);
  });
}
