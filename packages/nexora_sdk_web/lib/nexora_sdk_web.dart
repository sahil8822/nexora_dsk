import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';
import 'dart:typed_data';

import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:nexora_sdk_platform_interface/core/hardware_core.dart';
import 'package:nexora_sdk_platform_interface/models/device_models.dart';
import 'package:nexora_sdk_platform_interface/models/hardware_models.dart';
import 'package:nexora_sdk_platform_interface/models/permission_models.dart';
import 'package:nexora_sdk_platform_interface/nexora_sdk_platform_interface.dart';
import 'package:web/web.dart' as web;

/// Web implementation for browsers.
class NexoraSdkWeb extends NexoraSdkPlatform {
  final StreamController<HardwareEvent> _eventController =
      StreamController<HardwareEvent>.broadcast();

  static void registerWith(Registrar registrar) {
    NexoraSdkPlatform.instance = NexoraSdkWeb();
  }

  @override
  Stream<HardwareEvent> get unifiedStream => _eventController.stream;

  @override
  Future<String?> getPlatformVersion() async {
    return 'Web';
  }

  @override
  Future<bool> requestPermissions() async => false;

  @override
  Future<bool> requestCameraPermission() async => false;

  @override
  Future<bool> requestAudioPermission() async => false;

  @override
  Future<bool> requestLocationPermission() async => false;

  @override
  Future<bool> requestBluetoothPermission() async => false;

  @override
  Future<HardwarePermissionStatus> getPermissionStatus(
    HardwarePermission permission,
  ) async {
    return HardwarePermissionStatus(
      permission: permission,
      state: HardwarePermissionState.unsupported,
      canRequest: false,
    );
  }

  @override
  Future<bool> openAppSettings() async => false;

  @override
  Future<DeviceInfo> getDeviceInfo() async {
    return const DeviceInfo(
      platform: 'web',
      manufacturer: 'browser',
      model: 'browser',
      osVersion: 'web',
      sdkVersion: 'web',
      isPhysicalDevice: true,
      totalRamBytes: 0,
      availableRamBytes: 0,
      cpuArchitecture: 'unknown',
      screenRefreshRate: 0,
      thermalState: 'unknown',
    );
  }

  @override
  Future<ConnectivityInfo> getConnectivityInfo() async {
    return ConnectivityInfo(
      isConnected: web.window.navigator.onLine,
      networkType: 'browser',
      isMetered: false,
      isVpn: false,
      signalStrength: null,
      ipAddress: null,
    );
  }

  @override
  Future<dynamic> startCamera({int width = 1280, int height = 720}) async {
    return false;
  }

  @override
  Future<dynamic> startCameraWithOptions(CameraOptions options) async {
    return false;
  }

  @override
  Future<bool> stopCamera() async => true;

  @override
  Future<bool> setVisionMode({bool barcode = false, bool face = false}) async {
    return false;
  }

  @override
  Future<bool> registerCustomClassifier({
    required String modelAssetPath,
    required List<String> labels,
    double threshold = 0.5,
  }) async {
    return false;
  }

  @override
  Future<bool> setFlash(bool on) async => false;

  @override
  Future<bool> setZoom(double level) async => false;

  @override
  Future<bool> flipCamera() async => false;

  @override
  Future<String?> takePhoto({String? fileName}) async => null;

  @override
  Future<String?> startVideoRecording({String? fileName}) async => null;

  @override
  Future<String?> stopVideoRecording() async => null;

  @override
  Future<bool> startAudio({
    bool enableFFT = false,
    bool streamBytes = false,
    int updateIntervalMs = 80,
  }) async {
    return false;
  }

  @override
  Future<bool> startAudioWithOptions(AudioOptions options) async {
    return false;
  }

  @override
  Future<bool> stopAudio() async => true;

  @override
  Future<bool> routeAudioOutput(AudioOutputRoute route) async => true;

  @override
  Future<double> getAudioVolume() async => 0.5;

  @override
  Future<bool> setAudioVolume(double level) async => true;

