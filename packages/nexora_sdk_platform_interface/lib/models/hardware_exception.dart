import 'package:flutter/services.dart';

/// Stable SDK error codes for hardware operations.
enum HardwareErrorCode {
  /// API Documentation for permissionDenied,.
  permissionDenied,

  /// API Documentation for notSupported,.
  notSupported,

  /// API Documentation for deviceBusy,.
  deviceBusy,

  /// API Documentation for timeout,.
  timeout,

  /// API Documentation for bluetoothUnavailable,.
  bluetoothUnavailable,

  /// API Documentation for cameraUnavailable,.
  cameraUnavailable,

  /// API Documentation for invalidArgument,.
  invalidArgument,

  /// API Documentation for noActivity,.
  noActivity,

  /// API Documentation for nativeError,.
  nativeError,

  /// API Documentation for unknown.
  unknown;

  /// API Documentation for fromPlatformCode.
  static HardwareErrorCode fromPlatformCode(String? code) {
    return switch (code) {
      'PERMISSION_DENIED' => HardwareErrorCode.permissionDenied,
      'NOT_SUPPORTED' => HardwareErrorCode.notSupported,
      'DEVICE_BUSY' => HardwareErrorCode.deviceBusy,
      'TIMEOUT' => HardwareErrorCode.timeout,
      'BLUETOOTH_UNAVAILABLE' => HardwareErrorCode.bluetoothUnavailable,
      'CAMERA_ERROR' ||
      'CAMERA_UNAVAILABLE' =>
        HardwareErrorCode.cameraUnavailable,
      'INVALID_ARGUMENT' => HardwareErrorCode.invalidArgument,
      'NO_ACTIVITY' => HardwareErrorCode.noActivity,
      'NEXORA_ERROR' => HardwareErrorCode.nativeError,
      _ => HardwareErrorCode.unknown,
    };
  }
}

/// Exception thrown when a native hardware operation fails.
class HardwareException implements Exception {
  /// Base constructor for hardware exceptions.
  const HardwareException({
    required this.code,
    required this.message,
    this.details,
  });

  /// Creates a specific unsupported exception subclass.
  factory HardwareException.unsupported(String feature) {
    return HardwareUnsupportedException(
      message: '$feature is not supported on this platform.',
    );
  }

  /// Maps a native [PlatformException] into a specialized [HardwareException].
  factory HardwareException.fromPlatformException(PlatformException error) {
    final code = HardwareErrorCode.fromPlatformCode(error.code);
    final message = error.message ?? 'Hardware operation failed.';

    switch (code) {
      case HardwareErrorCode.permissionDenied:
        return HardwarePermissionException(
            message: message, details: error.details);
      case HardwareErrorCode.notSupported:
        return HardwareUnsupportedException(
            message: message, details: error.details);
      case HardwareErrorCode.timeout:
        return HardwareTimeoutException(
            message: message, details: error.details);
      case HardwareErrorCode.bluetoothUnavailable:
      case HardwareErrorCode.cameraUnavailable:
        return HardwareUnavailableException(
            code: code, message: message, details: error.details);
      default:
        return HardwareException(
            code: code, message: message, details: error.details);
    }
  }

  /// The standardized error code for the failure.
  final HardwareErrorCode code;

  /// A human-readable description of the error.
  final String message;

  /// Optional platform-specific details regarding the error.
  final Object? details;

  /// Checks if this exception indicates the feature is not supported.
  bool get isUnsupported => code == HardwareErrorCode.notSupported;

  /// Checks if this exception indicates missing permissions.
  bool get isPermissionDenied => code == HardwareErrorCode.permissionDenied;

  @override
  String toString() => 'HardwareException(${code.name}, $message)';
}

/// Thrown when a hardware feature is missing necessary OS permissions.
class HardwarePermissionException extends HardwareException {
  /// Creates a [HardwarePermissionException].
  const HardwarePermissionException({required super.message, super.details})
      : super(code: HardwareErrorCode.permissionDenied);
}

/// Thrown when a hardware feature is simply not supported on the current device.
class HardwareUnsupportedException extends HardwareException {
  /// Creates a [HardwareUnsupportedException].
  const HardwareUnsupportedException({required super.message, super.details})
      : super(code: HardwareErrorCode.notSupported);
}

/// Thrown when a hardware operation exceeds its time limit.
class HardwareTimeoutException extends HardwareException {
  /// Creates a [HardwareTimeoutException].
  const HardwareTimeoutException({required super.message, super.details})
      : super(code: HardwareErrorCode.timeout);
}

/// Thrown when a specific hardware component (like Bluetooth or Camera) is unavailable.
class HardwareUnavailableException extends HardwareException {
  /// Creates a [HardwareUnavailableException].
  const HardwareUnavailableException({
    required super.code,
    required super.message,
    super.details,
  });
}
