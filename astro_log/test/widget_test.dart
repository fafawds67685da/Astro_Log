// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:astro_log/main.dart';

void main() {
  testWidgets('AstroLog app smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const AstroLogApp());

    // Verify that the app starts with Home screen.
    expect(find.text('Home'), findsWidgets);
    expect(find.text('Welcome to AstroLog'), findsOneWidget);

    // Verify bottom navigation items are present.
    expect(find.text('Explore'), findsOneWidget);
    expect(find.text('Track'), findsOneWidget);
    expect(find.text('Events'), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);
  });
}
