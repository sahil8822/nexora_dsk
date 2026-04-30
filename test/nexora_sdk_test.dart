import 'package:flutter_test/flutter_test.dart';
import 'package:nexora_sdk/nexora_sdk.dart';
import 'package:nexora_sdk/nexora_sdk_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockNexoraSdkPlatform extends NexoraSdkPlatform
    with MockPlatformInterfaceMixin {
  @override
  Future<bool> startCamera({int width = 640, int height = 480}) => Future.value(true);
  @override
  Future<bool> stopCamera() => Future.value(true);
  @override
  Future<bool> startBluetoothScan() => Future.value(true);
  @override
  Future<bool> stopBluetoothScan() => Future.value(true);
  @override
  Future<bool> connectDevice(String id) => Future.value(true);
  @override
  Future<WifiInfo?> getWifiInfo() => Future.value(null);
  @override
  Future<bool> startLocation() => Future.value(true);
  @override
  Future<bool> stopLocation() => Future.value(true);
  @override
  Future<bool> startSensor({int frequencyHz = 60}) => Future.value(true);
  @override
  Future<bool> stopSensor() => Future.value(true);
  @override
  Future<bool> requestPermissions() => Future.value(true);
  @override
  Stream<HardwareEvent> get unifiedStream => Stream.empty();
}

void main() {
  test('NexoraSdk.instance is singleton', () {
    expect(NexoraSdk.instance, isNotNull);
  });

  test('camera start/stop', () async {
    final sdk = NexoraSdk.instance;
    MockNexoraSdkPlatform fakePlatform = MockNexoraSdkPlatform();
    NexoraSdkPlatform.instance = fakePlatform;

    expect(await sdk.camera.start(), true);
    expect(await sdk.camera.stop(), true);
  });

  test('bluetooth scan start/stop', () async {
    final sdk = NexoraSdk.instance;
    MockNexoraSdkPlatform fakePlatform = MockNexoraSdkPlatform();
    NexoraSdkPlatform.instance = fakePlatform;

    expect(await sdk.bluetooth.startScan(), true);
    expect(await sdk.bluetooth.stopScan(), true);
  });

  test('location start/stop', () async {
    final sdk = NexoraSdk.instance;
    MockNexoraSdkPlatform fakePlatform = MockNexoraSdkPlatform();
    NexoraSdkPlatform.instance = fakePlatform;

    expect(await sdk.location.start(), true);
    expect(await sdk.location.stop(), true);
  });
}
