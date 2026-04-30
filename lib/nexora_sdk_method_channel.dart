import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'nexora_sdk_platform_interface.dart';
import 'core/hardware_core.dart';
import 'models/hardware_models.dart';

/// An implementation of [NexoraSdkPlatform] that uses method channels.
class MethodChannelNexoraSdk extends NexoraSdkPlatform {
  @visibleForTesting
  final methodChannel = const MethodChannel('nexora_sdk/methods');
  @visibleForTesting
  final eventChannel = const EventChannel('nexora_sdk/events');

  @override
  Future<String?> getPlatformVersion() async {
    return await methodChannel.invokeMethod<String>('getPlatformVersion');
  }

  @override
  Future<bool> requestPermissions() async {
    return await methodChannel.invokeMethod<bool>('requestPermissions') ?? false;
  }

  // --- Camera & Vision ---
  @override
  Future<dynamic> startCamera({int width = 640, int height = 480}) async {
    return await methodChannel.invokeMethod<dynamic>('startCamera', {'width': width, 'height': height});
  }

  @override
  Future<bool> stopCamera() async {
    return await methodChannel.invokeMethod<bool>('stopCamera') ?? false;
  }

  @override
  Future<bool> setVisionMode({bool barcode = false, bool face = false}) async {
    return await methodChannel.invokeMethod<bool>('setVisionMode', {'barcode': barcode, 'face': face}) ?? false;
  }

  @override
  Future<bool> setFlash(bool on) async {
    return await methodChannel.invokeMethod<bool>('setFlash', {'on': on}) ?? false;
  }

  @override
  Future<bool> setZoom(double level) async {
    return await methodChannel.invokeMethod<bool>('setZoom', {'level': level}) ?? false;
  }

  @override
  Future<bool> flipCamera() async {
    return await methodChannel.invokeMethod<bool>('flipCamera') ?? false;
  }

  // --- Audio ---
  @override
  Future<bool> startAudio({bool enableFFT = false}) async {
    return await methodChannel.invokeMethod<bool>('startAudio', {'enableFFT': enableFFT}) ?? false;
  }

  @override
  Future<bool> stopAudio() async {
    return await methodChannel.invokeMethod<bool>('stopAudio') ?? false;
  }

  // --- Intelligence & Logging ---
  @override
  Future<bool> startHardwareLogging(LogConfig config) async {
    return await methodChannel.invokeMethod<bool>('startLogging', {
      'fileName': config.fileName,
      'interval': config.intervalMs,
    }) ?? false;
  }

  @override
  Future<bool> stopHardwareLogging() async {
    return await methodChannel.invokeMethod<bool>('stopLogging') ?? false;
  }

  @override
  Future<bool> addGeofence(String id, double lat, double lon, double radius) async {
    return await methodChannel.invokeMethod<bool>('addGeofence', {
      'id': id,
      'lat': lat,
      'lon': lon,
      'radius': radius,
    }) ?? false;
  }

  // --- Bluetooth ---
  @override
  Future<bool> startBluetoothScan() async {
    return await methodChannel.invokeMethod<bool>('startBluetoothScan') ?? false;
  }

  @override
  Future<bool> stopBluetoothScan() async {
    return await methodChannel.invokeMethod<bool>('stopBluetoothScan') ?? false;
  }

  @override
  Future<bool> connectDevice(String id) async {
    return await methodChannel.invokeMethod<bool>('connectDevice', {'id': id}) ?? false;
  }

  @override
  Future<List<String>> discoverServices(String deviceId) async {
    final services = await methodChannel.invokeListMethod<String>('discoverServices', {'id': deviceId});
    return services ?? [];
  }

  @override
  Future<bool> sendData(String deviceId, String serviceId, String charId, List<int> data) async {
    return await methodChannel.invokeMethod<bool>('sendData', {
      'deviceId': deviceId,
      'serviceId': serviceId,
      'charId': charId,
      'data': data,
    }) ?? false;
  }

  // --- Biometrics ---
  @override
  Future<bool> authenticate(String reason) async {
    return await methodChannel.invokeMethod<bool>('authenticate', {'reason': reason}) ?? false;
  }

  @override
  Future<bool> canAuthenticate() async {
    return await methodChannel.invokeMethod<bool>('canAuthenticate') ?? false;
  }

  // --- Feedback ---
  @override
  Future<void> vibrate(int durationMs) async {
    await methodChannel.invokeMethod('vibrate', {'duration': durationMs});
  }

  @override
  Future<void> hapticFeedback(String type) async {
    await methodChannel.invokeMethod('hapticFeedback', {'type': type});
  }

  // --- Health ---
  @override
  Future<BatteryInfo?> getBatteryInfo() async {
    final map = await methodChannel.invokeMapMethod('getBatteryInfo');
    return map != null ? BatteryInfo.fromMap(map) : null;
  }

  @override
  Future<WifiInfo?> getWifiInfo() async {
    final map = await methodChannel.invokeMapMethod('getWifiInfo');
    return map != null ? WifiInfo.fromMap(map) : null;
  }

  // --- Location & Sensors ---
  @override
  Future<bool> startLocation() async {
    return await methodChannel.invokeMethod<bool>('startLocation') ?? false;
  }

  @override
  Future<bool> stopLocation() async {
    return await methodChannel.invokeMethod<bool>('stopLocation') ?? false;
  }

  @override
  Future<bool> startSensor({int frequencyHz = 60}) async {
    return await methodChannel.invokeMethod<bool>('startSensor', {'frequency': frequencyHz}) ?? false;
  }

  @override
  Future<bool> stopSensor() async {
    return await methodChannel.invokeMethod<bool>('stopSensor') ?? false;
  }

  @override
  Stream<HardwareEvent> get unifiedStream => eventChannel.receiveBroadcastStream().map((data) {
        final map = data as Map;
        return HardwareEvent(
          module: map['module'] as String,
          type: map['type'] as String,
          data: map['data'],
          timestamp: DateTime.now(),
        );
      });
}
