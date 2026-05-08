import '../../nexora_sdk_platform_interface.dart';
import '../../models/hardware_models.dart';

/// Module for controlling device cameras and receiving frame streams.
class CameraModule {
  /// Starts the camera and returns the native [textureId] for rendering.
  ///
  /// Use the returned ID with a [Texture] widget for high-performance preview.
  /// Returns null if the camera failed to start.
  Future<int?> start({
    CameraQuality quality = CameraQuality.hd,
    int? width,
    int? height,
  }) async {
    final result = await NexoraSdkPlatform.instance.startCamera(
      width: width ?? quality.width,
      height: height ?? quality.height,
    );
    if (result is int) return result;
    return null;
  }

  /// Stops the camera and releases all native resources.
  Future<bool> stop() => NexoraSdkPlatform.instance.stopCamera();

  /// Toggles the device flash/torch.
  Future<bool> setFlash(bool on) => NexoraSdkPlatform.instance.setFlash(on);

  /// Sets the digital zoom level (e.g., 1.0 to 10.0).
  Future<bool> setZoom(double level) =>
      NexoraSdkPlatform.instance.setZoom(level);

  /// Flips between front and back cameras.
  Future<bool> flip() => NexoraSdkPlatform.instance.flipCamera();

  /// A stream of [CameraFrame] objects captured in real-time.
  Stream<CameraFrame> get stream => NexoraSdkPlatform.instance.cameraStream;
}
