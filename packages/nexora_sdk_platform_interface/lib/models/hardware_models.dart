import 'dart:typed_data';

import 'package:flutter/cupertino.dart' show Texture;

import 'package:flutter/material.dart' show Texture;

import 'package:flutter/widgets.dart' show Texture;

/// Preset camera preview sizes tuned for quality vs speed.
enum CameraQuality {
  /// API Documentation for low.
  low(640, 480),

  /// API Documentation for medium.
  medium(960, 540),

  /// API Documentation for hd.
  hd(1280, 720),

  /// API Documentation for fullHd.
  fullHd(1920, 1080);

  const CameraQuality(this.width, this.height);

  /// API Documentation for width;.
  final int width;

  /// API Documentation for height;.
  final int height;
}

/// Represents a high-performance camera frame or a reference to a GPU texture.
class CameraFrame {
  /// API Documentation for CameraFrame.
  CameraFrame({
    required this.width,
    required this.height,
    this.bytes,
    this.textureId,
    this.format = 'rgba',
    this.vision,
  });

  /// API Documentation for CameraFrame.fromMap.
  factory CameraFrame.fromMap(Map<dynamic, dynamic> map) {
    return CameraFrame(
      bytes: map['bytes'] as Uint8List?,
      textureId: (map['textureId'] as num?)?.toInt(),
      width: (map['width'] as num?)?.toInt() ?? 0,
      height: (map['height'] as num?)?.toInt() ?? 0,
      format: map['format'] as String? ?? 'rgba',
      vision: map['vision'] != null
          ? VisionResult.fromMap(map['vision'] as Map<dynamic, dynamic>)
          : null,
    );
  }

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

  /// API Documentation for toMap.
  Map<String, Object?> toMap() => <String, Object?>{
        'bytes': bytes,
        'textureId': textureId,
        'width': width,
        'height': height,
        'format': format,
        'vision': vision?.toMap(),
      };

  @override
  String toString() =>
      'CameraFrame(width: $width, height: $height, format: $format, vision: $vision)';
}

/// API Documentation for Public member.
class VisionResult {
  /// API Documentation for VisionResult.
  VisionResult({this.barcodes = const [], this.faces = const []});

  /// API Documentation for VisionResult.fromMap.
  factory VisionResult.fromMap(Map<dynamic, dynamic> map) {
    return VisionResult(
      barcodes: (map['barcodes'] as List?)?.cast<String>() ?? [],
      faces: (map['faces'] as List?)
              ?.map((f) => FaceData.fromMap(f as Map<dynamic, dynamic>))
              .toList() ??
          [],
    );
  }

  /// API Documentation for barcodes;.
  final List<String> barcodes;

  /// API Documentation for faces;.
  final List<FaceData> faces;

  /// API Documentation for toMap.
  Map<String, Object?> toMap() => <String, Object?>{
        'barcodes': barcodes,
        'faces': faces.map((face) => face.toMap()).toList(growable: false),
      };
}

/// API Documentation for Public member.
class FaceData {
  /// API Documentation for FaceData.
  FaceData({
    required this.boundingBoxTop,
    required this.boundingBoxLeft,
    this.smileProb,
  });

  /// API Documentation for FaceData.fromMap.
  factory FaceData.fromMap(Map<dynamic, dynamic> map) {
    return FaceData(
      boundingBoxTop: (map['top'] as num).toDouble(),
      boundingBoxLeft: (map['left'] as num).toDouble(),
      smileProb: (map['smile'] as num?)?.toDouble(),
    );
  }

  /// API Documentation for boundingBoxTop;.
  final double boundingBoxTop;

  /// API Documentation for boundingBoxLeft;.
  final double boundingBoxLeft;

  /// API Documentation for smileProb;.
  final double? smileProb;

  /// API Documentation for toMap.
  Map<String, Object?> toMap() => <String, Object?>{
        'top': boundingBoxTop,
        'left': boundingBoxLeft,
        'smile': smileProb,
      };
}

/// API Documentation for Public member.
class AudioFrame {
  /// API Documentation for AudioFrame.
  AudioFrame({required this.spectrum, required this.sampleRate, this.bytes});

