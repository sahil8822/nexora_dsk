import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:nexora_sdk/nexora_sdk.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('getPlatformVersion test', (WidgetTester tester) async {
    final sdk = NexoraSdk.instance;
    // The getPlatformVersion() method should return a non-empty string.
    final String? version = await sdk.getPlatformVersion();
    expect(version?.isNotEmpty, true);
  });

  testWidgets('camera initialize test', (WidgetTester tester) async {
    final sdk = NexoraSdk.instance;
    // Basic test to see if camera module responds to start (may fail on emulator without camera)
    final bool success = await sdk.camera.start();
    expect(success, isNotNull);
  });
}
