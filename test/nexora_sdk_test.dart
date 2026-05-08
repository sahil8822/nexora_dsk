import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexora_sdk/nexora_sdk_platform_interface.dart';
import 'package:nexora_sdk/models/hardware_models.dart';
import 'package:nexora_sdk/core/hardware_core.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockNexoraSdkPlatform
    with MockPlatformInterfaceMixin
    implements NexoraSdkPlatform {
  @override
  Future<String?> getPlatformVersion() => Future.value('42');
  @override
  Future<bool> requestPermissions() => Future.value(true);
  @override
  Future<bool> requestCameraPermission() => Future.value(true);
  @override
  Future<bool> requestAudioPermission() => Future.value(true);
  @override
  Future<bool> requestLocationPermission() => Future.value(true);
  @override
  Future<bool> requestBluetoothPermission() => Future.value(true);

  @override
  Future<bool> startCamera({int width = 1280, int height = 720}) =>
      Future.value(true);
  @override
  Future<bool> stopCamera() => Future.value(true);
  @override
  Future<bool> setVisionMode({bool barcode = false, bool face = false}) =>
      Future.value(true);
  @override
  Future<bool> setFlash(bool on) => Future.value(true);
  @override
  Future<bool> setZoom(double level) => Future.value(true);
  @override
  Future<bool> flipCamera() => Future.value(true);

  @override
  Future<bool> startAudio({
    bool enableFFT = false,
    bool streamBytes = false,
    int updateIntervalMs = 80,
  }) => Future.value(true);
  @override
  Future<bool> stopAudio() => Future.value(true);

  @override
  Future<bool> startHardwareLogging(LogConfig config) => Future.value(true);
  @override
  Future<bool> stopHardwareLogging() => Future.value(true);
  @override
  Future<bool> addGeofence(String id, double lat, double lon, double radius) =>
      Future.value(true);

  @override
  Future<bool> startBluetoothScan() => Future.value(true);
  @override
  Future<bool> stopBluetoothScan() => Future.value(true);
  @override
  Future<bool> connectDevice(String id) => Future.value(true);
  @override
  Future<List<String>> discoverServices(String deviceId) =>
      Future.value(['test_service']);
  @override
  Future<bool> sendData(
    String deviceId,
    String serviceId,
    String charId,
    List<int> data,
  ) => Future.value(true);

  @override
  Future<bool> authenticate(String reason) => Future.value(true);
  @override
  Future<bool> canAuthenticate() => Future.value(true);

  @override
  Future<void> vibrate(int durationMs) => Future.value();
  @override
  Future<void> hapticFeedback(String type) => Future.value();

  @override
  Future<BatteryInfo?> getBatteryInfo() => Future.value(null);
  @override
  Future<WifiInfo?> getWifiInfo() => Future.value(null);

  @override
  Future<bool> startLocation() => Future.value(true);
  @override
  Future<bool> stopLocation() => Future.value(true);
  @override
  Future<bool> setBackgroundLocationEnabled(bool enabled) => Future.value(true);
  @override
  Future<bool> startSensor({int frequencyHz = 60}) => Future.value(true);
  @override
  Future<bool> stopSensor() => Future.value(true);

  @override
  Stream<HardwareEvent> get unifiedStream => const Stream.empty();
  @override
  Stream<CameraFrame> get cameraStream => const Stream.empty();
  @override
  Stream<AudioFrame> get audioStream => const Stream.empty();
  @override
  Stream<BleDevice> get bluetoothStream => const Stream.empty();
  @override
  Stream<LocationData> get locationStream => const Stream.empty();
  @override
  Stream<HardwareEvent> get sensorStream => const Stream.empty();

  // --- Storage Mocks ---
  @override
  Future<StorageInfo?> getStorageInfo() => Future.value(null);
  @override
  Future<String?> writeFile(String fileName, String content) =>
      Future.value(null);
  @override
  Future<String?> readFile(String fileName) => Future.value(null);
  @override
  Future<bool> deleteFile(String fileName) => Future.value(false);
  @override
  Future<bool> fileExists(String fileName) => Future.value(false);
  @override
  Future<List<FileInfo>> listFiles() => Future.value([]);
  @override
  Future<String?> writeBytes(String fileName, dynamic bytes) =>
      Future.value(null);
  @override
  Future<Uint8List?> readBytes(String fileName) => Future.value(null);
  @override
  Future<bool> clearCache() => Future.value(true);
  @override
  Future<String?> getAppDirectory() => Future.value('/test');
  @override
  Future<String?> getCacheDirectory() => Future.value('/test/cache');
  @override
  Future<String?> getExternalDirectory() => Future.value(null);
}

void main() {
  test('getPlatformVersion', () async {
    MockNexoraSdkPlatform fakePlatform = MockNexoraSdkPlatform();
    NexoraSdkPlatform.instance = fakePlatform;
    expect(await NexoraSdkPlatform.instance.getPlatformVersion(), '42');
  });
}
