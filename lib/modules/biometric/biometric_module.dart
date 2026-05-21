import 'package:nexora_sdk_platform_interface/models/hardware_models.dart';
import 'package:nexora_sdk_platform_interface/nexora_sdk_platform_interface.dart';

/// Module for secure biometric authentication (FaceID/Fingerprint).
class BiometricModule {
  /// Triggers a system biometric prompt with the specified [reason].
  ///
  /// Returns true if the user successfully authenticated.
  Future<bool> authenticate({String reason = 'Authenticate to continue'}) {
    if (reason.trim().isEmpty) {
      throw ArgumentError.value(
        reason,
        'reason',
        'Authentication reason cannot be empty.',
      );
    }
    return NexoraSdkPlatform.instance.authenticate(reason);
  }

  /// Triggers a system biometric prompt with native-level customizable options.
  Future<bool> authenticateWithOptions(BiometricPromptOptions options) {
    if (options.title.trim().isEmpty) {
      throw ArgumentError.value(
        options.title,
        'title',
        'Authentication title cannot be empty.',
      );
    }
    return NexoraSdkPlatform.instance.authenticateWithOptions(options);
  }

  /// Checks if the device supports and has biometrics configured.
  Future<bool> canAuthenticate() =>
      NexoraSdkPlatform.instance.canAuthenticate();
}
