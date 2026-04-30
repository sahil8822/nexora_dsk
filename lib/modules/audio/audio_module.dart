import '../../nexora_sdk_platform_interface.dart';
import '../../models/hardware_models.dart';

/// Module for raw audio capture and signal analysis.
class AudioModule {
  /// Starts capturing raw PCM audio from the device microphone.
  /// 
  /// Set [enableFFT] to true to receive frequency spectrum data in the stream.
  Future<bool> start({bool enableFFT = false}) =>
      NexoraSdkPlatform.instance.startAudio(enableFFT: enableFFT);

  /// Stops audio capture and analysis.
  Future<bool> stop() => NexoraSdkPlatform.instance.stopAudio();

  /// A stream of [AudioFrame] objects containing raw bytes and FFT spectrum.
  Stream<AudioFrame> get stream => NexoraSdkPlatform.instance.audioStream;
}
