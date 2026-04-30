import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'models/hardware_models.dart';
import 'core/hardware_core.dart';
import 'nexora_sdk_method_channel.dart';

/// The interface that implementations of NexoraSdk must implement.
abstract class NexoraSdkPlatform extends PlatformInterface {
  NexoraSdkPlatform() : super(token: _token);
  static final Object _token = Object();
  static NexoraSdkPlatform _instance = MethodChannelNexoraSdk();
  static NexoraSdkPlatform get instance => _instance;
  static set instance(NexoraSdkPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  // --- Base ---
  Future<String?> getPlatformVersion();
  Future<bool> requestPermissions();

  // --- Camera & Vision (AI) ---
  /// Starts the camera and returns the native texture ID or a success flag.
  Future<dynamic> startCamera({int width = 640, int height = 480});
  Future<bool> stopCamera();
  Future<bool> setVisionMode({bool barcode = false, bool face = false});
  Future<bool> setFlash(bool on);
  Future<bool> setZoom(double level);
  Future<bool> flipCamera();

  // --- Audio & Analysis (AI) ---
  Future<bool> startAudio({bool enableFFT = false});
  Future<bool> stopAudio();

  // --- Intelligence & Logging ---
  Future<bool> startHardwareLogging(LogConfig config);
  Future<bool> stopHardwareLogging();
  Future<bool> addGeofence(String id, double lat, double lon, double radius);

  // --- Bluetooth Pro ---
  Future<bool> startBluetoothScan();
  Future<bool> stopBluetoothScan();
  Future<bool> connectDevice(String id);
  Future<List<String>> discoverServices(String deviceId);
  Future<bool> sendData(String deviceId, String serviceId, String charId, List<int> data);

  // --- Biometrics & Security ---
  Future<bool> authenticate(String reason);
  Future<bool> canAuthenticate();

  // --- Feedback & Health ---
  Future<void> vibrate(int durationMs);
  Future<void> hapticFeedback(String type);
  Future<BatteryInfo?> getBatteryInfo();
  Future<WifiInfo?> getWifiInfo();

  // --- Location & Sensors ---
  Future<bool> startLocation();
  Future<bool> stopLocation();
  Future<bool> startSensor({int frequencyHz = 60});
  Future<bool> stopSensor();

  // --- Unified Streams ---
  Stream<HardwareEvent> get unifiedStream;

  Stream<CameraFrame> get cameraStream => unifiedStream
      .where((e) => e.module == 'camera')
      .map((e) => CameraFrame.fromMap(e.data));

  Stream<AudioFrame> get audioStream => unifiedStream
      .where((e) => e.module == 'audio')
      .map((e) => AudioFrame.fromMap(e.data));

  Stream<BleDevice> get bluetoothStream => unifiedStream
      .where((e) => e.module == 'bluetooth')
      .map((e) => BleDevice.fromMap(e.data));

  Stream<LocationData> get locationStream => unifiedStream
      .where((e) => e.module == 'gps')
      .map((e) => LocationData.fromMap(e.data));

  Stream<HardwareEvent> get sensorStream => unifiedStream
      .where((e) => e.module == 'sensor');
}
