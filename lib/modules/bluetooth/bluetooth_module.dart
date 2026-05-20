import 'dart:typed_data';
import '../../nexora_sdk_platform_interface.dart';
import '../../models/hardware_models.dart';

/// Module for high-performance Bluetooth Low Energy (BLE) management.
class BluetoothModule {
  bool _isScanning = false;

  /// Returns true if a BLE scan is currently active.
  bool get isScanning => _isScanning;

  /// Starts scanning for nearby BLE devices. Discovered devices are
  /// delivered via the [scanStream].
  Future<bool> startScan() async {
    final result = await NexoraSdkPlatform.instance.startBluetoothScan();
    if (result) _isScanning = true;
    return result;
  }

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
    final result = await NexoraSdkPlatform.instance.startBluetoothScanWithOptions(options);
    if (result) _isScanning = true;
    return result;
  }

  /// Stops the active BLE scan.
  Future<bool> stopScan() async {
    final result = await NexoraSdkPlatform.instance.stopBluetoothScan();
    if (result) _isScanning = false;
    return result;
  }

  /// Attempts to connect to a specific BLE device by its [id].
  Future<bool> connect(String id) {
    _validateId(id, 'id');
    return NexoraSdkPlatform.instance.connectDevice(id);
  }

  /// Disconnects from the BLE device with the given [id].
  Future<bool> disconnect(String id) {
    _validateId(id, 'id');
    return NexoraSdkPlatform.instance.disconnectDevice(id);
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

  /// Reads raw byte data from a specific GATT characteristic.
  Future<Uint8List?> readData(
    String deviceId,
    String serviceId,
    String charId,
  ) {
    _validateId(deviceId, 'deviceId');
    _validateId(serviceId, 'serviceId');
    _validateId(charId, 'charId');
    return NexoraSdkPlatform.instance.readData(deviceId, serviceId, charId);
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
