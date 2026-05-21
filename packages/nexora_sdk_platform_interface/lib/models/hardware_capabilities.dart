import 'package:flutter/foundation.dart';

/// Hardware features exposed by Nexora SDK.
enum HardwareFeature {
  /// API Documentation for camera,.
  camera,

  /// API Documentation for audio,.
  audio,

  /// API Documentation for bluetooth,.
  bluetooth,

  /// API Documentation for location,.
  location,

  /// API Documentation for biometrics,.
  biometrics,

  /// API Documentation for sensors,.
  sensors,

  /// API Documentation for haptics,.
  haptics,

  /// API Documentation for storage,.
  storage,

  /// API Documentation for health,.
  health,

  /// API Documentation for nativeUtilities,.
  nativeUtilities,

  /// API Documentation for smartSync,.
  smartSync,

  /// API Documentation for cameraFilters,.
  cameraFilters,

  /// API Documentation for videoRecording,.
  videoRecording,

  /// API Documentation for bleL2cap,.
  bleL2cap,

  /// API Documentation for deadReckoning,.
  deadReckoning,
}

/// Coarse-grained implementation status for one feature on one platform.
enum HardwareFeatureSupportLevel {
  /// Backed by a native or platform API intended for production use.
  supported,

  /// Available through a lighter Dart/platform fallback with reduced behavior.
  fallback,

  /// API is present but the implementation is intentionally guarded.
  experimental,

  /// Not implemented on the current platform.
  unsupported,
}

/// Detailed feature support metadata for the current runtime.
class HardwareFeatureSupport {
  /// API Documentation for HardwareFeatureSupport.
  const HardwareFeatureSupport({
    required this.feature,
    required this.level,
    required this.reason,
    this.requiresMinSdkVersion,
  });

  /// API Documentation for feature;.
  final HardwareFeature feature;

  /// API Documentation for level;.
  final HardwareFeatureSupportLevel level;

  /// API Documentation for reason;.
  final String reason;

  /// API Documentation for requiresMinSdkVersion;.
  final String? requiresMinSdkVersion;

  /// API Documentation for =>.
  bool get isAvailable =>
      level == HardwareFeatureSupportLevel.supported ||
      level == HardwareFeatureSupportLevel.fallback;

  /// API Documentation for HardwareFeatureSupportLevel.supported;.
  bool get isNative => level == HardwareFeatureSupportLevel.supported;

  /// API Documentation for toMap.
  Map<String, Object?> toMap() => <String, Object?>{
        'feature': feature.name,
        'level': level.name,
        'reason': reason,
        'isAvailable': isAvailable,
        'isNative': isNative,
        'requiresMinSdkVersion': requiresMinSdkVersion,
      };
}

/// Describes which SDK features are expected to be available on this runtime.
///
/// This is a lightweight Dart-side capability snapshot. Mobile native calls
/// may still return false when permissions, hardware, or OS settings block a
/// feature at runtime.
class HardwareCapabilities {
  /// API Documentation for HardwareCapabilities.
  const HardwareCapabilities({
    required this.platform,
    required this.isWeb,
    required this.isDesktop,
    required this.isMobile,
    required this.camera,
    required this.audio,
    required this.bluetooth,
    required this.location,
    required this.biometrics,
    required this.sensors,
    required this.haptics,
    required this.storage,
    required this.health,
    required this.nativeCameraPreview,
  });

  /// Returns a conservative capability snapshot for the current Flutter target.
  factory HardwareCapabilities.current() {
    if (kIsWeb) {
      return const HardwareCapabilities(
        platform: 'web',
        isWeb: true,
        isDesktop: false,
        isMobile: false,
        camera: false,
        audio: false,
        bluetooth: false,
        location: false,
        biometrics: false,
        sensors: false,
        haptics: false,
        storage: true,
        health: false,
        nativeCameraPreview: false,
      );
    }

    return switch (defaultTargetPlatform) {
      TargetPlatform.android || TargetPlatform.iOS => HardwareCapabilities(
          platform: defaultTargetPlatform.name,
          isWeb: false,
          isDesktop: false,
          isMobile: true,
          camera: true,
          audio: true,
          bluetooth: true,
          location: true,
          biometrics: true,
          sensors: true,
          haptics: true,
          storage: true,
          health: true,
          nativeCameraPreview: true,
        ),
      TargetPlatform.macOS ||
      TargetPlatform.windows ||
      TargetPlatform.linux =>
        HardwareCapabilities(
          platform: defaultTargetPlatform.name,
          isWeb: false,
          isDesktop: true,
          isMobile: false,
          camera: false,
          audio: false,
          bluetooth: false,
          location: false,
          biometrics: false,
          sensors: false,
          haptics: false,
          storage: true,
          health: false,
          nativeCameraPreview: false,
        ),
      TargetPlatform.fuchsia => const HardwareCapabilities(
          platform: 'fuchsia',
          isWeb: false,
          isDesktop: false,
          isMobile: false,
          camera: false,
          audio: false,
          bluetooth: false,
          location: false,
          biometrics: false,
          sensors: false,
          haptics: false,
          storage: true,
          health: false,
          nativeCameraPreview: false,
        ),
    };
  }

