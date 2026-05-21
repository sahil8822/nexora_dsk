// ignore_for_file: avoid_catches_without_on_clauses, avoid_web_libraries_in_flutter
import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'dart:typed_data';

import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:nexora_sdk_platform_interface/core/hardware_core.dart';
import 'package:nexora_sdk_platform_interface/models/device_models.dart';
import 'package:nexora_sdk_platform_interface/models/hardware_exception.dart';
import 'package:nexora_sdk_platform_interface/models/hardware_models.dart';
import 'package:nexora_sdk_platform_interface/models/permission_models.dart';
import 'package:nexora_sdk_platform_interface/nexora_sdk_platform_interface.dart';
import 'package:web/web.dart' as web;

/// Web implementation for browsers.
class NexoraSdkWeb extends NexoraSdkPlatform {
  final StreamController<HardwareEvent> _eventController =
      StreamController<HardwareEvent>.broadcast();

  int? _watchId;

  /// API Documentation for registerWith.
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
  Future<bool> requestPermissions({dynamic options}) async =>
      throw HardwareException.unsupported('requestPermissions');

  @override
  Future<bool> requestCameraPermission({dynamic options}) async =>
      throw HardwareException.unsupported('requestCameraPermission');

  @override
  Future<bool> requestAudioPermission({dynamic options}) async =>
      throw HardwareException.unsupported('requestAudioPermission');

  @override
  Future<bool> requestLocationPermission({dynamic options}) async =>
      throw HardwareException.unsupported('requestLocationPermission');

  @override
  Future<bool> requestBluetoothPermission({dynamic options}) async =>
      throw HardwareException.unsupported('requestBluetoothPermission');

  @override
  Future<HardwarePermissionStatus> getPermissionStatus(
    HardwarePermission permission,
  ) async {
    throw HardwareException.unsupported('getPermissionStatus');
  }

  @override
  Future<bool> openAppSettings({dynamic options}) async =>
      throw HardwareException.unsupported('openAppSettings');

