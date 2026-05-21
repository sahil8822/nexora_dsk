import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:nexora_sdk/nexora_sdk.dart';
import 'mock_channel_setup.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  
  // Set up the mock native backend for the integration tests.
  // This allows tests to run consistently in CI without needing real hardware
  // to return camera textures, geofence callbacks, etc.
  setUpAll(() {
    setupMockMethodChannel();
  });

  group('Nexora v3.0 Intelligence Integration Tests', () {
    final sdk = NexoraSdk.instance;

    testWidgets('Platform version check (Mocked)', (WidgetTester tester) async {
      final String? version = await sdk.getPlatformVersion();
      expect(version, 'Mock Native Version');
    });

    testWidgets('Ultra-Performance Camera (Texture) test', (
      WidgetTester tester,
    ) async {
      // Mock returns 42 as the texture ID
      final textureId = await sdk.camera.start();
      expect(textureId, 42);
      await sdk.camera.stop();
    });

    testWidgets('AI Vision Mode configuration test', (
      WidgetTester tester,
    ) async {
      final success = await sdk.setVisionMode(face: true, barcode: true);
      expect(success, true);
    });

    testWidgets('Native FFT Audio initialization test', (
      WidgetTester tester,
    ) async {
      final success = await sdk.startAudioWithAnalysis();
      expect(success, true);
      await sdk.audio.stop();
    });

    testWidgets('Background Hardware Logging test', (
      WidgetTester tester,
    ) async {
      final success = await sdk.startLogging(
        LogConfig(fileName: "test_log.csv"),
      );
      expect(success, true);
      await sdk.stopLogging();
    });

    testWidgets('Geofence Registration test', (WidgetTester tester) async {
      await sdk.location.setBackgroundEnabled(true);
      final success = await sdk.addGeofence(
        "test_zone",
        37.422,
        -122.084,
        100.0,
      );
      expect(success, true);
    });

    testWidgets('Deep Model Verification - Battery Info', (WidgetTester tester) async {
      final battery = await sdk.health.getBatteryInfo();
      expect(battery, isNotNull);
      expect(battery?.level, 0.85);
      expect(battery?.status, 'charging');
      expect(battery?.temperature, 35.5);
    });

    testWidgets('Deep Model Verification - WiFi Info', (WidgetTester tester) async {
      final wifi = await sdk.health.getWifiInfo();
      expect(wifi, isNotNull);
      expect(wifi?.ssid, 'MockWiFi');
      expect(wifi?.signalStrength, -50);
    });

    testWidgets('Deep Model Verification - Storage Info', (WidgetTester tester) async {
      final storage = await sdk.storage.getStorageInfo();
      expect(storage, isNotNull);
      expect(storage?.appDataSize, 1024 * 1024 * 50);
      expect(storage?.appCacheSize, 1024 * 1024 * 10);
    });
  });
}