  /// A readable platform name such as `android`, `ios`, `web`, or `macos`.
  final String platform;

  /// API Documentation for 'ios';.
  bool get isIos => platform == 'ios';

  /// API Documentation for 'android';.
  bool get isAndroid => platform == 'android';

  /// API Documentation for 'macos';.
  bool get isMacos => platform == 'macos';

  /// API Documentation for 'windows';.
  bool get isWindows => platform == 'windows';

  /// API Documentation for 'linux';.
  bool get isLinux => platform == 'linux';

  /// API Documentation for isWeb;.
  final bool isWeb;

  /// API Documentation for isDesktop;.
  final bool isDesktop;

  /// API Documentation for isMobile;.
  final bool isMobile;

  /// API Documentation for camera;.
  final bool camera;

  /// API Documentation for audio;.
  final bool audio;

  /// API Documentation for bluetooth;.
  final bool bluetooth;

  /// API Documentation for location;.
  final bool location;

  /// API Documentation for biometrics;.
  final bool biometrics;

  /// API Documentation for sensors;.
  final bool sensors;

  /// API Documentation for haptics;.
  final bool haptics;

  /// API Documentation for storage;.
  final bool storage;

  /// API Documentation for health;.
  final bool health;

  /// API Documentation for nativeCameraPreview;.
  final bool nativeCameraPreview;

  /// API Documentation for supports.
  bool supports(HardwareFeature feature) {
    return switch (feature) {
      HardwareFeature.camera => camera,
      HardwareFeature.audio => audio,
      HardwareFeature.bluetooth => bluetooth,
      HardwareFeature.location => location,
      HardwareFeature.biometrics => biometrics,
      HardwareFeature.sensors => sensors,
      HardwareFeature.haptics => haptics,
      HardwareFeature.storage => storage,
      HardwareFeature.health => health,
      HardwareFeature.nativeUtilities => isMobile || isDesktop || isWeb,
      HardwareFeature.smartSync => false,
      HardwareFeature.cameraFilters => false,
      HardwareFeature.videoRecording => false,
      HardwareFeature.bleL2cap => false,
      HardwareFeature.deadReckoning => false,
    };
  }

