import '../../nexora_sdk_platform_interface.dart';

/// Modular Sensor Module (Accelerometer, etc.).
class SensorModule {
  Future<bool> start({int frequencyHz = 60}) async {
    return await NexoraSdkPlatform.instance.startSensor(frequencyHz: frequencyHz);
  }

  Future<bool> stop() async {
    return await NexoraSdkPlatform.instance.stopSensor();
  }

  /// Real-time Accelerometer and other sensor data.
  Stream<Map<String, dynamic>> get accelerometerStream {
    return NexoraSdkPlatform.instance.unifiedStream
        .where((e) => e.module == 'sensor')
        .map((e) => Map<String, dynamic>.from(e.data));
  }
}
