import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexora_sdk_example/main.dart';

void main() {
  testWidgets('Dashboard basic smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MaterialApp(home: IntelligenceDashboard()));

    // Verify that the dashboard title exists
    expect(find.text('NEXORA INTELLIGENCE'), findsOneWidget);
  });
}
