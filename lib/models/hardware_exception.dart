import 'package:flutter/services.dart';

/// Stable SDK error codes for hardware operations.
enum HardwareErrorCode {
  permissionDenied,
  notSupported,
  deviceBusy,
  timeout,
  bluetoothUnavailable,
  cameraUnavailable,
  invalidArgument,
  noActivity,
  nativeError,
  unknown;

  static HardwareErrorCode fromPlatformCode(String? code) {
    return switch (code) {
      'PERMISSION_DENIED' => HardwareErrorCode.permissionDenied,
      'NOT_SUPPORTED' => HardwareErrorCode.notSupported,
      'DEVICE_BUSY' => HardwareErrorCode.deviceBusy,
      'TIMEOUT' => HardwareErrorCode.timeout,
      'BLUETOOTH_UNAVAILABLE' => HardwareErrorCode.bluetoothUnavailable,
      'CAMERA_ERROR' ||
      'CAMERA_UNAVAILABLE' => HardwareErrorCode.cameraUnavailable,
      'INVALID_ARGUMENT' => HardwareErrorCode.invalidArgument,
      'NO_ACTIVITY' => HardwareErrorCode.noActivity,
      'NEXORA_ERROR' => HardwareErrorCode.nativeError,
      _ => HardwareErrorCode.unknown,
    };
  }
}

/// Exception thrown when a native hardware operation fails.
class HardwareException implements Exception {
  const HardwareException({
    required this.code,
    required this.message,
    this.details,
  });

  final HardwareErrorCode code;
  final String message;
  final Object? details;

  bool get isUnsupported => code == HardwareErrorCode.notSupported;

  bool get isPermissionDenied => code == HardwareErrorCode.permissionDenied;

  factory HardwareException.unsupported(String feature) {
    return HardwareException(
      code: HardwareErrorCode.notSupported,
      message: '$feature is not supported on this platform.',
    );
  }

  factory HardwareException.fromPlatformException(PlatformException error) {
    return HardwareException(
      code: HardwareErrorCode.fromPlatformCode(error.code),
      message: error.message ?? 'Hardware operation failed.',
      details: error.details,
    );
  }

  @override
  String toString() => 'HardwareException(${code.name}, $message)';
}
