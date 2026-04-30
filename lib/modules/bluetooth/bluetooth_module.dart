import 'package:nexora_sdk/models/hardware_models.dart';
import '../../nexora_sdk_platform_interface.dart';

/// Modular Bluetooth LE Module.
/// Features scanning, connecting, and characteristic streaming.
class BluetoothModule {
  Future<bool> startScan() async {
    return await NexoraSdkPlatform.instance.startBluetoothScan();
  }

  Future<bool> stopScan() async {
    return await NexoraSdkPlatform.instance.stopBluetoothScan();
  }

  Future<bool> connect(String deviceId) async {
    return await NexoraSdkPlatform.instance.connectDevice(deviceId);
  }

  /// Real-time BLE device and data stream.
  Stream<BleDevice> get deviceStream =>
      NexoraSdkPlatform.instance.bluetoothStream;
}