  @override
  Future<bool> selectAudioInput(AudioInputDevice device) async => true;

  @override
  Future<bool> setAudioGain(double gain) async => true;

  @override
  Future<bool> startHardwareLogging(LogConfig config) async => false;

  @override
  Future<bool> stopHardwareLogging() async => true;

  @override
  Future<bool> addGeofence(
    String id,
    double lat,
    double lon,
    double radius,
  ) async {
    return false;
  }

  @override
  Future<bool> startBluetoothScan() async => false;

  @override
  Future<bool> startBluetoothScanWithOptions(
    BluetoothScanOptions options,
  ) async => false;

  @override
  Future<bool> stopBluetoothScan() async => true;

  @override
  Future<bool> connectDevice(String id) async => false;

  @override
  Future<bool> disconnectDevice(String id) async => false;

  @override
  Future<List<String>> discoverServices(String deviceId) async => [];

  @override
  Future<bool> sendData(
    String deviceId,
    String serviceId,
    String charId,
    List<int> data,
  ) async {
    return false;
  }

  @override
  Future<Uint8List?> readData(
    String deviceId,
    String serviceId,
    String charId,
  ) async {
    return null;
  }

  @override
  Future<bool> authenticate(String reason) async => false;

  @override
  Future<bool> authenticateWithOptions(BiometricPromptOptions options) async =>
      false;

  @override
  Future<bool> canAuthenticate() async => false;

  @override
  Future<void> vibrate(int durationMs) async {}

  @override
  Future<void> hapticFeedback(String type) async {}

  @override
  Future<void> performHapticWithOptions(HapticOptions options) async {}

  @override
  Future<BatteryInfo?> getBatteryInfo() async => null;

  @override
  Future<WifiInfo?> getWifiInfo() async => null;

  @override
  Future<bool> startLocation() async => false;

  @override
  Future<bool> startLocationWithOptions(LocationOptions options) async => false;

  @override
  Future<bool> stopLocation() async => true;

  @override
  Future<bool> setBackgroundLocationEnabled(bool enabled) async => false;

  @override
  Future<bool> startSensor({int frequencyHz = 60}) async => false;

  @override
  Future<bool> startSensorWithOptions(SensorOptions options) async => false;

  @override
  Future<bool> stopSensor() async => true;

  @override
  Future<StorageInfo?> getStorageInfo() async {
    final size = _storageEntries().fold<int>(
      0,
      (total, entry) => total + entry.key.length + _valueSize(entry.value),
    );
    return StorageInfo(
      internalTotal: 0,
      internalFree: 0,
      externalTotal: 0,
      externalFree: 0,
      appCacheSize: 0,
      appDataSize: size,
    );
  }

  @override
  Future<String?> writeFile(String fileName, String content) async {
    web.window.localStorage.setItem(
      _key(fileName),
      jsonEncode({
        'type': 'text',
        'value': content,
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      }),
    );
    return fileName;
  }

  @override
  Future<String?> appendFile(String fileName, String content) async {
    final key = _key(fileName);
    final current = await readFile(fileName) ?? '';
    web.window.localStorage.setItem(
      key,
      jsonEncode({
        'type': 'text',
        'value': '$current$content',
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      }),
    );
    return fileName;
  }

  @override
  Future<String?> readFile(String fileName) async {
    final value = _decodeStoredValue(fileName);
    return value != null && value['type'] == 'text'
        ? value['value'] as String?
        : null;
  }

  @override
  Future<bool> deleteFile(String fileName) async {
    final key = _key(fileName);
    final existed = web.window.localStorage.getItem(key) != null;
    web.window.localStorage.removeItem(key);
    return existed;
  }

  @override
  Future<bool> fileExists(String fileName) async {
    return web.window.localStorage.getItem(_key(fileName)) != null;
  }