  @override
  Future<DeviceInfo> getDeviceInfo() async {
    final nav = web.window.navigator;
    final ua = nav.userAgent.toLowerCase();

    var browser = 'unknown';
    if (ua.contains('chrome') && !ua.contains('edg')) {
      browser = 'chrome';
    } else if (ua.contains('safari') && !ua.contains('chrome')) {
      browser = 'safari';
    } else if (ua.contains('firefox')) {
      browser = 'firefox';
    } else if (ua.contains('edg')) {
      browser = 'edge';
    }

    var os = 'unknown';
    if (ua.contains('win')) {
      os = 'windows';
    } else if (ua.contains('mac')) {
      os = 'macos';
    } else if (ua.contains('linux')) {
      os = 'linux';
    } else if (ua.contains('android')) {
      os = 'android';
    } else if (ua.contains('like mac os x')) {
      os = 'ios';
    }

    return DeviceInfo(
      platform: 'web',
      manufacturer: browser,
      model: os,
      osVersion: nav.appVersion,
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
    final nav = web.window.navigator;
    final isConnected = nav.onLine;
    var networkType = 'browser';
    var isMetered = false;

    if (nav.hasProperty('connection'.toJS).toDart) {
      final conn = nav.getProperty('connection'.toJS)! as JSObject;
      if (conn.hasProperty('effectiveType'.toJS).toDart) {
        networkType =
            (conn.getProperty('effectiveType'.toJS)! as JSString).toDart;
      }
      if (conn.hasProperty('saveData'.toJS).toDart) {
        isMetered = (conn.getProperty('saveData'.toJS)! as JSBoolean).toDart;
      }
    }

    return ConnectivityInfo(
      isConnected: isConnected,
      networkType: networkType,
      isMetered: isMetered,
      isVpn: false,
      signalStrength: null,
      ipAddress: null,
    );
  }

  @override
  Future<int?> startCamera({int width = 1280, int height = 720}) async {
    throw HardwareException.unsupported('startCamera');
  }

  @override
  Future<int?> startCameraWithOptions(CameraOptions options) async {
    throw HardwareException.unsupported('startCameraWithOptions');
  }

  @override
  Future<bool> stopCamera() async => true;

  @override
  Future<bool> setVisionMode({bool barcode = false, bool face = false}) async {
    throw HardwareException.unsupported('setVisionMode');
  }

  @override
  Future<bool> registerCustomClassifier({
    required String modelAssetPath,
    required List<String> labels,
    double threshold = 0.5,
  }) async {
    throw HardwareException.unsupported('registerCustomClassifier');
  }

  @override
  Future<bool> setFlash(bool on) async =>
      throw HardwareException.unsupported('setFlash');

  @override
  Future<bool> setZoom(double level) async =>
      throw HardwareException.unsupported('setZoom');

  @override
  Future<bool> flipCamera({dynamic options}) async =>
      throw HardwareException.unsupported('flipCamera');

  @override
  Future<String?> takePhoto({String? fileName}) async =>
      throw HardwareException.unsupported('takePhoto');

  @override
  Future<String?> startVideoRecording({String? fileName}) async =>
      throw HardwareException.unsupported('startVideoRecording');

  @override
  Future<String?> stopVideoRecording() async =>
      throw HardwareException.unsupported('stopVideoRecording');

  @override
  Future<bool> startAudio({
    bool enableFFT = false,
    bool streamBytes = false,
    int updateIntervalMs = 80,
  }) async {
    throw HardwareException.unsupported('startAudio');
  }

  @override
  Future<bool> startAudioWithOptions(AudioOptions options) async {
    throw HardwareException.unsupported('startAudioWithOptions');
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
    throw HardwareException.unsupported('addGeofence');
  }

  @override
  Future<bool> startBluetoothScan({dynamic options}) async =>
      throw HardwareException.unsupported('startBluetoothScan');

  @override
  Future<bool> startBluetoothScanWithOptions(
    BluetoothScanOptions options,
  ) async =>
      throw HardwareException.unsupported('startBluetoothScanWithOptions');

  @override
  Future<bool> stopBluetoothScan() async => true;

  @override
  Future<bool> connectDevice(String id) async =>
      throw HardwareException.unsupported('connectDevice');

  @override
  Future<bool> disconnectDevice(String id) async =>
      throw HardwareException.unsupported('disconnectDevice');

  @override
  Future<List<String>> discoverServices(String deviceId) async =>
      throw HardwareException.unsupported('discoverServices');

  @override
  Future<bool> sendData(
    String deviceId,
    String serviceId,
    String charId,
    List<int> data,
  ) async {
    throw HardwareException.unsupported('sendData');
  }

  @override
  Future<Uint8List?> readData(
    String deviceId,
    String serviceId,
    String charId,
  ) async {
    throw HardwareException.unsupported('readData');
  }

  @override
  Future<bool> authenticate(String reason) async =>
      throw HardwareException.unsupported('authenticate');

  @override
  Future<bool> authenticateWithOptions(BiometricPromptOptions options) async =>
      throw HardwareException.unsupported('authenticateWithOptions');

  @override
  Future<bool> canAuthenticate({dynamic options}) async =>
      throw HardwareException.unsupported('canAuthenticate');

  @override
  Future<void> vibrate(int durationMs) async {
    throw HardwareException.unsupported('vibrate');
  }

  @override
  Future<void> hapticFeedback(String type) async {
    throw HardwareException.unsupported('hapticFeedback');
  }

  @override
  Future<void> performHapticWithOptions(HapticOptions options) async {
    throw HardwareException.unsupported('performHapticWithOptions');
  }

  @override
  Future<BatteryInfo?> getBatteryInfo() async {
    try {
      final nav = web.window.navigator;
      if (!nav.hasProperty('getBattery'.toJS).toDart) {
        return null;
      }
      final promise = nav.callMethod<JSPromise>('getBattery'.toJS);
      final batteryManager = (await promise.toDart)! as JSObject;

      final levelJS = batteryManager.getProperty('level'.toJS)! as JSNumber;
      final chargingJS =
          batteryManager.getProperty('charging'.toJS)! as JSBoolean;

      return BatteryInfo(
        level: levelJS.toDartDouble,
        isCharging: chargingJS.toDart,
        status: chargingJS.toDart ? 'charging' : 'discharging',
        temperature: 0, // Unavailable on web
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Future<WifiInfo?> getWifiInfo() async => null;

  @override
  Future<bool> startLocation() async {
    try {
      final nav = web.window.navigator;
      if (!nav.hasProperty('geolocation'.toJS).toDart) {
        return false;
      }
      final geolocation = nav.getProperty('geolocation'.toJS)! as JSObject;

      // We'll broadcast the location
      final successCallback = ((JSObject position) {
        final coords = position.getProperty('coords'.toJS)! as JSObject;
        final lat =
            (coords.getProperty('latitude'.toJS)! as JSNumber).toDartDouble;
        final lng =
            (coords.getProperty('longitude'.toJS)! as JSNumber).toDartDouble;
        final alt = ((coords.getProperty('altitude'.toJS)) as JSNumber?)
                ?.toDartDouble ??
            0.0;
        final acc =
            (coords.getProperty('accuracy'.toJS)! as JSNumber).toDartDouble;
        final spd =
            ((coords.getProperty('speed'.toJS)) as JSNumber?)?.toDartDouble ??
                0.0;

        _eventController.add(
          HardwareEvent(
            module: 'location',
            type: 'location_update',
            data: LocationData(
              latitude: lat,
              longitude: lng,
              altitude: alt,
              accuracy: acc,
              speed: spd,
            ).toMap(),
            timestamp: DateTime.now(),
          ),
        );
      }).toJS;

      final errorCallback = ((JSObject error) {
        _eventController.add(
          HardwareEvent(
            module: 'location',
            type: 'location_error',
            data: {'error': 'Failed to get position'},
            timestamp: DateTime.now(),
          ),
        );
      }).toJS;

      geolocation.callMethod(
        'getCurrentPosition'.toJS,
        successCallback,
        errorCallback,
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> startLocationWithOptions(LocationOptions options) async {
    return startLocation();
  }

  @override
  Future<bool> stopLocation() async {
    if (_watchId != null) {
      try {
        final nav = web.window.navigator;
        final geolocation = nav.getProperty('geolocation'.toJS)! as JSObject;
        // ignore: cascade_invocations
        geolocation.callMethod('clearWatch'.toJS, _watchId!.toJS);
        _watchId = null;
      } catch (_) {}
    }
    return true;
  }

  @override
  Future<bool> setBackgroundLocationEnabled(bool enabled) async =>
      throw HardwareException.unsupported('setBackgroundLocationEnabled');

  @override
  Future<bool> startSensor({int frequencyHz = 60}) async =>
      throw HardwareException.unsupported('startSensor');

  @override
  Future<bool> startSensorWithOptions(SensorOptions options) async =>
      throw HardwareException.unsupported('startSensorWithOptions');

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
        final textArea = web.HTMLTextAreaElement()..value = text;
        textArea.style
          ..position = 'fixed'
          ..left = '-9999px';
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
  Future<String?> pasteText() async {
    try {
      final nav = web.window.navigator;
      if (!nav.hasProperty('clipboard'.toJS).toDart) return null;
      final clipboard = nav.getProperty('clipboard'.toJS)! as JSObject;
      final promise = clipboard.callMethod<JSPromise>('readText'.toJS);
      final textJs = (await promise.toDart)! as JSString;
      return textJs.toDart;
    } catch (_) {
      return null;
    }
  }

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
  }) async =>
      throw HardwareException.unsupported('enableSmartSync');

  @override
  Future<bool> applyCameraFilterShader(String shaderType) async =>
      throw HardwareException.unsupported('applyCameraFilterShader');

  @override
  Stream<Uint8List> openL2capStream(String deviceId, int psm) =>
      throw HardwareException.unsupported('openL2capStream');

  @override
  Future<bool> enableDeadReckoning(bool enabled) async =>
      throw HardwareException.unsupported('enableDeadReckoning');

  @override
  Future<void> setEcoModeEnabled(bool enabled) async {
    throw HardwareException.unsupported('setEcoModeEnabled');
  }

  @override
  Future<bool> isEcoModeActive({dynamic options}) async =>
      throw HardwareException.unsupported('isEcoModeActive');

  @override
  Future<DeviceThermalState> getThermalState() async =>
      throw HardwareException.unsupported('getThermalState');

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
