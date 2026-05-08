import '../../nexora_sdk_platform_interface.dart';

/// Module for secure biometric authentication (FaceID/Fingerprint).
class BiometricModule {
  /// Triggers a system biometric prompt with the specified [reason].
  ///
  /// Returns true if the user successfully authenticated.
  Future<bool> authenticate({String reason = "Authenticate to continue"}) {
    if (reason.trim().isEmpty) {
      throw ArgumentError.value(
        reason,
        'reason',
        'Authentication reason cannot be empty.',
      );
    }
    return NexoraSdkPlatform.instance.authenticate(reason);
  }

  /// Checks if the device supports and has biometrics configured.
  Future<bool> canAuthenticate() =>
      NexoraSdkPlatform.instance.canAuthenticate();
}
