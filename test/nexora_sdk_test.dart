import 'package:flutter_test/flutter_test.dart';
import 'package:nexora_sdk/nexora_sdk.dart';
import 'package:nexora_sdk/nexora_sdk_platform_interface.dart';

import 'mocks/mock_platform.dart';

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
      expect(sdk.supportFor(HardwareFeature.storage).isAvailable, isTrue);
      expect(sdk.featureMatrix, contains(HardwareFeature.videoRecording));
      expect(
        sdk.supportFor(HardwareFeature.videoRecording).level,
        HardwareFeatureSupportLevel.experimental,
      );
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
      await NexoraSdk.instance.camera.start();
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
      expect(
        await NexoraSdk.instance.camera.registerCustomClassifier(
          modelAssetPath: 'assets/model.tflite',
          labels: ['cat', 'dog'],
        ),
        isTrue,
      );
      expect(
        () => NexoraSdk.instance.camera.registerCustomClassifier(
          modelAssetPath: ' ',
          labels: ['cat'],
        ),
        throwsArgumentError,
      );
      expect(
        () => NexoraSdk.instance.camera.registerCustomClassifier(
          modelAssetPath: 'assets/model.tflite',
          labels: [],
        ),
        throwsArgumentError,
      );
      await NexoraSdk.instance.camera.stop();
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

    test('validates camera arguments', () async {
      expect(
        () => NexoraSdk.instance.camera.start(width: 0),
        throwsArgumentError,
      );
      expect(
        () => NexoraSdk.instance.camera.start(height: -1),
        throwsArgumentError,
      );
      await NexoraSdk.instance.camera.start();
      expect(() => NexoraSdk.instance.camera.setZoom(0), throwsArgumentError);
      await NexoraSdk.instance.camera.stop();
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

    test(
      'supports pro features (smart sync, camera filters, BLE L2CAP, and Dead Reckoning)',
      () async {
        expect(
          await NexoraSdk.instance.health.enableSmartSync(
            uploadEndpointUrl: 'https://example.com/sync',
            headers: {'Authorization': 'Bearer 123'},
          ),
          isTrue,
        );
        expect(
          () => NexoraSdk.instance.health.enableSmartSync(
            uploadEndpointUrl: ' ',
            headers: {},
          ),
          throwsArgumentError,
        );

        await NexoraSdk.instance.camera.start();
        expect(
          await NexoraSdk.instance.camera.applyFilterShader('chromaKey'),
          isTrue,
        );
        expect(
          () => NexoraSdk.instance.camera.applyFilterShader(' '),
          throwsArgumentError,
        );

        expect(
          NexoraSdk.instance.bluetooth.openL2capStream('device_1', 12),
          isNotNull,
        );
        expect(
          () => NexoraSdk.instance.bluetooth.openL2capStream(' ', 12),
          throwsArgumentError,
        );
        expect(
          () => NexoraSdk.instance.bluetooth.openL2capStream('device_1', 0),
          throwsArgumentError,
        );

        expect(
          await NexoraSdk.instance.location.enableDeadReckoning(true),
          isTrue,
        );
      },
    );

    test('exposes typed hardware exceptions', () {
      final unsupported = HardwareException.unsupported('Camera filters');

      expect(unsupported.code, HardwareErrorCode.notSupported);
      expect(unsupported.isUnsupported, isTrue);
      expect(unsupported.isPermissionDenied, isFalse);
      expect(
        HardwareErrorCode.fromPlatformCode('PERMISSION_DENIED'),
        HardwareErrorCode.permissionDenied,
      );
    });

    test(
      'supports lazy modules, customizable options builders, and auto-permissions',
      () async {
        expect(NexoraSdk.instance.camera, isNotNull);
        expect(NexoraSdk.instance.audio, isNotNull);
        expect(NexoraSdk.instance.location, isNotNull);

        const camOptions = CameraOptions(
          resolution: CameraQuality.fullHd,
          focusMode: CameraFocusMode.macro,
          exposureMode: CameraExposureMode.locked,
          exposureCompensation: -0.5,
        );
        expect(
          await NexoraSdk.instance.camera.startWithOptions(camOptions),
          isNotNull,
        );

        const audOptions = AudioOptions(
          sampleRate: 48000,
          channels: AudioChannelFormat.stereo,
          enableEchoCancellation: false,
          enableNoiseSuppression: false,
        );
        expect(
          await NexoraSdk.instance.audio.startWithOptions(audOptions),
          isTrue,
        );

        expect(
          await NexoraSdk.instance.location.start(autoRequestPermission: true),
          isTrue,
        );

        // 4. BLE Options scan
        const bleOptions = BluetoothScanOptions(
          scanMode: BluetoothScanMode.lowLatency,
          allowDuplicates: true,
        );
        expect(
          await NexoraSdk.instance.bluetooth.startScanWithOptions(bleOptions),
          isTrue,
        );

        // 5. Biometric Options prompt
        const bioOptions = BiometricPromptOptions(
          title: 'Sign Transactions',
          subtitle: 'Authorize security token',
        );
        expect(
          await NexoraSdk.instance.biometrics.authenticateWithOptions(
            bioOptions,
          ),
          isTrue,
        );

        // 6. Haptic Options perform
        const hapticOptions = HapticOptions(
          type: HapticFeedbackType.success,
          intensityPercent: 80,
        );
        await NexoraSdk.instance.feedback.performHapticWithOptions(
          hapticOptions,
        );

        // 7. Location Options
        const locOptions = LocationOptions(
          accuracy: LocationAccuracy.navigation,
          distanceFilterMeters: 5.0,
        );
        expect(
          await NexoraSdk.instance.location.startWithOptions(locOptions),
          isTrue,
        );

        // 8. Sensor Options
        const sensorOptions = SensorOptions(
          accuracy: SensorAccuracy.fastest,
          enableLowPassFilter: true,
        );
        expect(
          await NexoraSdk.instance.sensors.startWithOptions(sensorOptions),
          isTrue,
        );

        // 9. Speaker & Microphone Controls
        expect(
          await NexoraSdk.instance.audio.output.routeTo(
            AudioOutputRoute.speakerphone,
          ),
          isTrue,
        );
        expect(await NexoraSdk.instance.audio.output.getVolume(), equals(0.5));
        expect(await NexoraSdk.instance.audio.output.setVolume(0.8), isTrue);
        expect(
          await NexoraSdk.instance.audio.input.selectMicrophone(
            AudioInputDevice.bluetoothMic,
          ),
          isTrue,
        );
        expect(await NexoraSdk.instance.audio.input.setGain(0.75), isTrue);

        expect(
          () => NexoraSdk.instance.audio.output.setVolume(-0.1),
          throwsArgumentError,
        );
        expect(
          () => NexoraSdk.instance.audio.input.setGain(1.5),
          throwsArgumentError,
        );

        // 10. EcoMode & Thermal Safeguard System
        await NexoraSdk.instance.utility.setEcoModeEnabled(true);
        expect(await NexoraSdk.instance.utility.isEcoModeActive(), isFalse);
        expect(
          await NexoraSdk.instance.utility.getThermalState(),
          equals(DeviceThermalState.normal),
        );
      },
    );
  });
}
