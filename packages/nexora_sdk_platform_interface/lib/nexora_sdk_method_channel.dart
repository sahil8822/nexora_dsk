import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:nexora_sdk_platform_interface/core/hardware_core.dart';
import 'package:nexora_sdk_platform_interface/models/device_models.dart';
import 'package:nexora_sdk_platform_interface/models/hardware_exception.dart';
import 'package:nexora_sdk_platform_interface/models/hardware_models.dart';
import 'package:nexora_sdk_platform_interface/models/permission_models.dart';
import 'package:nexora_sdk_platform_interface/nexora_sdk_platform_interface.dart';
import 'package:nexora_sdk_platform_interface/src/pigeon/hardware_api.g.dart'
    as pigeon;

/// An implementation of [NexoraSdkPlatform] that uses type-safe Pigeon APIs.
class MethodChannelNexoraSdk extends NexoraSdkPlatform {
  @visibleForTesting
  final methodChannel = const MethodChannel('nexora_sdk/methods');

  @visibleForTesting
  final eventChannel = const EventChannel('nexora_sdk/events');

  final pigeon.HardwareApi _hardwareApi = pigeon.HardwareApi();
  final pigeon.AudioApi _audioApi = pigeon.AudioApi();
  final pigeon.LocationApi _locationApi = pigeon.LocationApi();
  final pigeon.SensorApi _sensorApi = pigeon.SensorApi();
  final pigeon.BiometricsApi _biometricsApi = pigeon.BiometricsApi();
  final pigeon.BluetoothApi _bluetoothApi = pigeon.BluetoothApi();
  final pigeon.SecureStorageApi _secureStorageApi = pigeon.SecureStorageApi();
  final pigeon.SystemApi _systemApi = pigeon.SystemApi();

  Stream<HardwareEvent>? _cachedUnifiedStream;

