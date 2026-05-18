import '../../nexora_sdk_platform_interface.dart';
import '../../models/hardware_models.dart';

/// Module for raw audio capture and signal analysis.
class AudioModule {
  bool _isRunning = false;
  bool get isRunning => _isRunning;

  bool _lastEnableFFT = false;
  bool get lastEnableFFT => _lastEnableFFT;

  bool _lastStreamBytes = false;
  bool get lastStreamBytes => _lastStreamBytes;

  int _lastUpdateIntervalMs = 80;
  int get lastUpdateIntervalMs => _lastUpdateIntervalMs;

  /// Starts capturing audio from the device microphone.
  ///
  /// Set [enableFFT] to true to receive frequency spectrum data in the stream.
  /// Keep [streamBytes] false for lightweight visualizers that only need FFT.
  Future<bool> start({
    bool enableFFT = false,
    bool streamBytes = false,
    int updateIntervalMs = 80,
  }) async {
    if (updateIntervalMs <= 0) {
      throw ArgumentError.value(
        updateIntervalMs,
        'updateIntervalMs',
        'Must be greater than zero.',
      );
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

  /// Stops audio capture and analysis.
  Future<bool> stop() async {
    final success = await NexoraSdkPlatform.instance.stopAudio();
    if (success) _isRunning = false;
    return success;
  }

  /// A stream of [AudioFrame] objects containing raw bytes and FFT spectrum.
  Stream<AudioFrame> get stream => NexoraSdkPlatform.instance.audioStream;
}
