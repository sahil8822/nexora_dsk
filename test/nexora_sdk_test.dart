import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexora_sdk/nexora_sdk.dart';
import 'package:nexora_sdk/nexora_sdk_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockNexoraSdkPlatform
    with MockPlatformInterfaceMixin
    implements NexoraSdkPlatform {
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
  Future<bool> startCamera({int width = 1280, int height = 720}) =>
      Future.value(true);
  @override
  Future<bool> stopCamera() => Future.value(true);
  @override
  Future<bool> setVisionMode({bool barcode = false, bool face = false}) =>
      Future.value(true);
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
  }) => Future.value(true);
  @override
  Future<bool> stopAudio() => Future.value(true);

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
  Future<bool> stopBluetoothScan() => Future.value(true);
  @override
  Future<bool> connectDevice(String id) => Future.value(true);
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
  Future<bool> authenticate(String reason) => Future.value(true);
  @override
  Future<bool> canAuthenticate() => Future.value(true);

  @override
  Future<void> vibrate(int durationMs) => Future.value();
  @override
  Future<void> hapticFeedback(String type) => Future.value();

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
  Future<bool> stopLocation() => Future.value(true);
  @override
  Future<bool> setBackgroundLocationEnabled(bool enabled) => Future.value(true);
  @override
  Future<bool> startSensor({int frequencyHz = 60}) => Future.value(true);
  @override
  Future<bool> stopSensor() => Future.value(true);

  @override
  Stream<HardwareEvent> get unifiedStream => const Stream.empty();
  @override
  Stream<CameraFrame> get cameraStream => const Stream.empty();
  @override
  Stream<AudioFrame> get audioStream => const Stream.empty();
  @override
  Stream<BleDevice> get bluetoothStream => const Stream.empty();
  @override
  Stream<LocationData> get locationStream => const Stream.empty();
  @override
  Stream<HardwareEvent> get sensorStream => const Stream.empty();

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
  Future<String?> getExternalDirectory() => Future.value(null);

  @override
  Future<bool> copyText(String text) => Future.value(true);
  @override
  Future<String?> pasteText() => Future.value('copied');
  @override
  Future<bool> openUrl(String url) => Future.value(true);
  @override
  Future<bool> shareText(String text, {String? subject}) => Future.value(true);
}

