import 'package:flutter_test/flutter_test.dart';
import 'package:nexora_sdk/nexora_sdk.dart';
import 'package:nexora_sdk/nexora_sdk_platform_interface.dart';
import '../mocks/mock_platform.dart';

class MockAudioPlatform extends MockNexoraSdkPlatform {
  bool isAudioRunning = false;
  bool requestPermissionResult = true;
  double volume = 0.5;
  double gain = 0.5;
  AudioOutputRoute activeRoute = AudioOutputRoute.defaultRoute;
  AudioInputDevice activeInput = AudioInputDevice.defaultMic;

  @override
  Future<bool> requestAudioPermission() async => requestPermissionResult;

  @override
  Future<bool> startAudio({
    bool enableFFT = false,
    bool streamBytes = false,
    int updateIntervalMs = 80,
  }) async {
    isAudioRunning = true;
    return true;
  }

  @override
  Future<bool> startAudioWithOptions(AudioOptions options) async {
    isAudioRunning = true;
    return true;
  }

  @override
  Future<bool> stopAudio() async {
    isAudioRunning = false;
    return true;
  }

  @override
  Future<bool> routeAudioOutput(AudioOutputRoute route) async {
    activeRoute = route;
    return true;
  }

  @override
  Future<double> getAudioVolume() async => volume;

  @override
  Future<bool> setAudioVolume(double level) async {
    volume = level;
    return true;
  }

  @override
  Future<bool> selectAudioInput(AudioInputDevice device) async {
    activeInput = device;
    return true;
  }

  @override
  Future<bool> setAudioGain(double level) async {
    gain = level;
    return true;
  }
}

void main() {
  late MockAudioPlatform mockPlatform;

  setUp(() {
    mockPlatform = MockAudioPlatform();
    NexoraSdkPlatform.instance = mockPlatform;
  });

  group('AudioModule Tests', () {
    test('start() success', () async {
      final audio = AudioModule();
      expect(audio.isRunning, false);
      final success = await audio.start(enableFFT: true);
      expect(success, true);
      expect(audio.isRunning, true);
      expect(audio.lastEnableFFT, true);
    });

    test('start() permission denied', () async {
      mockPlatform.requestPermissionResult = false;
      final audio = AudioModule();
      final success = await audio.start();
      expect(success, false);
      expect(audio.isRunning, false);
    });

    test('start() validation', () async {
      final audio = AudioModule();
      expect(() => audio.start(updateIntervalMs: -1), throwsArgumentError);
    });

    test('startWithOptions() success', () async {
      final audio = AudioModule();
      final success = await audio.startWithOptions(const AudioOptions(sampleRate: 22050));
      expect(success, true);
      expect(audio.isRunning, true);
    });

    test('stop() resets isRunning', () async {
      final audio = AudioModule();
      await audio.start();
      expect(audio.isRunning, true);
      await audio.stop();
      expect(audio.isRunning, false);
    });

    test('output controller functions', () async {
      final audio = AudioModule();
      expect(await audio.output.getVolume(), 0.5);
      expect(await audio.output.setVolume(0.8), true);
      expect(mockPlatform.volume, 0.8);
      expect(() => audio.output.setVolume(1.5), throwsArgumentError);
      expect(() => audio.output.setVolume(-0.5), throwsArgumentError);

      expect(await audio.output.routeTo(AudioOutputRoute.speakerphone), true);
      expect(mockPlatform.activeRoute, AudioOutputRoute.speakerphone);
    });

    test('input controller functions', () async {
      final audio = AudioModule();
      expect(await audio.input.selectMicrophone(AudioInputDevice.backMic), true);
      expect(mockPlatform.activeInput, AudioInputDevice.backMic);

      expect(await audio.input.setGain(0.9), true);
      expect(mockPlatform.gain, 0.9);
      expect(() => audio.input.setGain(2.0), throwsArgumentError);
      expect(() => audio.input.setGain(-0.1), throwsArgumentError);
    });
  });
}
