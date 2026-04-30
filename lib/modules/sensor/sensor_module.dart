import 'dart:async';
import '../../nexora_sdk_platform_interface.dart';
import '../../core/hardware_core.dart';

/// Module for accessing hardware motion sensors like the Accelerometer.
class SensorModule {
  /// Internal constructor.
  SensorModule();

  /// Throttled stream of accelerometer data events.
  Stream<HardwareEvent> get stream => NexoraSdkPlatform.instance.unifiedStream
      .where((e) => e.module == 'sensor');

  /// Alias for [stream] specific to accelerometer data.
  Stream<HardwareEvent> get accelerometerStream => stream;

  /// Starts the sensor with a specific [frequencyHz] (default 60Hz).
  Future<bool> start({int frequencyHz = 60}) =>
      NexoraSdkPlatform.instance.startSensor(frequencyHz: frequencyHz);

  /// Stops the sensor stream.
  Future<bool> stop() => NexoraSdkPlatform.instance.stopSensor();
}
