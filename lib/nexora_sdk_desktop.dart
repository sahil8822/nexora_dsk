import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'core/hardware_core.dart';
import 'models/device_models.dart';
import 'models/hardware_models.dart';
import 'models/permission_models.dart';
import 'nexora_sdk_platform_interface.dart';

/// Desktop fallback implementation for Linux, macOS, and Windows.
///
/// Mobile-only hardware features return safe unsupported values. Storage APIs
/// are implemented with local files so desktop apps can still use the common
/// Nexora SDK surface without platform-channel crashes.
class NexoraSdkDesktop extends NexoraSdkPlatform {
  final StreamController<HardwareEvent> _eventController =
      StreamController<HardwareEvent>.broadcast();

  static void registerWith() {
    NexoraSdkPlatform.instance = NexoraSdkDesktop();
  }

  @override
  Stream<HardwareEvent> get unifiedStream => _eventController.stream;

  @override
  Future<String?> getPlatformVersion() async {
    return '${Platform.operatingSystem} ${Platform.operatingSystemVersion}';
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
      state: HardwarePermissionState.granted,
      canRequest: false,
    );
  }

  @override
  Future<bool> openAppSettings() async => false;

  @override
  Future<DeviceInfo> getDeviceInfo() async {
    return DeviceInfo(
      platform: Platform.operatingSystem,
      manufacturer: Platform.operatingSystem,
      model: Platform.localHostname,
      osVersion: Platform.operatingSystemVersion,
      sdkVersion: Platform.version,
      isPhysicalDevice: true,
      totalRamBytes: 0,
      availableRamBytes: 0,
      cpuArchitecture: _cpuArchitecture(),
      screenRefreshRate: 0,
      thermalState: 'unknown',
    );
  }

  @override
  Future<ConnectivityInfo> getConnectivityInfo() async {
    return const ConnectivityInfo(
      isConnected: true,
      networkType: 'desktop',
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
    final appDir = await _appDirectory();
    final tempDir = await _cacheDirectory();
    await appDir.create(recursive: true);
    await tempDir.create(recursive: true);

    final stat = await appDir.stat();
    final cacheSize = await _directorySize(tempDir);
    final dataSize = await _directorySize(appDir);

    return StorageInfo(
      internalTotal: 0,
      internalFree: 0,
      externalTotal: 0,
      externalFree: 0,
      appCacheSize: stat.type == FileSystemEntityType.directory ? cacheSize : 0,
      appDataSize: dataSize,
    );
  }

  @override
  Future<String?> writeFile(String fileName, String content) async {
    final file = await _file(fileName);
    await file.parent.create(recursive: true);
    await file.writeAsString(content);
    return file.path;
  }

  @override
  Future<String?> readFile(String fileName) async {
    final file = await _file(fileName);
    if (!await file.exists()) return null;
    return file.readAsString();
  }

  @override
  Future<bool> deleteFile(String fileName) async {
    final file = await _file(fileName);
    if (!await file.exists()) return false;
    await file.delete();
    return true;
  }

  @override
  Future<bool> fileExists(String fileName) async {
    return (await _file(fileName)).exists();
  }

  @override
  Future<List<FileInfo>> listFiles() async {
    final dir = await _appDirectory();
    if (!await dir.exists()) return [];

    final entries = await dir.list().toList();
    final files = <FileInfo>[];
    for (final entry in entries) {
      final stat = await entry.stat();
      files.add(
        FileInfo(
          name: entry.uri.pathSegments.last,
          size: stat.type == FileSystemEntityType.file ? stat.size : 0,
          isDirectory: stat.type == FileSystemEntityType.directory,
          lastModified: stat.modified,
        ),
      );
    }
    return files;
  }

  @override
  Future<String?> writeBytes(String fileName, Uint8List bytes) async {
    final file = await _file(fileName);
    await file.parent.create(recursive: true);
    await file.writeAsBytes(bytes);
    return file.path;
  }

  @override
  Future<Uint8List?> readBytes(String fileName) async {
    final file = await _file(fileName);
    if (!await file.exists()) return null;
    return file.readAsBytes();
  }

  @override
  Future<bool> clearCache() async {
    final dir = await _cacheDirectory();
    if (await dir.exists()) {
      await dir.delete(recursive: true);
    }
    await dir.create(recursive: true);
    return true;
  }

  @override
  Future<String?> getAppDirectory() async => (await _appDirectory()).path;

  @override
  Future<String?> getCacheDirectory() async => (await _cacheDirectory()).path;

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

  Future<File> _file(String fileName) async {
    final safeName = fileName.replaceAll(
      RegExp(r'[\\/]+'),
      Platform.pathSeparator,
    );
    return File(
      '${(await _appDirectory()).path}${Platform.pathSeparator}$safeName',
    );
  }

  Future<Directory> _appDirectory() async {
    final base = _dataHome();
    return Directory('$base${Platform.pathSeparator}nexora_sdk');
  }

  Future<Directory> _cacheDirectory() async {
    return Directory(
      '${Directory.systemTemp.path}${Platform.pathSeparator}nexora_sdk',
    );
  }

  String _dataHome() {
    if (Platform.isWindows) {
      return Platform.environment['APPDATA'] ?? Directory.systemTemp.path;
    }
    if (Platform.isMacOS) {
      final home = Platform.environment['HOME'];
      if (home != null && home.isNotEmpty) {
        return '$home/Library/Application Support';
      }
    }
    return Platform.environment['XDG_DATA_HOME'] ??
        '${Platform.environment['HOME'] ?? Directory.systemTemp.path}/.local/share';
  }

  String _cpuArchitecture() {
    final executable = Platform.resolvedExecutable.toLowerCase();
    if (executable.contains('arm64') || executable.contains('aarch64')) {
      return 'arm64';
    }
    if (executable.contains('x64') || executable.contains('x86_64')) {
      return 'x64';
    }
    return Platform.version.contains('arm64') ? 'arm64' : 'unknown';
  }

  Future<int> _directorySize(Directory directory) async {
    if (!await directory.exists()) return 0;
    var total = 0;
    await for (final entity in directory.list(recursive: true)) {
      if (entity is File) {
        total += await entity.length();
      }
    }
    return total;
  }
}
