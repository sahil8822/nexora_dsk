import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:nexora_sdk_platform_interface/core/hardware_core.dart';
import 'package:nexora_sdk_platform_interface/models/device_models.dart';
import 'package:nexora_sdk_platform_interface/models/hardware_exception.dart';
import 'package:nexora_sdk_platform_interface/models/hardware_models.dart';
import 'package:nexora_sdk_platform_interface/models/permission_models.dart';
import 'package:nexora_sdk_platform_interface/nexora_sdk_platform_interface.dart';

/// An implementation of [NexoraSdkPlatform] that uses method channels.
class MethodChannelNexoraSdk extends NexoraSdkPlatform {
  @visibleForTesting

  /// API Documentation for MethodChannel.
  final methodChannel = const MethodChannel('nexora_sdk/methods');
  @visibleForTesting

  /// API Documentation for EventChannel.
  final eventChannel = const EventChannel('nexora_sdk/events');

  Stream<HardwareEvent>? _cachedUnifiedStream;

  Future<T?> _invoke<T>(String method, [Object? arguments]) async {
    try {
      return await methodChannel.invokeMethod<T>(method, arguments);
    } on PlatformException catch (error) {
      throw HardwareException.fromPlatformException(error);
    }
  }

  Future<List<T>?> _invokeList<T>(String method, [Object? arguments]) async {
    try {
      return await methodChannel.invokeListMethod<T>(method, arguments);
    } on PlatformException catch (error) {
      throw HardwareException.fromPlatformException(error);
    }
  }

  Future<Map<K, V>?> _invokeMap<K, V>(
    String method, [
    Object? arguments,
  ]) async {
    try {
      return await methodChannel.invokeMapMethod<K, V>(method, arguments);
    } on PlatformException catch (error) {
      throw HardwareException.fromPlatformException(error);
    }
  }

  
  @override
  Future<String?> getPlatformVersion() async {
    return _invoke<String>('getPlatformVersion');
  }

  @override
  Future<bool> startBlePeripheral(String uuid) async {
    final result = await methodChannel.invokeMethod<bool>('startBlePeripheral', {'uuid': uuid});
    return result ?? false;
  }

  @override
  Future<void> stopBlePeripheral() async {
    await methodChannel.invokeMethod<void>('stopBlePeripheral');
  }

  @override
  Future<bool> enterPictureInPicture() async {
    final result = await methodChannel.invokeMethod<bool>('enterPictureInPicture');
    return result ?? false;
  }

  @override
  Future<List<String>> getConnectedUsbDevices() async {
    final result = await methodChannel.invokeListMethod<String>('connectUsbDevice');
    return result ?? [];
  }

  @override
  Future<bool> updateForegroundService(String title, String text) async {
    final result = await methodChannel.invokeMethod<bool>('updateForegroundService', {
      'title': title,
      'text': text,
    });
    return result ?? false;
  }

  @override
  Future<bool> requestPermissions() async {
    return await _invoke<bool>('requestPermissions') ?? false;
  }

  @override
  Future<bool> requestCameraPermission() async {
    return await _invoke<bool>('requestPermission', {'type': 'camera'}) ??
        false;
  }

  @override
  Future<bool> requestAudioPermission() async {
    return await _invoke<bool>('requestPermission', {'type': 'audio'}) ?? false;
  }

  @override
  Future<bool> requestLocationPermission() async {
    return await _invoke<bool>('requestPermission', {'type': 'location'}) ??
        false;
  }

  @override
  Future<bool> requestBluetoothPermission() async {
    return await _invoke<bool>('requestPermission', {'type': 'bluetooth'}) ??
        false;
  }

  @override
  Future<HardwarePermissionStatus> getPermissionStatus(
    HardwarePermission permission,
  ) async {
    final map = await _invokeMap<String, Object>('getPermissionStatus', {
      'type': permission.value,
    });
    return HardwarePermissionStatus.fromMap(
      map ??
          <String, Object>{
            'permission': permission.value,
            'state': HardwarePermissionState.unsupported.name,
            'canRequest': false,
          },
    );
  }

  @override
  Future<bool> openAppSettings() async {
    return await _invoke<bool>('openAppSettings') ?? false;
  }

  @override
  Future<DeviceInfo> getDeviceInfo() async {
    final map = await _invokeMap<String, Object>('getDeviceInfo');
    return DeviceInfo.fromMap(map ?? const <String, Object>{});
  }

