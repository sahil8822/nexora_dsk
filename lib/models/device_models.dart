/// Basic device and OS details for native-feeling Flutter apps.
class DeviceInfo {
  const DeviceInfo({
    required this.platform,
    required this.manufacturer,
    required this.model,
    required this.osVersion,
    required this.sdkVersion,
    required this.isPhysicalDevice,
    required this.totalRamBytes,
    required this.availableRamBytes,
    required this.cpuArchitecture,
    required this.screenRefreshRate,
    required this.thermalState,
  });

  final String platform;
  final String manufacturer;
  final String model;
  final String osVersion;
  final String sdkVersion;
  final bool isPhysicalDevice;
  final int totalRamBytes;
  final int availableRamBytes;
  final String cpuArchitecture;
  final double screenRefreshRate;
  final String thermalState;

  factory DeviceInfo.fromMap(Map<dynamic, dynamic> map) {
    return DeviceInfo(
      platform: map['platform'] as String? ?? 'unknown',
      manufacturer: map['manufacturer'] as String? ?? 'unknown',
      model: map['model'] as String? ?? 'unknown',
      osVersion: map['osVersion'] as String? ?? 'unknown',
      sdkVersion: map['sdkVersion'] as String? ?? 'unknown',
      isPhysicalDevice: map['isPhysicalDevice'] as bool? ?? true,
      totalRamBytes: (map['totalRamBytes'] as num?)?.toInt() ?? 0,
      availableRamBytes: (map['availableRamBytes'] as num?)?.toInt() ?? 0,
      cpuArchitecture: map['cpuArchitecture'] as String? ?? 'unknown',
      screenRefreshRate: (map['screenRefreshRate'] as num?)?.toDouble() ?? 0,
      thermalState: map['thermalState'] as String? ?? 'unknown',
    );
  }

  Map<String, Object> toMap() => <String, Object>{
    'platform': platform,
    'manufacturer': manufacturer,
    'model': model,
    'osVersion': osVersion,
    'sdkVersion': sdkVersion,
    'isPhysicalDevice': isPhysicalDevice,
    'totalRamBytes': totalRamBytes,
    'availableRamBytes': availableRamBytes,
    'cpuArchitecture': cpuArchitecture,
    'screenRefreshRate': screenRefreshRate,
    'thermalState': thermalState,
  };
}

/// Snapshot of the current network route.
class ConnectivityInfo {
  const ConnectivityInfo({
    required this.isConnected,
    required this.networkType,
    required this.isMetered,
    required this.isVpn,
    required this.signalStrength,
    required this.ipAddress,
  });

  final bool isConnected;
  final String networkType;
  final bool isMetered;
  final bool isVpn;
  final int? signalStrength;
  final String? ipAddress;

  factory ConnectivityInfo.fromMap(Map<dynamic, dynamic> map) {
    return ConnectivityInfo(
      isConnected: map['isConnected'] as bool? ?? false,
      networkType: map['networkType'] as String? ?? 'unknown',
      isMetered: map['isMetered'] as bool? ?? false,
      isVpn: map['isVpn'] as bool? ?? false,
      signalStrength: (map['signalStrength'] as num?)?.toInt(),
      ipAddress: map['ipAddress'] as String?,
    );
  }

  Map<String, Object?> toMap() => <String, Object?>{
    'isConnected': isConnected,
    'networkType': networkType,
    'isMetered': isMetered,
    'isVpn': isVpn,
    'signalStrength': signalStrength,
    'ipAddress': ipAddress,
  };
}
