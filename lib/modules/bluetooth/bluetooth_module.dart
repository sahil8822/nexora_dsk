import 'dart:async';
import 'dart:math';
import 'dart:typed_data';
import '../../nexora_sdk_platform_interface.dart';
import '../../models/hardware_models.dart';
import '../../core/concurrency.dart';

/// Module for high-performance Bluetooth Low Energy (BLE) management.
class BluetoothModule {
  final Mutex _mutex = Mutex();
  bool _isScanning = false;

  final Set<String> _desiredConnectedDevices = {};
  final Map<String, StreamSubscription> _statusSubscriptions = {};
  final Map<String, int> _reconnectAttempts = {};

  /// Returns true if a BLE scan is currently active.
  bool get isScanning => _isScanning;

  /// Starts scanning for nearby BLE devices. Discovered devices are
  /// delivered via the [scanStream].
  Future<bool> startScan() async {
    return _mutex.protect(() async {
      final result = await NexoraSdkPlatform.instance.startBluetoothScan();
      if (result) _isScanning = true;
      return result;
    });
  }

  /// Starts scanning with granular native Bluetooth scanning options.
  Future<bool> startScanWithOptions(
    BluetoothScanOptions options, {
    bool autoRequestPermission = true,
  }) async {
    return _mutex.protect(() async {
      if (autoRequestPermission) {
        final granted = await NexoraSdkPlatform.instance
            .requestBluetoothPermission();
        if (!granted) return false;
      }
      final result = await NexoraSdkPlatform.instance.startBluetoothScanWithOptions(options);
      if (result) _isScanning = true;
      return result;
    });
  }

  /// Stops the active BLE scan.
  Future<bool> stopScan() async {
    return _mutex.protect(() async {
      final result = await NexoraSdkPlatform.instance.stopBluetoothScan();
      if (result) _isScanning = false;
      return result;
    });
  }

  /// Attempts to connect to a specific BLE device by its [id].
  Future<bool> connect(String id, {bool autoReconnect = true}) {
    _validateId(id, 'id');
    return _mutex.protect(() async {
      _desiredConnectedDevices.add(id);
      final result = await NexoraSdkPlatform.instance.connectDevice(id);
      if (result) {
        _reconnectAttempts[id] = 0;
        _setupStatusSubscription(id, autoReconnect);
      }
      return result;
    });
  }

  /// Disconnects from the BLE device with the given [id].
  Future<bool> disconnect(String id) {
    _validateId(id, 'id');
    return _mutex.protect(() async {
      _desiredConnectedDevices.remove(id);
      _statusSubscriptions[id]?.cancel();
      _statusSubscriptions.remove(id);
      _reconnectAttempts.remove(id);
      return NexoraSdkPlatform.instance.disconnectDevice(id);
    });
  }

  void _setupStatusSubscription(String id, bool autoReconnect) {
    _statusSubscriptions[id]?.cancel();
    if (!autoReconnect) return;
    
    _statusSubscriptions[id] = NexoraSdkPlatform.instance.unifiedStream
        .where((e) => e.module == 'bluetooth' && e.type == 'status')
        .listen((e) {
          final data = e.data as Map?;
          if (data != null && data['id'] == id) {
            final state = data['state'] as String?;
            if (state == 'disconnected' && _desiredConnectedDevices.contains(id)) {
              _triggerReconnect(id);
            }
          }
        });
  }

  void _triggerReconnect(String id) {
    final attempts = _reconnectAttempts[id] ?? 0;
    if (attempts >= 5) {
      _reconnectAttempts.remove(id);
      return;
    }
    _reconnectAttempts[id] = attempts + 1;
    final delay = Duration(seconds: pow(2, attempts).toInt());
    Timer(delay, () async {
      if (_desiredConnectedDevices.contains(id)) {
        final success = await NexoraSdkPlatform.instance.connectDevice(id);
        if (success) {
          _reconnectAttempts[id] = 0;
        } else {
          _triggerReconnect(id);
        }
      }
    });
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