  @override
  Future<ConnectivityInfo> getConnectivityInfo() async {
    final map = await _invokeMap<String, Object>('getConnectivityInfo');
    return ConnectivityInfo.fromMap(map ?? const <String, Object>{});
  }

  // --- Camera & Vision ---
  @override
  Future<int?> startCamera({int width = 1280, int height = 720}) async {
    return _invoke<int>('startCamera', {
      'width': width,
      'height': height,
    });
  }

  @override
  Future<int?> startCameraWithOptions(CameraOptions options) async {
    return _invoke<int>('startCameraWithOptions', options.toMap());
  }

  @override
  Future<bool> stopCamera() async {
    return await _invoke<bool>('stopCamera') ?? false;
  }

  @override
  Future<bool> setVisionMode({bool barcode = false, bool face = false}) async {
    return await _invoke<bool>('setVisionMode', {
          'barcode': barcode,
          'face': face,
        }) ??
        false;
  }

  @override
  Future<bool> registerCustomClassifier({
    required String modelAssetPath,
    required List<String> labels,
    double threshold = 0.5,
  }) async {
    return await _invoke<bool>('registerCustomClassifier', {
          'modelAssetPath': modelAssetPath,
          'labels': labels,
          'threshold': threshold,
        }) ??
        false;
  }

  @override
  Future<bool> setFlash(bool on) async {
    return await _invoke<bool>('setFlash', {'on': on}) ?? false;
  }

  @override
  Future<bool> setZoom(double level) async {
    return await _invoke<bool>('setZoom', {'level': level}) ?? false;
  }

  @override
  Future<bool> flipCamera() async {
    return await _invoke<bool>('flipCamera') ?? false;
  }

  @override
  Future<String?> takePhoto({String? fileName}) async {
    return _invoke<String>('takePhoto', {'fileName': fileName});
  }

  @override
  Future<String?> startVideoRecording({String? fileName}) async {
    return _invoke<String>('startVideoRecording', {'fileName': fileName});
  }

  @override
  Future<String?> stopVideoRecording() async {
    return _invoke<String>('stopVideoRecording');
  }

  // --- Audio ---
  @override
  Future<bool> startAudio({
    bool enableFFT = false,
    bool streamBytes = false,
    int updateIntervalMs = 80,
  }) async {
    return await _invoke<bool>('startAudio', {
          'enableFFT': enableFFT,
          'streamBytes': streamBytes,
          'updateIntervalMs': updateIntervalMs,
        }) ??
        false;
  }

  @override
  Future<bool> startAudioWithOptions(AudioOptions options) async {
    return await _invoke<bool>('startAudioWithOptions', options.toMap()) ??
        false;
  }

  @override
  Future<bool> stopAudio() async {
    return await _invoke<bool>('stopAudio') ?? false;
  }

  @override
  Future<bool> routeAudioOutput(AudioOutputRoute route) async {
    return await _invoke<bool>('routeAudioOutput', {
          'route': route.name,
        }) ??
        false;
  }

  @override
  Future<double> getAudioVolume() async {
    return await _invoke<double>('getAudioVolume') ?? 0.5;
  }

  @override
  Future<bool> setAudioVolume(double level) async {
    return await _invoke<bool>('setAudioVolume', {
          'level': level,
        }) ??
        false;
  }

  @override
  Future<bool> selectAudioInput(AudioInputDevice device) async {
    return await _invoke<bool>('selectAudioInput', {
          'device': device.name,
        }) ??
        false;
  }

  @override
  Future<bool> setAudioGain(double gain) async {
    return await _invoke<bool>('setAudioGain', {
          'gain': gain,
        }) ??
        false;
  }

  // --- Intelligence & Logging ---
  @override
  Future<bool> startHardwareLogging(LogConfig config) async {
    return await _invoke<bool>('startLogging', {
          'fileName': config.fileName,
          'interval': config.intervalMs,
        }) ??
        false;
  }

  @override
  Future<bool> stopHardwareLogging() async {
    return await _invoke<bool>('stopLogging') ?? false;
  }

