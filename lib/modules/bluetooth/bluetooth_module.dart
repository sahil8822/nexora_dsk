import 'package:flutter/services.dart';

/// Modular Bluetooth LE Module.
/// Features scanning, connecting, and characteristic streaming.
class BluetoothModule {
  static const methodChannel = MethodChannel('my_hardware_plugin/bluetooth/methods');
  static const eventChannel = EventChannel('my_hardware_plugin/bluetooth/events');

  Future<bool> startScan() async {
    final success = await methodChannel.invokeMethod<bool>('startScan');
    return success ?? false;
  }

  Future<bool> stopScan() async {
    final success = await methodChannel.invokeMethod<bool>('stopScan');
    return success ?? false;
  }

  Future<bool> connect(String deviceId) async {
    final success = await methodChannel.invokeMethod<bool>('connect', {'id': deviceId});
    return success ?? false;
  }

  /// Real-time BLE device and data stream.
  Stream<Map<dynamic, dynamic>> get deviceStream {
    return eventChannel.receiveBroadcastStream().cast<Map<dynamic, dynamic>>();
  }
}
