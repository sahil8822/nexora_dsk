import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_web_plugins/flutter_web_plugins.dart';

import 'core/hardware_core.dart';
import 'models/device_models.dart';
import 'models/hardware_models.dart';
import 'models/permission_models.dart';
import 'nexora_sdk_platform_interface.dart';

/// Web implementation for browsers.
class NexoraSdkWeb extends NexoraSdkPlatform {
  final StreamController<HardwareEvent> _eventController =
      StreamController<HardwareEvent>.broadcast();
  final Map<String, Object> _storage = <String, Object>{};

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
  Future<bool> requestPermissions() async => true;

  @override
  Future<bool> requestCameraPermission() async => true;

  @override
  Future<bool> requestAudioPermission() async => true;

  @override
  Future<bool> requestLocationPermission() async => true;

  @override
  Future<bool> requestBluetoothPermission() async => true;

  @override
  Future<HardwarePermissionStatus> getPermissionStatus(
    HardwarePermission permission,
  ) async {
    return HardwarePermissionStatus(
      permission: permission,
      state: permission == HardwarePermission.bluetooth
          ? HardwarePermissionState.unsupported
          : HardwarePermissionState.granted,
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
    return const ConnectivityInfo(
      isConnected: true,
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
  Future<bool> stopCamera() async => true;

  @override
  Future<bool> setVisionMode({bool barcode = false, bool face = false}) async {
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
  Future<bool> stopAudio() async => true;

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
  Future<bool> stopBluetoothScan() async => true;

  @override
  Future<bool> connectDevice(String id) async => false;

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
  Future<bool> authenticate(String reason) async => false;

  @override
  Future<bool> canAuthenticate() async => false;

  @override
  Future<void> vibrate(int durationMs) async {}

  @override
  Future<void> hapticFeedback(String type) async {}

  @override
  Future<BatteryInfo?> getBatteryInfo() async => null;

  @override
  Future<WifiInfo?> getWifiInfo() async => null;

  @override
  Future<bool> startLocation() async => false;

  @override
  Future<bool> stopLocation() async => true;

  @override
  Future<bool> setBackgroundLocationEnabled(bool enabled) async => false;

  @override
  Future<bool> startSensor({int frequencyHz = 60}) async => false;

  @override
  Future<bool> stopSensor() async => true;

  @override
  Future<StorageInfo?> getStorageInfo() async {
    final size = _storage.entries.fold<int>(
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
    _storage[_key(fileName)] = content;
    return fileName;
  }

  @override
  Future<String?> readFile(String fileName) async {
    final value = _storage[_key(fileName)];
    return value is String ? value : null;
  }

  @override
  Future<bool> deleteFile(String fileName) async {
    return _storage.remove(_key(fileName)) != null;
  }

  @override
  Future<bool> fileExists(String fileName) async {
    return _storage.containsKey(_key(fileName));
  }

  @override
  Future<List<FileInfo>> listFiles() async {
    return _storage.entries
        .where((entry) => entry.key.startsWith(_storagePrefix))
        .map(
          (entry) => FileInfo(
            name: entry.key.substring(_storagePrefix.length),
            size: _valueSize(entry.value),
            isDirectory: false,
            lastModified: DateTime.now(),
          ),
        )
        .toList();
  }

  @override
  Future<String?> writeBytes(String fileName, Uint8List bytes) async {
    _storage[_key(fileName)] = Uint8List.fromList(bytes);
    return fileName;
  }

  @override
  Future<Uint8List?> readBytes(String fileName) async {
    final value = _storage[_key(fileName)];
    return value is Uint8List ? Uint8List.fromList(value) : null;
  }

  @override
  Future<bool> clearCache() async => true;

  @override
  Future<String?> getAppDirectory() async => 'localStorage://nexora_sdk';

  @override
  Future<String?> getCacheDirectory() async => 'memory://nexora_sdk/cache';

  @override
  Future<String?> getExternalDirectory() async => null;

  @override
  Future<bool> copyText(String text) async => false;

  @override
  Future<String?> pasteText() async => null;

  @override
  Future<bool> openUrl(String url) async => false;

  @override
  Future<bool> shareText(String text, {String? subject}) async => false;

  static const String _storagePrefix = 'nexora_sdk:file:';

  String _key(String fileName) => '$_storagePrefix$fileName';

  int _valueSize(Object value) {
    if (value is Uint8List) return value.length;
    if (value is String) return value.length;
    return 0;
  }
}
