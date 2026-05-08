import '../../models/device_models.dart';
import '../../nexora_sdk_platform_interface.dart';

/// Device identity, memory, display, CPU, and thermal diagnostics.
class DeviceModule {
  /// Returns a native device information snapshot.
  Future<DeviceInfo> getInfo() => NexoraSdkPlatform.instance.getDeviceInfo();
}
