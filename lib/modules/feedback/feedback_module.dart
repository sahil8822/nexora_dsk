import '../../nexora_sdk_platform_interface.dart';

/// Module for controlling device haptics and vibration.
class FeedbackModule {
  /// Triggers a standard vibration for the specified [durationMs].
  Future<void> vibrate({int durationMs = 50}) =>
      NexoraSdkPlatform.instance.vibrate(durationMs);

  /// Triggers a native haptic pattern.
  ///
  /// Supported [type] values: 'impact', 'success', 'warning', 'error'.
  Future<void> haptic(String type) =>
      NexoraSdkPlatform.instance.hapticFeedback(type);
}
