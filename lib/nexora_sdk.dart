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
import 'modules/device/device_module.dart';
import 'modules/connectivity/connectivity_module.dart';
import 'modules/native/native_module.dart';
import 'modules/permissions/permissions_module.dart';
import 'modules/utility/utility_module.dart';
import 'core/hardware_lifecycle.dart';
import 'models/device_models.dart';
import 'models/hardware_capabilities.dart';
import 'models/hardware_diagnostics.dart';
import 'models/hardware_models.dart';
import 'models/permission_models.dart';
import 'core/hardware_core.dart';
import 'modules/nfc/nfc_module.dart';
import 'modules/storage/secure_storage_module.dart';

export 'nexora_sdk_desktop_stub.dart'
    if (dart.library.io) 'nexora_sdk_desktop.dart';
export 'nexora_sdk_web_stub.dart' if (dart.library.html) 'nexora_sdk_web.dart';
export 'models/hardware_capabilities.dart';
export 'models/hardware_diagnostics.dart';
export 'models/hardware_models.dart';
export 'models/hardware_exception.dart';
export 'models/device_models.dart';
export 'models/permission_models.dart';
export 'models/sensor_data.dart';
export 'core/hardware_core.dart';
export 'core/stream_utils.dart';
export 'core/hardware_retry.dart';
export 'core/hardware_lifecycle.dart';
export 'modules/audio/audio_module.dart';
export 'modules/biometric/biometric_module.dart';
export 'modules/bluetooth/bluetooth_module.dart';
export 'modules/camera/camera_module.dart';
export 'modules/feedback/feedback_module.dart';
export 'modules/health/health_module.dart';
export 'modules/location/location_module.dart';
export 'modules/sensor/sensor_module.dart';
export 'modules/storage/storage_module.dart';
export 'modules/device/device_module.dart';
export 'modules/connectivity/connectivity_module.dart';
export 'modules/native/native_module.dart';
export 'modules/permissions/permissions_module.dart';
export 'modules/utility/utility_module.dart';
export 'modules/nfc/nfc_module.dart';
export 'modules/storage/secure_storage_module.dart';
export 'core/background_isolates.dart';

/// Nexora SDK (v2.2.1) - Intelligence + Storage Edition.
///
/// A world-class, lightweight hardware toolkit for Flutter.
/// Provides unified access to Camera, Audio, GPS, Bluetooth, Biometrics,
/// Sensors, Health Diagnostics, and now device Storage.
class NexoraSdk {
  NexoraSdk._();
  static final NexoraSdk instance = NexoraSdk._();

  /// The current SDK version.
  static const String version = '2.2.1';

  /// Initializes the SDK by pre-warming capabilities/platform channel.
  Future<void> initialize({bool logCapabilities = false}) async {
    final platform = await NexoraSdkPlatform.instance.getPlatformVersion();
    if (logCapabilities) {
      // ignore: avoid_print
      print('Nexora SDK $version on $platform');
      for (final entry in featureMatrix.entries) {
        // ignore: avoid_print
        print('  ${entry.key.name}: ${entry.value.level.name}');
      }
    }
  }

  CameraModule? _camera;
  AudioModule? _audio;
  SensorModule? _sensors;
  BluetoothModule? _bluetooth;
  LocationModule? _location;
  BiometricModule? _biometrics;
  FeedbackModule? _feedback;
  HealthModule? _health;
  StorageModule? _storage;
  DeviceModule? _device;
  ConnectivityModule? _connectivity;
  PermissionsModule? _permissions;
  NativeModule? _native;
  UtilityModule? _utility;
  NfcModule? _nfc;
  SecureStorageModule? _secureStorage;

  /// NFC read/write support module.
  NfcModule get nfc => _nfc ??= NfcModule();

  /// AES-256 secure storage module.
  SecureStorageModule get secureStorage => _secureStorage ??= SecureStorageModule();

  /// Vision AI camera module with face/barcode detection.
  CameraModule get camera => _camera ??= CameraModule();

  /// Audio capture with real-time FFT spectrum analysis.
  AudioModule get audio => _audio ??= AudioModule();

  /// Motion sensor (accelerometer/gyroscope) module.
  SensorModule get sensors => _sensors ??= SensorModule();

  /// Bluetooth Low Energy (BLE) scanning and GATT operations.
  BluetoothModule get bluetooth => _bluetooth ??= BluetoothModule();

  /// High-accuracy GPS with geofencing support.
  LocationModule get location => _location ??= LocationModule();

  /// Biometric authentication (Face ID / Fingerprint).
  BiometricModule get biometrics => _biometrics ??= BiometricModule();

  /// Haptic feedback and vibration control.
  FeedbackModule get feedback => _feedback ??= FeedbackModule();

  /// Battery health, WiFi diagnostics, and telemetry logging.
  HealthModule get health => _health ??= HealthModule();

  /// Lightweight file I/O, storage info, and cache management.
  StorageModule get storage => _storage ??= StorageModule();

  /// Device identity, memory, display, CPU, and thermal diagnostics.
  DeviceModule get device => _device ??= DeviceModule();

  /// Current network route and connectivity diagnostics.
  ConnectivityModule get connectivity => _connectivity ??= ConnectivityModule();

  /// Permission status checks and settings helpers.
  PermissionsModule get permissions => _permissions ??= PermissionsModule();

  /// Clipboard, share sheet, and URL/deep-link helpers.
  NativeModule get native => _native ??= NativeModule();

  /// EcoMode power-saver and thermal protection controls.
  UtilityModule get utility => _utility ??= UtilityModule();

