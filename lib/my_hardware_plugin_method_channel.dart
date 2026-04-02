import 'package:flutter/services.dart';
import 'models/hardware_models.dart';
import 'core/hardware_core.dart';
import 'my_hardware_plugin_platform_interface.dart';

class MethodChannelMyHardwarePlugin extends MyHardwarePluginPlatform {
  final methodChannel = const MethodChannel('my_hardware_plugin/methods');
  final eventChannel = const EventChannel('my_hardware_plugin/events');

  @override
  Future<String?> getPlatformVersion() async {
    return await methodChannel.invokeMethod<String>('getPlatformVersion');
  }

  @override
  Future<bool> startCamera() async => await methodChannel.invokeMethod<bool>('startCamera') ?? false;

  @override
  Future<bool> stopCamera() async => await methodChannel.invokeMethod<bool>('stopCamera') ?? false;

  @override
  Future<bool> startBluetoothScan() async => await methodChannel.invokeMethod<bool>('startBluetoothScan') ?? false;

  @override
  Future<bool> stopBluetoothScan() async => await methodChannel.invokeMethod<bool>('stopBluetoothScan') ?? false;

  @override
  Future<bool> connectDevice(String id) async => await methodChannel.invokeMethod<bool>('connectDevice', {'id': id}) ?? false;

  @override
  Future<WifiInfo?> getWifiInfo() async {
    final map = await methodChannel.invokeMapMethod<dynamic, dynamic>('getWifiInfo');
    return map != null ? WifiInfo.fromMap(map) : null;
  }

  @override
  Future<bool> startLocation() async => await methodChannel.invokeMethod<bool>('startLocation') ?? false;

  @override
  Future<bool> stopLocation() async => await methodChannel.invokeMethod<bool>('stopLocation') ?? false;

  @override
  Stream<HardwareEvent> get unifiedStream {
    return eventChannel.receiveBroadcastStream().map((event) {
      if (event is Map) {
        return HardwareEvent(
          module: event['type'] as String,
          type: 'data',
          data: event['data'],
          timestamp: DateTime.fromMillisecondsSinceEpoch(event['timestamp'] as int),
        );
      }
      throw PlatformException(code: 'INVALID_STREAM_DATA', message: 'Expected Map');
    });
  }
}
