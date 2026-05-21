import 'dart:typed_data';
import 'package:nexora_sdk/nexora_sdk.dart';
import 'package:nexora_sdk_platform_interface/nexora_sdk_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockNexoraSdkPlatform extends NexoraSdkPlatform
    with MockPlatformInterfaceMixin {
  final Map<String, Object> storedFiles = <String, Object>{};

  @override
  Future<String?> getPlatformVersion() => Future.value('42');
  @override
  Future<bool> requestPermissions() => Future.value(true);
  @override
  Future<bool> requestCameraPermission() => Future.value(true);
  @override
  Future<bool> requestAudioPermission() => Future.value(true);
  @override
  Future<bool> requestLocationPermission() => Future.value(true);
  @override
  Future<bool> requestBluetoothPermission() => Future.value(true);

  @override
  Future<HardwarePermissionStatus> getPermissionStatus(
    HardwarePermission permission,
  ) {
    return Future.value(
      HardwarePermissionStatus(
        permission: permission,
        state: HardwarePermissionState.granted,
        canRequest: false,
      ),
    );
  }

  @override
  Future<bool> openAppSettings() => Future.value(true);

  @override
  Future<DeviceInfo> getDeviceInfo() => Future.value(
    const DeviceInfo(
      platform: 'test',
      manufacturer: 'Nexora',
      model: 'Test Device',
      osVersion: '1.0',
      sdkVersion: '1',
      isPhysicalDevice: false,
      totalRamBytes: 1024,
      availableRamBytes: 512,
      cpuArchitecture: 'test64',
      screenRefreshRate: 60,
      thermalState: 'nominal',
    ),
  );

  @override
  Future<ConnectivityInfo> getConnectivityInfo() => Future.value(
    const ConnectivityInfo(
      isConnected: true,
      networkType: 'wifi',
      isMetered: false,
      isVpn: false,
      signalStrength: -40,
      ipAddress: '127.0.0.1',
    ),
  );

  @override
  Future<int?> startCamera({int width = 1280, int height = 720}) =>
      Future.value(1);
  @override
  Future<int?> startCameraWithOptions(CameraOptions options) =>
      Future.value(1);
  @override
  Future<bool> stopCamera() => Future.value(true);
  @override
  Future<bool> setVisionMode({bool barcode = false, bool face = false}) =>
      Future.value(true);
  @override
  Future<bool> registerCustomClassifier({
    required String modelAssetPath,
    required List<String> labels,
    double threshold = 0.5,
  }) => Future.value(true);
  @override
  Future<bool> setFlash(bool on) => Future.value(true);
  @override
  Future<bool> setZoom(double level) => Future.value(true);
  @override
  Future<bool> flipCamera() => Future.value(true);
  @override
  Future<String?> takePhoto({String? fileName}) =>
      Future.value('/test/photo.jpg');
  @override
  Future<String?> startVideoRecording({String? fileName}) =>
      Future.value('/test/video.mp4');
  @override
  Future<String?> stopVideoRecording() => Future.value('/test/video.mp4');

  @override
  Future<bool> startAudio({
    bool enableFFT = false,
    bool streamBytes = false,
    int updateIntervalMs = 80,
  }) async {
    return false;
  }

  @override
  Future<bool> startAudioWithOptions(AudioOptions options) =>
      Future.value(true);
  @override
  Future<bool> stopAudio() => Future.value(true);
  @override
  Future<bool> routeAudioOutput(AudioOutputRoute route) => Future.value(true);
  @override
  Future<double> getAudioVolume() => Future.value(0.5);
  @override
  Future<bool> setAudioVolume(double level) => Future.value(true);
  @override
  Future<bool> selectAudioInput(AudioInputDevice device) => Future.value(true);
  @override
  Future<bool> setAudioGain(double gain) => Future.value(true);

  @override
  Future<bool> startHardwareLogging(LogConfig config) => Future.value(true);
  @override
  Future<bool> stopHardwareLogging() => Future.value(true);
  @override
  Future<bool> addGeofence(String id, double lat, double lon, double radius) =>
      Future.value(true);

  @override
  Future<bool> startBluetoothScan() => Future.value(true);
  @override
  Future<bool> startBluetoothScanWithOptions(BluetoothScanOptions options) =>
      Future.value(true);
  @override
  Future<bool> stopBluetoothScan() => Future.value(true);
  @override
  Future<bool> connectDevice(String id) => Future.value(true);
  @override
  Future<bool> disconnectDevice(String id) => Future.value(true);
  @override
  Future<List<String>> discoverServices(String deviceId) =>
      Future.value(['test_service']);
  @override
  Future<bool> sendData(
    String deviceId,
    String serviceId,
    String charId,
    List<int> data,
  ) => Future.value(true);
  @override
  Future<Uint8List?> readData(
    String deviceId,
    String serviceId,
    String charId,
  ) => Future.value(Uint8List(0));

  @override
  Future<bool> authenticate(String reason) => Future.value(true);
  @override
  Future<bool> authenticateWithOptions(BiometricPromptOptions options) =>
      Future.value(true);
  @override
  Future<bool> canAuthenticate() => Future.value(true);

  @override
  Future<void> vibrate(int durationMs) => Future.value();
  @override
  Future<void> hapticFeedback(String type) => Future.value();
  @override
  Future<void> performHapticWithOptions(HapticOptions options) =>
      Future.value();

  @override
  Future<BatteryInfo?> getBatteryInfo() => Future.value(
    BatteryInfo(
      level: 75,
      isCharging: true,
      status: 'charging',
      temperature: 32,
    ),
  );
  @override
  Future<WifiInfo?> getWifiInfo() => Future.value(
    WifiInfo(
      ssid: 'test',
      bssid: '00:00:00:00:00:00',
      signalStrength: -55,
      ipAddress: '127.0.0.1',
    ),
  );

  @override
  Future<bool> startLocation() => Future.value(true);
  @override
  Future<bool> startLocationWithOptions(LocationOptions options) =>
      Future.value(true);
  @override
  Future<bool> stopLocation() => Future.value(true);
  @override
  Future<bool> setBackgroundLocationEnabled(bool enabled) => Future.value(true);
  @override
  Future<bool> startSensor({int frequencyHz = 60}) => Future.value(true);
  @override
  Future<bool> startSensorWithOptions(SensorOptions options) =>
      Future.value(true);
  @override
  Future<bool> stopSensor() => Future.value(true);

  @override
  Stream<HardwareEvent> get unifiedStream => const Stream.empty();

  // --- Storage Mocks ---
  @override
  Future<StorageInfo?> getStorageInfo() => Future.value(
    StorageInfo(
      internalTotal: 1000,
      internalFree: 400,
      externalTotal: 0,
      externalFree: 0,
      appCacheSize: 10,
      appDataSize: storedFiles.length,
    ),
  );
  @override
  Future<String?> writeFile(String fileName, String content) async {
    storedFiles[fileName] = content;
    return '/test/$fileName';
  }

  @override
  Future<String?> appendFile(String fileName, String content) async {
    final current = storedFiles[fileName] as String? ?? '';
    storedFiles[fileName] = '$current$content';
    return '/test/$fileName';
  }

  @override
  Future<String?> readFile(String fileName) async {
    final value = storedFiles[fileName];
    return value is String ? value : null;
  }

  @override
  Future<bool> deleteFile(String fileName) async =>
      storedFiles.remove(fileName) != null;

  @override
  Future<bool> fileExists(String fileName) async =>
      storedFiles.containsKey(fileName);

  @override
  Future<List<FileInfo>> listFiles() async => storedFiles.entries
      .map(
        (entry) => FileInfo(
          name: entry.key,
          size: entry.value.toString().length,
          isDirectory: false,
          lastModified: DateTime(2026),
        ),
      )
      .toList(growable: false);

  @override
  Future<String?> writeBytes(String fileName, dynamic bytes) async {
    storedFiles[fileName] = Uint8List.fromList(bytes as List<int>);
    return '/test/$fileName';
  }

  @override
  Future<Uint8List?> readBytes(String fileName) async {
    final value = storedFiles[fileName];
    return value is Uint8List ? value : null;
  }

  @override
  Future<bool> clearCache() => Future.value(true);
  @override
  Future<String?> getAppDirectory() => Future.value('/test');
  @override
  Future<String?> getCacheDirectory() => Future.value('/test/cache');
  @override
  Future<String?> getExternalDirectory() => Future.value();

  @override
  Future<bool> copyText(String text) => Future.value(true);
  @override
  Future<String?> pasteText() => Future.value('copied');
  @override
  Future<bool> openUrl(String url) => Future.value(true);
  @override
  Future<bool> shareText(String text, {String? subject}) => Future.value(true);

  @override
  Future<bool> enableSmartSync({
    required String uploadEndpointUrl,
    required Map<String, String> headers,
    int rollLimitBytes = 2 * 1024 * 1024,
    bool requireWifi = true,
  }) => Future.value(true);

  @override
  Future<bool> applyCameraFilterShader(String shaderType) => Future.value(true);

  @override
  Stream<Uint8List> openL2capStream(String deviceId, int psm) =>
      const Stream.empty();

  @override
  Future<bool> enableDeadReckoning(bool enabled) => Future.value(true);

  @override
  Future<void> setEcoModeEnabled(bool enabled) => Future.value();
  @override
  Future<bool> isEcoModeActive() => Future.value(false);
  @override
  Future<DeviceThermalState> getThermalState() =>
      Future.value(DeviceThermalState.normal);

  @override
  Future<bool> subscribeToCharacteristic(
    String deviceId,
    String serviceId,
    String charId, {
    required bool enable,
  }) async => true;

  @override
  Future<bool> requestMtu(String deviceId, int mtu) async => true;

  @override
  Future<String?> saveToGallery(String filePath) async => 'gallery/$filePath';

  @override
  Future<bool> startForegroundService({
    required String title,
    required String content,
  }) async => true;

  @override
  Future<bool> stopForegroundService() async => true;
}
