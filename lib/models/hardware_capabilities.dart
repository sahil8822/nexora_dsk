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
    };
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
