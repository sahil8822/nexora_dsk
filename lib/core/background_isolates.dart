import 'dart:async';
import 'dart:isolate';

/// A wrapper to easily offload heavy computations or stream processing (like FFT/Sensor analysis) to a separate background Isolate.
class BackgroundIsolateWrapper {
  Isolate? _isolate;
  ReceivePort? _receivePort;
  SendPort? _sendPort;
  final StreamController<dynamic> _dataController = StreamController<dynamic>.broadcast();

  Stream<dynamic> get dataStream => _dataController.stream;

  /// Starts the background isolate.
  /// [entryPoint] is the main function that runs inside the isolate.
  Future<void> start(void Function(SendPort sendPort) entryPoint) async {
    if (_isolate != null) return;

    _receivePort = ReceivePort();
    _isolate = await Isolate.spawn(entryPoint, _receivePort!.sendPort);

    _receivePort!.listen((message) {
      if (message is SendPort) {
        _sendPort = message;
      } else {
        _dataController.add(message);
      }
    });
  }

  /// Sends a message to the background isolate.
  void send(dynamic message) {
    _sendPort?.send(message);
  }

  /// Stops the background isolate and releases resources.
  void stop() {
    _isolate?.kill(priority: Isolate.beforeNextEvent);
    _isolate = null;
    _receivePort?.close();
    _receivePort = null;
    _sendPort = null;
  }
}
