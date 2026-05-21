import 'package:flutter_test/flutter_test.dart';
import 'package:nexora_sdk/nexora_sdk.dart';
import 'package:nexora_sdk_platform_interface/nexora_sdk_platform_interface.dart';
import '../mocks/mock_platform.dart';

class MockSensorPlatform extends MockNexoraSdkPlatform {
  bool isRunning = false;
  int frequencyHz = 0;

  @override
  Future<bool> startSensor({int frequencyHz = 60}) async {
    isRunning = true;
    this.frequencyHz = frequencyHz;
    return true;
  }

  @override
  Future<bool> startSensorWithOptions(SensorOptions options) async {
    isRunning = true;
    return true;
  }

  @override
  Future<bool> stopSensor() async {
    isRunning = false;
    return true;
  }
}

void main() {
  late MockSensorPlatform mockPlatform;

  setUp(() {
    mockPlatform = MockSensorPlatform();
    NexoraSdkPlatform.instance = mockPlatform;
  });

  group('SensorModule Tests', () {
    test('start() & stop() success', () async {
      final sensor = SensorModule();
      expect(sensor.isRunning, false);
      expect(await sensor.start(frequencyHz: 100), true);
      expect(sensor.isRunning, true);
      expect(sensor.lastFrequencyHz, 100);
      expect(mockPlatform.frequencyHz, 100);

      expect(await sensor.stop(), true);
      expect(sensor.isRunning, false);
    });

    test('start() validation', () async {
      final sensor = SensorModule();
      expect(() => sensor.start(frequencyHz: 0), throwsArgumentError);
      expect(() => sensor.start(frequencyHz: -10), throwsArgumentError);
    });

    test('startWithOptions() success', () async {
      final sensor = SensorModule();
      expect(
        await sensor.startWithOptions(
          const SensorOptions(accuracy: SensorAccuracy.fastest),
        ),
        true,
      );
      expect(sensor.isRunning, true);
    });
  });
}
