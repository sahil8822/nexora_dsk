import 'dart:async';
import 'package:nexora_sdk/models/hardware_models.dart';
import '../../nexora_sdk_platform_interface.dart';

/// Module for high-performance raw camera frame streaming.
class CameraModule {
  /// Internal constructor.
  CameraModule();

  /// Stream of raw [CameraFrame] objects for real-time processing.
  Stream<CameraFrame> get stream => NexoraSdkPlatform.instance.cameraStream;

  /// Alias for [stream] specific to camera frames.
  Stream<CameraFrame> get frameStream => stream;

  /// Starts the camera with requested [width] and [height].
  Future<bool> start({int width = 640, int height = 480}) =>
      NexoraSdkPlatform.instance.startCamera(width: width, height: height);

  /// Stops the camera and releases the hardware lock.
  Future<bool> stop() => NexoraSdkPlatform.instance.stopCamera();
}