  /// Runtime capability snapshot for the current platform.
  HardwareCapabilities get capabilities => HardwareCapabilities.current();

  /// Unified stream of all SDK events.
  Stream<HardwareEvent> get events => NexoraSdkPlatform.instance.unifiedStream;

  /// Unified stream filtered to error events.
  Stream<HardwareEvent> get errors =>
      events.where((event) => event.type == 'error');

  /// Unified stream filtered to status events.
  Stream<HardwareEvent> get statusEvents =>
      events.where((event) => event.type == 'status');

  /// Unified stream filtered to one hardware [module].
  Stream<HardwareEvent> eventsFor(String module) {
    if (module.trim().isEmpty) {
      throw ArgumentError.value(module, 'module', 'Module cannot be empty.');
    }
    return events.where((event) => event.module == module);
  }

  /// Unified stream filtered to one event [type].
  Stream<HardwareEvent> eventsOfType(String type) {
    if (type.trim().isEmpty) {
      throw ArgumentError.value(type, 'type', 'Type cannot be empty.');
    }
    return events.where((event) => event.type == type);
  }

  /// Returns whether [feature] is expected to work on this Flutter target.
  bool supports(HardwareFeature feature) => capabilities.supports(feature);

  /// Returns detailed implementation status for [feature] on this target.
  HardwareFeatureSupport supportFor(HardwareFeature feature) {
    return capabilities.supportFor(feature);
  }

  /// Detailed support matrix for every SDK feature on this target.
  Map<HardwareFeature, HardwareFeatureSupport> get featureMatrix {
    return capabilities.featureMatrix;
  }

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

  /// Requests each core runtime permission and returns detailed results.
  Future<HardwarePermissionReport> requestPermissionReport() async {
    final results = await Future.wait<bool>([
      requestCameraPermission(),
      requestAudioPermission(),
      requestLocationPermission(),
      requestBluetoothPermission(),
    ]);

    return HardwarePermissionReport(
      camera: results[0],
      audio: results[1],
      location: results[2],
      bluetooth: results[3],
    );
  }

  /// Returns current status for one hardware permission without prompting.
  Future<HardwarePermissionStatus> getPermissionStatus(
    HardwarePermission permission,
  ) {
    return permissions.status(permission);
  }

  /// Returns current status for all core hardware permissions.
  Future<HardwarePermissionSnapshot> getPermissionSnapshot() {
    return permissions.snapshot();
  }

  /// Opens the host app settings page.
  Future<bool> openAppSettings() => permissions.openAppSettings();

  /// Attaches an app lifecycle controller that can stop hardware on pause.
  HardwareLifecycleController attachLifecycleController({
    bool autoStopOnPause = true,
    bool stopCamera = true,
    bool stopAudio = true,
    bool stopBluetoothScan = true,
    bool stopLocation = true,
    bool stopSensors = true,
    bool stopLogging = true,
  }) {
    return HardwareLifecycleController.attach(
      this,
      autoStopOnPause: autoStopOnPause,
      stopCamera: stopCamera,
      stopAudio: stopAudio,
      stopBluetoothScan: stopBluetoothScan,
      stopLocation: stopLocation,
      stopSensors: stopSensors,
      stopLogging: stopLogging,
    );
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

  /// Returns native device information such as model, memory, CPU, and thermal state.
  Future<DeviceInfo> getDeviceInfo() => device.getInfo();

  /// Returns current connectivity information.
  Future<ConnectivityInfo> getConnectivityInfo() => connectivity.getInfo();

  /// Collects a lightweight diagnostics snapshot for support screens/logging.
  Future<HardwareDiagnostics> collectDiagnostics() async {
    final values = await Future.wait<Object?>([
      getPlatformVersion(),
      storage.getStorageInfo(),
      health.getBatteryInfo(),
      health.getWifiInfo(),
      device.getInfo(),
      connectivity.getInfo(),
    ]);

    return HardwareDiagnostics(
      generatedAt: DateTime.now(),
      platformVersion: values[0] as String?,
      capabilities: capabilities,
      storage: values[1] as StorageInfo?,
      battery: values[2] as BatteryInfo?,
      wifi: values[3] as WifiInfo?,
      device: values[4] as DeviceInfo?,
      connectivity: values[5] as ConnectivityInfo?,
    );
  }

  /// Adds a circular Geofence for background monitoring.
  Future<bool> addGeofence(String id, double lat, double lon, double radius) {
    return NexoraSdkPlatform.instance.addGeofence(id, lat, lon, radius);
  }

  /// Stops all long-running hardware sessions started through the SDK.
  ///
  /// This is useful from app lifecycle hooks such as pause, logout, or dispose.
  Future<HardwareShutdownResult> stopAll({
    bool camera = true,
    bool audio = true,
    bool bluetoothScan = true,
    bool location = true,
    bool sensors = true,
    bool logging = true,
  }) async {
    final tasks = <String, Future<bool>>{};
    if (camera) tasks['camera'] = this.camera.stop();
    if (audio) tasks['audio'] = this.audio.stop();
    if (bluetoothScan) tasks['bluetoothScan'] = bluetooth.stopScan();
    if (location) tasks['location'] = this.location.stop();
    if (sensors) tasks['sensors'] = this.sensors.stop();
    if (logging) tasks['logging'] = stopLogging();

    final entries = await Future.wait(
      tasks.entries.map((entry) async {
        try {
          return MapEntry(entry.key, await entry.value);
        } catch (_) {
          return MapEntry(entry.key, false);
        }
      }),
    );

    return HardwareShutdownResult(Map<String, bool>.fromEntries(entries));
  }
}
