import 'dart:async';
import 'dart:html' as html;
import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'nexora_sdk_platform_interface.dart';
import 'core/hardware_core.dart';
import 'models/hardware_models.dart';

/// Nexora SDK Web Implementation.
/// Updated for v3.0 Intelligence Edition.
class NexoraSdkWeb extends NexoraSdkPlatform {
  static void registerWith(Registrar registrar) {
    NexoraSdkPlatform.instance = NexoraSdkWeb();
  }

  final StreamController<HardwareEvent> _eventController = StreamController<HardwareEvent>.broadcast();
  html.MediaStream? _cameraStream;
  String _facingMode = 'user';

  @override
  Stream<HardwareEvent> get unifiedStream => _eventController.stream;

  @override
  Future<String?> getPlatformVersion() async => 'Web Browsers';

  @override
  Future<bool> requestPermissions() async => true;

  // --- Camera & Vision ---
  @override
  Future<dynamic> startCamera({int width = 640, int height = 480}) async {
    try {
      final constraints = {'video': {'width': width, 'height': height, 'facingMode': _facingMode}};
      _cameraStream = await html.window.navigator.mediaDevices?.getUserMedia(constraints);
      return true; // Web uses video tags, not texture IDs currently
    } catch (e) { return false; }
  }

  @override
  Future<bool> stopCamera() async {
    _cameraStream?.getTracks().forEach((track) => track.stop());
    _cameraStream = null;
    return true;
  }

  @override
  Future<bool> setVisionMode({bool barcode = false, bool face = false}) async => false;
  @override
  Future<bool> setFlash(bool on) async => false;
  @override
  Future<bool> setZoom(double level) async => true;
  @override
  Future<bool> flipCamera() async {
    _facingMode = (_facingMode == 'user') ? 'environment' : 'user';
    await stopCamera();
    return await startCamera();
  }

  // --- Audio & FFT ---
  @override
  Future<bool> startAudio({bool enableFFT = false}) async => true;
  @override
  Future<bool> stopAudio() async => true;

  // --- Intelligence ---
  @override
  Future<bool> startHardwareLogging(LogConfig config) async => false;
  @override
  Future<bool> stopHardwareLogging() async => false;
  @override
  Future<bool> addGeofence(String id, double lat, double lon, double radius) async => false;

  // --- Bluetooth ---
  @override
  Future<bool> startBluetoothScan() async => true;
  @override
  Future<bool> stopBluetoothScan() async => true;
  @override
  Future<bool> connectDevice(String id) async => true;
  @override
  Future<List<String>> discoverServices(String deviceId) async => [];
  @override
  Future<bool> sendData(String d, String s, String c, List<int> data) async => true;

  // --- Biometrics ---
  @override
  Future<bool> authenticate(String reason) async => true;
  @override
  Future<bool> canAuthenticate() async => false;

  // --- Feedback ---
  @override
  Future<void> vibrate(int durationMs) async {
    (html.window.navigator as dynamic).vibrate(durationMs);
  }
  @override
  Future<void> hapticFeedback(String type) async {
    (html.window.navigator as dynamic).vibrate(50);
  }

  // --- Health ---
  @override
  Future<BatteryInfo?> getBatteryInfo() async {
    try {
      final battery = await (html.window.navigator as dynamic).getBattery();
      return BatteryInfo(
        level: battery.level.toDouble(),
        isCharging: battery.charging,
        status: battery.charging ? 'charging' : 'discharging',
        temperature: 0.0
      );
    } catch (e) { return null; }
  }

  @override
  Future<WifiInfo?> getWifiInfo() async => null;

  // --- Location & Sensors ---
  @override
  Future<bool> startLocation() async => true;
  @override
  Future<bool> stopLocation() async => true;
  @override
  Future<bool> startSensor({int frequencyHz = 60}) async => true;
  @override
  Future<bool> stopSensor() async => true;
}