  /// API Documentation for AudioFrame.fromMap.
  factory AudioFrame.fromMap(Map<dynamic, dynamic> map) {
    return AudioFrame(
      bytes: map['bytes'] as Uint8List?,
      spectrum: (map['spectrum'] as List?)
              ?.map((e) => (e as num).toDouble())
              .toList() ??
          [],
      sampleRate: (map['sampleRate'] as num?)?.toInt() ?? 0,
    );
  }

  /// API Documentation for bytes;.
  final Uint8List? bytes;

  /// API Documentation for spectrum;.
  final List<double> spectrum;

  /// API Documentation for sampleRate;.
  final int sampleRate;

  /// API Documentation for toMap.
  Map<String, Object?> toMap() => <String, Object?>{
        'bytes': bytes,
        'spectrum': spectrum,
        'sampleRate': sampleRate,
      };

  @override
  String toString() =>
      'AudioFrame(sampleRate: $sampleRate, spectrumLength: ${spectrum.length})';
}

/// API Documentation for Public member.
class LogConfig {
  /// API Documentation for LogConfig.
  LogConfig({
    this.fileName = 'nexora_log.csv',
    this.includeSensors = true,
    this.includeGPS = true,
    this.intervalMs = 100,
  });

  /// API Documentation for fileName;.
  final String fileName;

  /// API Documentation for includeSensors;.
  final bool includeSensors;

  /// API Documentation for includeGPS;.
  final bool includeGPS;

  /// API Documentation for intervalMs;.
  final int intervalMs;

  /// API Documentation for toMap.
  Map<String, Object> toMap() => <String, Object>{
        'fileName': fileName,
        'includeSensors': includeSensors,
        'includeGPS': includeGPS,
        'intervalMs': intervalMs,
      };

  /// API Documentation for copyWith.
  LogConfig copyWith({
    String? fileName,
    bool? includeSensors,
    bool? includeGPS,
    int? intervalMs,
  }) {
    return LogConfig(
      fileName: fileName ?? this.fileName,
      includeSensors: includeSensors ?? this.includeSensors,
      includeGPS: includeGPS ?? this.includeGPS,
      intervalMs: intervalMs ?? this.intervalMs,
    );
  }

  @override
  String toString() =>
      'LogConfig(file: $fileName, sensors: $includeSensors, gps: $includeGPS, interval: $intervalMs)';
}

/// API Documentation for Public member.
class BleDevice {
  /// API Documentation for BleDevice.
  BleDevice({required this.id, required this.name, required this.rssi});

  /// API Documentation for BleDevice.fromMap.
  factory BleDevice.fromMap(Map<dynamic, dynamic> map) {
    return BleDevice(
      id: map['id'] as String,
      name: map['name'] as String? ?? 'Unknown',
      rssi: map['rssi'] as int? ?? 0,
    );
  }

  /// API Documentation for id;.
  final String id;

  /// API Documentation for name;.
  final String name;

  /// API Documentation for rssi;.
  final int rssi;

  /// API Documentation for toMap.
  Map<String, Object> toMap() => <String, Object>{
        'id': id,
        'name': name,
        'rssi': rssi,
      };

  @override
  String toString() => 'BleDevice(id: $id, name: $name, rssi: $rssi)';
}

/// API Documentation for Public member.
class LocationData {
  /// API Documentation for LocationData.
  LocationData({
    required this.latitude,
    required this.longitude,
    required this.altitude,
    required this.accuracy,
    required this.speed,
  });

