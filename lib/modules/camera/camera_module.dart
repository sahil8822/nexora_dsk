import '../../nexora_sdk_platform_interface.dart';
import '../../models/hardware_models.dart';

/// Module for controlling device cameras and receiving frame streams.
class CameraModule {
  bool _isRunning = false;

  /// Returns whether the camera is currently active.
  bool get isRunning => _isRunning;

  /// Starts the camera and returns the native [textureId] for rendering.
  ///
  /// Use the returned ID with a [Texture] widget for high-performance preview.
  /// Returns null if the camera failed to start.
  Future<int?> start({
    CameraQuality quality = CameraQuality.hd,
    int? width,
    int? height,
  }) {
    if (width != null && width <= 0) {
      throw ArgumentError.value(width, 'width', 'Must be greater than zero.');
    }
    if (height != null && height <= 0) {
      throw ArgumentError.value(height, 'height', 'Must be greater than zero.');
    }
    return NexoraSdkPlatform.instance
        .startCamera(
          width: width ?? quality.width,
          height: height ?? quality.height,
        )
        .then((result) {
          if (result is int) {
            _isRunning = true;
            return result;
          }
          return null;
        });
  }

  /// Stops the camera and releases all native resources.
  Future<bool> stop() async {
    final success = await NexoraSdkPlatform.instance.stopCamera();
    if (success) _isRunning = false;
    return success;
  }

  /// Toggles the device flash/torch.
  Future<bool> setFlash(bool on) => NexoraSdkPlatform.instance.setFlash(on);

  /// Sets the digital zoom level (e.g., 1.0 to 10.0).
  Future<bool> setZoom(double level) {
    if (level <= 0) {
      throw ArgumentError.value(level, 'level', 'Must be greater than zero.');
    }
    return NexoraSdkPlatform.instance.setZoom(level);
  }

  /// Flips between front and back cameras.
  Future<bool> flip() => NexoraSdkPlatform.instance.flipCamera();

  /// Captures a still photo and returns the saved file path when supported.
  Future<String?> takePhoto({String? fileName}) {
    if (fileName != null && fileName.trim().isEmpty) {
      throw ArgumentError.value(fileName, 'fileName', 'File name is empty.');
    }
    return NexoraSdkPlatform.instance.takePhoto(fileName: fileName);
  }

  /// Starts native video recording and returns the output file path.
  Future<String?> startVideoRecording({String? fileName}) {
    if (fileName != null && fileName.trim().isEmpty) {
      throw ArgumentError.value(fileName, 'fileName', 'File name is empty.');
    }
    return NexoraSdkPlatform.instance.startVideoRecording(fileName: fileName);
  }

  /// Stops native video recording and returns the saved file path.
  Future<String?> stopVideoRecording() {
    return NexoraSdkPlatform.instance.stopVideoRecording();
  }

  /// A stream of [CameraFrame] objects captured in real-time.
  Stream<CameraFrame> get stream => NexoraSdkPlatform.instance.cameraStream;
}
