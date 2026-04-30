import '../../nexora_sdk_platform_interface.dart';
import '../../models/hardware_models.dart';

/// Module for monitoring device health, power, and connectivity.
class HealthModule {
  /// Fetches real-time battery diagnostics (level, temperature, charging).
  Future<BatteryInfo?> getBattery() => NexoraSdkPlatform.instance.getBatteryInfo();

  /// Fetches basic WiFi connection metadata.
  Future<WifiInfo?> getWifi() => NexoraSdkPlatform.instance.getWifiInfo();
}
