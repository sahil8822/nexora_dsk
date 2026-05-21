import 'dart:async';

/// A lightweight Mutex class to serialize async operations.
class Mutex {
  Future<void> _last = Future<void>.value();

  /// Runs the [criticalSection] when all prior tasks in this mutex queue have finished.
  Future<T> protect<T>(FutureOr<T> Function() criticalSection) {
    final completer = Completer<void>();
    final result =
        _last.then((_) => criticalSection()).whenComplete(completer.complete);
    _last = completer.future;
    return result;
  }
}
