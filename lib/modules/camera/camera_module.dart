import 'dart:async';
import 'package:flutter/services.dart';
import '../../core/hardware_core.dart';

/// Performance-optimized Camera module with Binary Channel Support.
class CameraModule {
  static const methodChannel = MethodChannel('my_hardware_plugin/camera/methods');
  static const binaryChannel = BasicMessageChannel<ByteData?>('my_hardware_plugin/camera/frames', BinaryCodec());
  
  final _eventStream = StreamController<HardwareEvent>.broadcast();

  Future<bool> start() async {
    final success = await methodChannel.invokeMethod<bool>('start');
    return success ?? false;
  }

  Future<bool> stop() async {
    final success = await methodChannel.invokeMethod<bool>('stop');
    return success ?? false;
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
