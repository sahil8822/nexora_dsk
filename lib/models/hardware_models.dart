import 'dart:typed_data';

/// Represents a high-performance camera frame or a reference to a GPU texture.
class CameraFrame {
  /// Raw image byte data. Null if [textureId] is being used for rendering.
  final Uint8List? bytes;
  
  /// The ID of the native texture for zero-copy GPU rendering.
  /// Use this with Flutter's [Texture] widget for ultra-low memory usage.
  final int? textureId;
  
  /// Width of the captured image/texture.
  final int width;
  
  /// Height of the captured image/texture.
  final int height;
  
  /// The pixel format of the data.
  final String format;
  
  /// Intelligent vision results (Face/Barcode) if AI mode is active.
  final VisionResult? vision;
  
  CameraFrame({this.bytes, this.textureId, required this.width, required this.height, this.format = 'rgba', this.vision});

  factory CameraFrame.fromMap(Map<dynamic, dynamic> map) {
    return CameraFrame(
      bytes: map['bytes'] as Uint8List?,
      textureId: map['textureId'] as int?,
      width: map['width'] as int,
      height: map['height'] as int,
      format: map['format'] as String,
      vision: map['vision'] != null ? VisionResult.fromMap(map['vision']) : null,
    );
  }
}

// ... rest of the models remain same ...
class VisionResult {
  final List<String> barcodes;
  final List<FaceData> faces;
  VisionResult({this.barcodes = const [], this.faces = const []});
  factory VisionResult.fromMap(Map<dynamic, dynamic> map) {
    return VisionResult(
      barcodes: (map['barcodes'] as List?)?.cast<String>() ?? [],
      faces: (map['faces'] as List?)?.map((f) => FaceData.fromMap(f)).toList() ?? [],
    );
  }
}
class FaceData {
  final double boundingBoxTop;
  final double boundingBoxLeft;
  final double? smileProb;
  FaceData({required this.boundingBoxTop, required this.boundingBoxLeft, this.smileProb});
  factory FaceData.fromMap(Map<dynamic, dynamic> map) {
    return FaceData(
      boundingBoxTop: (map['top'] as num).toDouble(),
      boundingBoxLeft: (map['left'] as num).toDouble(),
      smileProb: (map['smile'] as num?)?.toDouble(),
    );
  }
}
class AudioFrame {
  final Uint8List bytes;
  final List<double> spectrum; 
  final int sampleRate;
  AudioFrame({required this.bytes, required this.spectrum, required this.sampleRate});
  factory AudioFrame.fromMap(Map<dynamic, dynamic> map) {
    return AudioFrame(
      bytes: map['bytes'] as Uint8List,
      spectrum: (map['spectrum'] as List?)?.cast<double>() ?? [],
      sampleRate: map['sampleRate'] as int,
    );
  }
}
class LogConfig {
  final String fileName;
  final bool includeSensors;
  final bool includeGPS;
  final int intervalMs;
  LogConfig({this.fileName = "nexora_log.csv", this.includeSensors = true, this.includeGPS = true, this.intervalMs = 100});
}
class BleDevice {
  final String id;
  final String name;
  final int rssi;
  BleDevice({required this.id, required this.name, required this.rssi});
  factory BleDevice.fromMap(Map<dynamic, dynamic> map) {
    return BleDevice(id: map['id'] as String, name: map['name'] as String? ?? 'Unknown', rssi: map['rssi'] as int? ?? 0);
  }
}
class LocationData {
  final double latitude;
  final double longitude;
  final double altitude;
  final double accuracy;
  final double speed;
  LocationData({required this.latitude, required this.longitude, required this.altitude, required this.accuracy, required this.speed});
  factory LocationData.fromMap(Map<dynamic, dynamic> map) {
    return LocationData(
      latitude: (map['latitude'] as num).toDouble(),
      longitude: (map['longitude'] as num).toDouble(),
      altitude: (map['altitude'] as num).toDouble(),
      accuracy: (map['accuracy'] as num).toDouble(),
      speed: (map['speed'] as num).toDouble(),
    );
  }
}
class BatteryInfo {
  final double level;
  final bool isCharging;
  final String status;
  final double temperature;
  BatteryInfo({required this.level, required this.isCharging, required this.status, required this.temperature});
  factory BatteryInfo.fromMap(Map<dynamic, dynamic> map) {
    return BatteryInfo(
      level: (map['level'] as num).toDouble(),
      isCharging: map['isCharging'] as bool,
      status: map['status'] as String,
      temperature: (map['temperature'] as num).toDouble(),
    );
  }
}
class WifiInfo {
  final String ssid;
  final String bssid;
  final int signalStrength;
  final String ipAddress;
  WifiInfo({required this.ssid, required this.bssid, required this.signalStrength, required this.ipAddress});
  factory WifiInfo.fromMap(Map<dynamic, dynamic> map) {
    return WifiInfo(
      ssid: map['ssid'] as String,
      bssid: map['bssid'] as String,
      signalStrength: map['signalStrength'] as int,
      ipAddress: map['ipAddress'] as String,
    );
  }
}
