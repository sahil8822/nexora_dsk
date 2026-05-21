import 'package:nexora_sdk_platform_interface/models/device_models.dart';
import 'package:nexora_sdk_platform_interface/models/hardware_capabilities.dart';
import 'package:nexora_sdk_platform_interface/models/hardware_models.dart';

/// A point-in-time device and SDK diagnostics snapshot.
class HardwareDiagnostics {
  /// API Documentation for HardwareDiagnostics.
  const HardwareDiagnostics({
    required this.generatedAt,
    required this.platformVersion,
    required this.capabilities,
    required this.storage,
    required this.battery,
    required this.wifi,
    required this.device,
    required this.connectivity,
  });

  /// API Documentation for generatedAt;.
  final DateTime generatedAt;

  /// API Documentation for platformVersion;.
  final String? platformVersion;

  /// API Documentation for capabilities;.
  final HardwareCapabilities capabilities;

  /// API Documentation for storage;.
  final StorageInfo? storage;

  /// API Documentation for battery;.
  final BatteryInfo? battery;

  /// API Documentation for wifi;.
  final WifiInfo? wifi;

  /// API Documentation for device;.
  final DeviceInfo? device;

  /// API Documentation for connectivity;.
  final ConnectivityInfo? connectivity;

  /// API Documentation for toMap.
  Map<String, Object?> toMap() => <String, Object?>{
        'generatedAt': generatedAt.toIso8601String(),
        'platformVersion': platformVersion,
        'capabilities': capabilities.toMap(),
        'storage': storage?.toMap(),
        'battery': battery?.toMap(),
        'wifi': wifi?.toMap(),
        'device': device?.toMap(),
        'connectivity': connectivity?.toMap(),
      };
}
