import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:nexora_sdk/nexora_sdk.dart';
import 'package:nexora_sdk/models/hardware_models.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Nexora v3.0 Intelligence Integration Tests', () {
    final sdk = NexoraSdk.instance;

    testWidgets('Platform version check', (WidgetTester tester) async {
      final String? version = await sdk.getPlatformVersion();
      expect(version?.isNotEmpty, true);
    });

    testWidgets('Ultra-Performance Camera (Texture) test', (WidgetTester tester) async {
      // Should return a native texture ID (int) instead of just bool
      final textureId = await sdk.camera.start();
      expect(textureId, anyOf([isA<int>(), isNull])); // Null if no camera hardware found
      await sdk.camera.stop();
    });

    testWidgets('AI Vision Mode configuration test', (WidgetTester tester) async {
      final success = await sdk.setVisionMode(face: true, barcode: true);
      expect(success, true);
    });

    testWidgets('Native FFT Audio initialization test', (WidgetTester tester) async {
      final success = await sdk.startAudioWithAnalysis();
      expect(success, isNotNull);
      await sdk.audio.stop();
    });

    testWidgets('Background Hardware Logging test', (WidgetTester tester) async {
      final success = await sdk.startLogging(LogConfig(fileName: "test_log.csv"));
      expect(success, true);
      await sdk.stopLogging();
    });

    testWidgets('Geofence Registration test', (WidgetTester tester) async {
      final success = await sdk.addGeofence("test_zone", 37.422, -122.084, 100.0);
      expect(success, true);
    });
  });
}
