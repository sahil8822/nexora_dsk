import 'dart:async';
import 'package:nexora_sdk/models/hardware_models.dart';
import '../../nexora_sdk_platform_interface.dart';

/// Module for managing Bluetooth Low Energy (BLE) operations.
/// Supports scanning for devices and connecting to GATT peripherals.
class BluetoothModule {
  /// Internal constructor for singleton-like access via NexoraSdk.
  BluetoothModule();

  /// Returns a stream of [BleDevice] discovered during scanning.
  Stream<BleDevice> get scanStream => NexoraSdkPlatform.instance.bluetoothStream;

  /// Starts scanning for nearby BLE devices.
  /// Ensure Bluetooth permissions are granted before calling this.
  Future<bool> startScan() => NexoraSdkPlatform.instance.startBluetoothScan();

  /// Stops the active BLE scan to conserve battery.
  Future<bool> stopScan() => NexoraSdkPlatform.instance.stopBluetoothScan();

  /// Attempts to connect to a specific BLE device by its unique [id].
  /// Returns true if the connection request was successfully initiated.
  Future<bool> connect(String id) => NexoraSdkPlatform.instance.connectDevice(id);
}
