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
}
