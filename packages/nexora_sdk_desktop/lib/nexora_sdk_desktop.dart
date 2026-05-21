import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:nexora_sdk_platform_interface/core/hardware_core.dart';
import 'package:nexora_sdk_platform_interface/models/device_models.dart';
import 'package:nexora_sdk_platform_interface/models/hardware_exception.dart';
import 'package:nexora_sdk_platform_interface/models/hardware_models.dart';
import 'package:nexora_sdk_platform_interface/models/permission_models.dart';
import 'package:nexora_sdk_platform_interface/nexora_sdk_platform_interface.dart';

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
  Future<bool> requestPermissions() async =>
      throw HardwareException.unsupported('unsupported');

  @override
  Future<bool> requestCameraPermission() async =>
      throw HardwareException.unsupported('unsupported');

  @override
  Future<bool> requestAudioPermission() async =>
      throw HardwareException.unsupported('unsupported');

  @override
  Future<bool> requestLocationPermission() async =>
      throw HardwareException.unsupported('unsupported');

  @override
  Future<bool> requestBluetoothPermission() async =>
      throw HardwareException.unsupported('unsupported');

  @override
  Future<HardwarePermissionStatus> getPermissionStatus(
    HardwarePermission permission,
  ) async {
    throw HardwareException.unsupported('getPermissionStatus');
  }

  @override
  Future<bool> openAppSettings() async =>
      throw HardwareException.unsupported('unsupported');

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
    throw HardwareException.unsupported('startCamera');
  }

  @override
  Future<dynamic> startCameraWithOptions(CameraOptions options) async {
    throw HardwareException.unsupported('startCameraWithOptions');
  }

  @override
  Future<bool> stopCamera() async =>
      throw HardwareException.unsupported('unsupported');

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
      throw HardwareException.unsupported('unsupported');

  @override
  Future<bool> setZoom(double level) async =>
      throw HardwareException.unsupported('unsupported');

  @override
  Future<bool> flipCamera() async =>
      throw HardwareException.unsupported('unsupported');

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
  Future<bool> stopAudio() async =>
      throw HardwareException.unsupported('unsupported');

  @override
  Future<bool> routeAudioOutput(AudioOutputRoute route) async =>
      throw HardwareException.unsupported('unsupported');

  @override
  Future<double> getAudioVolume() async =>
      throw HardwareException.unsupported('getAudioVolume');

  @override
  Future<bool> setAudioVolume(double level) async =>
      throw HardwareException.unsupported('unsupported');

  @override
  Future<bool> selectAudioInput(AudioInputDevice device) async =>
      throw HardwareException.unsupported('unsupported');

  @override
  Future<bool> setAudioGain(double gain) async =>
      throw HardwareException.unsupported('unsupported');

  @override
  Future<bool> startHardwareLogging(LogConfig config) async =>
      throw HardwareException.unsupported('unsupported');

  @override
  Future<bool> stopHardwareLogging() async =>
      throw HardwareException.unsupported('unsupported');

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
  Future<bool> startBluetoothScan() async =>
      throw HardwareException.unsupported('unsupported');

  @override
  Future<bool> startBluetoothScanWithOptions(
    BluetoothScanOptions options,
  ) async =>
      throw HardwareException.unsupported('unsupported');

  @override
  Future<bool> stopBluetoothScan() async =>
      throw HardwareException.unsupported('unsupported');

  @override
  Future<bool> connectDevice(String id) async =>
      throw HardwareException.unsupported('unsupported');

  @override
  Future<bool> disconnectDevice(String id) async =>
      throw HardwareException.unsupported('unsupported');

  @override
  Future<List<String>> discoverServices(String deviceId) async =>
      throw HardwareException.unsupported('unsupported');

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
      throw HardwareException.unsupported('unsupported');

  @override
  Future<bool> authenticateWithOptions(BiometricPromptOptions options) async =>
      throw HardwareException.unsupported('unsupported');

  @override
  Future<bool> canAuthenticate() async =>
      throw HardwareException.unsupported('unsupported');

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
  Future<BatteryInfo?> getBatteryInfo() async =>
      throw HardwareException.unsupported('getBatteryInfo');

  @override
  Future<WifiInfo?> getWifiInfo() async =>
      throw HardwareException.unsupported('getWifiInfo');

  @override
  Future<bool> startLocation() async =>
      throw HardwareException.unsupported('unsupported');

  @override
  Future<bool> startLocationWithOptions(LocationOptions options) async =>
      throw HardwareException.unsupported('unsupported');

  @override
  Future<bool> stopLocation() async =>
      throw HardwareException.unsupported('unsupported');

  @override
  Future<bool> setBackgroundLocationEnabled(bool enabled) async =>
      throw HardwareException.unsupported('unsupported');

  @override
  Future<bool> startSensor({int frequencyHz = 60}) async =>
      throw HardwareException.unsupported('unsupported');

  @override
  Future<bool> startSensorWithOptions(SensorOptions options) async =>
      throw HardwareException.unsupported('unsupported');

  @override
  Future<bool> stopSensor() async =>
      throw HardwareException.unsupported('unsupported');

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
  Future<String?> appendFile(String fileName, String content) async {
    final file = await _file(fileName);
    await file.parent.create(recursive: true);
    await file.writeAsString(content, mode: FileMode.append);
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
  Future<bool> copyText(String text) async {
    try {
      if (Platform.isMacOS) {
        final process = await Process.start('pbcopy', const []);
        process.stdin.write(text);
        await process.stdin.close();
        return await process.exitCode == 0;
      }
      if (Platform.isWindows) {
        final process = await Process.start('clip', const []);
        process.stdin.write(text);
        await process.stdin.close();
        return await process.exitCode == 0;
      }
      return await _runClipboardWriteLinux(text);
    } catch (_) {
      return false;
    }
  }

  @override
  Future<String?> pasteText() async {
    try {
      if (Platform.isMacOS) {
        return await _readProcessText('pbpaste', const []);
      }
      if (Platform.isWindows) {
        return await _readProcessText('powershell', const [
          '-NoProfile',
          '-Command',
          'Get-Clipboard',
        ]);
      }
      return await _readClipboardLinux();
    } catch (_) {
      return null;
    }
  }

  @override
  Future<bool> openUrl(String url) async {
    try {
      final command = Platform.isMacOS
          ? 'open'
          : Platform.isWindows
              ? 'rundll32'
              : 'xdg-open';
      final args = Platform.isWindows
          ? <String>['url.dll,FileProtocolHandler', url]
          : <String>[url];
      final result = await Process.run(command, args);
      return result.exitCode == 0;
    } catch (_) {
      return false;
    }
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
      throw HardwareException.unsupported('unsupported');

  @override
  Future<bool> applyCameraFilterShader(String shaderType) async =>
      throw HardwareException.unsupported('unsupported');

  @override
  Stream<Uint8List> openL2capStream(String deviceId, int psm) =>
      throw HardwareException.unsupported('openL2capStream');

  @override
  Future<bool> enableDeadReckoning(bool enabled) async =>
      throw HardwareException.unsupported('unsupported');

  @override
  Future<void> setEcoModeEnabled(bool enabled) async {
    throw HardwareException.unsupported('setEcoModeEnabled');
  }

  @override
  Future<bool> isEcoModeActive() async =>
      throw HardwareException.unsupported('unsupported');

  @override
  Future<DeviceThermalState> getThermalState() async =>
      throw HardwareException.unsupported('getThermalState');

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

  Future<bool> _runClipboardWriteLinux(String text) async {
    for (final command in const ['wl-copy', 'xclip', 'xsel']) {
      try {
        final args = switch (command) {
          'xclip' => const ['-selection', 'clipboard'],
          'xsel' => const ['--clipboard', '--input'],
          _ => const <String>[],
        };
        final process = await Process.start(command, args);
        process.stdin.write(text);
        await process.stdin.close();
        if (await process.exitCode == 0) return true;
      } catch (_) {}
    }
    return false;
  }

  Future<String?> _readClipboardLinux() async {
    for (final command in const ['wl-paste', 'xclip', 'xsel']) {
      try {
        final args = switch (command) {
          'xclip' => const ['-selection', 'clipboard', '-o'],
          'xsel' => const ['--clipboard', '--output'],
          _ => const <String>[],
        };
        final text = await _readProcessText(command, args);
        if (text != null) return text;
      } catch (_) {}
    }
    return null;
  }

  Future<String?> _readProcessText(String command, List<String> args) async {
    final result = await Process.run(command, args);
    if (result.exitCode != 0) return null;
    final output = result.stdout?.toString();
    return output?.isEmpty == true ? null : output;
  }
}
