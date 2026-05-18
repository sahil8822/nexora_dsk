import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'nexora_sdk_platform_interface.dart';
import 'core/hardware_core.dart';
import 'models/device_models.dart';
import 'models/hardware_exception.dart';
import 'models/hardware_models.dart';
import 'models/permission_models.dart';

/// An implementation of [NexoraSdkPlatform] that uses method channels.
class MethodChannelNexoraSdk extends NexoraSdkPlatform {
  @visibleForTesting
  final methodChannel = const MethodChannel('nexora_sdk/methods');
  @visibleForTesting
  final eventChannel = const EventChannel('nexora_sdk/events');

  Future<T?> _invoke<T>(String method, [Object? arguments]) async {
    try {
      return await methodChannel.invokeMethod<T>(method, arguments);
    } on PlatformException catch (error) {
      throw HardwareException.fromPlatformException(error);
    }
  }

  @override
  Future<String?> getPlatformVersion() async {
    return await _invoke<String>('getPlatformVersion');
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
    final map = await methodChannel.invokeMapMethod('getPermissionStatus', {
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
    final map = await methodChannel.invokeMapMethod('getDeviceInfo');
    return DeviceInfo.fromMap(map ?? const <String, Object>{});
  }

  @override
  Future<ConnectivityInfo> getConnectivityInfo() async {
    final map = await methodChannel.invokeMapMethod('getConnectivityInfo');
    return ConnectivityInfo.fromMap(map ?? const <String, Object>{});
  }

  // --- Camera & Vision ---
  @override
  Future<dynamic> startCamera({int width = 1280, int height = 720}) async {
    return await _invoke<dynamic>('startCamera', {
      'width': width,
      'height': height,
    });
  }

  @override
  Future<dynamic> startCameraWithOptions(CameraOptions options) async {
    return await _invoke<dynamic>('startCameraWithOptions', options.toMap());
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
    return await _invoke<String>('takePhoto', {'fileName': fileName});
  }

  @override
  Future<String?> startVideoRecording({String? fileName}) async {
    return await _invoke<String>('startVideoRecording', {'fileName': fileName});
  }

  @override
  Future<String?> stopVideoRecording() async {
    return await _invoke<String>('stopVideoRecording');
  }

  // --- Audio ---
  @override
  Future<bool> startAudio({
    bool enableFFT = false,
    bool streamBytes = false,
    int updateIntervalMs = 80,
  }) async {
    return await methodChannel.invokeMethod<bool>('startAudio', {
          'enableFFT': enableFFT,
          'streamBytes': streamBytes,
          'updateIntervalMs': updateIntervalMs,
        }) ??
        false;
  }

  @override
  Future<bool> startAudioWithOptions(AudioOptions options) async {
    return await _invoke<bool>('startAudioWithOptions', options.toMap()) ?? false;
  }

  @override
  Future<bool> stopAudio() async {
    return await methodChannel.invokeMethod<bool>('stopAudio') ?? false;
  }

  @override
  Future<bool> routeAudioOutput(AudioOutputRoute route) async {
    return await methodChannel.invokeMethod<bool>('routeAudioOutput', {
          'route': route.name,
        }) ??
        false;
  }

  @override
  Future<double> getAudioVolume() async {
    return await methodChannel.invokeMethod<double>('getAudioVolume') ?? 0.5;
  }

  @override
  Future<bool> setAudioVolume(double level) async {
    return await methodChannel.invokeMethod<bool>('setAudioVolume', {
          'level': level,
        }) ??
        false;
  }

  @override
  Future<bool> selectAudioInput(AudioInputDevice device) async {
    return await methodChannel.invokeMethod<bool>('selectAudioInput', {
          'device': device.name,
        }) ??
        false;
  }

  @override
  Future<bool> setAudioGain(double gain) async {
    return await methodChannel.invokeMethod<bool>('setAudioGain', {
          'gain': gain,
        }) ??
        false;
  }

  // --- Intelligence & Logging ---
  @override
  Future<bool> startHardwareLogging(LogConfig config) async {
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
    return await methodChannel.invokeMethod<bool>('startBluetoothScan') ??
        false;
  }

  @override
  Future<bool> startBluetoothScanWithOptions(BluetoothScanOptions options) async {
    return await _invoke<bool>('startBluetoothScanWithOptions', options.toMap()) ?? false;
  }

  @override
  Future<bool> stopBluetoothScan() async {
    return await methodChannel.invokeMethod<bool>('stopBluetoothScan') ?? false;
  }

  @override
  Future<bool> connectDevice(String id) async {
    return await methodChannel.invokeMethod<bool>('connectDevice', {
          'id': id,
        }) ??
        false;
  }

  @override
  Future<List<String>> discoverServices(String deviceId) async {
    final services = await methodChannel.invokeListMethod<String>(
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
    return await methodChannel.invokeMethod<bool>('sendData', {
          'deviceId': deviceId,
          'serviceId': serviceId,
          'charId': charId,
          'data': data,
        }) ??
        false;
  }

  // --- Biometrics ---
  @override
  Future<bool> authenticate(String reason) async {
    return await methodChannel.invokeMethod<bool>('authenticate', {
          'reason': reason,
        }) ??
        false;
  }

  @override
  Future<bool> authenticateWithOptions(BiometricPromptOptions options) async {
    return await _invoke<bool>('authenticateWithOptions', options.toMap()) ?? false;
  }

  @override
  Future<bool> canAuthenticate() async {
    return await methodChannel.invokeMethod<bool>('canAuthenticate') ?? false;
  }

  // --- Feedback ---
  @override
  Future<void> vibrate(int durationMs) async {
    await methodChannel.invokeMethod('vibrate', {'duration': durationMs});
  }

  @override
  Future<void> hapticFeedback(String type) async {
    await methodChannel.invokeMethod('hapticFeedback', {'type': type});
  }

  @override
  Future<void> performHapticWithOptions(HapticOptions options) async {
    await _invoke<void>('performHapticWithOptions', options.toMap());
  }

  // --- Health ---
  @override
  Future<BatteryInfo?> getBatteryInfo() async {
    final map = await methodChannel.invokeMapMethod('getBatteryInfo');
    return map != null ? BatteryInfo.fromMap(map) : null;
  }

  @override
  Future<WifiInfo?> getWifiInfo() async {
    final map = await methodChannel.invokeMapMethod('getWifiInfo');
    return map != null ? WifiInfo.fromMap(map) : null;
  }

  // --- Location & Sensors ---
  @override
  Future<bool> startLocation() async {
    return await methodChannel.invokeMethod<bool>('startLocation') ?? false;
  }

  @override
  Future<bool> startLocationWithOptions(LocationOptions options) async {
    return await _invoke<bool>('startLocationWithOptions', options.toMap()) ?? false;
  }

  @override
  Future<bool> stopLocation() async {
    return await methodChannel.invokeMethod<bool>('stopLocation') ?? false;
  }

  @override
  Future<bool> setBackgroundLocationEnabled(bool enabled) async {
    return await methodChannel.invokeMethod<bool>(
          'setBackgroundLocationEnabled',
          {'enabled': enabled},
        ) ??
        false;
  }

  @override
  Future<bool> startSensor({int frequencyHz = 60}) async {
    return await methodChannel.invokeMethod<bool>('startSensor', {
          'frequency': frequencyHz,
        }) ??
        false;
  }

  @override
  Future<bool> startSensorWithOptions(SensorOptions options) async {
    return await _invoke<bool>('startSensorWithOptions', options.toMap()) ?? false;
  }

  @override
  Future<bool> stopSensor() async {
    return await methodChannel.invokeMethod<bool>('stopSensor') ?? false;
  }

  // ==================== Storage ====================

  @override
  Future<StorageInfo?> getStorageInfo() async {
    final map = await methodChannel.invokeMapMethod('getStorageInfo');
    return map != null ? StorageInfo.fromMap(map) : null;
  }

  @override
  Future<String?> writeFile(String fileName, String content) async {
    return await methodChannel.invokeMethod<String>('writeFile', {
      'fileName': fileName,
      'content': content,
    });
  }

  @override
  Future<String?> appendFile(String fileName, String content) async {
    return await methodChannel.invokeMethod<String>('appendFile', {
      'fileName': fileName,
      'content': content,
    });
  }

  @override
  Future<String?> readFile(String fileName) async {
    return await methodChannel.invokeMethod<String>('readFile', {
      'fileName': fileName,
    });
  }

  @override
  Future<bool> deleteFile(String fileName) async {
    return await methodChannel.invokeMethod<bool>('deleteFile', {
          'fileName': fileName,
        }) ??
        false;
  }

  @override
  Future<bool> fileExists(String fileName) async {
    return await methodChannel.invokeMethod<bool>('fileExists', {
          'fileName': fileName,
        }) ??
        false;
  }

  @override
  Future<List<FileInfo>> listFiles() async {
    final list = await methodChannel.invokeListMethod('listFiles');
    if (list == null) return [];
    return list.map((item) => FileInfo.fromMap(item as Map)).toList();
  }

  @override
  Future<String?> writeBytes(String fileName, Uint8List bytes) async {
    return await methodChannel.invokeMethod<String>('writeBytes', {
      'fileName': fileName,
      'bytes': bytes,
    });
  }

  @override
  Future<Uint8List?> readBytes(String fileName) async {
    return await methodChannel.invokeMethod<Uint8List>('readBytes', {
      'fileName': fileName,
    });
  }

  @override
  Future<bool> clearCache() async {
    return await methodChannel.invokeMethod<bool>('clearCache') ?? false;
  }

  @override
  Future<String?> getAppDirectory() async {
    return await methodChannel.invokeMethod<String>('getAppDirectory');
  }

  @override
  Future<String?> getCacheDirectory() async {
    return await methodChannel.invokeMethod<String>('getCacheDirectory');
  }

  @override
  Future<String?> getExternalDirectory() async {
    return await methodChannel.invokeMethod<String>('getExternalDirectory');
  }

  @override
  Future<bool> copyText(String text) async {
    return await _invoke<bool>('copyText', {'text': text}) ?? false;
  }

  @override
  Future<String?> pasteText() async {
    return await _invoke<String>('pasteText');
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
        .where((e) =>
            e.module == 'bluetooth' &&
            e.type == 'l2cap' &&
            (e.data as Map?)?['deviceId'] == deviceId &&
            (e.data as Map?)?['psm'] == psm)
        .map((e) => Uint8List.fromList(
            List<int>.from((e.data as Map?)?['bytes'] as List? ?? [])));
  }

  @override
  Future<bool> enableDeadReckoning(bool enabled) async {
    return await _invoke<bool>('enableDeadReckoning', {
          'enabled': enabled,
        }) ??
        false;
  }

  @override
  Future<void> setEcoModeEnabled(bool enabled) async {
    await methodChannel.invokeMethod('setEcoModeEnabled', {
      'enabled': enabled,
    });
  }

  @override
  Future<bool> isEcoModeActive() async {
    return await methodChannel.invokeMethod<bool>('isEcoModeActive') ?? false;
  }

  @override
  Future<DeviceThermalState> getThermalState() async {
    final stateStr = await methodChannel.invokeMethod<String>('getThermalState') ?? 'normal';
    return DeviceThermalState.values.firstWhere(
      (s) => s.name == stateStr,
      orElse: () => DeviceThermalState.normal,
    );
  }

  // --- Unified Stream ---
  @override
  Stream<HardwareEvent> get unifiedStream =>
      eventChannel.receiveBroadcastStream().map((data) {
        final map = data as Map;
        return HardwareEvent(
          module: map['module'] as String,
          type: map['type'] as String,
          data: map['data'],
          timestamp: DateTime.now(),
        );
      });
}
