/// Common structure for all hardware events emitted by the SDK.
/// This acts as the base data transfer object for the unified stream.
class HardwareEvent {
  /// The hardware subsystem emitting the event (e.g., 'camera', 'gps').
  final String module;
  /// The type of event (e.g., 'data', 'error', 'status').
  final String type;
  /// The payload of the event, usually a Map or specialized model data.
  final dynamic data;
  /// Precise timestamp when the event was generated.
  final DateTime timestamp;

  /// Constructs a [HardwareEvent].
  HardwareEvent({
    required this.module,
    required this.type,
    required this.data,
    required this.timestamp,
  });

  @override
  String toString() => 'HardwareEvent($module, $type, $timestamp, data: $data)';
}

/// Abstract base module defining the common lifecycle for hardware subsystems.
abstract class HardwareModule {
  /// Initializes the hardware module.
  Future<bool> initialize();
  /// Disposes and releases hardware resources.
  Future<bool> dispose();
  /// Provides access to the raw event stream for this specific module.
  Stream<HardwareEvent> get eventStream;
}
