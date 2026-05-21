import 'package:flutter_test/flutter_test.dart';
import 'package:nexora_sdk/nexora_sdk.dart';
import 'package:nexora_sdk_platform_interface/nexora_sdk_platform_interface.dart';
import '../mocks/mock_platform.dart';

class MockPlatform extends MockNexoraSdkPlatform {
  bool isCameraRunning = false;
  bool requestPermissionResult = true;
  bool startCameraCalled = false;
  bool startCameraWithOptionsCalled = false;
  CameraOptions? lastCameraOptions;

  @override
  Future<bool> requestCameraPermission() async => requestPermissionResult;

  @override
  Future<int?> startCamera({int width = 1280, int height = 720}) async {
    startCameraCalled = true;
    return 1;
  }

  @override
  Future<int?> startCameraWithOptions(CameraOptions options) async {
    startCameraWithOptionsCalled = true;
    lastCameraOptions = options;
    return 1;
  }

  @override
  Future<bool> stopCamera() async {
    isCameraRunning = false;
    return true;
  }

  @override
  Future<bool> setFlash(bool on) async => true;

  @override
  Future<bool> setZoom(double level) async => true;

  @override
  Future<bool> flipCamera() async => true;

  @override
  Future<String?> takePhoto({String? fileName}) async => '/path/photo.jpg';

  @override
  Future<String?> startVideoRecording({String? fileName}) async =>
      '/path/video.mp4';

  @override
  Future<String?> stopVideoRecording() async => '/path/video.mp4';

  @override
  Future<bool> registerCustomClassifier({
    required String modelAssetPath,
    required List<String> labels,
    double threshold = 0.5,
  }) async => true;
}

void main() {
  late MockPlatform mockPlatform;

  setUp(() {
    mockPlatform = MockPlatform();
    NexoraSdkPlatform.instance = mockPlatform;
  });

  group('CameraModule Tests', () {
    test('start() success', () async {
      final camera = CameraModule();
      expect(camera.isRunning, false);
      final textureId = await camera.start();
      expect(textureId, 1);
      expect(camera.isRunning, true);
    });

    test('start() permission denied', () async {
      mockPlatform.requestPermissionResult = false;
      final camera = CameraModule();
      final textureId = await camera.start();
      expect(textureId, null);
      expect(camera.isRunning, false);
    });

    test('start() arg validation', () async {
      final camera = CameraModule();
      expect(() => camera.start(width: -100), throwsArgumentError);
      expect(() => camera.start(height: -100), throwsArgumentError);
    });

    test('isRunning guards throw when camera is not running', () async {
      final camera = CameraModule();
      expect(camera.isRunning, false);
      expect(() => camera.setFlash(true), throwsStateError);
      expect(() => camera.setZoom(2), throwsStateError);
      expect(camera.flip, throwsStateError);
      expect(camera.takePhoto, throwsStateError);
      expect(camera.startVideoRecording, throwsStateError);
      expect(camera.stopVideoRecording, throwsStateError);
    });

    test('operations succeed when camera is running', () async {
      final camera = CameraModule();
      await camera.start();
      expect(camera.isRunning, true);
      expect(await camera.setFlash(true), true);
      expect(await camera.setZoom(2), true);
      expect(await camera.flip(), true);
      expect(await camera.takePhoto(fileName: 'photo.jpg'), '/path/photo.jpg');
      expect(
        await camera.startVideoRecording(fileName: 'video.mp4'),
        '/path/video.mp4',
      );
      expect(await camera.stopVideoRecording(), '/path/video.mp4');
    });

    test('stop() resets isRunning', () async {
      final camera = CameraModule();
      await camera.start();
      expect(camera.isRunning, true);
      await camera.stop();
      expect(camera.isRunning, false);
    });
  });
}
