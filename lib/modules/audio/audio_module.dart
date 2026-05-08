import '../../nexora_sdk_platform_interface.dart';
import '../../models/hardware_models.dart';

/// Module for raw audio capture and signal analysis.
class AudioModule {
  /// Starts capturing audio from the device microphone.
  ///
  /// Set [enableFFT] to true to receive frequency spectrum data in the stream.
  /// Keep [streamBytes] false for lightweight visualizers that only need FFT.
  Future<bool> start({
    bool enableFFT = false,
    bool streamBytes = false,
    int updateIntervalMs = 80,
  }) {
    if (updateIntervalMs <= 0) {
      throw ArgumentError.value(
        updateIntervalMs,
        'updateIntervalMs',
        'Must be greater than zero.',
      );
    }
    return NexoraSdkPlatform.instance.startAudio(
      enableFFT: enableFFT,
      streamBytes: streamBytes,
      updateIntervalMs: updateIntervalMs,
    );
  }

  /// Stops audio capture and analysis.
  Future<bool> stop() => NexoraSdkPlatform.instance.stopAudio();

  /// A stream of [AudioFrame] objects containing raw bytes and FFT spectrum.
  Stream<AudioFrame> get stream => NexoraSdkPlatform.instance.audioStream;
}
