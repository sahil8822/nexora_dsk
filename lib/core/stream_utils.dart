import 'dart:async';

/// Extension methods providing advanced stream manipulation utilities
/// (throttle, debounce, bufferCount) for high-frequency hardware event streams.
extension StreamUtilsExtension<T> on Stream<T> {
  /// Skips events that occur within the [duration] window after the last emitted event.
  Stream<T> throttle(Duration duration) {
    Timer? timer;
    T? lastEvent;
    var hasEvent = false;

    return StreamTransformer<T, T>.fromHandlers(
      handleData: (data, sink) {
        lastEvent = data;
        hasEvent = true;
        if (timer == null) {
          sink.add(data);
          hasEvent = false;
          timer = Timer(duration, () {
            timer = null;
            if (hasEvent && lastEvent != null) {
              sink.add(lastEvent as T);
              hasEvent = false;
            }
          });
        }
      },
      handleDone: (sink) {
        timer?.cancel();
        sink.close();
      },
    ).bind(this);
  }

  /// Waits for [duration] of inactivity before emitting the last event.
  Stream<T> debounce(Duration duration) {
    Timer? timer;

    return StreamTransformer<T, T>.fromHandlers(
      handleData: (data, sink) {
        timer?.cancel();
        timer = Timer(duration, () {
          sink.add(data);
        });
      },
      handleDone: (sink) {
        timer?.cancel();
        sink.close();
      },
    ).bind(this);
  }

  /// Batches [count] events into a List.
  Stream<List<T>> bufferCount(int count) {
    var buffer = <T>[];

    return StreamTransformer<T, List<T>>.fromHandlers(
      handleData: (data, sink) {
        buffer.add(data);
        if (buffer.length >= count) {
          sink.add(List<T>.from(buffer));
          buffer.clear();
        }
      },
      handleDone: (sink) {
        if (buffer.isNotEmpty) {
          sink.add(buffer);
        }
        sink.close();
      },
    ).bind(this);
  }
}
