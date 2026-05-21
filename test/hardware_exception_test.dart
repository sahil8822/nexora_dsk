import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexora_sdk_platform_interface/models/hardware_exception.dart';

void main() {
  group('HardwareException Mapping Tests', () {
    test('HardwareErrorCode fromPlatformCode mapping', () {
      expect(
        HardwareErrorCode.fromPlatformCode('PERMISSION_DENIED'),
        HardwareErrorCode.permissionDenied,
      );
      expect(
        HardwareErrorCode.fromPlatformCode('NOT_SUPPORTED'),
        HardwareErrorCode.notSupported,
      );
      expect(
        HardwareErrorCode.fromPlatformCode('DEVICE_BUSY'),
        HardwareErrorCode.deviceBusy,
      );
      expect(
        HardwareErrorCode.fromPlatformCode('TIMEOUT'),
        HardwareErrorCode.timeout,
      );
      expect(
        HardwareErrorCode.fromPlatformCode('BLUETOOTH_UNAVAILABLE'),
        HardwareErrorCode.bluetoothUnavailable,
      );
      expect(
        HardwareErrorCode.fromPlatformCode('CAMERA_UNAVAILABLE'),
        HardwareErrorCode.cameraUnavailable,
      );
      expect(
        HardwareErrorCode.fromPlatformCode('CAMERA_ERROR'),
        HardwareErrorCode.cameraUnavailable,
      );
      expect(
        HardwareErrorCode.fromPlatformCode('INVALID_ARGUMENT'),
        HardwareErrorCode.invalidArgument,
      );
      expect(
        HardwareErrorCode.fromPlatformCode('NO_ACTIVITY'),
        HardwareErrorCode.noActivity,
      );
      expect(
        HardwareErrorCode.fromPlatformCode('NEXORA_ERROR'),
        HardwareErrorCode.nativeError,
      );
      expect(
        HardwareErrorCode.fromPlatformCode('SOME_RANDOM_CODE'),
        HardwareErrorCode.unknown,
      );
      expect(
        HardwareErrorCode.fromPlatformCode(null),
        HardwareErrorCode.unknown,
      );
    });

    test('HardwareException construction and platform exception mapping', () {
      final platEx = PlatformException(
        code: 'TIMEOUT',
        message: 'The operation timed out.',
        details: 'GATT connect timed out after 10s',
      );

      final hwEx = HardwareException.fromPlatformException(platEx);
      expect(hwEx.code, HardwareErrorCode.timeout);
      expect(hwEx.message, 'The operation timed out.');
      expect(hwEx.details, 'GATT connect timed out after 10s');
      expect(hwEx.toString(), contains('timeout'));
      expect(hwEx.toString(), contains('The operation timed out.'));

      final unsupportedEx = HardwareException.unsupported('Face detection');
      expect(unsupportedEx.code, HardwareErrorCode.notSupported);
      expect(
        unsupportedEx.message,
        contains('Face detection is not supported'),
      );
      expect(unsupportedEx.isUnsupported, true);
      expect(unsupportedEx.isPermissionDenied, false);
    });
  });
}
