import 'package:nexora_sdk_platform_interface/models/hardware_models.dart';
import 'package:nexora_sdk_platform_interface/models/sensor_data.dart';
import 'package:nexora_sdk_platform_interface/nexora_sdk_platform_interface.dart';

/// Module for motion and environmental hardware sensors.
class SensorModule {
  bool _isRunning = false;

  /// API Documentation for _isRunning;.
  bool get isRunning => _isRunning;

  int _lastFrequencyHz = 60;

  /// API Documentation for _lastFrequencyHz;.
  int get lastFrequencyHz => _lastFrequencyHz;

  /// Starts the accelerometer and gyroscope at the specified [frequencyHz].
  ///
  /// High frequency (e.g. 100Hz) is recommended for motion analysis.
  Future<bool> start({int frequencyHz = 60}) async {
    if (frequencyHz <= 0) {
      throw ArgumentError.value(
        frequencyHz,
        'frequencyHz',
        'Must be greater than zero.',
      );
    }
    final success = await NexoraSdkPlatform.instance.startSensor(
      frequencyHz: frequencyHz,
    );
    if (success) {
      _isRunning = true;
      _lastFrequencyHz = frequencyHz;
    }
    return success;
  }

  /// Starts accelerometer/gyroscope tracking with granular native customizations.
  Future<bool> startWithOptions(SensorOptions options) async {
    final success = await NexoraSdkPlatform.instance.startSensorWithOptions(
      options,
    );
    if (success) {
      _isRunning = true;
    }
    return success;
  }

  /// Stops all sensor monitoring.
  Future<bool> stop() async {
    final success = await NexoraSdkPlatform.instance.stopSensor();
    if (success) _isRunning = false;
    return success;
  }

  /// A stream of [SensorData] objects captured in real-time from the motion sensors.
  Stream<SensorData> get stream => NexoraSdkPlatform.instance.sensorStream;
}
