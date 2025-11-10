// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:workout_app/main.dart';
import 'package:workout_app/utils/theme_manager.dart';

void main() {
  testWidgets('App loads correctly', (WidgetTester tester) async {
    // Initialize theme manager for testing
    final themeManager = ThemeManager();
    await themeManager.initializeTheme();

    // Build our app and trigger a frame.
    await tester.pumpWidget(WorkoutApp(themeManager: themeManager));

    // Verify that the app loads
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
