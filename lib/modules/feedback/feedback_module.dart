import 'package:nexora_sdk_platform_interface/models/hardware_models.dart';
import 'package:nexora_sdk_platform_interface/nexora_sdk_platform_interface.dart';

/// Supported haptic feedback patterns.
enum HapticPattern {
  /// API Documentation for impact.
  impact('impact'),

  /// API Documentation for success.
  success('success'),

  /// API Documentation for warning.
  warning('warning'),

  /// API Documentation for error.
  error('error');

  const HapticPattern(this.value);

  /// API Documentation for value;.
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

  /// Triggers a highly-customizable native haptic vibration.
  Future<void> performHapticWithOptions(HapticOptions options) {
    if (options.intensityPercent < 0 || options.intensityPercent > 100) {
      throw ArgumentError.value(
        options.intensityPercent,
        'intensityPercent',
        'Must be between 0 and 100.',
      );
    }
    return NexoraSdkPlatform.instance.performHapticWithOptions(options);
  }
}
