import 'dart:async';
import '../models/hardware_exception.dart';

/// Runs the [operation] and retries it on transient failures (e.g. TIMEOUT, DEVICE_BUSY)
/// using exponential backoff.
Future<T> withRetry<T>(
  Future<T> Function() operation, {
  int maxAttempts = 3,
  Duration initialDelay = const Duration(milliseconds: 200),
  double backoffFactor = 2.0,
  bool Function(Exception)? shouldRetry,
}) async {
  var attempts = 0;
  var currentDelay = initialDelay;

  while (true) {
    attempts++;
    try {
      return await operation();
    } on Exception catch (e) {
      if (attempts >= maxAttempts) {
        rethrow;
      }

      var isTransient = false;
      if (e is HardwareException) {
        isTransient = e.code == HardwareErrorCode.deviceBusy ||
            e.code == HardwareErrorCode.timeout;
      }

      final retryAllowed = shouldRetry != null ? shouldRetry(e) : isTransient;
      if (!retryAllowed) {
        rethrow;
      }

      await Future.delayed(currentDelay);
      currentDelay = currentDelay * backoffFactor;
    }
  }
}
