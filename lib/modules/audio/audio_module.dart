import 'package:nexora_sdk_platform_interface/models/hardware_models.dart';
import 'package:nexora_sdk_platform_interface/nexora_sdk_platform_interface.dart';

/// Module for raw audio capture and signal analysis.
class AudioModule {
  bool _isRunning = false;

  /// API Documentation for _isRunning;.
  bool get isRunning => _isRunning;

  bool _lastEnableFFT = false;

  /// API Documentation for _lastEnableFFT;.
  bool get lastEnableFFT => _lastEnableFFT;

  bool _lastStreamBytes = false;

  /// API Documentation for _lastStreamBytes;.
  bool get lastStreamBytes => _lastStreamBytes;

  int _lastUpdateIntervalMs = 80;

  /// API Documentation for _lastUpdateIntervalMs;.
  int get lastUpdateIntervalMs => _lastUpdateIntervalMs;

  /// Controls the speaker and audio output routing features.
  final AudioOutputController output = AudioOutputController();

  /// Controls the microphone selection and recording gain features.
  final AudioInputController input = AudioInputController();

  /// Starts capturing audio from the device microphone.
  ///
  /// Set [enableFFT] to true to receive frequency spectrum data in the stream.
  /// Keep [streamBytes] false for lightweight visualizers that only need FFT.
  Future<bool> start({
    bool enableFFT = false,
    bool streamBytes = false,
    int updateIntervalMs = 80,
    bool autoRequestPermission = true,
  }) async {
    if (updateIntervalMs <= 0) {
      throw ArgumentError.value(
        updateIntervalMs,
        'updateIntervalMs',
        'Must be greater than zero.',
      );
    }
    if (autoRequestPermission) {
      final granted = await NexoraSdkPlatform.instance.requestAudioPermission();
      if (!granted) return false;
    }
    final success = await NexoraSdkPlatform.instance.startAudio(
      enableFFT: enableFFT,
      streamBytes: streamBytes,
      updateIntervalMs: updateIntervalMs,
    );
    if (success) {
      _isRunning = true;
      _lastEnableFFT = enableFFT;
      _lastStreamBytes = streamBytes;
      _lastUpdateIntervalMs = updateIntervalMs;
    }
    return success;
  }

  /// Starts the audio capture with granular, fully-customized native options.
  Future<bool> startWithOptions(
    AudioOptions options, {
    bool autoRequestPermission = true,
  }) async {
    if (autoRequestPermission) {
      final granted = await NexoraSdkPlatform.instance.requestAudioPermission();
      if (!granted) return false;
    }
    final success = await NexoraSdkPlatform.instance.startAudioWithOptions(
      options,
    );
    if (success) {
      _isRunning = true;
    }
    return success;
  }

  /// Stops audio capture and analysis.
  Future<bool> stop() async {
    final success = await NexoraSdkPlatform.instance.stopAudio();
    if (success) _isRunning = false;
    return success;
  }

  /// A stream of [AudioFrame] objects containing raw bytes and FFT spectrum.
  Stream<AudioFrame> get stream => NexoraSdkPlatform.instance.audioStream;
}

/// Controller for routing audio output channels and volume controls.
class AudioOutputController {
  /// Routes audio output to speakerphone, earpiece, bluetooth, or wired headsets.
  Future<bool> routeTo(AudioOutputRoute route) {
    return NexoraSdkPlatform.instance.routeAudioOutput(route);
  }

  /// Gets the current system audio playback volume level (0.0 to 1.0).
  Future<double> getVolume() {
    return NexoraSdkPlatform.instance.getAudioVolume();
  }

  /// Sets the system audio playback volume level (0.0 to 1.0).
  Future<bool> setVolume(double level) {
    if (level < 0.0 || level > 1.0) {
      throw ArgumentError.value(
        level,
        'level',
        'Volume level must be between 0.0 and 1.0.',
      );
    }
    return NexoraSdkPlatform.instance.setAudioVolume(level);
  }
}

/// Controller for capturing and adjusting physical hardware microphones.
class AudioInputController {
  /// Selects the target hardware microphone for recording (front, back, bottom, bluetooth, etc).
  Future<bool> selectMicrophone(AudioInputDevice device) {
    return NexoraSdkPlatform.instance.selectAudioInput(device);
  }

  /// Sets the input recording gain (sensitivity) (0.0 to 1.0).
  Future<bool> setGain(double gain) {
    if (gain < 0.0 || gain > 1.0) {
      throw ArgumentError.value(
        gain,
        'gain',
        'Gain must be between 0.0 and 1.0.',
      );
    }
    return NexoraSdkPlatform.instance.setAudioGain(gain);
  }
}
