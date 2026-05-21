/// Encapsulates sensor data from native hardware.
class SensorData {

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
  final double x;
  final double y;
  final double z;
  final DateTime timestamp;

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
