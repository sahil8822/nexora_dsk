import 'package:flutter_test/flutter_test.dart';
import 'package:my_hardware_plugin/my_hardware_plugin.dart';
import 'package:my_hardware_plugin/my_hardware_plugin_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockMyHardwarePluginPlatform
    with MockPlatformInterfaceMixin
    implements MyHardwarePluginPlatform {
  @override
  Future<bool> startCamera() => Future.value(true);
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
  Stream<HardwareEvent> get unifiedStream => Stream.empty();
}

void main() {
  test('MyHardwarePlugin.instance is singleton', () {
    expect(MyHardwarePlugin.instance, isNotNull);
  });

  test('camera start/stop', () async {
    final sdk = MyHardwarePlugin.instance;
    MockMyHardwarePluginPlatform fakePlatform = MockMyHardwarePluginPlatform();
    MyHardwarePluginPlatform.instance = fakePlatform;

    expect(await sdk.camera.start(), true);
    expect(await sdk.camera.stop(), true);
  });
}
