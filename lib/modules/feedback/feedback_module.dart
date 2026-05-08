import '../../nexora_sdk_platform_interface.dart';

/// Supported haptic feedback patterns.
enum HapticPattern {
  impact('impact'),
  success('success'),
  warning('warning'),
  error('error');

  const HapticPattern(this.value);

  final String value;
}

/// Module for controlling device haptics and vibration.
class FeedbackModule {
  /// Triggers a standard vibration for the specified [durationMs].
  Future<void> vibrate({int durationMs = 50}) {
    if (durationMs < 0) {
      throw ArgumentError.value(
        durationMs,
        'durationMs',
        'Must be zero or greater.',
      );
    }
    return NexoraSdkPlatform.instance.vibrate(durationMs);
  }

  /// Triggers a native haptic pattern.
  ///
  /// Supported [type] values: 'impact', 'success', 'warning', 'error'.
  Future<void> haptic(String type) {
    const supportedTypes = {'impact', 'success', 'warning', 'error'};
    if (!supportedTypes.contains(type)) {
      throw ArgumentError.value(
        type,
        'type',
        'Use one of: impact, success, warning, error.',
      );
    }
    return NexoraSdkPlatform.instance.hapticFeedback(type);
  }

  /// Triggers a native haptic [pattern] with compile-time safe values.
  Future<void> hapticPattern(HapticPattern pattern) => haptic(pattern.value);
}
