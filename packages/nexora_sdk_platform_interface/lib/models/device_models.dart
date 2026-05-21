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

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DeviceInfo &&
        other.platform == platform &&
        other.manufacturer == manufacturer &&
        other.model == model &&
        other.osVersion == osVersion &&
        other.sdkVersion == sdkVersion &&
        other.isPhysicalDevice == isPhysicalDevice &&
        other.totalRamBytes == totalRamBytes &&
        other.availableRamBytes == availableRamBytes &&
        other.cpuArchitecture == cpuArchitecture &&
        other.screenRefreshRate == screenRefreshRate &&
        other.thermalState == thermalState;
  }

  @override
  int get hashCode => Object.hash(
    platform,
    manufacturer,
    model,
    osVersion,
    sdkVersion,
    isPhysicalDevice,
    totalRamBytes,
    availableRamBytes,
    cpuArchitecture,
    screenRefreshRate,
    thermalState,
  );

  @override
  String toString() {
    return 'DeviceInfo(platform: $platform, manufacturer: $manufacturer, model: $model, os: $osVersion, sdk: $sdkVersion, physical: $isPhysicalDevice, ram: $totalRamBytes, cpu: $cpuArchitecture, refresh: $screenRefreshRate, thermal: $thermalState)';
  }
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

  final bool isConnected;
  final String networkType;
  final bool isMetered;
  final bool isVpn;
  final int? signalStrength;
  final String? ipAddress;

  Map<String, Object?> toMap() => <String, Object?>{
    'isConnected': isConnected,
    'networkType': networkType,
    'isMetered': isMetered,
    'isVpn': isVpn,
    'signalStrength': signalStrength,
    'ipAddress': ipAddress,
  };

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ConnectivityInfo &&
        other.isConnected == isConnected &&
        other.networkType == networkType &&
        other.isMetered == isMetered &&
        other.isVpn == isVpn &&
        other.signalStrength == signalStrength &&
        other.ipAddress == ipAddress;
  }

  @override
  int get hashCode => Object.hash(
    isConnected,
    networkType,
    isMetered,
    isVpn,
    signalStrength,
    ipAddress,
  );

  @override
  String toString() {
    return 'ConnectivityInfo(connected: $isConnected, type: $networkType, metered: $isMetered, vpn: $isVpn, signal: $signalStrength, ip: $ipAddress)';
  }
}
