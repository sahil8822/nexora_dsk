import 'package:flutter/foundation.dart';

/// Hardware features exposed by Nexora SDK.
enum HardwareFeature {
  camera,
  audio,
  bluetooth,
  location,
  biometrics,
  sensors,
  haptics,
  storage,
  health,
  nativeUtilities,
  smartSync,
  cameraFilters,
  videoRecording,
  bleL2cap,
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
  const HardwareFeatureSupport({
    required this.feature,
    required this.level,
    required this.reason,
  });

  final HardwareFeature feature;
  final HardwareFeatureSupportLevel level;
  final String reason;

  bool get isAvailable =>
      level == HardwareFeatureSupportLevel.supported ||
      level == HardwareFeatureSupportLevel.fallback;

  bool get isNative => level == HardwareFeatureSupportLevel.supported;

  Map<String, Object> toMap() => <String, Object>{
    'feature': feature.name,
    'level': level.name,
    'reason': reason,
    'isAvailable': isAvailable,
    'isNative': isNative,
  };
}

/// Describes which SDK features are expected to be available on this runtime.
///
/// This is a lightweight Dart-side capability snapshot. Mobile native calls
/// may still return false when permissions, hardware, or OS settings block a
/// feature at runtime.
class HardwareCapabilities {
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

  /// A readable platform name such as `android`, `ios`, `web`, or `macos`.
  final String platform;

  final bool isWeb;
  final bool isDesktop;
  final bool isMobile;

  final bool camera;
  final bool audio;
  final bool bluetooth;
  final bool location;
  final bool biometrics;
  final bool sensors;
  final bool haptics;
  final bool storage;
  final bool health;
  final bool nativeCameraPreview;

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
      TargetPlatform.linux => HardwareCapabilities(
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
        unsupportedReason: 'Health diagnostics need a native platform backend.',
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
      HardwareFeature.videoRecording ||
      HardwareFeature.bleL2cap ||
      HardwareFeature.deadReckoning => HardwareFeatureSupport(
        feature: feature,
        level: HardwareFeatureSupportLevel.experimental,
        reason:
            'The API is reserved but no production backend is available yet.',
      ),
    };
  }

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
}

/// Result returned by [NexoraSdk.stopAll].
class HardwareShutdownResult {
  const HardwareShutdownResult(this.results);

  final Map<String, bool> results;

  bool get success => results.values.every((value) => value);

  List<String> get failedModules => results.entries
      .where((entry) => !entry.value)
      .map((entry) => entry.key)
      .toList(growable: false);
}
