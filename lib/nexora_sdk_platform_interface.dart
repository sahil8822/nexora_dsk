import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'models/hardware_models.dart';
import 'core/hardware_core.dart';
import 'nexora_sdk_method_channel.dart';

/// The interface that implementations of NexoraSdk must implement.
abstract class NexoraSdkPlatform extends PlatformInterface {
  /// Constructs a NexoraSdkPlatform.
  NexoraSdkPlatform() : super(token: _token);

  static final Object _token = Object();
  static NexoraSdkPlatform _instance = MethodChannelNexoraSdk();

  /// The default instance of [NexoraSdkPlatform] to use.
  static NexoraSdkPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [NexoraSdkPlatform] when
  /// they register themselves.
  static set instance(NexoraSdkPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  /// Returns the current platform version.
  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }

  /// Starts the camera with specified resolution.
  Future<bool> startCamera({int width = 640, int height = 480});
  
  /// Stops the camera.
  Future<bool> stopCamera();
  
  /// Starts scanning for Bluetooth devices.
  Future<bool> startBluetoothScan();
  
  /// Stops scanning for Bluetooth devices.
  Future<bool> stopBluetoothScan();
  
  /// Connects to a specific device.
  Future<bool> connectDevice(String id);
  
  /// Fetches current Wifi information.
  Future<WifiInfo?> getWifiInfo();
  
  /// Starts location updates.
  Future<bool> startLocation();
  
  /// Stops location updates.
  Future<bool> stopLocation();
  
  /// Starts sensor data stream.
  Future<bool> startSensor({int frequencyHz = 60});
  
  /// Stops sensor data stream.
  Future<bool> stopSensor();
  
  /// Requests all necessary permissions.
  Future<bool> requestPermissions();

  /// Stream of all hardware events.
  Stream<HardwareEvent> get unifiedStream;

  /// Stream filtered for camera frames.
  Stream<CameraFrame> get cameraStream => unifiedStream
      .where((e) => e.module == 'camera')
      .map((e) => CameraFrame.fromMap(e.data));

  /// Stream filtered for bluetooth devices.
  Stream<BleDevice> get bluetoothStream => unifiedStream
      .where((e) => e.module == 'bluetooth')
      .map((e) => BleDevice.fromMap(e.data));

  /// Stream filtered for GPS/Location data.
  Stream<LocationData> get locationStream => unifiedStream
      .where((e) => e.module == 'gps')
      .map((e) => LocationData.fromMap(e.data));
}
