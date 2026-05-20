import 'dart:typed_data';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'models/device_models.dart';
import 'models/hardware_models.dart';
import 'models/permission_models.dart';
import 'models/sensor_data.dart';
import 'core/hardware_core.dart';
import 'nexora_sdk_method_channel.dart';

/// The interface that implementations of NexoraSdk must implement.
abstract class NexoraSdkPlatform extends PlatformInterface {
  NexoraSdkPlatform() : super(token: _token);
  static final Object _token = Object();
  static NexoraSdkPlatform _instance = MethodChannelNexoraSdk();
  static NexoraSdkPlatform get instance => _instance;
  static set instance(NexoraSdkPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  // --- Base ---
  Future<String?> getPlatformVersion();
  Future<bool> requestPermissions();
  Future<bool> requestCameraPermission();
  Future<bool> requestAudioPermission();
  Future<bool> requestLocationPermission();
  Future<bool> requestBluetoothPermission();
  Future<HardwarePermissionStatus> getPermissionStatus(
    HardwarePermission permission,
  );
  Future<bool> openAppSettings();
  Future<DeviceInfo> getDeviceInfo();
  Future<ConnectivityInfo> getConnectivityInfo();

  // --- Camera & Vision (AI) ---
  Future<dynamic> startCamera({int width = 1280, int height = 720});
  Future<dynamic> startCameraWithOptions(CameraOptions options);
  Future<bool> stopCamera();
  Future<bool> setVisionMode({bool barcode = false, bool face = false});
  Future<bool> registerCustomClassifier({
    required String modelAssetPath,
    required List<String> labels,
    double threshold = 0.5,
  });
  Future<bool> setFlash(bool on);
  Future<bool> setZoom(double level);
  Future<bool> flipCamera();
  Future<String?> takePhoto({String? fileName});
  Future<String?> startVideoRecording({String? fileName});
  Future<String?> stopVideoRecording();

  // --- Audio & Analysis (AI) ---
  Future<bool> startAudio({
    bool enableFFT = false,
    bool streamBytes = false,
    int updateIntervalMs = 80,
  });
  Future<bool> startAudioWithOptions(AudioOptions options);
  Future<bool> stopAudio();
  Future<bool> routeAudioOutput(AudioOutputRoute route);
  Future<double> getAudioVolume();
  Future<bool> setAudioVolume(double level);
  Future<bool> selectAudioInput(AudioInputDevice device);
  Future<bool> setAudioGain(double gain);

  // --- Intelligence & Logging ---
  Future<bool> startHardwareLogging(LogConfig config);
  Future<bool> stopHardwareLogging();
  Future<bool> addGeofence(String id, double lat, double lon, double radius);

  // --- Bluetooth Pro ---
  Future<bool> startBluetoothScan();
  Future<bool> startBluetoothScanWithOptions(BluetoothScanOptions options);
  Future<bool> stopBluetoothScan();
  Future<bool> connectDevice(String id);
  Future<bool> disconnectDevice(String id);
  Future<List<String>> discoverServices(String deviceId);
  Future<bool> sendData(
    String deviceId,
    String serviceId,
    String charId,
    List<int> data,
  );
  Future<Uint8List?> readData(
    String deviceId,
    String serviceId,
    String charId,
  );

  // --- Biometrics & Security ---
  Future<bool> authenticate(String reason);
  Future<bool> authenticateWithOptions(BiometricPromptOptions options);
  Future<bool> canAuthenticate();

  // --- Feedback & Health ---
  Future<void> vibrate(int durationMs);
  Future<void> hapticFeedback(String type);
  Future<void> performHapticWithOptions(HapticOptions options);
  Future<BatteryInfo?> getBatteryInfo();
  Future<WifiInfo?> getWifiInfo();

  // --- Location & Sensors ---
  Future<bool> startLocation();
  Future<bool> startLocationWithOptions(LocationOptions options);
  Future<bool> stopLocation();
  Future<bool> setBackgroundLocationEnabled(bool enabled);
  Future<bool> startSensor({int frequencyHz = 60});
  Future<bool> startSensorWithOptions(SensorOptions options);
  Future<bool> stopSensor();

  // --- Storage ---
  Future<StorageInfo?> getStorageInfo();
  Future<String?> writeFile(String fileName, String content);
  Future<String?> appendFile(String fileName, String content);
  Future<String?> readFile(String fileName);
  Future<bool> deleteFile(String fileName);
  Future<bool> fileExists(String fileName);
  Future<List<FileInfo>> listFiles();
  Future<String?> writeBytes(String fileName, Uint8List bytes);
  Future<Uint8List?> readBytes(String fileName);
  Future<bool> clearCache();
  Future<String?> getAppDirectory();
  Future<String?> getCacheDirectory();
  Future<String?> getExternalDirectory();

  // --- Native Utilities ---
  Future<bool> copyText(String text);
  Future<String?> pasteText();
  Future<bool> openUrl(String url);
  Future<bool> shareText(String text, {String? subject});

  // --- Pro Features (AI & Streams) ---
  Future<bool> enableSmartSync({
    required String uploadEndpointUrl,
    required Map<String, String> headers,
    int rollLimitBytes = 2 * 1024 * 1024,
    bool requireWifi = true,
  });

  Future<bool> applyCameraFilterShader(String shaderType);

  Stream<Uint8List> openL2capStream(String deviceId, int psm);

  Future<bool> enableDeadReckoning(bool enabled);

  Future<void> setEcoModeEnabled(bool enabled);
  Future<bool> isEcoModeActive();
  Future<DeviceThermalState> getThermalState();

  // --- Unified Streams ---
  Stream<HardwareEvent> get unifiedStream;

  Stream<CameraFrame> get cameraStream => unifiedStream
      .where((e) => e.module == 'camera')
      .map((e) => CameraFrame.fromMap(e.data));

  Stream<AudioFrame> get audioStream => unifiedStream
      .where((e) => e.module == 'audio')
      .map((e) => AudioFrame.fromMap(e.data));

  Stream<BleDevice> get bluetoothStream => unifiedStream
      .where((e) => e.module == 'bluetooth')
      .map((e) => BleDevice.fromMap(e.data));

  Stream<LocationData> get locationStream => unifiedStream
      .where((e) => e.module == 'gps')
      .map((e) => LocationData.fromMap(e.data));

  Stream<SensorData> get sensorStream => unifiedStream
      .where((e) => e.module == 'sensor')
      .map((e) => SensorData.fromMap({
            ...(e.data as Map? ?? {}),
            'timestamp': e.timestamp.millisecondsSinceEpoch,
          }));
}
