import 'dart:typed_data';

import 'package:nexora_sdk_platform_interface/core/hardware_core.dart';
import 'package:nexora_sdk_platform_interface/models/device_models.dart';
import 'package:nexora_sdk_platform_interface/models/hardware_models.dart';
import 'package:nexora_sdk_platform_interface/models/permission_models.dart';
import 'package:nexora_sdk_platform_interface/models/sensor_data.dart';
import 'package:nexora_sdk_platform_interface/nexora_sdk_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

/// The interface that implementations of NexoraSdk must implement.
abstract class NexoraSdkPlatform extends PlatformInterface {
  /// API Documentation for NexoraSdkPlatform.
  NexoraSdkPlatform() : super(token: _token);
  static final Object _token = Object();
  static NexoraSdkPlatform _instance = MethodChannelNexoraSdk();

  /// API Documentation for _instance;.
  static NexoraSdkPlatform get instance => _instance;

  /// API Documentation for instance.
  static set instance(NexoraSdkPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  // --- Base ---
  /// API Documentation for getPlatformVersion.
  Future<String?> getPlatformVersion();

  /// API Documentation for requestPermissions.
  Future<bool> requestPermissions();

  /// API Documentation for requestCameraPermission.
  Future<bool> requestCameraPermission();

  /// API Documentation for requestAudioPermission.
  Future<bool> requestAudioPermission();

  /// API Documentation for requestLocationPermission.
  Future<bool> requestLocationPermission();

  /// API Documentation for requestBluetoothPermission.
  Future<bool> requestBluetoothPermission();

  /// API Documentation for getPermissionStatus.
  Future<HardwarePermissionStatus> getPermissionStatus(
    HardwarePermission permission,
  );

  /// API Documentation for openAppSettings.
  Future<bool> openAppSettings();

  /// API Documentation for getDeviceInfo.
  Future<DeviceInfo> getDeviceInfo();

  /// API Documentation for getConnectivityInfo.
  Future<ConnectivityInfo> getConnectivityInfo();

  // --- Camera & Vision (AI) ---
  /// API Documentation for startCamera.
  Future<int?> startCamera({int width = 1280, int height = 720});

  /// API Documentation for startCameraWithOptions.
  Future<int?> startCameraWithOptions(CameraOptions options);

  /// API Documentation for stopCamera.
  Future<bool> stopCamera();

  /// API Documentation for setVisionMode.
  Future<bool> setVisionMode({bool barcode = false, bool face = false});

  /// API Documentation for registerCustomClassifier.
  Future<bool> registerCustomClassifier({
    required String modelAssetPath,
    required List<String> labels,
    double threshold = 0.5,
  });

  /// API Documentation for setFlash.
  Future<bool> setFlash(bool on);

  /// API Documentation for setZoom.
  Future<bool> setZoom(double level);

  /// API Documentation for flipCamera.
  Future<bool> flipCamera();

  /// API Documentation for takePhoto.
  Future<String?> takePhoto({String? fileName});

  /// API Documentation for startVideoRecording.
  Future<String?> startVideoRecording({String? fileName});

  /// API Documentation for stopVideoRecording.
  Future<String?> stopVideoRecording();

  // --- Audio & Analysis (AI) ---
  /// API Documentation for startAudio.
  Future<bool> startAudio({
    bool enableFFT = false,
    bool streamBytes = false,
    int updateIntervalMs = 80,
  });

  /// API Documentation for startAudioWithOptions.
  Future<bool> startAudioWithOptions(AudioOptions options);

  /// API Documentation for stopAudio.
  Future<bool> stopAudio();

  /// API Documentation for routeAudioOutput.
  Future<bool> routeAudioOutput(AudioOutputRoute route);

  /// API Documentation for getAudioVolume.
  Future<double> getAudioVolume();

  /// API Documentation for setAudioVolume.
  Future<bool> setAudioVolume(double level);

  /// API Documentation for selectAudioInput.
  Future<bool> selectAudioInput(AudioInputDevice device);

  /// API Documentation for setAudioGain.
  Future<bool> setAudioGain(double gain);

  // --- Intelligence & Logging ---
  /// API Documentation for startHardwareLogging.
  Future<bool> startHardwareLogging(LogConfig config);

  /// API Documentation for stopHardwareLogging.
  Future<bool> stopHardwareLogging();

  /// API Documentation for addGeofence.
  Future<bool> addGeofence(String id, double lat, double lon, double radius);

  // --- Bluetooth Pro ---
  /// API Documentation for startBluetoothScan.
  Future<bool> startBluetoothScan();

  /// API Documentation for startBluetoothScanWithOptions.
  Future<bool> startBluetoothScanWithOptions(BluetoothScanOptions options);

  /// API Documentation for stopBluetoothScan.
  Future<bool> stopBluetoothScan();

  /// API Documentation for connectDevice.
  Future<bool> connectDevice(String id);

  /// API Documentation for disconnectDevice.
  Future<bool> disconnectDevice(String id);

  /// API Documentation for discoverServices.
  Future<List<String>> discoverServices(String deviceId);

  /// API Documentation for sendData.
  Future<bool> sendData(
    String deviceId,
    String serviceId,
    String charId,
    List<int> data,
  );

  /// API Documentation for readData.
  Future<Uint8List?> readData(
    String deviceId,
    String serviceId,
    String charId,
  );

  // --- Biometrics & Security ---
  /// API Documentation for authenticate.
  Future<bool> authenticate(String reason);

  /// API Documentation for authenticateWithOptions.
  Future<bool> authenticateWithOptions(BiometricPromptOptions options);

  /// API Documentation for canAuthenticate.
  Future<bool> canAuthenticate();

  // --- Feedback & Health ---
  /// API Documentation for vibrate.
  Future<void> vibrate(int durationMs);

  /// API Documentation for hapticFeedback.
  Future<void> hapticFeedback(String type);

  /// API Documentation for performHapticWithOptions.
  Future<void> performHapticWithOptions(HapticOptions options);

  /// API Documentation for getBatteryInfo.
  Future<BatteryInfo?> getBatteryInfo();

  /// API Documentation for getWifiInfo.
  Future<WifiInfo?> getWifiInfo();

  // --- Location & Sensors ---
  /// API Documentation for startLocation.
  Future<bool> startLocation();

  /// API Documentation for startLocationWithOptions.
  Future<bool> startLocationWithOptions(LocationOptions options);

  /// API Documentation for stopLocation.
  Future<bool> stopLocation();

  /// API Documentation for setBackgroundLocationEnabled.
  Future<bool> setBackgroundLocationEnabled(bool enabled);

  /// API Documentation for startSensor.
  Future<bool> startSensor({int frequencyHz = 60});

  /// API Documentation for startSensorWithOptions.
  Future<bool> startSensorWithOptions(SensorOptions options);

  /// API Documentation for stopSensor.
  Future<bool> stopSensor();

  // --- Storage ---
  /// API Documentation for getStorageInfo.
  Future<StorageInfo?> getStorageInfo();

  /// API Documentation for writeFile.
  Future<String?> writeFile(String fileName, String content);

  /// API Documentation for appendFile.
  Future<String?> appendFile(String fileName, String content);

  /// API Documentation for readFile.
  Future<String?> readFile(String fileName);

  /// API Documentation for deleteFile.
  Future<bool> deleteFile(String fileName);

  /// API Documentation for fileExists.
  Future<bool> fileExists(String fileName);

  /// API Documentation for listFiles.
  Future<List<FileInfo>> listFiles();

  /// API Documentation for writeBytes.
  Future<String?> writeBytes(String fileName, Uint8List bytes);

  /// API Documentation for readBytes.
  Future<Uint8List?> readBytes(String fileName);

  /// API Documentation for clearCache.
  Future<bool> clearCache();

  /// API Documentation for getAppDirectory.
  Future<String?> getAppDirectory();

  /// API Documentation for getCacheDirectory.
  Future<String?> getCacheDirectory();

  /// API Documentation for getExternalDirectory.
  Future<String?> getExternalDirectory();

  // --- Native Utilities ---
  /// API Documentation for copyText.
  Future<bool> copyText(String text);

  /// API Documentation for pasteText.
  Future<String?> pasteText();

  /// API Documentation for openUrl.
  Future<bool> openUrl(String url);

  /// API Documentation for shareText.
  Future<bool> shareText(String text, {String? subject});

  // --- Pro Features (AI & Streams) ---
  /// API Documentation for enableSmartSync.
  Future<bool> enableSmartSync({
    required String uploadEndpointUrl,
    required Map<String, String> headers,
    int rollLimitBytes = 2 * 1024 * 1024,
    bool requireWifi = true,
  });

  /// API Documentation for applyCameraFilterShader.
  Future<bool> applyCameraFilterShader(String shaderType);

  /// API Documentation for openL2capStream.
  Stream<Uint8List> openL2capStream(String deviceId, int psm);

  /// API Documentation for enableDeadReckoning.
  Future<bool> enableDeadReckoning(bool enabled);

  /// API Documentation for setEcoModeEnabled.
  Future<void> setEcoModeEnabled(bool enabled);

  /// API Documentation for isEcoModeActive.
  Future<bool> isEcoModeActive();

  /// API Documentation for getThermalState.
  Future<DeviceThermalState> getThermalState();

  // --- Unified Streams ---
  /// API Documentation for unifiedStream;.
  Stream<HardwareEvent> get unifiedStream;

  /// API Documentation for unifiedStream.
  Stream<CameraFrame> get cameraStream => unifiedStream
      .where((e) => e.module == 'camera')
      .map((e) => CameraFrame.fromMap(e.data as Map<dynamic, dynamic>));

  /// API Documentation for unifiedStream.
  Stream<AudioFrame> get audioStream => unifiedStream
      .where((e) => e.module == 'audio')
      .map((e) => AudioFrame.fromMap(e.data as Map<dynamic, dynamic>));

  /// API Documentation for unifiedStream.
  Stream<BleDevice> get bluetoothStream => unifiedStream
      .where((e) => e.module == 'bluetooth')
      .map((e) => BleDevice.fromMap(e.data as Map<dynamic, dynamic>));

  /// API Documentation for unifiedStream.
  Stream<LocationData> get locationStream => unifiedStream
      .where((e) => e.module == 'gps')
      .map((e) => LocationData.fromMap(e.data as Map<dynamic, dynamic>));

  /// API Documentation for unifiedStream.
  Stream<SensorData> get sensorStream =>
      unifiedStream.where((e) => e.module == 'sensor').map(
            (e) => SensorData.fromMap({
              ...(e.data as Map? ?? {}),
              'timestamp': e.timestamp.millisecondsSinceEpoch,
            }),
          );

  /// API Documentation for subscribeToCharacteristic.
  Future<bool> subscribeToCharacteristic(
    String deviceId,
    String serviceId,
    String charId, {
    required bool enable,
  }) {
    throw UnimplementedError(
      'subscribeToCharacteristic() has not been implemented.',
    );
  }

  /// API Documentation for requestMtu.
  Future<bool> requestMtu(String deviceId, int mtu) {
    throw UnimplementedError('requestMtu() has not been implemented.');
  }

  /// API Documentation for saveToGallery.
  Future<String?> saveToGallery(String filePath) {
    throw UnimplementedError('saveToGallery() has not been implemented.');
  }

  /// API Documentation for startForegroundService.
  Future<bool> startForegroundService({
    required String title,
    required String content,
  }) {
    throw UnimplementedError(
      'startForegroundService() has not been implemented.',
    );
  }

  /// API Documentation for stopForegroundService.
  Future<bool> stopForegroundService() {
    throw UnimplementedError(
      'stopForegroundService() has not been implemented.',
    );
  }
}
