import 'dart:async';
import 'package:flutter/services.dart';
import '../../core/hardware_core.dart';
import '../../nexora_sdk_platform_interface.dart';

/// Performance-optimized Camera module with Binary Channel Support.
class CameraModule {
  static const binaryChannel = BasicMessageChannel<ByteData?>('nexora_sdk/camera/frames', BinaryCodec());
  
  final _eventStream = StreamController<HardwareEvent>.broadcast();

  Future<bool> start({int width = 640, int height = 480}) async {
    return await NexoraSdkPlatform.instance.startCamera(width: width, height: height);
  }

  Future<bool> stop() async {
    return await NexoraSdkPlatform.instance.stopCamera();
  }

  /// High-performance raw frame stream using BasicMessageChannel.
  Stream<Uint8List> get frameStream {
    final controller = StreamController<Uint8List>();
    binaryChannel.setMessageHandler((ByteData? msg) async {
      if (msg != null) {
        controller.add(msg.buffer.asUint8List());
      }
      return null;
    });
    return controller.stream;
  }

  void dispose() {
    _eventStream.close();
  }
}