  @override
  Future<List<FileInfo>> listFiles() async {
    return _storageEntries().map((entry) {
      final decoded = _decodeRawValue(entry.value);
      return FileInfo(
        name: entry.key.substring(_storagePrefix.length),
        size: _valueSize(entry.value),
        isDirectory: false,
        lastModified: DateTime.fromMillisecondsSinceEpoch(
          decoded?['updatedAt'] as int? ?? 0,
        ),
      );
    }).toList();
  }

  @override
  Future<String?> writeBytes(String fileName, Uint8List bytes) async {
    web.window.localStorage.setItem(
      _key(fileName),
      jsonEncode({
        'type': 'bytes',
        'value': base64Encode(bytes),
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      }),
    );
    return fileName;
  }

  @override
  Future<Uint8List?> readBytes(String fileName) async {
    final value = _decodeStoredValue(fileName);
    if (value == null || value['type'] != 'bytes') return null;
    return base64Decode(value['value']! as String);
  }

  @override
  Future<bool> clearCache() async {
    final keys = _storageKeys().toList(growable: false);
    for (final key in keys) {
      web.window.localStorage.removeItem(key);
    }
    return true;
  }

  @override
  Future<String?> getAppDirectory() async => 'localStorage://nexora_sdk';

  @override
  Future<String?> getCacheDirectory() async => 'memory://nexora_sdk/cache';

  @override
  Future<String?> getExternalDirectory() async => null;

  @override
  Future<bool> copyText(String text) async {
    try {
      final clipboard = web.window.navigator.clipboard;
      await clipboard.writeText(text).toDart;
      return true;
    } catch (_) {
      try {
        final textArea = web.HTMLTextAreaElement()
          ..value = text
          ..style.position = 'fixed'
          ..style.left = '-9999px';
        web.document.body?.appendChild(textArea);
        textArea.select();
        final success = web.document.execCommand('copy');
        textArea.remove();
        return success;
      } catch (_) {
        return false;
      }
    }
  }

  @override
  Future<String?> pasteText() async => null;

  @override
  Future<bool> openUrl(String url) async {
    web.window.open(url, '_blank');
    return true;
  }

  @override
  Future<bool> shareText(String text, {String? subject}) => copyText(text);

  @override
  Future<bool> enableSmartSync({
    required String uploadEndpointUrl,
    required Map<String, String> headers,
    int rollLimitBytes = 2 * 1024 * 1024,
    bool requireWifi = true,
  }) async => false;

  @override
  Future<bool> applyCameraFilterShader(String shaderType) async => false;

  @override
  Stream<Uint8List> openL2capStream(String deviceId, int psm) =>
      const Stream.empty();

  @override
  Future<bool> enableDeadReckoning(bool enabled) async => false;

  @override
  Future<void> setEcoModeEnabled(bool enabled) async {}

  @override
  Future<bool> isEcoModeActive() async => false;

  @override
  Future<DeviceThermalState> getThermalState() async =>
      DeviceThermalState.normal;

  static const String _storagePrefix = 'nexora_sdk:file:';

  String _key(String fileName) => '$_storagePrefix$fileName';

  Map<String, Object?>? _decodeStoredValue(String fileName) {
    return _decodeRawValue(web.window.localStorage.getItem(_key(fileName)));
  }

  Map<String, Object?>? _decodeRawValue(String? value) {
    if (value == null) return null;
    try {
      final decoded = jsonDecode(value);
      return decoded is Map ? decoded.cast<String, Object?>() : null;
    } catch (_) {
      return null;
    }
  }

  int _valueSize(Object value) {
    if (value is String) return value.length;
    return 0;
  }

  Iterable<String> _storageKeys() sync* {
    final storage = web.window.localStorage;
    for (var index = 0; index < storage.length; index += 1) {
      final key = storage.key(index);
      if (key != null && key.startsWith(_storagePrefix)) {
        yield key;
      }
    }
  }

  Iterable<MapEntry<String, String>> _storageEntries() sync* {
    final storage = web.window.localStorage;
    for (final key in _storageKeys()) {
      final value = storage.getItem(key);
      if (value != null) {
        yield MapEntry<String, String>(key, value);
      }
    }
  }
}