void main() {
  test('getPlatformVersion', () async {
    MockNexoraSdkPlatform fakePlatform = MockNexoraSdkPlatform();
    NexoraSdkPlatform.instance = fakePlatform;
    expect(await NexoraSdkPlatform.instance.getPlatformVersion(), '42');
  });

  group('NexoraSdk helpers', () {
    late MockNexoraSdkPlatform fakePlatform;

    setUp(() {
      fakePlatform = MockNexoraSdkPlatform();
      NexoraSdkPlatform.instance = fakePlatform;
    });

    test('reports platform capabilities', () {
      final sdk = NexoraSdk.instance;

      expect(sdk.capabilities.storage, isTrue);
      expect(sdk.supports(HardwareFeature.storage), isTrue);
      expect(sdk.capabilities.toMap(), containsPair('storage', true));
    });

    test('returns detailed permission report', () async {
      final report = await NexoraSdk.instance.requestPermissionReport();

      expect(report.allGranted, isTrue);
      expect(report.deniedPermissions, isEmpty);
      expect(report.toMap(), containsPair('camera', true));
    });

    test('returns permission status snapshot and opens settings', () async {
      final sdk = NexoraSdk.instance;
      final status = await sdk.permissions.status(HardwarePermission.camera);
      final snapshot = await sdk.getPermissionSnapshot();

      expect(status.isGranted, isTrue);
      expect(status.needsSettings, isFalse);
      expect(snapshot.allGranted, isTrue);
      expect(
        snapshot.statusFor(HardwarePermission.audio).state,
        HardwarePermissionState.granted,
      );
      expect(await sdk.openAppSettings(), isTrue);
    });

    test('attaches and disposes lifecycle controller', () {
      TestWidgetsFlutterBinding.ensureInitialized();

      final controller = NexoraSdk.instance.attachLifecycleController(
        stopCamera: false,
      );
      expect(controller.stopCamera, isFalse);
      controller.dispose();
    });

    test('collects diagnostics snapshot', () async {
      final diagnostics = await NexoraSdk.instance.collectDiagnostics();

      expect(diagnostics.platformVersion, '42');
      expect(diagnostics.storage?.internalTotal, 1000);
      expect(diagnostics.battery?.level, 75);
      expect(diagnostics.wifi?.ssid, 'test');
      expect(diagnostics.device?.model, 'Test Device');
      expect(diagnostics.connectivity?.networkType, 'wifi');
      expect(diagnostics.toMap(), contains('capabilities'));
    });

    test('returns device and connectivity info', () async {
      final sdk = NexoraSdk.instance;

      expect((await sdk.device.getInfo()).manufacturer, 'Nexora');
      expect((await sdk.getDeviceInfo()).cpuArchitecture, 'test64');
      expect((await sdk.connectivity.getInfo()).isConnected, isTrue);
      expect(await sdk.connectivity.isConnected, isTrue);
      expect((await sdk.getConnectivityInfo()).networkType, 'wifi');
    });

    test('validates event filters', () {
      expect(() => NexoraSdk.instance.eventsFor(''), throwsArgumentError);
      expect(() => NexoraSdk.instance.eventsOfType(' '), throwsArgumentError);
    });

    test('supports camera pro helpers', () async {
      expect(await NexoraSdk.instance.camera.takePhoto(), '/test/photo.jpg');
      expect(
        await NexoraSdk.instance.camera.startVideoRecording(),
        '/test/video.mp4',
      );
      expect(
        await NexoraSdk.instance.camera.stopVideoRecording(),
        '/test/video.mp4',
      );
      expect(
        () => NexoraSdk.instance.camera.takePhoto(fileName: ' '),
        throwsArgumentError,
      );
    });

    test('supports native utility helpers', () async {
      final native = NexoraSdk.instance.native;

      expect(await native.copyText('hello'), isTrue);
      expect(await native.pasteText(), 'copied');
      expect(await native.openUrl('https://example.com'), isTrue);
      expect(await native.shareText('hello', subject: 'Subject'), isTrue);
      expect(() => native.copyText(''), throwsArgumentError);
      expect(() => native.openUrl('bad-url'), throwsArgumentError);
    });

    test('stopAll returns module shutdown results', () async {
      final result = await NexoraSdk.instance.stopAll();

      expect(result.success, isTrue);
      expect(result.failedModules, isEmpty);
      expect(
        result.results.keys,
        containsAll(<String>[
          'camera',
          'audio',
          'bluetoothScan',
          'location',
          'sensors',
          'logging',
        ]),
      );
    });

    test('validates camera arguments', () {
      expect(
        () => NexoraSdk.instance.camera.start(width: 0),
        throwsArgumentError,
      );
      expect(
        () => NexoraSdk.instance.camera.start(height: -1),
        throwsArgumentError,
      );
      expect(() => NexoraSdk.instance.camera.setZoom(0), throwsArgumentError);
    });

    test('validates audio and sensor arguments', () {
      expect(
        () => NexoraSdk.instance.audio.start(updateIntervalMs: 0),
        throwsArgumentError,
      );
      expect(
        () => NexoraSdk.instance.sensors.start(frequencyHz: 0),
        throwsArgumentError,
      );
    });

    test('validates bluetooth arguments', () {
      expect(
        () => NexoraSdk.instance.bluetooth.connect(''),
        throwsArgumentError,
      );
      expect(
        () => NexoraSdk.instance.bluetooth.discoverServices(' '),
        throwsArgumentError,
      );
      expect(
        () => NexoraSdk.instance.bluetooth.sendData('d', 's', 'c', const []),
        throwsArgumentError,
      );
    });

    test('validates location and feedback arguments', () {
      expect(
        () => NexoraSdk.instance.location.addGeofence('', 0, 0, 100),
        throwsArgumentError,
      );
      expect(
        () => NexoraSdk.instance.location.addGeofence('home', 91, 0, 100),
        throwsArgumentError,
      );
      expect(
        () => NexoraSdk.instance.location.addGeofence('home', 0, 181, 100),
        throwsArgumentError,
      );
      expect(
        () => NexoraSdk.instance.location.addGeofence('home', 0, 0, 0),
        throwsArgumentError,
      );
      expect(
        () => NexoraSdk.instance.feedback.vibrate(durationMs: -1),
        throwsArgumentError,
      );
      expect(
        () => NexoraSdk.instance.feedback.haptic('soft'),
        throwsArgumentError,
      );
    });

    test('validates biometric prompt reason', () {
      expect(
        () => NexoraSdk.instance.biometrics.authenticate(reason: ' '),
        throwsArgumentError,
      );
    });

    test('supports typed haptic pattern helper', () async {
      await expectLater(
        NexoraSdk.instance.feedback.hapticPattern(HapticPattern.success),
        completes,
      );
    });

    test('supports storage json, append, and deleteIfExists helpers', () async {
      final storage = NexoraSdk.instance.storage;

      await storage.writeJson('settings.json', <String, Object>{
        'enabled': true,
        'rate': 60,
      });
      expect(
        await storage.readJson<Map<String, dynamic>>('settings.json'),
        containsPair('enabled', true),
      );

      await storage.writeFile('log.txt', 'a');
      await storage.appendFile('log.txt', 'b');
      expect(await storage.readFile('log.txt'), 'ab');

      expect(await storage.deleteIfExists('missing.txt'), isTrue);
      expect(await storage.deleteIfExists('log.txt'), isTrue);
      expect(await storage.fileExists('log.txt'), isFalse);
    });
  });
}
