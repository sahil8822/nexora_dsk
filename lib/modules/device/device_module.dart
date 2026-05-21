import 'package:nexora_sdk_platform_interface/models/device_models.dart';
import 'package:nexora_sdk_platform_interface/nexora_sdk_platform_interface.dart';

/// Device identity, memory, display, CPU, and thermal diagnostics.
class DeviceModule {
  /// Returns a native device information snapshot.
  Future<DeviceInfo> getInfo() => NexoraSdkPlatform.instance.getDeviceInfo();
}