  @override
  Future<bool> addGeofence(
    String id,
    double lat,
    double lon,
    double radius,
  ) async {
    return await _invoke<bool>('addGeofence', {
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
    return await _invoke<bool>('startBluetoothScan') ?? false;
  }

  @override
  Future<bool> startBluetoothScanWithOptions(
    BluetoothScanOptions options,
  ) async {
    return await _invoke<bool>(
          'startBluetoothScanWithOptions',
          options.toMap(),
        ) ??
        false;
  }

  @override
  Future<bool> stopBluetoothScan() async {
    return await _invoke<bool>('stopBluetoothScan') ?? false;
  }

  @override
  Future<bool> connectDevice(String id) async {
    return await _invoke<bool>('connectDevice', {
          'id': id,
        }) ??
        false;
  }

  @override
  Future<bool> disconnectDevice(String id) async {
    return await _invoke<bool>('disconnectDevice', {
          'id': id,
        }) ??
        false;
  }

  @override
  Future<List<String>> discoverServices(String deviceId) async {
    final services = await _invokeList<String>(
      'discoverServices',
      {'id': deviceId},
    );
    return services ?? [];
  }

  @override
  Future<bool> sendData(
    String deviceId,
    String serviceId,
    String charId,
    List<int> data,
  ) async {
    return await _invoke<bool>('sendData', {
          'deviceId': deviceId,
          'serviceId': serviceId,
          'charId': charId,
          'data': data,
        }) ??
        false;
  }

  @override
  Future<Uint8List?> readData(
    String deviceId,
    String serviceId,
    String charId,
  ) async {
    return _invoke<Uint8List>('readData', {
      'deviceId': deviceId,
      'serviceId': serviceId,
      'charId': charId,
    });
  }

  // --- Biometrics ---
  @override
  Future<bool> authenticate(String reason) async {
    return await _invoke<bool>('authenticate', {
          'reason': reason,
        }) ??
        false;
  }

  @override
  Future<bool> authenticateWithOptions(BiometricPromptOptions options) async {
    return await _invoke<bool>('authenticateWithOptions', options.toMap()) ??
        false;
  }

  @override
  Future<bool> canAuthenticate() async {
    return await _invoke<bool>('canAuthenticate') ?? false;
  }

  // --- Feedback ---
  @override
  Future<void> vibrate(int durationMs) async {
    await _invoke<void>('vibrate', {'duration': durationMs});
  }

  @override
  Future<void> hapticFeedback(String type) async {
    await _invoke<void>('hapticFeedback', {'type': type});
  }

  @override
  Future<void> performHapticWithOptions(HapticOptions options) async {
    await _invoke<void>('performHapticWithOptions', options.toMap());
  }

  // --- Health ---
  @override
  Future<BatteryInfo?> getBatteryInfo() async {
    final map = await _invokeMap<String, dynamic>('getBatteryInfo');
    return map != null ? BatteryInfo.fromMap(map) : null;
  }

  @override
  Future<WifiInfo?> getWifiInfo() async {
    final map = await _invokeMap<String, dynamic>('getWifiInfo');
    return map != null ? WifiInfo.fromMap(map) : null;
  }

  // --- Location & Sensors ---
  @override
  Future<bool> startLocation() async {
    return await _invoke<bool>('startLocation') ?? false;
  }

  @override
  Future<bool> startLocationWithOptions(LocationOptions options) async {
    return await _invoke<bool>('startLocationWithOptions', options.toMap()) ??
        false;
  }

  @override
  Future<bool> stopLocation() async {
    return await _invoke<bool>('stopLocation') ?? false;
  }

  @override
  Future<bool> setBackgroundLocationEnabled(bool enabled) async {
    return await _invoke<bool>(
          'setBackgroundLocationEnabled',
          {'enabled': enabled},
        ) ??
        false;
  }

  @override
  Future<bool> startSensor({int frequencyHz = 60}) async {
    return await _invoke<bool>('startSensor', {
          'frequency': frequencyHz,
        }) ??
        false;
  }

  @override
  Future<bool> startSensorWithOptions(SensorOptions options) async {
    return await _invoke<bool>('startSensorWithOptions', options.toMap()) ??
        false;
  }

  @override
  Future<bool> stopSensor() async {
    return await _invoke<bool>('stopSensor') ?? false;
  }

  // ==================== Storage ====================

  @override
  Future<StorageInfo?> getStorageInfo() async {
    final map = await _invokeMap<String, dynamic>('getStorageInfo');
    return map != null ? StorageInfo.fromMap(map) : null;
  }

  @override
  Future<String?> writeFile(String fileName, String content) async {
    return _invoke<String>('writeFile', {
      'fileName': fileName,
      'content': content,
    });
  }

  @override
  Future<String?> appendFile(String fileName, String content) async {
    return _invoke<String>('appendFile', {
      'fileName': fileName,
      'content': content,
    });
  }

  @override
  Future<String?> readFile(String fileName) async {
    return _invoke<String>('readFile', {
      'fileName': fileName,
    });
  }

  @override
  Future<bool> deleteFile(String fileName) async {
    return await _invoke<bool>('deleteFile', {
          'fileName': fileName,
        }) ??
        false;
  }

  @override
  Future<bool> fileExists(String fileName) async {
    return await _invoke<bool>('fileExists', {
          'fileName': fileName,
        }) ??
        false;
  }

  @override
  Future<List<FileInfo>> listFiles() async {
    final list = await _invokeList<dynamic>('listFiles');
    if (list == null) return [];
    return list.map((item) => FileInfo.fromMap(item as Map)).toList();
  }

  @override
  Future<String?> writeBytes(String fileName, Uint8List bytes) async {
    return _invoke<String>('writeBytes', {
      'fileName': fileName,
      'bytes': bytes,
    });
  }

  @override
  Future<Uint8List?> readBytes(String fileName) async {
    return _invoke<Uint8List>('readBytes', {
      'fileName': fileName,
    });
  }

  @override
  Future<bool> clearCache() async {
    return await _invoke<bool>('clearCache') ?? false;
  }

  @override
  Future<String?> getAppDirectory() async {
    return _invoke<String>('getAppDirectory');
  }

  @override
  Future<String?> getCacheDirectory() async {
    return _invoke<String>('getCacheDirectory');
  }

  @override
  Future<String?> getExternalDirectory() async {
    return _invoke<String>('getExternalDirectory');
  }

  @override
  Future<bool> copyText(String text) async {
    return await _invoke<bool>('copyText', {'text': text}) ?? false;
  }

  @override
  Future<String?> pasteText() async {
    return _invoke<String>('pasteText');
  }

  @override
  Future<bool> openUrl(String url) async {
    return await _invoke<bool>('openUrl', {'url': url}) ?? false;
  }

  @override
  Future<bool> shareText(String text, {String? subject}) async {
    return await _invoke<bool>('shareText', {
          'text': text,
          'subject': subject,
        }) ??
        false;
  }

  @override
  Future<bool> enableSmartSync({
    required String uploadEndpointUrl,
    required Map<String, String> headers,
    int rollLimitBytes = 2 * 1024 * 1024,
    bool requireWifi = true,
  }) async {
    return await _invoke<bool>('enableSmartSync', {
          'uploadEndpointUrl': uploadEndpointUrl,
          'headers': headers,
          'rollLimitBytes': rollLimitBytes,
          'requireWifi': requireWifi,
        }) ??
        false;
  }

  @override
  Future<bool> applyCameraFilterShader(String shaderType) async {
    return await _invoke<bool>('applyCameraFilterShader', {
          'shaderType': shaderType,
        }) ??
        false;
  }

  @override
  Stream<Uint8List> openL2capStream(String deviceId, int psm) {
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
    return await _invoke<bool>('enableDeadReckoning', {'enabled': enabled}) ??
        false;
  }

  @override
  Future<void> setEcoModeEnabled(bool enabled) async {
    await _invoke<void>('setEcoModeEnabled', {'enabled': enabled});
  }

  @override
  Future<bool> isEcoModeActive() async {
    return await _invoke<bool>('isEcoModeActive') ?? false;
  }

  @override
  Future<DeviceThermalState> getThermalState() async {
    final stateStr = await _invoke<String>('getThermalState') ?? 'normal';
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
    final result = await methodChannel.invokeMethod<bool>(
      'subscribeToCharacteristic',
      {
        'deviceId': deviceId,
        'serviceId': serviceId,
        'charId': charId,
        'enable': enable,
      },
    );
    return result ?? false;
  }

  @override
  Future<bool> requestMtu(String deviceId, int mtu) async {
    final result = await methodChannel.invokeMethod<bool>('requestMtu', {
      'deviceId': deviceId,
      'mtu': mtu,
    });
    return result ?? false;
  }

  @override
  Future<String?> saveToGallery(String filePath) async {
    return methodChannel.invokeMethod<String>('saveToGallery', {
      'filePath': filePath,
    });
  }

  @override
  Future<bool> startForegroundService({
    required String title,
    required String content,
  }) async {
    final result = await methodChannel.invokeMethod<bool>(
      'startForegroundService',
      {'title': title, 'content': content},
    );
    return result ?? false;
  }

  @override
  Future<bool> stopForegroundService() async {
    final result =
        await methodChannel.invokeMethod<bool>('stopForegroundService');
    return result ?? false;
  }
}
