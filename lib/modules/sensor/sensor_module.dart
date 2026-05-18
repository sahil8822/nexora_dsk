import '../../nexora_sdk_platform_interface.dart';
import '../../core/hardware_core.dart';
import '../../models/hardware_models.dart';

/// Module for motion and environmental hardware sensors.
class SensorModule {
  bool _isRunning = false;
  bool get isRunning => _isRunning;

  int _lastFrequencyHz = 60;
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

  /// A stream of raw [HardwareEvent] data from the motion sensors.
  Stream<HardwareEvent> get stream => NexoraSdkPlatform.instance.sensorStream;
}
