import '../../nexora_sdk_platform_interface.dart';
import '../../models/hardware_models.dart';

/// Module for high-performance Bluetooth Low Energy (BLE) management.
class BluetoothModule {
  /// Starts scanning for nearby BLE devices. Discovered devices are 
  /// delivered via the [scanStream].
  Future<bool> startScan() => NexoraSdkPlatform.instance.startBluetoothScan();

  /// Stops the active BLE scan.
  Future<bool> stopScan() => NexoraSdkPlatform.instance.stopBluetoothScan();

  /// Attempts to connect to a specific BLE device by its [id].
  Future<bool> connect(String id) => NexoraSdkPlatform.instance.connectDevice(id);

  /// Discovers GATT services for a connected device.
  Future<List<String>> discoverServices(String deviceId) =>
      NexoraSdkPlatform.instance.discoverServices(deviceId);

  /// Sends raw byte data to a specific GATT characteristic.
  Future<bool> sendData(String deviceId, String serviceId, String charId, List<int> data) =>
      NexoraSdkPlatform.instance.sendData(deviceId, serviceId, charId, data);

  /// A stream of [BleDevice] objects discovered during a scan.
  Stream<BleDevice> get scanStream => NexoraSdkPlatform.instance.bluetoothStream;
}
