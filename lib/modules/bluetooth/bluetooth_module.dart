import 'dart:typed_data';
import '../../nexora_sdk_platform_interface.dart';
import '../../models/hardware_models.dart';

/// Module for high-performance Bluetooth Low Energy (BLE) management.
class BluetoothModule {
  /// Starts scanning for nearby BLE devices. Discovered devices are
  /// delivered via the [scanStream].
  Future<bool> startScan() => NexoraSdkPlatform.instance.startBluetoothScan();

  /// Starts scanning with granular native Bluetooth scanning options.
  Future<bool> startScanWithOptions(
    BluetoothScanOptions options, {
    bool autoRequestPermission = true,
  }) async {
    if (autoRequestPermission) {
      final granted = await NexoraSdkPlatform.instance
          .requestBluetoothPermission();
      if (!granted) return false;
    }
    return NexoraSdkPlatform.instance.startBluetoothScanWithOptions(options);
  }

  /// Stops the active BLE scan.
  Future<bool> stopScan() => NexoraSdkPlatform.instance.stopBluetoothScan();

  /// Attempts to connect to a specific BLE device by its [id].
  Future<bool> connect(String id) {
    _validateId(id, 'id');
    return NexoraSdkPlatform.instance.connectDevice(id);
  }

  /// Discovers GATT services for a connected device.
  Future<List<String>> discoverServices(String deviceId) {
    _validateId(deviceId, 'deviceId');
    return NexoraSdkPlatform.instance.discoverServices(deviceId);
  }

  /// Sends raw byte data to a specific GATT characteristic.
  Future<bool> sendData(
    String deviceId,
    String serviceId,
    String charId,
    List<int> data,
  ) {
    _validateId(deviceId, 'deviceId');
    _validateId(serviceId, 'serviceId');
    _validateId(charId, 'charId');
    if (data.isEmpty) {
      throw ArgumentError.value(data, 'data', 'Data cannot be empty.');
    }
    return NexoraSdkPlatform.instance.sendData(
      deviceId,
      serviceId,
      charId,
      data,
    );
  }

  /// Opens a raw binary socket directly to a BLE device over L2CAP.
  /// Returns a stream of [Uint8List] bytes.
  Stream<Uint8List> openL2capStream(String deviceId, int psm) {
    if (deviceId.trim().isEmpty) {
      throw ArgumentError.value(
        deviceId,
        'deviceId',
        'Device ID cannot be empty.',
      );
    }
    if (psm <= 0) {
      throw ArgumentError.value(psm, 'psm', 'PSM must be greater than zero.');
    }
    return NexoraSdkPlatform.instance.openL2capStream(deviceId, psm);
  }

  /// A stream of [BleDevice] objects discovered during a scan.
  Stream<BleDevice> get scanStream =>
      NexoraSdkPlatform.instance.bluetoothStream;

  void _validateId(String value, String name) {
    if (value.trim().isEmpty) {
      throw ArgumentError.value(value, name, 'Value cannot be empty.');
    }
  }
}
