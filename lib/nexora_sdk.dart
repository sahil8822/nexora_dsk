import 'modules/camera/camera_module.dart';
import 'modules/bluetooth/bluetooth_module.dart';
import 'modules/location/location_module.dart';
import 'modules/sensor/sensor_module.dart';
import 'modules/biometric/biometric_module.dart';
import 'modules/audio/audio_module.dart';
import 'modules/feedback/feedback_module.dart';
import 'modules/health/health_module.dart';
import 'nexora_sdk_platform_interface.dart';
import 'models/hardware_models.dart';

/// The main entry point for the Nexora SDK v3.0 (Intelligence Edition).
///
/// Nexora provides a unified, high-performance interface for all mobile hardware 
/// including Camera, Bluetooth LE, Biometrics, GPS, and native AI Vision.
class NexoraSdk {
  NexoraSdk._();
  
  /// The singleton instance of the [NexoraSdk].
  static final NexoraSdk instance = NexoraSdk._();

  /// Advanced Camera controls and high-frequency frame streaming.
  final camera = CameraModule();
  
  /// Professional Bluetooth Low Energy (BLE) management and GATT communication.
  final bluetooth = BluetoothModule();
  
  /// High-accuracy Location (GPS) tracking and background Geofencing.
  final location = LocationModule();
  
  /// Motion (Accelerometer/Gyro) and environmental sensor management.
  final sensor = SensorModule();

  /// Secure Biometric authentication (FaceID/Fingerprint) with system dialogs.
  final biometrics = BiometricModule();

  /// Raw PCM Audio streaming and real-time FFT frequency analysis.
  final audio = AudioModule();

  /// Tactile Haptic feedback and timed vibration patterns.
  final feedback = FeedbackModule();

  /// Real-time Battery health, Thermal state, and Network diagnostics.
  final health = HealthModule();

  // --- Intelligence API ---

  /// Enables real-time AI processing on the camera stream.
  /// 
  /// Set [face] to true for face detection and [barcode] to true for 
  /// QR/Barcode scanning. Processing occurs on native background threads.
  Future<bool> setVisionMode({bool face = false, bool barcode = false}) =>
      NexoraSdkPlatform.instance.setVisionMode(face: face, barcode: barcode);

  /// Enables native FFT (Fast Fourier Transform) analysis for the microphone.
  /// 
  /// When active, the [audio.stream] will include frequency spectrum data.
  Future<bool> startAudioWithAnalysis() =>
      NexoraSdkPlatform.instance.startAudio(enableFFT: true);

  /// Starts automated hardware telemetry logging to a local CSV file.
  /// 
  /// Use [config] to specify the file name and update frequency.
  Future<bool> startLogging(LogConfig config) =>
      NexoraSdkPlatform.instance.startHardwareLogging(config);

  /// Stops the background hardware logging process.
  Future<bool> stopLogging() =>
      NexoraSdkPlatform.instance.stopHardwareLogging();

  /// Adds a circular Geofence for location-based background triggers.
  /// 
  /// Requires [lat] (Latitude), [lon] (Longitude), and [radius] in meters.
  Future<bool> addGeofence(String id, double lat, double lon, double radius) =>
      NexoraSdkPlatform.instance.addGeofence(id, lat, lon, radius);

  // --- Base ---
  
  /// Returns the current native platform version (e.g., 'Android 14', 'iOS 17.2').
  Future<String?> getPlatformVersion() => NexoraSdkPlatform.instance.getPlatformVersion();

  /// Requests all required hardware permissions (Camera, Mic, GPS, Bluetooth).
  /// 
  /// Returns true if all permissions are successfully granted.
  Future<bool> requestPermissions() => NexoraSdkPlatform.instance.requestPermissions();
}
