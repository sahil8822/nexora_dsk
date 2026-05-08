import '../../nexora_sdk_platform_interface.dart';
import '../../core/hardware_core.dart';

/// Module for motion and environmental hardware sensors.
class SensorModule {
  /// Starts the accelerometer and gyroscope at the specified [frequencyHz].
  ///
  /// High frequency (e.g. 100Hz) is recommended for motion analysis.
  Future<bool> start({int frequencyHz = 60}) {
    if (frequencyHz <= 0) {
      throw ArgumentError.value(
        frequencyHz,
        'frequencyHz',
        'Must be greater than zero.',
      );
    }
    return NexoraSdkPlatform.instance.startSensor(frequencyHz: frequencyHz);
  }

  /// Stops all sensor monitoring.
  Future<bool> stop() => NexoraSdkPlatform.instance.stopSensor();

  /// A stream of raw [HardwareEvent] data from the motion sensors.
  Stream<HardwareEvent> get stream => NexoraSdkPlatform.instance.sensorStream;
}
