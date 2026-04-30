import 'package:flutter/services.dart';
import 'models/hardware_models.dart';
import 'core/hardware_core.dart';
import 'nexora_sdk_platform_interface.dart';

class MethodChannelNexoraSdk extends NexoraSdkPlatform {
  final methodChannel = const MethodChannel('nexora_sdk/methods');
  final eventChannel = const EventChannel('nexora_sdk/events');

  @override
  Future<String?> getPlatformVersion() async {
    return await methodChannel.invokeMethod<String>('getPlatformVersion');
  }

  @override
  Future<bool> startCamera({int width = 640, int height = 480}) async => 
      await methodChannel.invokeMethod<bool>('startCamera', {'width': width, 'height': height}) ?? false;

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
  Future<bool> startSensor({int frequencyHz = 60}) async => 
      await methodChannel.invokeMethod<bool>('startSensor', {'frequency': frequencyHz}) ?? false;

  @override
  Future<bool> stopSensor() async => await methodChannel.invokeMethod<bool>('stopSensor') ?? false;

  @override
  Future<bool> requestPermissions() async => await methodChannel.invokeMethod<bool>('requestPermissions') ?? false;

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
