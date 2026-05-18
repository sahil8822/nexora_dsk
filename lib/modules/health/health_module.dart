import '../../nexora_sdk_platform_interface.dart';
import '../../models/hardware_models.dart';

/// Advanced Health and Diagnostics Module.
class HealthModule {
  /// Retrieves current battery status and health info.
  /// Returns null if battery data is unavailable.
  Future<BatteryInfo?> getBatteryInfo() =>
      NexoraSdkPlatform.instance.getBatteryInfo();

  /// Retrieves current WiFi diagnostics.
  /// Returns null if WiFi data is unavailable.
  Future<WifiInfo?> getWifiInfo() => NexoraSdkPlatform.instance.getWifiInfo();

  /// Starts background logging of hardware telemetry.
  Future<bool> startLogging(LogConfig config) =>
      NexoraSdkPlatform.instance.startHardwareLogging(config);

  /// Stops hardware telemetry logging.
  Future<bool> stopLogging() =>
      NexoraSdkPlatform.instance.stopHardwareLogging();

  /// Configures log rolling parameters and target synchronization endpoint.
  Future<bool> enableSmartSync({
    required String uploadEndpointUrl,
    required Map<String, String> headers,
    int rollLimitBytes = 2 * 1024 * 1024, // 2MB
    bool requireWifi = true,
  }) {
    if (uploadEndpointUrl.trim().isEmpty) {
      throw ArgumentError.value(
        uploadEndpointUrl,
        'uploadEndpointUrl',
        'Upload endpoint URL cannot be empty.',
      );
    }
    return NexoraSdkPlatform.instance.enableSmartSync(
      uploadEndpointUrl: uploadEndpointUrl,
      headers: headers,
      rollLimitBytes: rollLimitBytes,
      requireWifi: requireWifi,
    );
  }
}