  Future<T> _wrap<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on PlatformException catch (error) {
      throw HardwareException.fromPlatformException(error);
    } on MissingPluginException {
      throw HardwareException(
        code: HardwareErrorCode.notSupported,
        message: 'MODULE_DISABLED',
        details:
            'You called a feature that is disabled in your native build settings. Please enable it in your Podfile or gradle.properties.',
      );
    }
  }

  @override
  Future<String?> getPlatformVersion() async {
    // Keep as method channel or redirect through SystemApi?
    // Let's redirect through DeviceInfo to find OS version, or implement directly.
    try {
      final info = await _systemApi.getDeviceInfo();
      return '${info.platform} ${info.osVersion}';
    } catch (_) {
      return 'Unknown';
    }
  }

  @override
  Future<bool> configure(NexoraSdkConfig config) async {
    return _wrap(() => _systemApi.configureSdk(pigeon.NexoraSdkConfig(
          enableLogging: config.logNativeCalls,
          ecoMode: config.ecoMode,
        )));
  }

  @override
  Future<bool> startBlePeripheral(String uuid) async {
    return _wrap(() => _bluetoothApi.startBlePeripheral(uuid));
  }

  @override
  Future<void> stopBlePeripheral() async {
    await _wrap(() => _bluetoothApi.stopBlePeripheral());
  }

  @override
  Future<bool> enterPictureInPicture() async {
    return _wrap(() => _systemApi.enterPictureInPicture());
  }

  @override
  Future<List<String>> getConnectedUsbDevices() async {
    final result = await _wrap(() => _systemApi.getConnectedUsbDevices());
    return result.whereType<String>().toList();
  }

  @override
  Future<bool> updateForegroundService(String title, String text) async {
    return _wrap(() => _systemApi.updateForegroundService(title, text));
  }

  @override
  Future<bool> requestPermissions() async {
    return _wrap(() => _systemApi.requestPermissions());
  }

  @override
  Future<bool> requestCameraPermission() async {
    return _wrap(() => _systemApi.requestPermission('camera'));
  }

  @override
  Future<bool> requestAudioPermission() async {
    return _wrap(() => _systemApi.requestPermission('audio'));
  }

  @override
  Future<bool> requestLocationPermission() async {
    return _wrap(() => _systemApi.requestPermission('location'));
  }

  @override
  Future<bool> requestBluetoothPermission() async {
    return _wrap(() => _systemApi.requestPermission('bluetooth'));
  }

  @override
  Future<HardwarePermissionStatus> getPermissionStatus(
    HardwarePermission permission,
  ) async {
    final status =
        await _wrap(() => _systemApi.getPermissionStatus(permission.value));
    return HardwarePermissionStatus(
      permission: permission,
      state: HardwarePermissionState.values.firstWhere(
        (s) => s.name == (status.state ?? 'denied'),
        orElse: () => HardwarePermissionState.denied,
      ),
      canRequest: status.canRequest ?? false,
    );
  }

  @override
  Future<bool> openAppSettings() async {
    return _wrap(() => _systemApi.openAppSettings());
  }

  @override
  Future<DeviceInfo> getDeviceInfo() async {
    final info = await _wrap(() => _systemApi.getDeviceInfo());
    return DeviceInfo(
      platform: info.platform ?? '',
      manufacturer: info.manufacturer ?? '',
      model: info.model ?? '',
      osVersion: info.osVersion ?? '',
      sdkVersion: info.sdkVersion ?? '',
      isPhysicalDevice: info.isPhysicalDevice ?? true,
      totalRamBytes: info.totalRamBytes ?? 0,
      availableRamBytes: info.availableRamBytes ?? 0,
      cpuArchitecture: info.cpuArchitecture ?? '',
      screenRefreshRate: info.screenRefreshRate ?? 0.0,
      thermalState: info.thermalState ?? 'normal',
    );
  }

  @override
  Future<ConnectivityInfo> getConnectivityInfo() async {
    final info = await _wrap(() => _systemApi.getConnectivityInfo());
    return ConnectivityInfo(
      isConnected: info.isConnected ?? false,
      networkType: info.networkType ?? 'none',
      isMetered: info.isMetered ?? false,
      isVpn: info.isVpn ?? false,
      signalStrength: info.signalStrength,
      ipAddress: info.ipAddress,
    );
  }

  // --- Camera & Vision ---
  @override
  Future<int?> startCamera({int width = 1280, int height = 720}) async {
    return _wrap(() => _hardwareApi.startCamera(width, height));
  }

  @override
  Future<int?> startCameraWithOptions(CameraOptions options) async {
    final pigeonOptions = pigeon.NexoraCameraOptions(
      resolution: options.resolution.name,
      focusMode: options.focusMode.name,
      exposureMode: options.exposureMode.name,
      exposureCompensation: options.exposureCompensation,
      mirrorFrontCamera: options.mirrorFrontCamera,
    );
    return _wrap(() => _hardwareApi.startCameraWithOptions(pigeonOptions));
  }

  @override
  Future<bool> stopCamera() async {
    return _wrap(() => _hardwareApi.stopCamera());
  }

  @override
  Future<bool> setVisionMode({bool barcode = false, bool face = false}) async {
    final options = pigeon.VisionModeOptions(barcode: barcode, face: face);
    return _wrap(() => _hardwareApi.setVisionMode(options));
  }

  @override
  Future<bool> registerCustomClassifier({
    required String modelAssetPath,
    required List<String> labels,
    double threshold = 0.5,
  }) async {
    final options = pigeon.CustomClassifierOptions(
      modelAssetPath: modelAssetPath,
      labels: labels,
      threshold: threshold,
    );
    return _wrap(() => _hardwareApi.registerCustomClassifier(options));
  }

  @override
  Future<bool> setFlash(bool on) async {
    return _wrap(() => _hardwareApi.setFlash(on));
  }

  @override
  Future<bool> setZoom(double level) async {
    return _wrap(() => _hardwareApi.setZoom(level));
  }

  @override
  Future<bool> flipCamera() async {
    return _wrap(() => _hardwareApi.flipCamera());
  }

  @override
  Future<String?> takePhoto({String? fileName}) async {
    return _wrap(() => _hardwareApi.takePhoto(fileName));
  }

  @override
  Future<String?> startVideoRecording({String? fileName}) async {
    return _wrap(() => _hardwareApi.startVideoRecording(fileName));
  }

  @override
  Future<String?> stopVideoRecording() async {
    return _wrap(() => _hardwareApi.stopVideoRecording());
  }

  // --- Audio ---
  @override
  Future<bool> startAudio({
    bool enableFFT = false,
    bool streamBytes = false,
    int updateIntervalMs = 80,
  }) async {
    final options = pigeon.BasicAudioOptions(
      enableFFT: enableFFT,
      streamBytes: streamBytes,
      updateIntervalMs: updateIntervalMs,
    );
    return _wrap(() => _audioApi.startAudio(options));
  }

  @override
  Future<bool> startAudioWithOptions(AudioOptions options) async {
    final pigeonOptions = pigeon.NexoraAudioOptions(
      sampleRate: options.sampleRate,
      channels: options.channels.name,
      enableEchoCancellation: options.enableEchoCancellation,
      enableNoiseSuppression: options.enableNoiseSuppression,
    );
    return _wrap(() => _audioApi.startAudioWithOptions(pigeonOptions));
  }

  @override
  Future<bool> stopAudio() async {
    return _wrap(() => _audioApi.stopAudio());
  }

  @override
  Future<bool> routeAudioOutput(AudioOutputRoute route) async {
    return _wrap(() => _audioApi.routeAudioOutput(route.name));
  }

  @override
  Future<double> getAudioVolume() async {
    return _wrap(() => _audioApi.getAudioVolume());
  }

  @override
  Future<bool> setAudioVolume(double level) async {
    return _wrap(() => _audioApi.setAudioVolume(level));
  }

  @override
  Future<bool> selectAudioInput(AudioInputDevice device) async {
    return _wrap(() => _audioApi.selectAudioInput(device.name));
  }

  @override
  Future<bool> setAudioGain(double gain) async {
    return _wrap(() => _audioApi.setAudioGain(gain));
  }

  // --- Intelligence & Logging ---
  @override
  Future<bool> startHardwareLogging(LogConfig config) async {
    // Keep custom method channel or implement in SystemApi?
    // Since it's startLogging / stopLogging, let's keep basic fallback for now if it requires more native work.
    // Or we can invoke it via SystemApi if needed, but since it's already there let's route it or fallback.
    return await methodChannel.invokeMethod<bool>('startLogging', {
          'fileName': config.fileName,
          'interval': config.intervalMs,
        }) ??
        false;
  }

  @override
  Future<bool> stopHardwareLogging() async {
    return await methodChannel.invokeMethod<bool>('stopLogging') ?? false;
  }

  @override
  Future<bool> addGeofence(
    String id,
    double lat,
    double lon,
    double radius,
  ) async {
    // Geofencing can be kept in methodChannel or moved to LocationApi in future updates.
    return await methodChannel.invokeMethod<bool>('addGeofence', {
          'id': id,
          'lat': lat,
          'lon': lon,
          'radius': radius,
        }) ??
        false;
  }

  // --- Bluetooth ---
  @override
  Future<bool> startBluetoothScan() async {
    return _wrap(() => _bluetoothApi.startBluetoothScan());
  }

  @override
  Future<bool> startBluetoothScanWithOptions(
    BluetoothScanOptions options,
  ) async {
    return _wrap(() => _bluetoothApi.startBluetoothScanWithOptions(
          pigeon.NexoraBluetoothScanOptions(
            serviceUuids: options.serviceUuids,
            scanMode: options.scanMode.name,
          ),
        ));
  }

  @override
  Future<bool> stopBluetoothScan() async {
    return _wrap(() => _bluetoothApi.stopBluetoothScan());
  }

  @override
  Future<bool> connectDevice(String id) async {
    return _wrap(() => _bluetoothApi.connectDevice(id));
  }

  @override
  Future<bool> disconnectDevice(String id) async {
    return _wrap(() => _bluetoothApi.disconnectDevice(id));
  }

  @override
  Future<List<String>> discoverServices(String deviceId) async {
    final services =
        await _wrap(() => _bluetoothApi.discoverServices(deviceId));
    return services.whereType<String>().toList();
  }

  @override
  Future<bool> sendData(
    String deviceId,
    String serviceId,
    String charId,
    List<int> data,
  ) async {
    return _wrap(
        () => _bluetoothApi.sendData(deviceId, serviceId, charId, data));
  }

  @override
  Future<Uint8List?> readData(
    String deviceId,
    String serviceId,
    String charId,
  ) async {
    return _wrap(() => _bluetoothApi.readData(deviceId, serviceId, charId));
  }

  // --- Biometrics ---
  @override
  Future<bool> authenticate(String reason) async {
    return _wrap(() => _biometricsApi.authenticate(reason));
  }

  @override
  Future<bool> authenticateWithOptions(BiometricPromptOptions options) async {
    return _wrap(() => _biometricsApi.authenticateWithOptions(
          pigeon.NexoraBiometricOptions(
            title: options.title,
            subtitle: options.subtitle,
            description: options.description,
            negativeButtonText: options.negativeButtonText,
          ),
        ));
  }

  @override
  Future<bool> canAuthenticate() async {
    return _wrap(() => _biometricsApi.canAuthenticate());
  }

  // --- Feedback ---
  @override
  Future<void> vibrate(int durationMs) async {
    await _wrap(() => _systemApi.vibrate(durationMs));
  }

  @override
  Future<void> hapticFeedback(String type) async {
    await _wrap(() => _systemApi.hapticFeedback(type));
  }

  @override
  Future<void> performHapticWithOptions(HapticOptions options) async {
    await _wrap(() => _systemApi.performHapticWithOptions(
          pigeon.NexoraHapticOptions(
            type: options.type.name,
          ),
        ));
  }

  // --- Health ---
  @override
  Future<BatteryInfo?> getBatteryInfo() async {
    final info = await _wrap(() => _systemApi.getBatteryInfo());
    if (info == null) return null;
    return BatteryInfo(
      level: info.level ?? 0.0,
      isCharging: info.isCharging ?? false,
      status: info.status ?? 'unknown',
      temperature: info.temperature ?? 0.0,
    );
  }

  @override
  Future<WifiInfo?> getWifiInfo() async {
    final info = await _wrap(() => _systemApi.getWifiInfo());
    if (info == null) return null;
    return WifiInfo(
      ssid: info.ssid ?? 'unknown',
      bssid: info.bssid ?? '00:00:00:00:00:00',
      signalStrength: info.signalStrength ?? 0,
      ipAddress: '0.0.0.0',
    );
  }

  // --- Location & Sensors ---
  @override
  Future<bool> startLocation() async {
    return _wrap(() => _locationApi.startLocation());
  }

  @override
  Future<bool> startLocationWithOptions(LocationOptions options) async {
    return _wrap(() => _locationApi.startLocationWithOptions(
          pigeon.NexoraLocationOptions(
            accuracy: options.accuracy.name,
            distanceFilter: options.distanceFilterMeters,
            intervalMs: 5000,
          ),
        ));
  }

  @override
  Future<bool> stopLocation() async {
    return _wrap(() => _locationApi.stopLocation());
  }

  @override
  Future<bool> setBackgroundLocationEnabled(bool enabled) async {
    return _wrap(() => _locationApi.setBackgroundLocationEnabled(enabled));
  }

  @override
  Future<bool> startSensor({int frequencyHz = 60}) async {
    return _wrap(() => _sensorApi.startSensor(frequencyHz));
  }

  @override
  Future<bool> startSensorWithOptions(SensorOptions options) async {
    int frequencyHz;
    switch (options.accuracy) {
      case SensorAccuracy.fastest:
        frequencyHz = 120;
        break;
      case SensorAccuracy.game:
        frequencyHz = 100;
        break;
      case SensorAccuracy.ui:
        frequencyHz = 60;
        break;
      case SensorAccuracy.normal:
        frequencyHz = 30;
        break;
    }
    return _wrap(() => _sensorApi.startSensorWithOptions(
          pigeon.NexoraSensorOptions(
            frequencyHz: frequencyHz,
          ),
        ));
  }

  @override
  Future<bool> stopSensor() async {
    return _wrap(() => _sensorApi.stopSensor());
  }

  // ==================== Storage ====================
  @override
  Future<StorageInfo?> getStorageInfo() async {
    final info = await _wrap(() => _secureStorageApi.getStorageInfo());
    if (info == null) return null;
    return StorageInfo(
      internalTotal: info.internalTotal ?? 0,
      internalFree: info.internalFree ?? 0,
      externalTotal: info.externalTotal ?? 0,
      externalFree: info.externalFree ?? 0,
      appCacheSize: info.appCacheSize ?? 0,
      appDataSize: info.appDataSize ?? 0,
    );
  }

  @override
  Future<String?> writeFile(String fileName, String content) async {
    return _wrap(() => _secureStorageApi.writeFile(fileName, content));
  }

  @override
  Future<String?> appendFile(String fileName, String content) async {
    return _wrap(() => _secureStorageApi.appendFile(fileName, content));
  }

  @override
  Future<String?> readFile(String fileName) async {
    return _wrap(() => _secureStorageApi.readFile(fileName));
  }

  @override
  Future<bool> deleteFile(String fileName) async {
    return _wrap(() => _secureStorageApi.deleteFile(fileName));
  }

  @override
  Future<bool> fileExists(String fileName) async {
    return _wrap(() => _secureStorageApi.fileExists(fileName));
  }

  @override
  Future<List<FileInfo>> listFiles() async {
    final result = await _wrap(() => _secureStorageApi.listFiles());
    return result
        .whereType<pigeon.NexoraFileInfo>()
        .map((info) => FileInfo(
              name: info.name ?? '',
              size: info.size ?? 0,
              isDirectory: info.isDirectory ?? false,
              lastModified: DateTime.fromMillisecondsSinceEpoch(
                info.lastModifiedMs ?? 0,
              ),
            ))
        .toList();
  }

  @override
  Future<String?> writeBytes(String fileName, Uint8List bytes) async {
    return _wrap(() => _secureStorageApi.writeBytes(fileName, bytes));
  }

  @override
  Future<Uint8List?> readBytes(String fileName) async {
    return _wrap(() => _secureStorageApi.readBytes(fileName));
  }

  @override
  Future<bool> clearCache() async {
    return _wrap(() => _secureStorageApi.clearCache());
  }

  @override
  Future<String?> getAppDirectory() async {
    return _wrap(() => _secureStorageApi.getAppDirectory());
  }

  @override
  Future<String?> getCacheDirectory() async {
    return _wrap(() => _secureStorageApi.getCacheDirectory());
  }

  @override
  Future<String?> getExternalDirectory() async {
    return _wrap(() => _secureStorageApi.getExternalDirectory());
  }

  @override
  Future<bool> copyText(String text) async {
    return _wrap(() => _systemApi.copyText(text));
  }

  @override
  Future<String?> pasteText() async {
    return _wrap(() => _systemApi.pasteText());
  }

  @override
  Future<bool> openUrl(String url) async {
    return _wrap(() => _systemApi.openUrl(url));
  }

  @override
  Future<bool> shareText(String text, {String? subject}) async {
    return _wrap(() => _systemApi.shareText(text, subject));
  }

  @override
  Future<bool> enableSmartSync({
    required String uploadEndpointUrl,
    required Map<String, String> headers,
    int rollLimitBytes = 2 * 1024 * 1024,
    bool requireWifi = true,
  }) async {
    final castedHeaders =
        headers.map((key, value) => MapEntry<String?, String?>(key, value));
    return _wrap(() => _systemApi.enableSmartSync(
          uploadEndpointUrl,
          castedHeaders,
          rollLimitBytes,
          requireWifi,
        ));
  }

  @override
  Future<bool> applyCameraFilterShader(String shaderType) async {
    return _wrap(() => _hardwareApi.applyCameraFilterShader(shaderType));
  }

  @override
  Stream<Uint8List> openL2capStream(String deviceId, int psm) {
    // Trigger the native L2CAP connection
    methodChannel.invokeMethod<bool>('connectL2cap', {
      'deviceId': deviceId,
      'psm': psm,
    });

    return unifiedStream
        .where(
          (e) =>
              e.module == 'bluetooth' &&
              e.type == 'l2cap' &&
              (e.data as Map?)?['deviceId'] == deviceId &&
              (e.data as Map?)?['psm'] == psm,
        )
        .map(
          (e) => Uint8List.fromList(
            List<int>.from((e.data as Map?)?['bytes'] as List? ?? []),
          ),
        );
  }

  @override
  Future<bool> enableDeadReckoning(bool enabled) async {
    return _wrap(() => _sensorApi.enableDeadReckoning(enabled));
  }

  @override
  Future<void> setEcoModeEnabled(bool enabled) async {
    await _wrap(() => _systemApi.setEcoModeEnabled(enabled));
  }

  @override
  Future<bool> isEcoModeActive() async {
    return _wrap(() => _systemApi.isEcoModeActive());
  }

  @override
  Future<DeviceThermalState> getThermalState() async {
    final stateStr = await _wrap(() => _systemApi.getThermalState());
    return DeviceThermalState.values.firstWhere(
      (s) => s.name == stateStr,
      orElse: () => DeviceThermalState.normal,
    );
  }

  // --- Unified Stream ---
  @override
  Stream<HardwareEvent> get unifiedStream => _cachedUnifiedStream ??=
          eventChannel.receiveBroadcastStream().map((data) {
        final map = data as Map;
        return HardwareEvent(
          module: map['module'] as String,
          type: map['type'] as String,
          data: map['data'],
          timestamp: DateTime.now(),
        );
      }).asBroadcastStream();

  @override
  Future<bool> subscribeToCharacteristic(
    String deviceId,
    String serviceId,
    String charId, {
    required bool enable,
  }) async {
    return _wrap(() => _bluetoothApi.subscribeToCharacteristic(
          deviceId,
          serviceId,
          charId,
          enable,
        ));
  }

  @override
  Future<bool> requestMtu(String deviceId, int mtu) async {
    return _wrap(() => _bluetoothApi.requestMtu(deviceId, mtu));
  }

  @override
  Future<String?> saveToGallery(String filePath) async {
    return _wrap(() => _systemApi.saveToGallery(filePath));
  }

  @override
  Future<bool> startForegroundService({
    required String title,
    required String content,
  }) async {
    return _wrap(() => _systemApi.startForegroundService(title, content));
  }

  @override
  Future<bool> stopForegroundService() async {
    return _wrap(() => _systemApi.stopForegroundService());
  }
}
