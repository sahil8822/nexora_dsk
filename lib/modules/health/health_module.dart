import '../../nexora_sdk_platform_interface.dart';
import '../../models/hardware_models.dart';

/// Advanced Health and Diagnostics Module.
class HealthModule {
  /// Retrieves current battery status and health info.
  /// Returns null if battery data is unavailable.
  Future<BatteryInfo?> getBatteryInfo() =>
      NexoraSdkPlatform.instance.getBatteryInfo();

  /// Starts background logging of hardware telemetry.
  Future<bool> startLogging(LogConfig config) =>
      NexoraSdkPlatform.instance.startHardwareLogging(config);

  /// Stops hardware telemetry logging.
  Future<bool> stopLogging() =>
      NexoraSdkPlatform.instance.stopHardwareLogging();
}
