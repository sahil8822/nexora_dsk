/// Runtime permissions managed by Nexora SDK.
enum HardwarePermission {
  camera('camera'),
  audio('audio'),
  location('location'),
  bluetooth('bluetooth');

  const HardwarePermission(this.value);

  final String value;
}

/// Cross-platform permission state.
enum HardwarePermissionState {
  granted,
  denied,
  permanentlyDenied,
  limited,
  restricted,
  notDetermined,
  unsupported;

  static HardwarePermissionState fromString(String? value) {
    return HardwarePermissionState.values.firstWhere(
      (state) => state.name == value,
      orElse: () => HardwarePermissionState.unsupported,
    );
  }
}

/// Status for a single hardware permission.
class HardwarePermissionStatus {
  const HardwarePermissionStatus({
    required this.permission,
    required this.state,
    this.canRequest = true,
  });

  final HardwarePermission permission;
  final HardwarePermissionState state;
  final bool canRequest;

  bool get isGranted =>
      state == HardwarePermissionState.granted ||
      state == HardwarePermissionState.limited;

  bool get needsSettings => state == HardwarePermissionState.permanentlyDenied;

  factory HardwarePermissionStatus.fromMap(Map<dynamic, dynamic> map) {
    return HardwarePermissionStatus(
      permission: HardwarePermission.values.firstWhere(
        (permission) => permission.value == map['permission'],
        orElse: () => HardwarePermission.camera,
      ),
      state: HardwarePermissionState.fromString(map['state'] as String?),
      canRequest: map['canRequest'] as bool? ?? true,
    );
  }

  Map<String, Object> toMap() => <String, Object>{
    'permission': permission.value,
    'state': state.name,
    'canRequest': canRequest,
  };

  @override
  String toString() => 'HardwarePermissionStatus(permission: ${permission.name}, state: ${state.name}, canRequest: $canRequest)';
}

/// Snapshot of all core runtime permission states.
class HardwarePermissionSnapshot {
  const HardwarePermissionSnapshot(this.statuses);

  final Map<HardwarePermission, HardwarePermissionStatus> statuses;

  bool get allGranted => statuses.values.every((status) => status.isGranted);

  List<HardwarePermission> get missingPermissions => statuses.entries
      .where((entry) => !entry.value.isGranted)
      .map((entry) => entry.key)
      .toList(growable: false);

  HardwarePermissionStatus statusFor(HardwarePermission permission) {
    return statuses[permission] ??
        HardwarePermissionStatus(
          permission: permission,
          state: HardwarePermissionState.unsupported,
          canRequest: false,
        );
  }

  Map<String, Object> toMap() => <String, Object>{
    for (final entry in statuses.entries) entry.key.value: entry.value.toMap(),
  };

  @override
  String toString() => 'HardwarePermissionSnapshot(allGranted: $allGranted, missing: $missingPermissions)';
}

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

  @override
  String toString() => 'HardwarePermissionReport(camera: $camera, audio: $audio, location: $location, bluetooth: $bluetooth)';
}
