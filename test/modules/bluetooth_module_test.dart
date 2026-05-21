import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexora_sdk/nexora_sdk.dart';
import 'package:nexora_sdk_platform_interface/nexora_sdk_platform_interface.dart';
import '../mocks/mock_platform.dart';

class MockBluetoothPlatform extends MockNexoraSdkPlatform {
  bool isScanning = false;
  bool requestPermissionResult = true;
  String connectedDevice = '';
  String disconnectedDevice = '';
  List<int> sentData = [];
  bool shouldReturnReadData = true;

  @override
  Future<bool> requestBluetoothPermission() async => requestPermissionResult;

  @override
  Future<bool> startBluetoothScan() async {
    isScanning = true;
    return true;
  }

  @override
  Future<bool> startBluetoothScanWithOptions(
    BluetoothScanOptions options,
  ) async {
    isScanning = true;
    return true;
  }

  @override
  Future<bool> stopBluetoothScan() async {
    isScanning = false;
    return true;
  }

  @override
  Future<bool> connectDevice(String id) async {
    connectedDevice = id;
    return true;
  }

  @override
  Future<bool> disconnectDevice(String id) async {
    disconnectedDevice = id;
    return true;
  }

  @override
  Future<List<String>> discoverServices(String deviceId) async {
    return ['srv-1', 'srv-2'];
  }

  @override
  Future<bool> sendData(
    String deviceId,
    String serviceId,
    String charId,
    List<int> data,
  ) async {
    sentData = data;
    return true;
  }

  @override
  Future<Uint8List?> readData(
    String deviceId,
    String serviceId,
    String charId,
  ) async {
    return shouldReturnReadData ? Uint8List.fromList([1, 2, 3]) : null;
  }

  @override
  Stream<Uint8List> openL2capStream(String deviceId, int psm) {
    return Stream.value(Uint8List.fromList([42]));
  }
}

void main() {
  late MockBluetoothPlatform mockPlatform;

  setUp(() {
    mockPlatform = MockBluetoothPlatform();
    NexoraSdkPlatform.instance = mockPlatform;
  });

  group('BluetoothModule Tests', () {
    test('startScan() / stopScan() success', () async {
      final ble = BluetoothModule();
      expect(ble.isScanning, false);
      expect(await ble.startScan(), true);
      expect(ble.isScanning, true);
      expect(await ble.stopScan(), true);
      expect(ble.isScanning, false);
    });

    test('startScanWithOptions() permission denied', () async {
      mockPlatform.requestPermissionResult = false;
      final ble = BluetoothModule();
      final success = await ble.startScanWithOptions(
        const BluetoothScanOptions(),
      );
      expect(success, false);
      expect(ble.isScanning, false);
    });

    test('connect() & disconnect() validation', () async {
      final ble = BluetoothModule();
      expect(() => ble.connect(''), throwsArgumentError);
      expect(() => ble.disconnect(''), throwsArgumentError);

      expect(await ble.connect('dev-123'), true);
      expect(mockPlatform.connectedDevice, 'dev-123');

      expect(await ble.disconnect('dev-123'), true);
      expect(mockPlatform.disconnectedDevice, 'dev-123');
    });

    test('discoverServices()', () async {
      final ble = BluetoothModule();
      expect(() => ble.discoverServices(''), throwsArgumentError);
      final services = await ble.discoverServices('dev-123');
      expect(services, ['srv-1', 'srv-2']);
    });

    test('sendData() & readData()', () async {
      final ble = BluetoothModule();
      expect(() => ble.sendData('', 'srv', 'chr', [1]), throwsArgumentError);
      expect(() => ble.sendData('dev', '', 'chr', [1]), throwsArgumentError);
      expect(() => ble.sendData('dev', 'srv', '', [1]), throwsArgumentError);
      expect(() => ble.sendData('dev', 'srv', 'chr', []), throwsArgumentError);

      expect(await ble.sendData('dev', 'srv', 'chr', [10, 20]), true);
      expect(mockPlatform.sentData, [10, 20]);

      final data = await ble.readData('dev', 'srv', 'chr');
      expect(data, [1, 2, 3]);

      mockPlatform.shouldReturnReadData = false;
      final nullData = await ble.readData('dev', 'srv', 'chr');
      expect(nullData, null);
    });

    test('openL2capStream() validation', () async {
      final ble = BluetoothModule();
      expect(() => ble.openL2capStream('', 10), throwsArgumentError);
      expect(() => ble.openL2capStream('dev', 0), throwsArgumentError);
      expect(() => ble.openL2capStream('dev', -5), throwsArgumentError);

      final stream = ble.openL2capStream('dev', 42);
      expect(await stream.first, [42]);
    });
  });
}
