import 'dart:typed_data';

/// Represents a raw camera frame from native hardware.
/// Contains the binary pixel data and resolution metadata.
class CameraFrame {
  /// The raw binary data of the frame.
  final Uint8List bytes;
  /// The width of the captured frame.
  final int width;
  /// The height of the captured frame.
  final int height;
  /// The format of the frame data (e.g., 'rgba', 'yuv').
  final String format;

  /// Constructs a [CameraFrame].
  CameraFrame({required this.bytes, required this.width, required this.height, this.format = 'rgba'});

  /// Creates a [CameraFrame] from a raw data map.
  factory CameraFrame.fromMap(Map<dynamic, dynamic> map) {
    return CameraFrame(
      bytes: map['bytes'] as Uint8List,
      width: map['width'] as int,
      height: map['height'] as int,
      format: map['format'] as String,
    );
  }
}

/// Representation of a Bluetooth Low Energy (BLE) device found during scanning.
class BleDevice {
  /// The unique identifier or address of the device.
  final String id;
  /// The advertised name of the device.
  final String name;
  /// The signal strength in dBm.
  final int rssi;
  /// Optional service-specific advertisement data.
  final Map<String, dynamic>? serviceData;

  /// Constructs a [BleDevice].
  BleDevice({required this.id, required this.name, required this.rssi, this.serviceData});

  /// Creates a [BleDevice] from a raw data map.
  factory BleDevice.fromMap(Map<dynamic, dynamic> map) {
    return BleDevice(
      id: map['id'] as String,
      name: map['name'] as String? ?? 'Unknown',
      rssi: map['rssi'] as int? ?? 0,
      serviceData: (map['serviceData'] as Map?)?.cast<String, dynamic>(),
    );
  }
}

/// High-accuracy GPS/Location data containing coordinates and precision.
class LocationData {
  /// Latitude in degrees.
  final double latitude;
  /// Longitude in degrees.
  final double longitude;
  /// Altitude in meters.
  final double altitude;
  /// Horizontal accuracy in meters.
  final double accuracy;
  /// Speed in meters per second.
  final double speed;

  /// Constructs [LocationData].
  LocationData({
    required this.latitude,
    required this.longitude,
    required this.altitude,
    required this.accuracy,
    required this.speed,
  });

  /// Creates [LocationData] from a raw data map.
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

/// Information about the current WiFi connection.
class WifiInfo {
  /// The Service Set Identifier (SSID).
  final String ssid;
  /// The Basic Service Set Identifier (BSSID).
  final String bssid;
  /// Relative signal strength (0-100 or dBm depending on platform).
  final int signalStrength;
  /// Current IPv4 address.
  final String ipAddress;

  /// Constructs [WifiInfo].
  WifiInfo({required this.ssid, required this.bssid, required this.signalStrength, required this.ipAddress});

  /// Creates [WifiInfo] from a raw data map.
  factory WifiInfo.fromMap(Map<dynamic, dynamic> map) {
    return WifiInfo(
      ssid: map['ssid'] as String? ?? 'Unknown',
      bssid: map['bssid'] as String? ?? 'Unknown',
      signalStrength: map['signalStrength'] as int? ?? 0,
      ipAddress: map['ipAddress'] as String? ?? '0.0.0.0',
    );
  }
}
