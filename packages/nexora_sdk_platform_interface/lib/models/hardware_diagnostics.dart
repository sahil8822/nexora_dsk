import 'package:nexora_sdk_platform_interface/models/device_models.dart';
import 'package:nexora_sdk_platform_interface/models/hardware_capabilities.dart';
import 'package:nexora_sdk_platform_interface/models/hardware_models.dart';

/// A point-in-time device and SDK diagnostics snapshot.
class HardwareDiagnostics {
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

  final DateTime generatedAt;
  final String? platformVersion;
  final HardwareCapabilities capabilities;
  final StorageInfo? storage;
  final BatteryInfo? battery;
  final WifiInfo? wifi;
  final DeviceInfo? device;
  final ConnectivityInfo? connectivity;

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
