/// Encapsulates sensor data from native hardware.
class SensorData {
  /// API Documentation for SensorData.
  SensorData({
    required this.x,
    required this.y,
    required this.z,
    required this.timestamp,
  });

  /// Factory constructor to create a [SensorData] from a map.
  factory SensorData.fromMap(Map<dynamic, dynamic> map) {
    return SensorData(
      x: (map['x'] as num?)?.toDouble() ?? 0.0,
      y: (map['y'] as num?)?.toDouble() ?? 0.0,
      z: (map['z'] as num?)?.toDouble() ?? 0.0,
      timestamp: map['timestamp'] != null
          ? DateTime.fromMillisecondsSinceEpoch(
              (map['timestamp'] as num).toInt(),
            )
          : DateTime.now(),
    );
  }

  /// API Documentation for x;.
  final double x;

  /// API Documentation for y;.
  final double y;

  /// API Documentation for z;.
  final double z;

  /// API Documentation for timestamp;.
  final DateTime timestamp;

  /// API Documentation for toMap.
  Map<String, dynamic> toMap() {
    return {
      'x': x,
      'y': y,
      'z': z,
      'timestamp': timestamp.millisecondsSinceEpoch,
    };
  }

  @override
  String toString() => 'SensorData(x: $x, y: $y, z: $z, time: $timestamp)';
}
