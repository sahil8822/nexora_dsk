import 'package:flutter/cupertino.dart' show Texture;
import 'package:flutter/material.dart' show Texture;
import 'package:flutter/widgets.dart' show Texture;
import 'package:nexora_sdk_platform_interface/core/concurrency.dart';
import 'package:nexora_sdk_platform_interface/models/hardware_models.dart';
import 'package:nexora_sdk_platform_interface/nexora_sdk_platform_interface.dart';

/// Module for controlling device cameras and receiving frame streams.
class CameraModule {
  final Mutex _mutex = Mutex();
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
    bool autoRequestPermission = true,
  }) async {
    if (width != null && width <= 0) {
      throw ArgumentError.value(width, 'width', 'Must be greater than zero.');
    }
    if (height != null && height <= 0) {
      throw ArgumentError.value(height, 'height', 'Must be greater than zero.');
    }
    return _mutex.protect(() async {
      if (autoRequestPermission) {
        final granted = await NexoraSdkPlatform.instance
            .requestCameraPermission();
        if (!granted) return null;
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
    });
  }

  /// Starts the camera with granular, fully-customized native options.
  Future<int?> startWithOptions(
    CameraOptions options, {
    bool autoRequestPermission = true,
  }) async {
    return _mutex.protect(() async {
      if (autoRequestPermission) {
        final granted = await NexoraSdkPlatform.instance
            .requestCameraPermission();
        if (!granted) return null;
      }
      return NexoraSdkPlatform.instance.startCameraWithOptions(options).then((
        result,
      ) {
        if (result is int) {
          _isRunning = true;
          return result;
        }
        return null;
      });
    });
  }

  /// Stops the camera and releases all native resources.
  Future<bool> stop() async {
    return _mutex.protect(() async {
      final success = await NexoraSdkPlatform.instance.stopCamera();
      if (success) _isRunning = false;
      return success;
    });
  }

  /// Toggles the device flash/torch.
  Future<bool> setFlash(bool on) {
    if (!_isRunning) throw StateError('Camera is not running.');
    return NexoraSdkPlatform.instance.setFlash(on);
  }

  /// Sets the digital zoom level (e.g., 1.0 to 10.0).
  Future<bool> setZoom(double level) {
    if (!_isRunning) throw StateError('Camera is not running.');
    if (level <= 0) {
      throw ArgumentError.value(level, 'level', 'Must be greater than zero.');
    }
    return NexoraSdkPlatform.instance.setZoom(level);
  }

  /// Flips between front and back cameras.
  Future<bool> flip() {
    if (!_isRunning) throw StateError('Camera is not running.');
    return NexoraSdkPlatform.instance.flipCamera();
  }

  /// Captures a still photo and returns the saved file path when supported.
  Future<String?> takePhoto({String? fileName}) {
    if (!_isRunning) throw StateError('Camera is not running.');
    if (fileName != null && fileName.trim().isEmpty) {
      throw ArgumentError.value(fileName, 'fileName', 'File name is empty.');
    }
    return NexoraSdkPlatform.instance.takePhoto(fileName: fileName);
  }

  /// Starts native video recording and returns the output file path.
  Future<String?> startVideoRecording({String? fileName}) {
    if (!_isRunning) throw StateError('Camera is not running.');
    if (fileName != null && fileName.trim().isEmpty) {
      throw ArgumentError.value(fileName, 'fileName', 'File name is empty.');
    }
    return NexoraSdkPlatform.instance.startVideoRecording(fileName: fileName);
  }

  /// Stops native video recording and returns the saved file path.
  Future<String?> stopVideoRecording() {
    if (!_isRunning) throw StateError('Camera is not running.');
    return NexoraSdkPlatform.instance.stopVideoRecording();
  }

  /// Registers a custom TensorFlow Lite or CoreML model for real-time edge classification.
  Future<bool> registerCustomClassifier({
    required String modelAssetPath,
    required List<String> labels,
    double threshold = 0.5,
  }) {
    if (!_isRunning) throw StateError('Camera is not running.');
    if (modelAssetPath.trim().isEmpty) {
      throw ArgumentError.value(
        modelAssetPath,
        'modelAssetPath',
        'Model asset path cannot be empty.',
      );
    }
    if (labels.isEmpty) {
      throw ArgumentError.value(
        labels,
        'labels',
        'Labels list cannot be empty.',
      );
    }
    return NexoraSdkPlatform.instance.registerCustomClassifier(
      modelAssetPath: modelAssetPath,
      labels: labels,
      threshold: threshold,
    );
  }

  /// Applies a real-time GPU fragment shader filter to the camera preview.
  /// Supported types: 'none', 'chromaKey', 'monochrome', 'sepia'
  Future<bool> applyFilterShader(String shaderType) {
    if (!_isRunning) throw StateError('Camera is not running.');
    if (shaderType.trim().isEmpty) {
      throw ArgumentError.value(
        shaderType,
        'shaderType',
        'Shader type cannot be empty.',
      );
    }
    return NexoraSdkPlatform.instance.applyCameraFilterShader(shaderType);
  }

  /// A stream of [CameraFrame] objects captured in real-time.
  Stream<CameraFrame> get stream => NexoraSdkPlatform.instance.cameraStream;
}
