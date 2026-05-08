import 'dart:async';
import 'nexora_sdk_platform_interface.dart';
import 'modules/camera/camera_module.dart';
import 'modules/audio/audio_module.dart';
import 'modules/sensor/sensor_module.dart';
import 'modules/bluetooth/bluetooth_module.dart';
import 'modules/location/location_module.dart';
import 'modules/biometric/biometric_module.dart';
import 'modules/feedback/feedback_module.dart';
import 'modules/health/health_module.dart';
import 'modules/storage/storage_module.dart';
import 'models/hardware_models.dart';

export 'nexora_sdk_desktop_stub.dart'
    if (dart.library.io) 'nexora_sdk_desktop.dart';
export 'nexora_sdk_web_stub.dart'
    if (dart.library.html) 'nexora_sdk_web.dart';

/// Nexora SDK (v3.1.2) - Intelligence + Storage Edition.
///
/// A world-class, lightweight hardware toolkit for Flutter.
/// Provides unified access to Camera, Audio, GPS, Bluetooth, Biometrics,
/// Sensors, Health Diagnostics, and now device Storage.
class NexoraSdk {
  NexoraSdk._();
  static final NexoraSdk instance = NexoraSdk._();

  /// Vision AI camera module with face/barcode detection.
  final camera = CameraModule();

  /// Audio capture with real-time FFT spectrum analysis.
  final audio = AudioModule();

  /// Motion sensor (accelerometer/gyroscope) module.
  final sensors = SensorModule();

  /// Bluetooth Low Energy (BLE) scanning and GATT operations.
  final bluetooth = BluetoothModule();

  /// High-accuracy GPS with geofencing support.
  final location = LocationModule();

  /// Biometric authentication (Face ID / Fingerprint).
  final biometrics = BiometricModule();

  /// Haptic feedback and vibration control.
  final feedback = FeedbackModule();

  /// Battery health, WiFi diagnostics, and telemetry logging.
  final health = HealthModule();

  /// Lightweight file I/O, storage info, and cache management.
  final storage = StorageModule();

  /// Requests all necessary hardware permissions at once.
  ///
  /// Native Android/iOS code shows system prompts for Camera, Microphone,
  /// foreground Location, and Bluetooth where the OS supports runtime prompts.
  /// Returns [true] when the critical runtime permissions are granted.
  Future<bool> requestPermissions() async {
    return NexoraSdkPlatform.instance.requestPermissions();
  }

  /// Requests only camera permission.
  Future<bool> requestCameraPermission() {
    return NexoraSdkPlatform.instance.requestCameraPermission();
  }

  /// Requests only microphone/audio permission.
  Future<bool> requestAudioPermission() {
    return NexoraSdkPlatform.instance.requestAudioPermission();
  }

  /// Requests only foreground location permission.
  Future<bool> requestLocationPermission() {
    return NexoraSdkPlatform.instance.requestLocationPermission();
  }

  /// Requests only Bluetooth runtime permission where required by the OS.
  Future<bool> requestBluetoothPermission() {
    return NexoraSdkPlatform.instance.requestBluetoothPermission();
  }

  /// Sets the native Vision AI mode.
  Future<bool> setVisionMode({bool face = false, bool barcode = false}) {
    return NexoraSdkPlatform.instance.setVisionMode(
      face: face,
      barcode: barcode,
    );
  }

  /// Starts background telemetry logging.
  Future<bool> startLogging(LogConfig config) {
    return NexoraSdkPlatform.instance.startHardwareLogging(config);
  }

  /// Stops background telemetry logging.
  Future<bool> stopLogging() {
    return NexoraSdkPlatform.instance.stopHardwareLogging();
  }

  /// Convenience method for quick audio analysis startup.
  Future<bool> startAudioWithAnalysis({
    bool streamBytes = false,
    int updateIntervalMs = 80,
  }) {
    return audio.start(
      enableFFT: true,
      streamBytes: streamBytes,
      updateIntervalMs: updateIntervalMs,
    );
  }

  /// Returns the current platform version.
  Future<String?> getPlatformVersion() {
    return NexoraSdkPlatform.instance.getPlatformVersion();
  }

  /// Adds a circular Geofence for background monitoring.
  Future<bool> addGeofence(String id, double lat, double lon, double radius) {
    return NexoraSdkPlatform.instance.addGeofence(id, lat, lon, radius);
  }
}
