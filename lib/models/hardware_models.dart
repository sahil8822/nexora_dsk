import 'dart:typed_data';

/// Preset camera preview sizes tuned for quality vs speed.
enum CameraQuality {
  low(640, 480),
  medium(960, 540),
  hd(1280, 720),
  fullHd(1920, 1080);

  const CameraQuality(this.width, this.height);

  final int width;
  final int height;
}

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

  CameraFrame({
    this.bytes,
    this.textureId,
    required this.width,
    required this.height,
    this.format = 'rgba',
    this.vision,
  });

  factory CameraFrame.fromMap(Map<dynamic, dynamic> map) {
    return CameraFrame(
      bytes: map['bytes'] as Uint8List?,
      textureId: (map['textureId'] as num?)?.toInt(),
      width: (map['width'] as num?)?.toInt() ?? 0,
      height: (map['height'] as num?)?.toInt() ?? 0,
      format: map['format'] as String? ?? 'rgba',
      vision: map['vision'] != null
          ? VisionResult.fromMap(map['vision'])
          : null,
    );
  }

  Map<String, Object?> toMap() => <String, Object?>{
    'bytes': bytes,
    'textureId': textureId,
    'width': width,
    'height': height,
    'format': format,
    'vision': vision?.toMap(),
  };
}

class VisionResult {
  final List<String> barcodes;
  final List<FaceData> faces;
  VisionResult({this.barcodes = const [], this.faces = const []});
  factory VisionResult.fromMap(Map<dynamic, dynamic> map) {
    return VisionResult(
      barcodes: (map['barcodes'] as List?)?.cast<String>() ?? [],
      faces:
          (map['faces'] as List?)?.map((f) => FaceData.fromMap(f)).toList() ??
          [],
    );
  }

  Map<String, Object?> toMap() => <String, Object?>{
    'barcodes': barcodes,
    'faces': faces.map((face) => face.toMap()).toList(growable: false),
  };
}

class FaceData {
  final double boundingBoxTop;
  final double boundingBoxLeft;
  final double? smileProb;
  FaceData({
    required this.boundingBoxTop,
    required this.boundingBoxLeft,
    this.smileProb,
  });
  factory FaceData.fromMap(Map<dynamic, dynamic> map) {
    return FaceData(
      boundingBoxTop: (map['top'] as num).toDouble(),
      boundingBoxLeft: (map['left'] as num).toDouble(),
      smileProb: (map['smile'] as num?)?.toDouble(),
    );
  }

  Map<String, Object?> toMap() => <String, Object?>{
    'top': boundingBoxTop,
    'left': boundingBoxLeft,
    'smile': smileProb,
  };
}

