import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'models/hardware_models.dart';
import 'core/hardware_core.dart';
import 'nexora_sdk_method_channel.dart';

abstract class NexoraSdkPlatform extends PlatformInterface {
  NexoraSdkPlatform() : super(token: _token);

  static final Object _token = Object();
  static NexoraSdkPlatform _instance = MethodChannelNexoraSdk();

  static NexoraSdkPlatform get instance => _instance;
  static set instance(NexoraSdkPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  // --- Base Platform Method ---
  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }

  // --- Subsystem Commands ---
  Future<bool> startCamera({int width = 640, int height = 480});
  Future<bool> stopCamera();
  Future<bool> startBluetoothScan();
  Future<bool> stopBluetoothScan();
  Future<bool> connectDevice(String id);
  Future<WifiInfo?> getWifiInfo();
  Future<bool> startLocation();
  Future<bool> stopLocation();
  Future<bool> startSensor({int frequencyHz = 60});
  Future<bool> stopSensor();
  Future<bool> requestPermissions();

  // --- Stream Access ---
  Stream<HardwareEvent> get unifiedStream;

  Stream<CameraFrame> get cameraStream => unifiedStream
      .where((e) => e.module == 'camera')
      .map((e) => CameraFrame.fromMap(e.data));

  Stream<BleDevice> get bluetoothStream => unifiedStream
      .where((e) => e.module == 'bluetooth')
      .map((e) => BleDevice.fromMap(e.data));

  Stream<LocationData> get locationStream => unifiedStream
      .where((e) => e.module == 'gps')
      .map((e) => LocationData.fromMap(e.data));
}
