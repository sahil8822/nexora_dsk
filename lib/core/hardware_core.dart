 
/// Common structure for all hardware events.
class HardwareEvent {
  final String module; // camera, bluetooth, etc.
  final String type; // data, error, status
  final dynamic data;
  final DateTime timestamp;

  HardwareEvent({
    required this.module,
    required this.type,
    required this.data,
    required this.timestamp,
  });

  @override
  String toString() => 'HardwareEvent($module, $type, $timestamp, data: $data)';
}

/// Abstract base module defining the common lifecycle.
abstract class HardwareModule {
  Future<bool> initialize();
  Future<bool> dispose();
  Stream<HardwareEvent> get eventStream;
}