  /// API Documentation for LocationData.fromMap.
  factory LocationData.fromMap(Map<dynamic, dynamic> map) {
    return LocationData(
      latitude: (map['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (map['longitude'] as num?)?.toDouble() ?? 0.0,
      altitude: (map['altitude'] as num?)?.toDouble() ?? 0.0,
      accuracy: (map['accuracy'] as num?)?.toDouble() ?? 0.0,
      speed: (map['speed'] as num?)?.toDouble() ?? 0.0,
    );
  }

  /// API Documentation for latitude;.
  final double latitude;

  /// API Documentation for longitude;.
  final double longitude;

  /// API Documentation for altitude;.
  final double altitude;

  /// API Documentation for accuracy;.
  final double accuracy;

  /// API Documentation for speed;.
  final double speed;

  /// API Documentation for toMap.
  Map<String, Object> toMap() => <String, Object>{
        'latitude': latitude,
        'longitude': longitude,
        'altitude': altitude,
        'accuracy': accuracy,
        'speed': speed,
      };

  @override
  String toString() =>
      'LocationData(latitude: $latitude, longitude: $longitude, altitude: $altitude, accuracy: $accuracy, speed: $speed)';
}

/// API Documentation for Public member.
class BatteryInfo {
  /// API Documentation for BatteryInfo.
  BatteryInfo({
    required this.level,
    required this.isCharging,
    required this.status,
    required this.temperature,
  });

  /// API Documentation for BatteryInfo.fromMap.
  factory BatteryInfo.fromMap(Map<dynamic, dynamic> map) {
    return BatteryInfo(
      level: (map['level'] as num?)?.toDouble() ?? 0.0,
      isCharging: map['isCharging'] as bool? ?? false,
      status: map['status'] as String? ?? 'unknown',
      temperature: (map['temperature'] as num?)?.toDouble() ?? 0.0,
    );
  }

  /// API Documentation for level;.
  final double level;

  /// API Documentation for isCharging;.
  final bool isCharging;

  /// API Documentation for status;.
  final String status;

  /// API Documentation for temperature;.
  final double temperature;

  /// API Documentation for toMap.
  Map<String, Object> toMap() => <String, Object>{
        'level': level,
        'isCharging': isCharging,
        'status': status,
        'temperature': temperature,
      };

  @override
  String toString() =>
      'BatteryInfo(level: $level, isCharging: $isCharging, status: $status, temp: $temperature)';
}

/// API Documentation for Public member.
class WifiInfo {
  /// API Documentation for WifiInfo.
  WifiInfo({
    required this.ssid,
    required this.bssid,
    required this.signalStrength,
    required this.ipAddress,
  });

  /// API Documentation for WifiInfo.fromMap.
  factory WifiInfo.fromMap(Map<dynamic, dynamic> map) {
    return WifiInfo(
      ssid: map['ssid'] as String? ?? 'unknown',
      bssid: map['bssid'] as String? ?? '00:00:00:00:00:00',
      signalStrength: (map['signalStrength'] as num?)?.toInt() ?? 0,
      ipAddress: map['ipAddress'] as String? ?? '0.0.0.0',
    );
  }

  /// API Documentation for ssid;.
  final String ssid;

  /// API Documentation for bssid;.
  final String bssid;

  /// API Documentation for signalStrength;.
  final int signalStrength;

  /// API Documentation for ipAddress;.
  final String ipAddress;

  /// API Documentation for toMap.
  Map<String, Object> toMap() => <String, Object>{
        'ssid': ssid,
        'bssid': bssid,
        'signalStrength': signalStrength,
        'ipAddress': ipAddress,
      };

  @override
  String toString() =>
      'WifiInfo(ssid: $ssid, bssid: $bssid, signal: $signalStrength, ip: $ipAddress)';
}

/// Device storage information including internal, external, cache, and data sizes.
class StorageInfo {
  /// API Documentation for StorageInfo.
  StorageInfo({
    required this.internalTotal,
    required this.internalFree,
    required this.externalTotal,
    required this.externalFree,
    required this.appCacheSize,
    required this.appDataSize,
  });

  /// API Documentation for StorageInfo.fromMap.
  factory StorageInfo.fromMap(Map<dynamic, dynamic> map) {
    return StorageInfo(
      internalTotal: (map['internalTotal'] as num).toInt(),
      internalFree: (map['internalFree'] as num).toInt(),
      externalTotal: (map['externalTotal'] as num).toInt(),
      externalFree: (map['externalFree'] as num).toInt(),
      appCacheSize: (map['appCacheSize'] as num).toInt(),
      appDataSize: (map['appDataSize'] as num).toInt(),
    );
  }

  /// Total internal storage in bytes.
  final int internalTotal;

  /// Free internal storage in bytes.
  final int internalFree;

  /// Total external (SD) storage in bytes. 0 if unavailable.
  final int externalTotal;

  /// Free external storage in bytes.
  final int externalFree;

  /// App cache directory size in bytes.
  final int appCacheSize;

  /// App data directory size in bytes.
  final int appDataSize;

  /// API Documentation for toMap.
  Map<String, Object> toMap() => <String, Object>{
        'internalTotal': internalTotal,
        'internalFree': internalFree,
        'externalTotal': externalTotal,
        'externalFree': externalFree,
        'appCacheSize': appCacheSize,
        'appDataSize': appDataSize,
      };

  /// API Documentation for copyWith.
  StorageInfo copyWith({
    int? internalTotal,
    int? internalFree,
    int? externalTotal,
    int? externalFree,
    int? appCacheSize,
    int? appDataSize,
  }) {
    return StorageInfo(
      internalTotal: internalTotal ?? this.internalTotal,
      internalFree: internalFree ?? this.internalFree,
      externalTotal: externalTotal ?? this.externalTotal,
      externalFree: externalFree ?? this.externalFree,
      appCacheSize: appCacheSize ?? this.appCacheSize,
      appDataSize: appDataSize ?? this.appDataSize,
    );
  }

  @override
  String toString() =>
      'StorageInfo(total: $internalTotal, free: $internalFree, externalTotal: $externalTotal, externalFree: $externalFree, cache: $appCacheSize, data: $appDataSize)';

  /// Returns internal storage usage as a percentage (0.0 - 1.0).
  double get internalUsage =>
      internalTotal > 0 ? 1.0 - (internalFree / internalTotal) : 0;

  /// Human-readable internal free space (e.g., "12.5 GB").
  String get internalFreeFormatted => formatBytes(internalFree);

  /// Human-readable internal total space (e.g., "128.0 GB").
  String get internalTotalFormatted => formatBytes(internalTotal);

  /// API Documentation for formatBytes.
  static String formatBytes(int bytes) {
    if (bytes >= 1073741824) {
      return '${(bytes / 1073741824).toStringAsFixed(1)} GB';
    }
    if (bytes >= 1048576) return '${(bytes / 1048576).toStringAsFixed(1)} MB';
    if (bytes >= 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '$bytes B';
  }
}

/// Metadata for a file in device storage.
class FileInfo {
  /// API Documentation for FileInfo.
  FileInfo({
    required this.name,
    required this.size,
    required this.isDirectory,
    required this.lastModified,
  });

  /// API Documentation for FileInfo.fromMap.
  factory FileInfo.fromMap(Map<dynamic, dynamic> map) {
    return FileInfo(
      name: map['name'] as String,
      size: (map['size'] as num).toInt(),
      isDirectory: map['isDirectory'] as bool,
      lastModified: DateTime.fromMillisecondsSinceEpoch(
        (map['lastModified'] as num).toInt(),
      ),
    );
  }

  /// API Documentation for name;.
  final String name;

  /// API Documentation for size;.
  final int size;

  /// API Documentation for isDirectory;.
  final bool isDirectory;

  /// API Documentation for lastModified;.
  final DateTime lastModified;

  /// API Documentation for toMap.
  Map<String, Object> toMap() => <String, Object>{
        'name': name,
        'size': size,
        'isDirectory': isDirectory,
        'lastModified': lastModified.millisecondsSinceEpoch,
      };

  /// API Documentation for copyWith.
  FileInfo copyWith({
    String? name,
    int? size,
    bool? isDirectory,
    DateTime? lastModified,
  }) {
    return FileInfo(
      name: name ?? this.name,
      size: size ?? this.size,
      isDirectory: isDirectory ?? this.isDirectory,
      lastModified: lastModified ?? this.lastModified,
    );
  }

  @override
  String toString() =>
      'FileInfo(name: $name, size: $size, dir: $isDirectory, modified: $lastModified)';

  /// Human-readable file size.
  String get sizeFormatted => StorageInfo.formatBytes(size);
}

/// Focus modes supported by the custom camera engine.
/// API Documentation for Public member.
/// API Documentation for Public member.
enum CameraFocusMode { auto, continuous, macro, locked }

/// Exposure modes supported by the custom camera engine.
/// API Documentation for Public member.
/// API Documentation for Public member.
enum CameraExposureMode { auto, locked }

/// Customizable camera rendering configurations.
class CameraOptions {
  /// API Documentation for CameraOptions.
  const CameraOptions({
    this.resolution = CameraQuality.hd,
    this.focusMode = CameraFocusMode.continuous,
    this.exposureMode = CameraExposureMode.auto,
    this.exposureCompensation = 0.0,
    this.mirrorFrontCamera = true,
  });

  /// API Documentation for resolution;.
  final CameraQuality resolution;

  /// API Documentation for focusMode;.
  final CameraFocusMode focusMode;

  /// API Documentation for exposureMode;.
  final CameraExposureMode exposureMode;

  /// API Documentation for exposureCompensation;.
  final double exposureCompensation;

  /// API Documentation for mirrorFrontCamera;.
  final bool mirrorFrontCamera;

  /// API Documentation for toMap.
  Map<String, dynamic> toMap() => {
        'resolution': resolution.name,
        'focusMode': focusMode.name,
        'exposureMode': exposureMode.name,
        'exposureCompensation': exposureCompensation,
        'mirrorFrontCamera': mirrorFrontCamera,
      };

  /// API Documentation for copyWith.
  CameraOptions copyWith({
    CameraQuality? resolution,
    CameraFocusMode? focusMode,
    CameraExposureMode? exposureMode,
    double? exposureCompensation,
    bool? mirrorFrontCamera,
  }) {
    return CameraOptions(
      resolution: resolution ?? this.resolution,
      focusMode: focusMode ?? this.focusMode,
      exposureMode: exposureMode ?? this.exposureMode,
      exposureCompensation: exposureCompensation ?? this.exposureCompensation,
      mirrorFrontCamera: mirrorFrontCamera ?? this.mirrorFrontCamera,
    );
  }

  @override
  String toString() =>
      'CameraOptions(resolution: $resolution, focusMode: $focusMode, exposureMode: $exposureMode, compensation: $exposureCompensation, mirrorFront: $mirrorFrontCamera)';
}

/// Format specifying number of audio channels.
/// API Documentation for Public member.
/// API Documentation for Public member.
enum AudioChannelFormat { mono, stereo }

/// Customizable audio capture configurations.
class AudioOptions {
  /// API Documentation for AudioOptions.
  const AudioOptions({
    this.sampleRate = 44100,
    this.channels = AudioChannelFormat.mono,
    this.enableEchoCancellation = true,
    this.enableNoiseSuppression = true,
  });

  /// API Documentation for sampleRate;.
  final int sampleRate;

  /// API Documentation for channels;.
  final AudioChannelFormat channels;

  /// API Documentation for enableEchoCancellation;.
  final bool enableEchoCancellation;

  /// API Documentation for enableNoiseSuppression;.
  final bool enableNoiseSuppression;

  /// API Documentation for toMap.
  Map<String, dynamic> toMap() => {
        'sampleRate': sampleRate,
        'channels': channels.name,
        'enableEchoCancellation': enableEchoCancellation,
        'enableNoiseSuppression': enableNoiseSuppression,
      };

  /// API Documentation for copyWith.
  AudioOptions copyWith({
    int? sampleRate,
    AudioChannelFormat? channels,
    bool? enableEchoCancellation,
    bool? enableNoiseSuppression,
  }) {
    return AudioOptions(
      sampleRate: sampleRate ?? this.sampleRate,
      channels: channels ?? this.channels,
      enableEchoCancellation:
          enableEchoCancellation ?? this.enableEchoCancellation,
      enableNoiseSuppression:
          enableNoiseSuppression ?? this.enableNoiseSuppression,
    );
  }

  @override
  String toString() =>
      'AudioOptions(sampleRate: $sampleRate, channels: $channels, echoCancellation: $enableEchoCancellation, noiseSuppression: $enableNoiseSuppression)';
}

/// Sampling frequencies supported by native motion sensors.
/// API Documentation for Public member.
/// API Documentation for Public member.
enum SensorAccuracy { normal, ui, game, fastest }

/// Customization options for motion sensors (accelerometer/gyroscope).
class SensorOptions {
  /// API Documentation for SensorOptions.
  const SensorOptions({
    this.accuracy = SensorAccuracy.normal,
    this.enableLowPassFilter = false,
    this.lowPassAlpha = 0.15,
  });

  /// API Documentation for accuracy;.
  final SensorAccuracy accuracy;

  /// API Documentation for enableLowPassFilter;.
  final bool enableLowPassFilter;

  /// API Documentation for lowPassAlpha;.
  final double lowPassAlpha;

  /// API Documentation for toMap.
  Map<String, dynamic> toMap() => {
        'accuracy': accuracy.name,
        'enableLowPassFilter': enableLowPassFilter,
        'lowPassAlpha': lowPassAlpha,
      };

  /// API Documentation for copyWith.
  SensorOptions copyWith({
    SensorAccuracy? accuracy,
    bool? enableLowPassFilter,
    double? lowPassAlpha,
  }) {
    return SensorOptions(
      accuracy: accuracy ?? this.accuracy,
      enableLowPassFilter: enableLowPassFilter ?? this.enableLowPassFilter,
      lowPassAlpha: lowPassAlpha ?? this.lowPassAlpha,
    );
  }

  @override
  String toString() =>
      'SensorOptions(accuracy: $accuracy, lowPassFilter: $enableLowPassFilter, lowPassAlpha: $lowPassAlpha)';
}

/// Scanning modes for Bluetooth Low Energy.
/// API Documentation for Public member.
/// API Documentation for Public member.
enum BluetoothScanMode { balanced, lowPower, lowLatency }

/// Customization options for BLE scanning.
class BluetoothScanOptions {
  /// API Documentation for BluetoothScanOptions.
  const BluetoothScanOptions({
    this.scanMode = BluetoothScanMode.balanced,
    this.serviceUuids = const [],
    this.allowDuplicates = false,
  });

  /// API Documentation for scanMode;.
  final BluetoothScanMode scanMode;

  /// API Documentation for serviceUuids;.
  final List<String> serviceUuids;

  /// API Documentation for allowDuplicates;.
  final bool allowDuplicates;

  /// API Documentation for toMap.
  Map<String, dynamic> toMap() => {
        'scanMode': scanMode.name,
        'serviceUuids': serviceUuids,
        'allowDuplicates': allowDuplicates,
      };

  /// API Documentation for copyWith.
  BluetoothScanOptions copyWith({
    BluetoothScanMode? scanMode,
    List<String>? serviceUuids,
    bool? allowDuplicates,
  }) {
    return BluetoothScanOptions(
      scanMode: scanMode ?? this.scanMode,
      serviceUuids: serviceUuids ?? this.serviceUuids,
      allowDuplicates: allowDuplicates ?? this.allowDuplicates,
    );
  }

  @override
  String toString() =>
      'BluetoothScanOptions(scanMode: $scanMode, serviceUuids: $serviceUuids, allowDuplicates: $allowDuplicates)';
}

/// Native coordinate accuracies for location services.
/// API Documentation for Public member.
/// API Documentation for Public member.
enum LocationAccuracy { powerSaving, balanced, highAccuracy, navigation }

/// Customization options for GPS and Inertial Sensor Fusion positioning.
class LocationOptions {
  /// API Documentation for LocationOptions.
  const LocationOptions({
    this.accuracy = LocationAccuracy.highAccuracy,
    this.distanceFilterMeters = 0.0,
    this.enableBackgroundUpdates = false,
    this.showsBackgroundLocationIndicator = false,
  });

  /// API Documentation for accuracy;.
  final LocationAccuracy accuracy;

  /// API Documentation for distanceFilterMeters;.
  final double distanceFilterMeters;

  /// API Documentation for enableBackgroundUpdates;.
  final bool enableBackgroundUpdates;

  /// API Documentation for showsBackgroundLocationIndicator;.
  final bool showsBackgroundLocationIndicator;

  /// API Documentation for toMap.
  Map<String, dynamic> toMap() => {
        'accuracy': accuracy.name,
        'distanceFilterMeters': distanceFilterMeters,
        'enableBackgroundUpdates': enableBackgroundUpdates,
        'showsBackgroundLocationIndicator': showsBackgroundLocationIndicator,
      };

  /// API Documentation for copyWith.
  LocationOptions copyWith({
    LocationAccuracy? accuracy,
    double? distanceFilterMeters,
    bool? enableBackgroundUpdates,
    bool? showsBackgroundLocationIndicator,
  }) {
    return LocationOptions(
      accuracy: accuracy ?? this.accuracy,
      distanceFilterMeters: distanceFilterMeters ?? this.distanceFilterMeters,
      enableBackgroundUpdates:
          enableBackgroundUpdates ?? this.enableBackgroundUpdates,
      showsBackgroundLocationIndicator: showsBackgroundLocationIndicator ??
          this.showsBackgroundLocationIndicator,
    );
  }

  @override
  String toString() =>
      'LocationOptions(accuracy: $accuracy, distanceFilter: $distanceFilterMeters, backgroundUpdates: $enableBackgroundUpdates, backgroundIndicator: $showsBackgroundLocationIndicator)';
}

/// Customization options for native Biometric Prompt overlays (Face ID / Touch ID / Fingerprint).
class BiometricPromptOptions {
  /// API Documentation for BiometricPromptOptions.
  const BiometricPromptOptions({
    required this.title,
    this.subtitle = '',
    this.description = '',
    this.negativeButtonText = 'Cancel',
    this.confirmationRequired = true,
  });

  /// API Documentation for title;.
  final String title;

  /// API Documentation for subtitle;.
  final String subtitle;

  /// API Documentation for description;.
  final String description;

  /// API Documentation for negativeButtonText;.
  final String negativeButtonText;

  /// API Documentation for confirmationRequired;.
  final bool confirmationRequired;

  /// API Documentation for toMap.
  Map<String, dynamic> toMap() => {
        'title': title,
        'subtitle': subtitle,
        'description': description,
        'negativeButtonText': negativeButtonText,
        'confirmationRequired': confirmationRequired,
      };

  /// API Documentation for copyWith.
  BiometricPromptOptions copyWith({
    String? title,
    String? subtitle,
    String? description,
    String? negativeButtonText,
    bool? confirmationRequired,
  }) {
    return BiometricPromptOptions(
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      description: description ?? this.description,
      negativeButtonText: negativeButtonText ?? this.negativeButtonText,
      confirmationRequired: confirmationRequired ?? this.confirmationRequired,
    );
  }

  @override
  String toString() =>
      'BiometricPromptOptions(title: $title, subtitle: $subtitle, description: $description, negativeButton: $negativeButtonText, confirmation: $confirmationRequired)';
}

/// Vibration intensities and pattern types for haptic actuators.
enum HapticFeedbackType {
  /// API Documentation for light,.
  light,

  /// API Documentation for medium,.
  medium,

  /// API Documentation for heavy,.
  heavy,

  /// API Documentation for selection,.
  selection,

  /// API Documentation for success,.
  success,

  /// API Documentation for warning,.
  warning,

  /// API Documentation for error,.
  error,
}

/// Customization options for high-precision haptics.
class HapticOptions {
  /// API Documentation for HapticOptions.
  const HapticOptions({
    this.type = HapticFeedbackType.medium,
    this.intensityPercent = 100,
    this.durationMs = 50,
  });

  /// API Documentation for type;.
  final HapticFeedbackType type;

  /// API Documentation for 100.
  final int intensityPercent; // 0 to 100
  /// API Documentation for durationMs;.
  final int durationMs;

  /// API Documentation for toMap.
  Map<String, dynamic> toMap() => {
        'type': type.name,
        'intensityPercent': intensityPercent,
        'durationMs': durationMs,
      };

  /// API Documentation for copyWith.
  HapticOptions copyWith({
    HapticFeedbackType? type,
    int? intensityPercent,
    int? durationMs,
  }) {
    return HapticOptions(
      type: type ?? this.type,
      intensityPercent: intensityPercent ?? this.intensityPercent,
      durationMs: durationMs ?? this.durationMs,
    );
  }

  @override
  String toString() =>
      'HapticOptions(type: $type, intensity: $intensityPercent, duration: $durationMs)';
}

/// Target output channels for routing audio playback.
enum AudioOutputRoute {
  /// API Documentation for speakerphone,.
  speakerphone,

  /// API Documentation for earpiece,.
  earpiece,

  /// API Documentation for bluetooth,.
  bluetooth,

  /// API Documentation for wiredHeadphones,.
  wiredHeadphones,

  /// API Documentation for defaultRoute,.
  defaultRoute,
}

/// Target input capture hardware microphones.
enum AudioInputDevice {
  /// API Documentation for defaultMic,.
  defaultMic,

  /// API Documentation for frontMic,.
  frontMic,

  /// API Documentation for backMic,.
  backMic,

  /// API Documentation for bottomMic,.
  bottomMic,

  /// API Documentation for bluetoothMic,.
  bluetoothMic,

  /// API Documentation for wiredHeadsetMic,.
  wiredHeadsetMic,
}

/// Device thermal warning status states.
/// API Documentation for Public member.
/// API Documentation for Public member.
enum DeviceThermalState { normal, fair, serious, critical }
