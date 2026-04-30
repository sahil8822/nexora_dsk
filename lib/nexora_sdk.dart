import 'dart:typed_data';
import 'modules/camera/camera_module.dart';
import 'modules/bluetooth/bluetooth_module.dart';
import 'modules/location/location_module.dart';
import 'modules/sensor/sensor_module.dart';
import 'core/hardware_core.dart';
import 'nexora_sdk_platform_interface.dart';

export 'models/hardware_models.dart';
export 'core/hardware_core.dart';
export 'modules/camera/camera_module.dart';
export 'modules/bluetooth/bluetooth_module.dart';
export 'modules/location/location_module.dart';
export 'modules/sensor/sensor_module.dart';

/// The Entry Point for the High-Performance Modular Hardware SDK.
class NexoraSdk {
  static final NexoraSdk instance = NexoraSdk._();
  NexoraSdk._();

  // Specialized Modules
  /// Modular Camera Module for streaming raw frames.
  final CameraModule camera = CameraModule();

  /// Modular Bluetooth Module for scanning and connections.
  final BluetoothModule bluetooth = BluetoothModule();

  /// Modular Location Module for high-accuracy GPS.
  final LocationModule location = LocationModule();

  /// Modular Sensor Module for Accelerometer data.
  final SensorModule sensor = SensorModule();

  /// Returns the current platform version (Android/iOS).
  Future<String?> getPlatformVersion() {
    return NexoraSdkPlatform.instance.getPlatformVersion();
  }

  /// Low-level unified listener for all hardware events.
  /// Use specialized modules (camera, bluetooth, etc.) for a better experience.
  Stream<HardwareEvent> get unifiedStream => NexoraSdkPlatform.instance.unifiedStream;

  /// Stops the sensor stream to save power.
  Future<bool> stopSensor() => NexoraSdkPlatform.instance.stopSensor();

  /// Request all necessary hardware permissions (Camera, Location, Bluetooth)
  /// in a single system dialog. Returns true if all are granted.
  Future<bool> requestPermissions() => NexoraSdkPlatform.instance.requestPermissions();

  /// Performance monitoring: Track FPS of the binary stream
  final double _fps = 0;
  double get currentFps => _fps;

  void trackPerformance(Uint8List frame) {
    // Logic to calculate FPS
  }
}
