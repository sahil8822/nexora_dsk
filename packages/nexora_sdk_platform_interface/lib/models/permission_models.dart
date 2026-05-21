/// Runtime permissions managed by Nexora SDK.
enum HardwarePermission {
  /// API Documentation for camera.
  camera('camera'),

  /// API Documentation for audio.
  audio('audio'),

  /// API Documentation for location.
  location('location'),

  /// API Documentation for bluetooth.
  bluetooth('bluetooth');

  const HardwarePermission(this.value);

  /// API Documentation for value;.
  final String value;
}

/// Cross-platform permission state.
enum HardwarePermissionState {
  /// API Documentation for granted,.
  granted,

  /// API Documentation for denied,.
  denied,

  /// API Documentation for permanentlyDenied,.
  permanentlyDenied,

  /// API Documentation for limited,.
  limited,

  /// API Documentation for restricted,.
  restricted,

  /// API Documentation for notDetermined,.
  notDetermined,

  /// API Documentation for unsupported.
  unsupported;

  /// API Documentation for fromString.
  static HardwarePermissionState fromString(String? value) {
    return HardwarePermissionState.values.firstWhere(
      (state) => state.name == value,
      orElse: () => HardwarePermissionState.unsupported,
    );
  }
}

/// Status for a single hardware permission.
class HardwarePermissionStatus {
  /// API Documentation for HardwarePermissionStatus.
  const HardwarePermissionStatus({
    required this.permission,
    required this.state,
    this.canRequest = true,
  });

  /// API Documentation for HardwarePermissionStatus.fromMap.
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

  /// API Documentation for permission;.
  final HardwarePermission permission;

  /// API Documentation for state;.
  final HardwarePermissionState state;

  /// API Documentation for canRequest;.
  final bool canRequest;

  /// API Documentation for =>.
  bool get isGranted =>
      state == HardwarePermissionState.granted ||
      state == HardwarePermissionState.limited;

  /// API Documentation for HardwarePermissionState.permanentlyDenied;.
  bool get needsSettings => state == HardwarePermissionState.permanentlyDenied;

  /// API Documentation for toMap.
  Map<String, Object> toMap() => <String, Object>{
        'permission': permission.value,
        'state': state.name,
        'canRequest': canRequest,
      };

  @override
  String toString() =>
      'HardwarePermissionStatus(permission: ${permission.name}, state: ${state.name}, canRequest: $canRequest)';
}

/// Snapshot of all core runtime permission states.
class HardwarePermissionSnapshot {
  /// API Documentation for HardwarePermissionSnapshot.
  const HardwarePermissionSnapshot(this.statuses);

  /// API Documentation for statuses;.
  final Map<HardwarePermission, HardwarePermissionStatus> statuses;

  /// API Documentation for statuses.values.every.
  bool get allGranted => statuses.values.every((status) => status.isGranted);

  /// API Documentation for statuses.entries.
  List<HardwarePermission> get missingPermissions => statuses.entries
      .where((entry) => !entry.value.isGranted)
      .map((entry) => entry.key)
      .toList(growable: false);

  /// API Documentation for statusFor.
  HardwarePermissionStatus statusFor(HardwarePermission permission) {
    return statuses[permission] ??
        HardwarePermissionStatus(
          permission: permission,
          state: HardwarePermissionState.unsupported,
          canRequest: false,
        );
  }

  /// API Documentation for toMap.
  Map<String, Object> toMap() => <String, Object>{
        for (final entry in statuses.entries)
          entry.key.value: entry.value.toMap(),
      };

  @override
  String toString() =>
      'HardwarePermissionSnapshot(allGranted: $allGranted, missing: $missingPermissions)';
}

/// Detailed result for requesting the core runtime permissions.
class HardwarePermissionReport {
  /// API Documentation for HardwarePermissionReport.
  const HardwarePermissionReport({
    required this.camera,
    required this.audio,
    required this.location,
    required this.bluetooth,
  });

  /// API Documentation for camera;.
  final bool camera;

  /// API Documentation for audio;.
  final bool audio;

  /// API Documentation for location;.
  final bool location;

  /// API Documentation for bluetooth;.
  final bool bluetooth;

  /// API Documentation for bluetooth;.
  bool get allGranted => camera && audio && location && bluetooth;

  /// API Documentation for <String>[.
  List<String> get deniedPermissions => <String>[
        if (!camera) 'camera',
        if (!audio) 'audio',
        if (!location) 'location',
        if (!bluetooth) 'bluetooth',
      ];

  /// API Documentation for toMap.
  Map<String, bool> toMap() => <String, bool>{
        'camera': camera,
        'audio': audio,
        'location': location,
        'bluetooth': bluetooth,
      };

  @override
  String toString() =>
      'HardwarePermissionReport(camera: $camera, audio: $audio, location: $location, bluetooth: $bluetooth)';
}