  /// API Documentation for supportFor.
  HardwareFeatureSupport supportFor(HardwareFeature feature) {
    final nativeMobile = isMobile;

    return switch (feature) {
      HardwareFeature.camera => _status(
          feature,
          nativeMobile,
          fallbackRuntime: false,
          supportedReason: 'Native camera texture preview is available.',
          unsupportedReason: 'Camera preview needs a native platform backend.',
        ),
      HardwareFeature.audio => _status(
          feature,
          nativeMobile,
          fallbackRuntime: false,
          supportedReason: 'Native microphone capture is available.',
          unsupportedReason: 'Audio capture needs a native platform backend.',
        ),
      HardwareFeature.bluetooth => _status(
          feature,
          nativeMobile,
          fallbackRuntime: false,
          supportedReason: 'Native BLE scanning and GATT APIs are available.',
          unsupportedReason: 'Bluetooth needs a native platform backend.',
        ),
      HardwareFeature.location => _status(
          feature,
          nativeMobile,
          fallbackRuntime: false,
          supportedReason: 'Native location updates are available.',
          unsupportedReason: 'Location needs a native platform backend.',
        ),
      HardwareFeature.biometrics => _status(
          feature,
          nativeMobile,
          fallbackRuntime: false,
          supportedReason: 'Native biometric prompts are available.',
          unsupportedReason: 'Biometrics need a native platform backend.',
        ),
      HardwareFeature.sensors => _status(
          feature,
          nativeMobile,
          fallbackRuntime: false,
          supportedReason: 'Native motion sensors are available.',
          unsupportedReason: 'Motion sensors need a native platform backend.',
        ),
      HardwareFeature.haptics => _status(
          feature,
          nativeMobile,
          fallbackRuntime: false,
          supportedReason: 'Native haptics are available.',
          unsupportedReason: 'Haptics need a native platform backend.',
        ),
      HardwareFeature.storage => HardwareFeatureSupport(
          feature: feature,
          level: nativeMobile
              ? HardwareFeatureSupportLevel.supported
              : HardwareFeatureSupportLevel.fallback,
          reason: nativeMobile
              ? 'Native app-private storage is available.'
              : 'Dart fallback storage is available with platform limits.',
        ),
      HardwareFeature.health => _status(
          feature,
          nativeMobile,
          fallbackRuntime: false,
          supportedReason:
              'Native battery, WiFi, and telemetry APIs are available.',
          unsupportedReason:
              'Health diagnostics need a native platform backend.',
        ),
      HardwareFeature.nativeUtilities => HardwareFeatureSupport(
          feature: feature,
          level: nativeMobile
              ? HardwareFeatureSupportLevel.supported
              : HardwareFeatureSupportLevel.fallback,
          reason: nativeMobile
              ? 'Native clipboard, URL, and share utilities are available.'
              : 'Best-effort Dart fallback utilities are available.',
        ),
      HardwareFeature.smartSync ||
      HardwareFeature.cameraFilters ||
      HardwareFeature.videoRecording =>
        HardwareFeatureSupport(
          feature: feature,
          level: HardwareFeatureSupportLevel.experimental,
          reason:
              'The API is reserved but no production backend is available yet.',
        ),
      HardwareFeature.bleL2cap => HardwareFeatureSupport(
          feature: feature,
          level: HardwareFeatureSupportLevel.experimental,
          reason: 'Reserved for BLE L2CAP Connection Oriented Channels.',
          requiresMinSdkVersion: 'Android 10 / iOS 13',
        ),
      HardwareFeature.deadReckoning => HardwareFeatureSupport(
          feature: feature,
          level: HardwareFeatureSupportLevel.experimental,
          reason: 'Reserved for Dead Reckoning inertial positioning.',
          requiresMinSdkVersion: 'Android 12 / iOS 16',
        ),
    };
  }

  /// API Documentation for Public member.
  Map<HardwareFeature, HardwareFeatureSupport> get featureMatrix {
    return <HardwareFeature, HardwareFeatureSupport>{
      for (final feature in HardwareFeature.values)
        feature: supportFor(feature),
    };
  }

  HardwareFeatureSupport _status(
    HardwareFeature feature,
    bool supported, {
    required bool fallbackRuntime,
    required String supportedReason,
    required String unsupportedReason,
  }) {
    if (supported) {
      return HardwareFeatureSupport(
        feature: feature,
        level: HardwareFeatureSupportLevel.supported,
        reason: supportedReason,
      );
    }
    if (fallbackRuntime) {
      return HardwareFeatureSupport(
        feature: feature,
        level: HardwareFeatureSupportLevel.fallback,
        reason: 'A reduced Dart fallback is available.',
      );
    }
    return HardwareFeatureSupport(
      feature: feature,
      level: HardwareFeatureSupportLevel.unsupported,
      reason: unsupportedReason,
    );
  }

  /// API Documentation for toMap.
  Map<String, Object> toMap() => <String, Object>{
        'platform': platform,
        'isWeb': isWeb,
        'isDesktop': isDesktop,
        'isMobile': isMobile,
        'camera': camera,
        'audio': audio,
        'bluetooth': bluetooth,
        'location': location,
        'biometrics': biometrics,
        'sensors': sensors,
        'haptics': haptics,
        'storage': storage,
        'health': health,
        'nativeCameraPreview': nativeCameraPreview,
        'featureMatrix': featureMatrix.map(
          (feature, support) => MapEntry(feature.name, support.toMap()),
        ),
      };

  @override
  String toString() =>
      'HardwareCapabilities(web: $isWeb, ios: $isIos, android: $isAndroid, macos: $isMacos, windows: $isWindows, linux: $isLinux)';
}

/// Result returned by [NexoraSdk.stopAll].
class HardwareShutdownResult {
  /// API Documentation for HardwareShutdownResult.
  const HardwareShutdownResult(this.results);

  /// API Documentation for results;.
  final Map<String, bool> results;

  /// API Documentation for results.values.every.
  bool get success => results.values.every((value) => value);

  /// API Documentation for results.entries.
  List<String> get failedModules => results.entries
      .where((entry) => !entry.value)
      .map((entry) => entry.key)
      .toList(growable: false);

  @override
  String toString() =>
      'HardwareShutdownResult(success: $success, failed: $failedModules)';
}