class AudioFrame {
  final Uint8List? bytes;
  final List<double> spectrum;
  final int sampleRate;
  AudioFrame({this.bytes, required this.spectrum, required this.sampleRate});
  factory AudioFrame.fromMap(Map<dynamic, dynamic> map) {
    return AudioFrame(
      bytes: map['bytes'] as Uint8List?,
      spectrum:
          (map['spectrum'] as List?)
              ?.map((e) => (e as num).toDouble())
              .toList() ??
          [],
      sampleRate: (map['sampleRate'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, Object?> toMap() => <String, Object?>{
    'bytes': bytes,
    'spectrum': spectrum,
    'sampleRate': sampleRate,
  };
}

class LogConfig {
  final String fileName;
  final bool includeSensors;
  final bool includeGPS;
  final int intervalMs;
  LogConfig({
    this.fileName = "nexora_log.csv",
    this.includeSensors = true,
    this.includeGPS = true,
    this.intervalMs = 100,
  });

  Map<String, Object> toMap() => <String, Object>{
    'fileName': fileName,
    'includeSensors': includeSensors,
    'includeGPS': includeGPS,
    'intervalMs': intervalMs,
  };
}

class BleDevice {
  final String id;
  final String name;
  final int rssi;
  BleDevice({required this.id, required this.name, required this.rssi});
  factory BleDevice.fromMap(Map<dynamic, dynamic> map) {
    return BleDevice(
      id: map['id'] as String,
      name: map['name'] as String? ?? 'Unknown',
      rssi: map['rssi'] as int? ?? 0,
    );
  }

  Map<String, Object> toMap() => <String, Object>{
    'id': id,
    'name': name,
    'rssi': rssi,
  };
}

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

  Map<String, Object> toMap() => <String, Object>{
    'latitude': latitude,
    'longitude': longitude,
    'altitude': altitude,
    'accuracy': accuracy,
    'speed': speed,
  };
}

class BatteryInfo {
  final double level;
  final bool isCharging;
  final String status;
  final double temperature;
  BatteryInfo({
    required this.level,
    required this.isCharging,
    required this.status,
    required this.temperature,
  });
  factory BatteryInfo.fromMap(Map<dynamic, dynamic> map) {
    return BatteryInfo(
      level: (map['level'] as num).toDouble(),
      isCharging: map['isCharging'] as bool,
      status: map['status'] as String,
      temperature: (map['temperature'] as num).toDouble(),
    );
  }

  Map<String, Object> toMap() => <String, Object>{
    'level': level,
    'isCharging': isCharging,
    'status': status,
    'temperature': temperature,
  };
}

class WifiInfo {
  final String ssid;
  final String bssid;
  final int signalStrength;
  final String ipAddress;
  WifiInfo({
    required this.ssid,
    required this.bssid,
    required this.signalStrength,
    required this.ipAddress,
  });
  factory WifiInfo.fromMap(Map<dynamic, dynamic> map) {
    return WifiInfo(
      ssid: map['ssid'] as String,
      bssid: map['bssid'] as String,
      signalStrength: map['signalStrength'] as int,
      ipAddress: map['ipAddress'] as String,
    );
  }

  Map<String, Object> toMap() => <String, Object>{
    'ssid': ssid,
    'bssid': bssid,
    'signalStrength': signalStrength,
    'ipAddress': ipAddress,
  };
}

/// Device storage information including internal, external, cache, and data sizes.
class StorageInfo {
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

  StorageInfo({
    required this.internalTotal,
    required this.internalFree,
    required this.externalTotal,
    required this.externalFree,
    required this.appCacheSize,
    required this.appDataSize,
  });

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

  Map<String, Object> toMap() => <String, Object>{
    'internalTotal': internalTotal,
    'internalFree': internalFree,
    'externalTotal': externalTotal,
    'externalFree': externalFree,
    'appCacheSize': appCacheSize,
    'appDataSize': appDataSize,
  };

  /// Returns internal storage usage as a percentage (0.0 - 1.0).
  double get internalUsage =>
      internalTotal > 0 ? 1.0 - (internalFree / internalTotal) : 0;

  /// Human-readable internal free space (e.g., "12.5 GB").
  String get internalFreeFormatted => formatBytes(internalFree);

  /// Human-readable internal total space (e.g., "128.0 GB").
  String get internalTotalFormatted => formatBytes(internalTotal);

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
  final String name;
  final int size;
  final bool isDirectory;
  final DateTime lastModified;

  FileInfo({
    required this.name,
    required this.size,
    required this.isDirectory,
    required this.lastModified,
  });

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

  Map<String, Object> toMap() => <String, Object>{
    'name': name,
    'size': size,
    'isDirectory': isDirectory,
    'lastModified': lastModified.millisecondsSinceEpoch,
  };

  /// Human-readable file size.
  String get sizeFormatted => StorageInfo.formatBytes(size);
}

/// Focus modes supported by the custom camera engine.
enum CameraFocusMode {
  auto,
  continuous,
  macro,
  locked,
}

/// Exposure modes supported by the custom camera engine.
enum CameraExposureMode {
  auto,
  locked,
}

/// Customizable camera rendering configurations.
class CameraOptions {
  final CameraQuality resolution;
  final CameraFocusMode focusMode;
  final CameraExposureMode exposureMode;
  final double exposureCompensation;
  final bool mirrorFrontCamera;

  const CameraOptions({
    this.resolution = CameraQuality.hd,
    this.focusMode = CameraFocusMode.continuous,
    this.exposureMode = CameraExposureMode.auto,
    this.exposureCompensation = 0.0,
    this.mirrorFrontCamera = true,
  });

  Map<String, dynamic> toMap() => {
        'resolution': resolution.name,
        'focusMode': focusMode.name,
        'exposureMode': exposureMode.name,
        'exposureCompensation': exposureCompensation,
        'mirrorFrontCamera': mirrorFrontCamera,
      };
}

/// Format specifying number of audio channels.
enum AudioChannelFormat {
  mono,
  stereo,
}

/// Customizable audio capture configurations.
class AudioOptions {
  final int sampleRate;
  final AudioChannelFormat channels;
  final bool enableEchoCancellation;
  final bool enableNoiseSuppression;

  const AudioOptions({
    this.sampleRate = 44100,
    this.channels = AudioChannelFormat.mono,
    this.enableEchoCancellation = true,
    this.enableNoiseSuppression = true,
  });

  Map<String, dynamic> toMap() => {
        'sampleRate': sampleRate,
        'channels': channels.name,
        'enableEchoCancellation': enableEchoCancellation,
        'enableNoiseSuppression': enableNoiseSuppression,
      };
}

/// Sampling frequencies supported by native motion sensors.
enum SensorAccuracy {
  normal,
  ui,
  game,
  fastest,
}

/// Customization options for motion sensors (accelerometer/gyroscope).
class SensorOptions {
  final SensorAccuracy accuracy;
  final bool enableLowPassFilter;
  final double lowPassAlpha;

  const SensorOptions({
    this.accuracy = SensorAccuracy.normal,
    this.enableLowPassFilter = false,
    this.lowPassAlpha = 0.15,
  });

  Map<String, dynamic> toMap() => {
        'accuracy': accuracy.name,
        'enableLowPassFilter': enableLowPassFilter,
        'lowPassAlpha': lowPassAlpha,
      };
}

/// Scanning modes for Bluetooth Low Energy.
enum BluetoothScanMode {
  balanced,
  lowPower,
  lowLatency,
}

/// Customization options for BLE scanning.
class BluetoothScanOptions {
  final BluetoothScanMode scanMode;
  final List<String> serviceUuids;
  final bool allowDuplicates;

  const BluetoothScanOptions({
    this.scanMode = BluetoothScanMode.balanced,
    this.serviceUuids = const [],
    this.allowDuplicates = false,
  });

  Map<String, dynamic> toMap() => {
        'scanMode': scanMode.name,
        'serviceUuids': serviceUuids,
        'allowDuplicates': allowDuplicates,
      };
}

/// Native coordinate accuracies for location services.
enum LocationAccuracy {
  powerSaving,
  balanced,
  highAccuracy,
  navigation,
}

/// Customization options for GPS and Inertial Sensor Fusion positioning.
class LocationOptions {
  final LocationAccuracy accuracy;
  final double distanceFilterMeters;
  final bool enableBackgroundUpdates;
  final bool showsBackgroundLocationIndicator;

  const LocationOptions({
    this.accuracy = LocationAccuracy.highAccuracy,
    this.distanceFilterMeters = 0.0,
    this.enableBackgroundUpdates = false,
    this.showsBackgroundLocationIndicator = false,
  });

  Map<String, dynamic> toMap() => {
        'accuracy': accuracy.name,
        'distanceFilterMeters': distanceFilterMeters,
        'enableBackgroundUpdates': enableBackgroundUpdates,
        'showsBackgroundLocationIndicator': showsBackgroundLocationIndicator,
      };
}

/// Customization options for native Biometric Prompt overlays (Face ID / Touch ID / Fingerprint).
class BiometricPromptOptions {
  final String title;
  final String subtitle;
  final String description;
  final String negativeButtonText;
  final bool confirmationRequired;

  const BiometricPromptOptions({
    required this.title,
    this.subtitle = '',
    this.description = '',
    this.negativeButtonText = 'Cancel',
    this.confirmationRequired = true,
  });

  Map<String, dynamic> toMap() => {
        'title': title,
        'subtitle': subtitle,
        'description': description,
        'negativeButtonText': negativeButtonText,
        'confirmationRequired': confirmationRequired,
      };
}

/// Vibration intensities and pattern types for haptic actuators.
enum HapticFeedbackType {
  light,
  medium,
  heavy,
  selection,
  success,
  warning,
  error,
}

/// Customization options for high-precision haptics.
class HapticOptions {
  final HapticFeedbackType type;
  final int intensityPercent; // 0 to 100
  final int durationMs;

  const HapticOptions({
    this.type = HapticFeedbackType.medium,
    this.intensityPercent = 100,
    this.durationMs = 50,
  });

  Map<String, dynamic> toMap() => {
        'type': type.name,
        'intensityPercent': intensityPercent,
        'durationMs': durationMs,
      };
}

/// Target output channels for routing audio playback.
enum AudioOutputRoute {
  speakerphone,
  earpiece,
  bluetooth,
  wiredHeadphones,
  defaultRoute,
}

/// Target input capture hardware microphones.
enum AudioInputDevice {
  defaultMic,
  frontMic,
  backMic,
  bottomMic,
  bluetoothMic,
  wiredHeadsetMic;
}

/// Device thermal warning status states.
enum DeviceThermalState {
  normal,
  fair,
  serious,
  critical,
}
