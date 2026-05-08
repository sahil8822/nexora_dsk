import 'device_models.dart';
import 'hardware_capabilities.dart';
import 'hardware_models.dart';

/// Detailed result for requesting the core runtime permissions.
class HardwarePermissionReport {
  const HardwarePermissionReport({
    required this.camera,
    required this.audio,
    required this.location,
    required this.bluetooth,
  });

  final bool camera;
  final bool audio;
  final bool location;
  final bool bluetooth;

  bool get allGranted => camera && audio && location && bluetooth;

  List<String> get deniedPermissions => <String>[
    if (!camera) 'camera',
    if (!audio) 'audio',
    if (!location) 'location',
    if (!bluetooth) 'bluetooth',
  ];

  Map<String, bool> toMap() => <String, bool>{
    'camera': camera,
    'audio': audio,
    'location': location,
    'bluetooth': bluetooth,
  };
}

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
