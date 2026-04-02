import 'dart:typed_data';

/// Represents a raw camera frame from native hardware.
class CameraFrame {
  final Uint8List bytes;
  final int width;
  final int height;
  final String format; // 'yuv', 'nv21', 'rgba'

  CameraFrame({required this.bytes, required this.width, required this.height, this.format = 'rgba'});

  factory CameraFrame.fromMap(Map<dynamic, dynamic> map) {
    return CameraFrame(
      bytes: map['bytes'] as Uint8List,
      width: map['width'] as int,
      height: map['height'] as int,
      format: map['format'] as String,
    );
  }
}

/// Representation of a Bluetooth Low Energy (BLE) device.
class BleDevice {
  final String id;
  final String name;
  final int rssi;
  final Map<String, dynamic>? serviceData;

  BleDevice({required this.id, required this.name, required this.rssi, this.serviceData});

  factory BleDevice.fromMap(Map<dynamic, dynamic> map) {
    return BleDevice(
      id: map['id'] as String,
      name: map['name'] as String? ?? 'Unknown',
      rssi: map['rssi'] as int? ?? 0,
      serviceData: (map['serviceData'] as Map?)?.cast<String, dynamic>(),
    );
  }
}

/// High-accuracy GPS/Location data.
class LocationData {
  final double latitude;
  final double longitude;
  final double altitude;
  final double accuracy;
  final double speed;

  LocationData({
    required this.latitude,
    required this.longitude,
    required this.altitude,
    required this.accuracy,
    required this.speed,
  });

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

/// WiFi/Network Information.
class WifiInfo {
  final String ssid;
  final String bssid;
  final int signalStrength;
  final String ipAddress;

  WifiInfo({required this.ssid, required this.bssid, required this.signalStrength, required this.ipAddress});

  factory WifiInfo.fromMap(Map<dynamic, dynamic> map) {
    return WifiInfo(
      ssid: map['ssid'] as String? ?? 'Unknown',
      bssid: map['bssid'] as String? ?? 'Unknown',
      signalStrength: map['signalStrength'] as int? ?? 0,
      ipAddress: map['ipAddress'] as String? ?? '0.0.0.0',
    );
  }
}
