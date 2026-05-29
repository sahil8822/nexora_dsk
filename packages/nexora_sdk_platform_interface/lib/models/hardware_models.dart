// ignore_for_file: lines_longer_than_80_chars, public_member_api_docs, sort_constructors_first
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

/// How the SDK should behave when a feature is unavailable on the platform.
enum UnsupportedFeaturePolicy {
  /// Throw a hardware exception so unsupported calls are visible in debugging.
  throwException,

  /// Return the safest fallback value supported by the platform implementation.
  returnFallback,
}

T _enumValue<T extends Enum>(
  List<T> values,
  Object? name,
  T fallback,
) {
  return values.firstWhere(
    (value) => value.name == name,
    orElse: () => fallback,
  );
}

Map<String, Object> _objectMap(Object? value) {
  return Map<String, Object>.from(value as Map? ?? const <String, Object>{});
}

List<String> _stringList(Object? value) {
  return (value as List?)?.cast<String>() ?? const <String>[];
}

/// Preferred native camera lens.
enum NativeCameraLens { defaultLens, front, back, ultraWide, telephoto }

/// Preferred native camera frame rate.
enum NativeCameraFps { platformDefault, fps24, fps30, fps60 }

/// Camera image encoding used for still images or analysis frames.
enum NativeImageFormat { platformDefault, jpeg, heic, yuv, raw }

/// Native video codec preference.
enum NativeVideoCodec { platformDefault, h264, hevc }

/// Barcode/face detector speed and quality preference.
enum NativeVisionPerformanceMode { balanced, fast, accurate }

/// Android microphone source preference.
enum AndroidAudioSource { mic, camcorder, voiceRecognition, voiceCommunication }

/// Android Bluetooth connection priority.
enum AndroidBleConnectionPriority { balanced, high, lowPower }

/// Android biometric authenticator strength.
enum AndroidBiometricStrength { deviceDefault, weak, strong }

/// iOS audio session category.
enum IosAudioSessionCategory {
  ambient,
  playback,
  record,
  playAndRecord,
  multiRoute,
}

/// iOS audio session mode.
enum IosAudioSessionMode {
  defaultMode,
  measurement,
  spokenAudio,
  videoChat,
  voiceChat,
}

/// iOS camera session preset preference.
enum IosCameraSessionPreset {
  high,
  medium,
  low,
  hd1280x720,
  hd1920x1080,
  photo,
}

/// Orientation lock preference for native UI helpers.
enum NativeOrientationLock { system, portrait, landscape, all }

/// Advanced Android camera customization.
class AndroidCameraOptions {
  /// Creates Android camera customization options.
  const AndroidCameraOptions({
    this.lens = NativeCameraLens.defaultLens,
    this.fps = NativeCameraFps.platformDefault,
    this.cameraSelectorId,
    this.enableVideoStabilization = true,
    this.imageFormat = NativeImageFormat.jpeg,
    this.videoCodec = NativeVideoCodec.platformDefault,
    this.videoBitrate,
    this.visionPerformanceMode = NativeVisionPerformanceMode.balanced,
    this.manualControls = const <String, Object>{},
  });

  /// Creates options from a serialized map.
  factory AndroidCameraOptions.fromMap(Map<dynamic, dynamic> map) {
    return AndroidCameraOptions(
      lens: _enumValue(
        NativeCameraLens.values,
        map['lens'],
        NativeCameraLens.defaultLens,
      ),
      fps: _enumValue(
        NativeCameraFps.values,
        map['fps'],
        NativeCameraFps.platformDefault,
      ),
      cameraSelectorId: map['cameraSelectorId'] as String?,
      enableVideoStabilization:
          map['enableVideoStabilization'] as bool? ?? true,
      imageFormat: _enumValue(
        NativeImageFormat.values,
        map['imageFormat'],
        NativeImageFormat.jpeg,
      ),
      videoCodec: _enumValue(
        NativeVideoCodec.values,
        map['videoCodec'],
        NativeVideoCodec.platformDefault,
      ),
      videoBitrate: (map['videoBitrate'] as num?)?.toInt(),
      visionPerformanceMode: _enumValue(
        NativeVisionPerformanceMode.values,
        map['visionPerformanceMode'],
        NativeVisionPerformanceMode.balanced,
      ),
      manualControls: _objectMap(map['manualControls']),
    );
  }

  /// Preferred lens.
  final NativeCameraLens lens;

  /// Preferred frame rate.
  final NativeCameraFps fps;

  /// Optional CameraX selector or vendor camera id.
  final String? cameraSelectorId;

  /// Whether native video stabilization should be requested.
  final bool enableVideoStabilization;

  /// Preferred image format.
  final NativeImageFormat imageFormat;

  /// Preferred video codec.
  final NativeVideoCodec videoCodec;

  /// Preferred video bitrate in bits per second.
  final int? videoBitrate;

  /// Vision detector performance preference.
  final NativeVisionPerformanceMode visionPerformanceMode;

  /// Manual focus, exposure, ISO, shutter, and white-balance values.
  final Map<String, Object> manualControls;

  /// Converts this object to a platform-channel map.
  Map<String, Object?> toMap() => <String, Object?>{
        'lens': lens.name,
        'fps': fps.name,
        'cameraSelectorId': cameraSelectorId,
        'enableVideoStabilization': enableVideoStabilization,
        'imageFormat': imageFormat.name,
        'videoCodec': videoCodec.name,
        'videoBitrate': videoBitrate,
        'visionPerformanceMode': visionPerformanceMode.name,
        'manualControls': manualControls,
      };
}

/// Advanced Android audio customization.
class AndroidAudioOptions {
  /// Creates Android audio customization options.
  const AndroidAudioOptions({
    this.source = AndroidAudioSource.mic,
    this.enableAutomaticGainControl = true,
    this.enableEchoCancellation = true,
    this.enableNoiseSuppression = true,
    this.allowBluetoothSco = true,
    this.bitDepth = 16,
    this.bufferSize,
  });

  /// Creates options from a serialized map.
  factory AndroidAudioOptions.fromMap(Map<dynamic, dynamic> map) {
    return AndroidAudioOptions(
      source: _enumValue(
        AndroidAudioSource.values,
        map['source'],
        AndroidAudioSource.mic,
      ),
      enableAutomaticGainControl:
          map['enableAutomaticGainControl'] as bool? ?? true,
      enableEchoCancellation: map['enableEchoCancellation'] as bool? ?? true,
      enableNoiseSuppression: map['enableNoiseSuppression'] as bool? ?? true,
      allowBluetoothSco: map['allowBluetoothSco'] as bool? ?? true,
      bitDepth: (map['bitDepth'] as num?)?.toInt() ?? 16,
      bufferSize: (map['bufferSize'] as num?)?.toInt(),
    );
  }

  /// Android microphone source.
  final AndroidAudioSource source;

  /// Whether Android AGC should be requested.
  final bool enableAutomaticGainControl;

  /// Whether echo cancellation should be requested.
  final bool enableEchoCancellation;

  /// Whether noise suppression should be requested.
  final bool enableNoiseSuppression;

  /// Whether Bluetooth SCO microphone routing may be used.
  final bool allowBluetoothSco;

  /// PCM bit depth preference.
  final int bitDepth;

  /// Native buffer size preference.
  final int? bufferSize;

  /// Converts this object to a platform-channel map.
  Map<String, Object?> toMap() => <String, Object?>{
        'source': source.name,
        'enableAutomaticGainControl': enableAutomaticGainControl,
        'enableEchoCancellation': enableEchoCancellation,
        'enableNoiseSuppression': enableNoiseSuppression,
        'allowBluetoothSco': allowBluetoothSco,
        'bitDepth': bitDepth,
        'bufferSize': bufferSize,
      };
}

/// Advanced Android BLE customization.
class AndroidBluetoothOptions {
  /// Creates Android BLE customization options.
  const AndroidBluetoothOptions({
    this.scanTimeoutMs,
    this.connectionPriority = AndroidBleConnectionPriority.balanced,
    this.defaultMtu,
    this.autoReconnect = true,
    this.filters = const <String, Object>{},
  });

  /// Creates options from a serialized map.
  factory AndroidBluetoothOptions.fromMap(Map<dynamic, dynamic> map) {
    return AndroidBluetoothOptions(
      scanTimeoutMs: (map['scanTimeoutMs'] as num?)?.toInt(),
      connectionPriority: _enumValue(
        AndroidBleConnectionPriority.values,
        map['connectionPriority'],
        AndroidBleConnectionPriority.balanced,
      ),
      defaultMtu: (map['defaultMtu'] as num?)?.toInt(),
      autoReconnect: map['autoReconnect'] as bool? ?? true,
      filters: _objectMap(map['filters']),
    );
  }

  /// Optional scan timeout.
  final int? scanTimeoutMs;

  /// Preferred GATT connection priority.
  final AndroidBleConnectionPriority connectionPriority;

  /// Default MTU requested after connection.
  final int? defaultMtu;

  /// Whether connection helpers should reconnect when possible.
  final bool autoReconnect;

  /// Manufacturer, service-data, and device-name filters.
  final Map<String, Object> filters;

  /// Converts this object to a platform-channel map.
  Map<String, Object?> toMap() => <String, Object?>{
        'scanTimeoutMs': scanTimeoutMs,
        'connectionPriority': connectionPriority.name,
        'defaultMtu': defaultMtu,
        'autoReconnect': autoReconnect,
        'filters': filters,
      };
}

/// Advanced Android location customization.
class AndroidLocationOptions {
  /// Creates Android location customization options.
  const AndroidLocationOptions({
    this.updateIntervalMs = 1000,
    this.fastestIntervalMs = 500,
    this.maxWaitTimeMs,
    this.foregroundServiceType = 'location',
    this.notificationChannelId = 'nexora_location',
    this.notificationTitle = 'Location active',
    this.notificationText = 'Nexora SDK is using location.',
    this.geofenceDwellMs,
    this.geofenceInitialTrigger = 'enter',
  });

  /// Creates options from a serialized map.
  factory AndroidLocationOptions.fromMap(Map<dynamic, dynamic> map) {
    return AndroidLocationOptions(
      updateIntervalMs: (map['updateIntervalMs'] as num?)?.toInt() ?? 1000,
      fastestIntervalMs: (map['fastestIntervalMs'] as num?)?.toInt() ?? 500,
      maxWaitTimeMs: (map['maxWaitTimeMs'] as num?)?.toInt(),
      foregroundServiceType:
          map['foregroundServiceType'] as String? ?? 'location',
      notificationChannelId:
          map['notificationChannelId'] as String? ?? 'nexora_location',
      notificationTitle:
          map['notificationTitle'] as String? ?? 'Location active',
      notificationText:
          map['notificationText'] as String? ?? 'Nexora SDK is using location.',
      geofenceDwellMs: (map['geofenceDwellMs'] as num?)?.toInt(),
      geofenceInitialTrigger:
          map['geofenceInitialTrigger'] as String? ?? 'enter',
    );
  }

  /// Desired update interval.
  final int updateIntervalMs;

  /// Desired fastest update interval.
  final int fastestIntervalMs;

  /// Desired batching wait time.
  final int? maxWaitTimeMs;

  /// Android foreground service type string.
  final String foregroundServiceType;

  /// Notification channel id for foreground work.
  final String notificationChannelId;

  /// Foreground notification title.
  final String notificationTitle;

  /// Foreground notification text.
  final String notificationText;

  /// Optional geofence dwell delay.
  final int? geofenceDwellMs;

  /// Initial geofence trigger preference.
  final String geofenceInitialTrigger;

  /// Converts this object to a platform-channel map.
  Map<String, Object?> toMap() => <String, Object?>{
        'updateIntervalMs': updateIntervalMs,
        'fastestIntervalMs': fastestIntervalMs,
        'maxWaitTimeMs': maxWaitTimeMs,
        'foregroundServiceType': foregroundServiceType,
        'notificationChannelId': notificationChannelId,
        'notificationTitle': notificationTitle,
        'notificationText': notificationText,
        'geofenceDwellMs': geofenceDwellMs,
        'geofenceInitialTrigger': geofenceInitialTrigger,
      };
}

/// Advanced Android sensor customization.
class AndroidSensorOptions {
  /// Creates Android sensor customization options.
  const AndroidSensorOptions({
    this.sensorTypes = const <String>[
      'accelerometer',
      'gyroscope',
    ],
    this.batchingLatencyUs,
    this.emitCalibration = false,
    this.useWakeUpSensors = false,
  });

  /// Creates options from a serialized map.
  factory AndroidSensorOptions.fromMap(Map<dynamic, dynamic> map) {
    return AndroidSensorOptions(
      sensorTypes: map.containsKey('sensorTypes')
          ? _stringList(map['sensorTypes'])
          : const <String>['accelerometer', 'gyroscope'],
      batchingLatencyUs: (map['batchingLatencyUs'] as num?)?.toInt(),
      emitCalibration: map['emitCalibration'] as bool? ?? false,
      useWakeUpSensors: map['useWakeUpSensors'] as bool? ?? false,
    );
  }

  /// Sensor type names to subscribe to.
  final List<String> sensorTypes;

  /// Sensor batching latency in microseconds.
  final int? batchingLatencyUs;

  /// Whether calibration status should be emitted.
  final bool emitCalibration;

  /// Whether wake-up sensors should be preferred.
  final bool useWakeUpSensors;

  /// Converts this object to a platform-channel map.
  Map<String, Object?> toMap() => <String, Object?>{
        'sensorTypes': sensorTypes,
        'batchingLatencyUs': batchingLatencyUs,
        'emitCalibration': emitCalibration,
        'useWakeUpSensors': useWakeUpSensors,
      };
}

/// Advanced Android biometric customization.
class AndroidBiometricOptions {
  /// Creates Android biometric customization options.
  const AndroidBiometricOptions({
    this.strength = AndroidBiometricStrength.deviceDefault,
    this.allowDeviceCredential = true,
    this.confirmationRequired = true,
    this.invalidateKeysOnEnrollment = true,
  });

  /// Creates options from a serialized map.
  factory AndroidBiometricOptions.fromMap(Map<dynamic, dynamic> map) {
    return AndroidBiometricOptions(
      strength: _enumValue(
        AndroidBiometricStrength.values,
        map['strength'],
        AndroidBiometricStrength.deviceDefault,
      ),
      allowDeviceCredential: map['allowDeviceCredential'] as bool? ?? true,
      confirmationRequired: map['confirmationRequired'] as bool? ?? true,
      invalidateKeysOnEnrollment:
          map['invalidateKeysOnEnrollment'] as bool? ?? true,
    );
  }

  /// Requested biometric strength.
  final AndroidBiometricStrength strength;

  /// Whether device PIN/pattern/password fallback is allowed.
  final bool allowDeviceCredential;

  /// Whether explicit confirmation is requested.
  final bool confirmationRequired;

  /// Whether generated keys should invalidate when enrollment changes.
  final bool invalidateKeysOnEnrollment;

  /// Converts this object to a platform-channel map.
  Map<String, Object?> toMap() => <String, Object?>{
        'strength': strength.name,
        'allowDeviceCredential': allowDeviceCredential,
        'confirmationRequired': confirmationRequired,
        'invalidateKeysOnEnrollment': invalidateKeysOnEnrollment,
      };
}

/// Android native UI/system customization.
class AndroidSystemOptions {
  /// Creates Android system customization options.
  const AndroidSystemOptions({
    this.keepScreenOn = false,
    this.orientationLock = NativeOrientationLock.system,
    this.pictureInPictureAspectRatio,
    this.openExactSettingsPages = true,
  });

  /// Creates options from a serialized map.
  factory AndroidSystemOptions.fromMap(Map<dynamic, dynamic> map) {
    return AndroidSystemOptions(
      keepScreenOn: map['keepScreenOn'] as bool? ?? false,
      orientationLock: _enumValue(
        NativeOrientationLock.values,
        map['orientationLock'],
        NativeOrientationLock.system,
      ),
      pictureInPictureAspectRatio:
          map['pictureInPictureAspectRatio'] as String?,
      openExactSettingsPages: map['openExactSettingsPages'] as bool? ?? true,
    );
  }

  /// Whether native code should keep the screen awake.
  final bool keepScreenOn;

  /// Preferred native orientation lock.
  final NativeOrientationLock orientationLock;

  /// Optional PiP aspect ratio, for example `16:9`.
  final String? pictureInPictureAspectRatio;

  /// Whether helpers should open exact settings pages where possible.
  final bool openExactSettingsPages;

  /// Converts this object to a platform-channel map.
  Map<String, Object?> toMap() => <String, Object?>{
        'keepScreenOn': keepScreenOn,
        'orientationLock': orientationLock.name,
        'pictureInPictureAspectRatio': pictureInPictureAspectRatio,
        'openExactSettingsPages': openExactSettingsPages,
      };
}

/// Android-specific native customization.
class AndroidNativeOptions {
  /// Creates Android native customization options.
  const AndroidNativeOptions({
    this.camera = const AndroidCameraOptions(),
    this.audio = const AndroidAudioOptions(),
    this.bluetooth = const AndroidBluetoothOptions(),
    this.location = const AndroidLocationOptions(),
    this.sensors = const AndroidSensorOptions(),
    this.biometrics = const AndroidBiometricOptions(),
    this.system = const AndroidSystemOptions(),
    this.extras = const <String, Object>{},
  });

  /// Creates options from a serialized map.
  factory AndroidNativeOptions.fromMap(Map<dynamic, dynamic> map) {
    return AndroidNativeOptions(
      camera: AndroidCameraOptions.fromMap(
        map['camera'] as Map<dynamic, dynamic>? ?? const <String, Object>{},
      ),
      audio: AndroidAudioOptions.fromMap(
        map['audio'] as Map<dynamic, dynamic>? ?? const <String, Object>{},
      ),
      bluetooth: AndroidBluetoothOptions.fromMap(
        map['bluetooth'] as Map<dynamic, dynamic>? ?? const <String, Object>{},
      ),
      location: AndroidLocationOptions.fromMap(
        map['location'] as Map<dynamic, dynamic>? ?? const <String, Object>{},
      ),
      sensors: AndroidSensorOptions.fromMap(
        map['sensors'] as Map<dynamic, dynamic>? ?? const <String, Object>{},
      ),
      biometrics: AndroidBiometricOptions.fromMap(
        map['biometrics'] as Map<dynamic, dynamic>? ?? const <String, Object>{},
      ),
      system: AndroidSystemOptions.fromMap(
        map['system'] as Map<dynamic, dynamic>? ?? const <String, Object>{},
      ),
      extras: _objectMap(map['extras']),
    );
  }

  /// Android camera options.
  final AndroidCameraOptions camera;

  /// Android audio options.
  final AndroidAudioOptions audio;

  /// Android BLE options.
  final AndroidBluetoothOptions bluetooth;

  /// Android location options.
  final AndroidLocationOptions location;

  /// Android sensor options.
  final AndroidSensorOptions sensors;

  /// Android biometric options.
  final AndroidBiometricOptions biometrics;

  /// Android system options.
  final AndroidSystemOptions system;

  /// Escape hatch for app-specific native extensions.
  final Map<String, Object> extras;

  /// Converts this object to a platform-channel map.
  Map<String, Object?> toMap() => <String, Object?>{
        'camera': camera.toMap(),
        'audio': audio.toMap(),
        'bluetooth': bluetooth.toMap(),
        'location': location.toMap(),
        'sensors': sensors.toMap(),
        'biometrics': biometrics.toMap(),
        'system': system.toMap(),
        'extras': extras,
      };
}

/// Advanced iOS camera customization.
class IosCameraOptions {
  /// Creates iOS camera customization options.
  const IosCameraOptions({
    this.lens = NativeCameraLens.defaultLens,
    this.fps = NativeCameraFps.platformDefault,
    this.sessionPreset = IosCameraSessionPreset.high,
    this.enableVideoStabilization = true,
    this.imageFormat = NativeImageFormat.heic,
    this.videoCodec = NativeVideoCodec.hevc,
    this.videoBitrate,
    this.visionPerformanceMode = NativeVisionPerformanceMode.balanced,
    this.manualControls = const <String, Object>{},
  });

  /// Creates options from a serialized map.
  factory IosCameraOptions.fromMap(Map<dynamic, dynamic> map) {
    return IosCameraOptions(
      lens: _enumValue(
        NativeCameraLens.values,
        map['lens'],
        NativeCameraLens.defaultLens,
      ),
      fps: _enumValue(
        NativeCameraFps.values,
        map['fps'],
        NativeCameraFps.platformDefault,
      ),
      sessionPreset: _enumValue(
        IosCameraSessionPreset.values,
        map['sessionPreset'],
        IosCameraSessionPreset.high,
      ),
      enableVideoStabilization:
          map['enableVideoStabilization'] as bool? ?? true,
      imageFormat: _enumValue(
        NativeImageFormat.values,
        map['imageFormat'],
        NativeImageFormat.heic,
      ),
      videoCodec: _enumValue(
        NativeVideoCodec.values,
        map['videoCodec'],
        NativeVideoCodec.hevc,
      ),
      videoBitrate: (map['videoBitrate'] as num?)?.toInt(),
      visionPerformanceMode: _enumValue(
        NativeVisionPerformanceMode.values,
        map['visionPerformanceMode'],
        NativeVisionPerformanceMode.balanced,
      ),
      manualControls: _objectMap(map['manualControls']),
    );
  }

  /// Preferred lens.
  final NativeCameraLens lens;

  /// Preferred frame rate.
  final NativeCameraFps fps;

  /// Preferred AVFoundation session preset.
  final IosCameraSessionPreset sessionPreset;

  /// Whether stabilization should be requested.
  final bool enableVideoStabilization;

  /// Preferred image format.
  final NativeImageFormat imageFormat;

  /// Preferred video codec.
  final NativeVideoCodec videoCodec;

  /// Preferred video bitrate.
  final int? videoBitrate;

  /// Vision detector performance preference.
  final NativeVisionPerformanceMode visionPerformanceMode;

  /// Manual focus, exposure, ISO, shutter, and white-balance values.
  final Map<String, Object> manualControls;

  /// Converts this object to a platform-channel map.
  Map<String, Object?> toMap() => <String, Object?>{
        'lens': lens.name,
        'fps': fps.name,
        'sessionPreset': sessionPreset.name,
        'enableVideoStabilization': enableVideoStabilization,
        'imageFormat': imageFormat.name,
        'videoCodec': videoCodec.name,
        'videoBitrate': videoBitrate,
        'visionPerformanceMode': visionPerformanceMode.name,
        'manualControls': manualControls,
      };
}

/// Advanced iOS audio customization.
class IosAudioOptions {
  /// Creates iOS audio customization options.
  const IosAudioOptions({
    this.category = IosAudioSessionCategory.playAndRecord,
    this.mode = IosAudioSessionMode.defaultMode,
    this.allowBluetooth = true,
    this.allowAirPlay = true,
    this.mixWithOthers = false,
    this.defaultToSpeaker = true,
    this.preferredSampleRate,
    this.preferredBufferDuration,
  });

  /// Creates options from a serialized map.
  factory IosAudioOptions.fromMap(Map<dynamic, dynamic> map) {
    return IosAudioOptions(
      category: _enumValue(
        IosAudioSessionCategory.values,
        map['category'],
        IosAudioSessionCategory.playAndRecord,
      ),
      mode: _enumValue(
        IosAudioSessionMode.values,
        map['mode'],
        IosAudioSessionMode.defaultMode,
      ),
      allowBluetooth: map['allowBluetooth'] as bool? ?? true,
      allowAirPlay: map['allowAirPlay'] as bool? ?? true,
      mixWithOthers: map['mixWithOthers'] as bool? ?? false,
      defaultToSpeaker: map['defaultToSpeaker'] as bool? ?? true,
      preferredSampleRate: (map['preferredSampleRate'] as num?)?.toDouble(),
      preferredBufferDuration:
          (map['preferredBufferDuration'] as num?)?.toDouble(),
    );
  }

  /// Audio session category.
  final IosAudioSessionCategory category;

  /// Audio session mode.
  final IosAudioSessionMode mode;

  /// Whether Bluetooth routing is allowed.
  final bool allowBluetooth;

  /// Whether AirPlay routing is allowed.
  final bool allowAirPlay;

  /// Whether mixing with other app audio is allowed.
  final bool mixWithOthers;

  /// Whether play-and-record should default output to speaker.
  final bool defaultToSpeaker;

  /// Preferred sample rate.
  final double? preferredSampleRate;

  /// Preferred IO buffer duration.
  final double? preferredBufferDuration;

  /// Converts this object to a platform-channel map.
  Map<String, Object?> toMap() => <String, Object?>{
        'category': category.name,
        'mode': mode.name,
        'allowBluetooth': allowBluetooth,
        'allowAirPlay': allowAirPlay,
        'mixWithOthers': mixWithOthers,
        'defaultToSpeaker': defaultToSpeaker,
        'preferredSampleRate': preferredSampleRate,
        'preferredBufferDuration': preferredBufferDuration,
      };
}

/// Advanced iOS BLE customization.
class IosBluetoothOptions {
  /// Creates iOS BLE customization options.
  const IosBluetoothOptions({
    this.restoreIdentifier,
    this.scanTimeoutMs,
    this.allowDuplicates = false,
    this.autoReconnect = true,
    this.filters = const <String, Object>{},
  });

  /// Creates options from a serialized map.
  factory IosBluetoothOptions.fromMap(Map<dynamic, dynamic> map) {
    return IosBluetoothOptions(
      restoreIdentifier: map['restoreIdentifier'] as String?,
      scanTimeoutMs: (map['scanTimeoutMs'] as num?)?.toInt(),
      allowDuplicates: map['allowDuplicates'] as bool? ?? false,
      autoReconnect: map['autoReconnect'] as bool? ?? true,
      filters: _objectMap(map['filters']),
    );
  }

  /// CoreBluetooth restore identifier.
  final String? restoreIdentifier;

  /// Optional scan timeout.
  final int? scanTimeoutMs;

  /// Whether duplicate advertisements should be delivered.
  final bool allowDuplicates;

  /// Whether connection helpers should reconnect when possible.
  final bool autoReconnect;

  /// Service and device filters.
  final Map<String, Object> filters;

  /// Converts this object to a platform-channel map.
  Map<String, Object?> toMap() => <String, Object?>{
        'restoreIdentifier': restoreIdentifier,
        'scanTimeoutMs': scanTimeoutMs,
        'allowDuplicates': allowDuplicates,
        'autoReconnect': autoReconnect,
        'filters': filters,
      };
}

/// Advanced iOS location customization.
class IosLocationOptions {
  /// Creates iOS location customization options.
  const IosLocationOptions({
    this.allowsBackgroundLocationUpdates = false,
    this.showsBackgroundLocationIndicator = false,
    this.pausesLocationUpdatesAutomatically = true,
    this.enableSignificantLocationChanges = false,
    this.enableVisitMonitoring = false,
    this.activityType = 'other',
    this.geofenceNotifyOnEntry = true,
    this.geofenceNotifyOnExit = true,
  });

  /// Creates options from a serialized map.
  factory IosLocationOptions.fromMap(Map<dynamic, dynamic> map) {
    return IosLocationOptions(
      allowsBackgroundLocationUpdates:
          map['allowsBackgroundLocationUpdates'] as bool? ?? false,
      showsBackgroundLocationIndicator:
          map['showsBackgroundLocationIndicator'] as bool? ?? false,
      pausesLocationUpdatesAutomatically:
          map['pausesLocationUpdatesAutomatically'] as bool? ?? true,
      enableSignificantLocationChanges:
          map['enableSignificantLocationChanges'] as bool? ?? false,
      enableVisitMonitoring: map['enableVisitMonitoring'] as bool? ?? false,
      activityType: map['activityType'] as String? ?? 'other',
      geofenceNotifyOnEntry: map['geofenceNotifyOnEntry'] as bool? ?? true,
      geofenceNotifyOnExit: map['geofenceNotifyOnExit'] as bool? ?? true,
    );
  }

  /// Whether background updates should be allowed.
  final bool allowsBackgroundLocationUpdates;

  /// Whether the iOS background location indicator should be visible.
  final bool showsBackgroundLocationIndicator;

  /// Whether iOS can pause updates automatically.
  final bool pausesLocationUpdatesAutomatically;

  /// Whether significant-change monitoring should be used.
  final bool enableSignificantLocationChanges;

  /// Whether visit monitoring should be used.
  final bool enableVisitMonitoring;

  /// CoreLocation activity type string.
  final String activityType;

  /// Whether geofences notify on entry.
  final bool geofenceNotifyOnEntry;

  /// Whether geofences notify on exit.
  final bool geofenceNotifyOnExit;

  /// Converts this object to a platform-channel map.
  Map<String, Object?> toMap() => <String, Object?>{
        'allowsBackgroundLocationUpdates': allowsBackgroundLocationUpdates,
        'showsBackgroundLocationIndicator': showsBackgroundLocationIndicator,
        'pausesLocationUpdatesAutomatically':
            pausesLocationUpdatesAutomatically,
        'enableSignificantLocationChanges': enableSignificantLocationChanges,
        'enableVisitMonitoring': enableVisitMonitoring,
        'activityType': activityType,
        'geofenceNotifyOnEntry': geofenceNotifyOnEntry,
        'geofenceNotifyOnExit': geofenceNotifyOnExit,
      };
}

/// Advanced iOS sensor customization.
class IosSensorOptions {
  /// Creates iOS sensor customization options.
  const IosSensorOptions({
    this.sensorTypes = const <String>[
      'accelerometer',
      'gyroscope',
    ],
    this.updateIntervalSeconds,
    this.emitCalibration = false,
    this.useDeviceMotionFusion = true,
  });

  /// Creates options from a serialized map.
  factory IosSensorOptions.fromMap(Map<dynamic, dynamic> map) {
    return IosSensorOptions(
      sensorTypes: map.containsKey('sensorTypes')
          ? _stringList(map['sensorTypes'])
          : const <String>['accelerometer', 'gyroscope'],
      updateIntervalSeconds: (map['updateIntervalSeconds'] as num?)?.toDouble(),
      emitCalibration: map['emitCalibration'] as bool? ?? false,
      useDeviceMotionFusion: map['useDeviceMotionFusion'] as bool? ?? true,
    );
  }

  /// Sensor type names to subscribe to.
  final List<String> sensorTypes;

  /// CoreMotion update interval.
  final double? updateIntervalSeconds;

  /// Whether calibration status should be emitted.
  final bool emitCalibration;

  /// Whether CoreMotion device-motion fusion should be preferred.
  final bool useDeviceMotionFusion;

  /// Converts this object to a platform-channel map.
  Map<String, Object?> toMap() => <String, Object?>{
        'sensorTypes': sensorTypes,
        'updateIntervalSeconds': updateIntervalSeconds,
        'emitCalibration': emitCalibration,
        'useDeviceMotionFusion': useDeviceMotionFusion,
      };
}

/// Advanced iOS biometric customization.
class IosBiometricOptions {
  /// Creates iOS biometric customization options.
  const IosBiometricOptions({
    this.localizedFallbackTitle,
    this.localizedCancelTitle,
    this.allowDevicePasscode = true,
    this.invalidateKeysOnEnrollment = true,
  });

  /// Creates options from a serialized map.
  factory IosBiometricOptions.fromMap(Map<dynamic, dynamic> map) {
    return IosBiometricOptions(
      localizedFallbackTitle: map['localizedFallbackTitle'] as String?,
      localizedCancelTitle: map['localizedCancelTitle'] as String?,
      allowDevicePasscode: map['allowDevicePasscode'] as bool? ?? true,
      invalidateKeysOnEnrollment:
          map['invalidateKeysOnEnrollment'] as bool? ?? true,
    );
  }

  /// iOS fallback button title.
  final String? localizedFallbackTitle;

  /// iOS cancel button title.
  final String? localizedCancelTitle;

  /// Whether device passcode fallback is allowed.
  final bool allowDevicePasscode;

  /// Whether generated keys should invalidate when enrollment changes.
  final bool invalidateKeysOnEnrollment;

  /// Converts this object to a platform-channel map.
  Map<String, Object?> toMap() => <String, Object?>{
        'localizedFallbackTitle': localizedFallbackTitle,
        'localizedCancelTitle': localizedCancelTitle,
        'allowDevicePasscode': allowDevicePasscode,
        'invalidateKeysOnEnrollment': invalidateKeysOnEnrollment,
      };
}

/// iOS native UI/system customization.
class IosSystemOptions {
  /// Creates iOS system customization options.
  const IosSystemOptions({
    this.keepScreenOn = false,
    this.orientationLock = NativeOrientationLock.system,
    this.pictureInPictureAspectRatio,
    this.prefersHomeIndicatorAutoHidden = false,
  });

  /// Creates options from a serialized map.
  factory IosSystemOptions.fromMap(Map<dynamic, dynamic> map) {
    return IosSystemOptions(
      keepScreenOn: map['keepScreenOn'] as bool? ?? false,
      orientationLock: _enumValue(
        NativeOrientationLock.values,
        map['orientationLock'],
        NativeOrientationLock.system,
      ),
      pictureInPictureAspectRatio:
          map['pictureInPictureAspectRatio'] as String?,
      prefersHomeIndicatorAutoHidden:
          map['prefersHomeIndicatorAutoHidden'] as bool? ?? false,
    );
  }

  /// Whether native code should keep the screen awake.
  final bool keepScreenOn;

  /// Preferred native orientation lock.
  final NativeOrientationLock orientationLock;

  /// Optional PiP aspect ratio, for example `16:9`.
  final String? pictureInPictureAspectRatio;

  /// Whether home indicator auto-hide is preferred.
  final bool prefersHomeIndicatorAutoHidden;

  /// Converts this object to a platform-channel map.
  Map<String, Object?> toMap() => <String, Object?>{
        'keepScreenOn': keepScreenOn,
        'orientationLock': orientationLock.name,
        'pictureInPictureAspectRatio': pictureInPictureAspectRatio,
        'prefersHomeIndicatorAutoHidden': prefersHomeIndicatorAutoHidden,
      };
}

/// iOS-specific native customization.
class IosNativeOptions {
  /// Creates iOS native customization options.
  const IosNativeOptions({
    this.camera = const IosCameraOptions(),
    this.audio = const IosAudioOptions(),
    this.bluetooth = const IosBluetoothOptions(),
    this.location = const IosLocationOptions(),
    this.sensors = const IosSensorOptions(),
    this.biometrics = const IosBiometricOptions(),
    this.system = const IosSystemOptions(),
    this.extras = const <String, Object>{},
  });

  /// Creates options from a serialized map.
  factory IosNativeOptions.fromMap(Map<dynamic, dynamic> map) {
    return IosNativeOptions(
      camera: IosCameraOptions.fromMap(
        map['camera'] as Map<dynamic, dynamic>? ?? const <String, Object>{},
      ),
      audio: IosAudioOptions.fromMap(
        map['audio'] as Map<dynamic, dynamic>? ?? const <String, Object>{},
      ),
      bluetooth: IosBluetoothOptions.fromMap(
        map['bluetooth'] as Map<dynamic, dynamic>? ?? const <String, Object>{},
      ),
      location: IosLocationOptions.fromMap(
        map['location'] as Map<dynamic, dynamic>? ?? const <String, Object>{},
      ),
      sensors: IosSensorOptions.fromMap(
        map['sensors'] as Map<dynamic, dynamic>? ?? const <String, Object>{},
      ),
      biometrics: IosBiometricOptions.fromMap(
        map['biometrics'] as Map<dynamic, dynamic>? ?? const <String, Object>{},
      ),
      system: IosSystemOptions.fromMap(
        map['system'] as Map<dynamic, dynamic>? ?? const <String, Object>{},
      ),
      extras: _objectMap(map['extras']),
    );
  }

  /// iOS camera options.
  final IosCameraOptions camera;

  /// iOS audio options.
  final IosAudioOptions audio;

  /// iOS BLE options.
  final IosBluetoothOptions bluetooth;

  /// iOS location options.
  final IosLocationOptions location;

  /// iOS sensor options.
  final IosSensorOptions sensors;

  /// iOS biometric options.
  final IosBiometricOptions biometrics;

  /// iOS system options.
  final IosSystemOptions system;

  /// Escape hatch for app-specific native extensions.
  final Map<String, Object> extras;

  /// Converts this object to a platform-channel map.
  Map<String, Object?> toMap() => <String, Object?>{
        'camera': camera.toMap(),
        'audio': audio.toMap(),
        'bluetooth': bluetooth.toMap(),
        'location': location.toMap(),
        'sensors': sensors.toMap(),
        'biometrics': biometrics.toMap(),
        'system': system.toMap(),
        'extras': extras,
      };
}

/// Global SDK configuration shared by Dart and native platform code.
///
/// Use this once during app startup to tune native behavior without passing the
/// same options into every module call.
class NexoraSdkConfig {
  /// Creates an SDK configuration with production-friendly defaults.
  const NexoraSdkConfig({
    this.autoRequestPermissions = true,
    this.logNativeCalls = false,
    this.unsupportedFeaturePolicy = UnsupportedFeaturePolicy.throwException,
    this.camera = const CameraOptions(),
    this.audio = const AudioOptions(),
    this.bluetooth = const BluetoothScanOptions(),
    this.location = const LocationOptions(),
    this.sensors = const SensorOptions(),
    this.haptics = const HapticOptions(),
    this.android = const AndroidNativeOptions(),
    this.ios = const IosNativeOptions(),
    this.nativeFlags = const <String, Object>{},
  });

  /// Beginner-friendly defaults that request permissions automatically.
  static const beginner = NexoraSdkConfig();

  /// Quieter defaults for apps that request permissions with their own flow.
  static const advanced = NexoraSdkConfig(autoRequestPermissions: false);

  /// Whether module helpers should request permissions before native calls.
  final bool autoRequestPermissions;

  /// Whether native implementations should emit lightweight diagnostic logs.
  final bool logNativeCalls;

  /// The fallback strategy for unsupported platform features.
  final UnsupportedFeaturePolicy unsupportedFeaturePolicy;

  /// Default camera options used by configured startup helpers.
  final CameraOptions camera;

  /// Default audio options used by configured startup helpers.
  final AudioOptions audio;

  /// Default BLE scan options.
  final BluetoothScanOptions bluetooth;

  /// Default location options.
  final LocationOptions location;

  /// Default sensor options.
  final SensorOptions sensors;

  /// Default haptic options.
  final HapticOptions haptics;

  /// Android-specific native customization.
  final AndroidNativeOptions android;

  /// iOS-specific native customization.
  final IosNativeOptions ios;

  /// Platform-specific feature switches forwarded to native code.
  ///
  /// Example keys might include `androidForegroundServiceChannelId`,
  /// `iosShowsBackgroundLocationIndicator`, or your own native extension flags.
  final Map<String, Object> nativeFlags;

  /// Converts this configuration to a platform-channel friendly map.
  Map<String, Object?> toMap() => <String, Object?>{
        'autoRequestPermissions': autoRequestPermissions,
        'logNativeCalls': logNativeCalls,
        'unsupportedFeaturePolicy': unsupportedFeaturePolicy.name,
        'camera': camera.toMap(),
        'audio': audio.toMap(),
        'bluetooth': bluetooth.toMap(),
        'location': location.toMap(),
        'sensors': sensors.toMap(),
        'haptics': haptics.toMap(),
        'android': android.toMap(),
        'ios': ios.toMap(),
        'nativeFlags': nativeFlags,
      };

  /// Creates a configuration from a map.
  factory NexoraSdkConfig.fromMap(Map<dynamic, dynamic> map) {
    final policyName = map['unsupportedFeaturePolicy'] as String?;
    return NexoraSdkConfig(
      autoRequestPermissions: map['autoRequestPermissions'] as bool? ?? true,
      logNativeCalls: map['logNativeCalls'] as bool? ?? false,
      unsupportedFeaturePolicy: UnsupportedFeaturePolicy.values.firstWhere(
        (policy) => policy.name == policyName,
        orElse: () => UnsupportedFeaturePolicy.throwException,
      ),
      camera: CameraOptions.fromMap(
        map['camera'] as Map<dynamic, dynamic>? ?? const <String, Object>{},
      ),
      audio: AudioOptions.fromMap(
        map['audio'] as Map<dynamic, dynamic>? ?? const <String, Object>{},
      ),
      bluetooth: BluetoothScanOptions.fromMap(
        map['bluetooth'] as Map<dynamic, dynamic>? ?? const <String, Object>{},
      ),
      location: LocationOptions.fromMap(
        map['location'] as Map<dynamic, dynamic>? ?? const <String, Object>{},
      ),
      sensors: SensorOptions.fromMap(
        map['sensors'] as Map<dynamic, dynamic>? ?? const <String, Object>{},
      ),
      haptics: HapticOptions.fromMap(
        map['haptics'] as Map<dynamic, dynamic>? ?? const <String, Object>{},
      ),
      android: AndroidNativeOptions.fromMap(
        map['android'] as Map<dynamic, dynamic>? ?? const <String, Object>{},
      ),
      ios: IosNativeOptions.fromMap(
        map['ios'] as Map<dynamic, dynamic>? ?? const <String, Object>{},
      ),
      nativeFlags: Map<String, Object>.from(
        map['nativeFlags'] as Map? ?? const <String, Object>{},
      ),
    );
  }

  /// Returns a copy with selected values changed.
  NexoraSdkConfig copyWith({
    bool? autoRequestPermissions,
    bool? logNativeCalls,
    UnsupportedFeaturePolicy? unsupportedFeaturePolicy,
    CameraOptions? camera,
    AudioOptions? audio,
    BluetoothScanOptions? bluetooth,
    LocationOptions? location,
    SensorOptions? sensors,
    HapticOptions? haptics,
    AndroidNativeOptions? android,
    IosNativeOptions? ios,
    Map<String, Object>? nativeFlags,
  }) {
    return NexoraSdkConfig(
      autoRequestPermissions:
          autoRequestPermissions ?? this.autoRequestPermissions,
      logNativeCalls: logNativeCalls ?? this.logNativeCalls,
      unsupportedFeaturePolicy:
          unsupportedFeaturePolicy ?? this.unsupportedFeaturePolicy,
      camera: camera ?? this.camera,
      audio: audio ?? this.audio,
      bluetooth: bluetooth ?? this.bluetooth,
      location: location ?? this.location,
      sensors: sensors ?? this.sensors,
      haptics: haptics ?? this.haptics,
      android: android ?? this.android,
      ios: ios ?? this.ios,
      nativeFlags: nativeFlags ?? this.nativeFlags,
    );
  }

  @override
  String toString() {
    return 'NexoraSdkConfig(autoRequestPermissions: $autoRequestPermissions, '
        'logNativeCalls: $logNativeCalls, policy: $unsupportedFeaturePolicy)';
  }
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

  /// Creates camera options from a serialized map.
  factory CameraOptions.fromMap(Map<dynamic, dynamic> map) {
    final resolution = map['resolution'] as String?;
    final focusMode = map['focusMode'] as String?;
    final exposureMode = map['exposureMode'] as String?;
    return CameraOptions(
      resolution: CameraQuality.values.firstWhere(
        (value) => value.name == resolution,
        orElse: () => CameraQuality.hd,
      ),
      focusMode: CameraFocusMode.values.firstWhere(
        (value) => value.name == focusMode,
        orElse: () => CameraFocusMode.continuous,
      ),
      exposureMode: CameraExposureMode.values.firstWhere(
        (value) => value.name == exposureMode,
        orElse: () => CameraExposureMode.auto,
      ),
      exposureCompensation:
          (map['exposureCompensation'] as num?)?.toDouble() ?? 0.0,
      mirrorFrontCamera: map['mirrorFrontCamera'] as bool? ?? true,
    );
  }

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

  /// Creates audio options from a serialized map.
  factory AudioOptions.fromMap(Map<dynamic, dynamic> map) {
    final channels = map['channels'] as String?;
    return AudioOptions(
      sampleRate: (map['sampleRate'] as num?)?.toInt() ?? 44100,
      channels: AudioChannelFormat.values.firstWhere(
        (value) => value.name == channels,
        orElse: () => AudioChannelFormat.mono,
      ),
      enableEchoCancellation: map['enableEchoCancellation'] as bool? ?? true,
      enableNoiseSuppression: map['enableNoiseSuppression'] as bool? ?? true,
    );
  }

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

  /// Creates sensor options from a serialized map.
  factory SensorOptions.fromMap(Map<dynamic, dynamic> map) {
    final accuracy = map['accuracy'] as String?;
    return SensorOptions(
      accuracy: SensorAccuracy.values.firstWhere(
        (value) => value.name == accuracy,
        orElse: () => SensorAccuracy.normal,
      ),
      enableLowPassFilter: map['enableLowPassFilter'] as bool? ?? false,
      lowPassAlpha: (map['lowPassAlpha'] as num?)?.toDouble() ?? 0.15,
    );
  }

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

  /// Creates Bluetooth scan options from a serialized map.
  factory BluetoothScanOptions.fromMap(Map<dynamic, dynamic> map) {
    final scanMode = map['scanMode'] as String?;
    return BluetoothScanOptions(
      scanMode: BluetoothScanMode.values.firstWhere(
        (value) => value.name == scanMode,
        orElse: () => BluetoothScanMode.balanced,
      ),
      serviceUuids:
          (map['serviceUuids'] as List?)?.cast<String>() ?? const <String>[],
      allowDuplicates: map['allowDuplicates'] as bool? ?? false,
    );
  }

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

  /// Creates location options from a serialized map.
  factory LocationOptions.fromMap(Map<dynamic, dynamic> map) {
    final accuracy = map['accuracy'] as String?;
    return LocationOptions(
      accuracy: LocationAccuracy.values.firstWhere(
        (value) => value.name == accuracy,
        orElse: () => LocationAccuracy.highAccuracy,
      ),
      distanceFilterMeters:
          (map['distanceFilterMeters'] as num?)?.toDouble() ?? 0.0,
      enableBackgroundUpdates: map['enableBackgroundUpdates'] as bool? ?? false,
      showsBackgroundLocationIndicator:
          map['showsBackgroundLocationIndicator'] as bool? ?? false,
    );
  }

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

  /// Creates haptic options from a serialized map.
  factory HapticOptions.fromMap(Map<dynamic, dynamic> map) {
    final type = map['type'] as String?;
    return HapticOptions(
      type: HapticFeedbackType.values.firstWhere(
        (value) => value.name == type,
        orElse: () => HapticFeedbackType.medium,
      ),
      intensityPercent: (map['intensityPercent'] as num?)?.toInt() ?? 100,
      durationMs: (map['durationMs'] as num?)?.toInt() ?? 50,
    );
  }

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

/// Data class representing a connected USB device.
class UsbDevice {
  /// The unique device identifier (e.g. device path or ID).
  final String deviceId;

  /// The product name or description.
  final String name;

  /// The manufacturer string.
  final String manufacturer;

  /// Creates a [UsbDevice].
  UsbDevice({
    required this.deviceId,
    required this.name,
    required this.manufacturer,
  });

  /// Creates a [UsbDevice] from a Map.
  factory UsbDevice.fromMap(Map<String, dynamic> map) {
    return UsbDevice(
      deviceId: map['deviceId'] as String? ?? '',
      name: map['name'] as String? ?? 'Unknown',
      manufacturer: map['manufacturer'] as String? ?? 'Unknown',
    );
  }

  /// Converts this [UsbDevice] to a Map.
  Map<String, dynamic> toMap() => {
        'deviceId': deviceId,
        'name': name,
        'manufacturer': manufacturer,
      };
}

/// Data class representing the result of an AI inference.
class AiInferenceResult {
  /// The raw tensor outputs mapped by their output names.
  final Map<String, dynamic> outputs;

  /// The execution time in milliseconds.
  final int executionTimeMs;

  /// Creates an [AiInferenceResult].
  AiInferenceResult({required this.outputs, required this.executionTimeMs});

  /// Creates an [AiInferenceResult] from a Map.
  factory AiInferenceResult.fromMap(Map<String, dynamic> map) {
    return AiInferenceResult(
      outputs: Map<String, dynamic>.from(map['outputs'] as Map? ?? {}),
      executionTimeMs: map['executionTimeMs'] as int? ?? 0,
    );
  }
}

/// Options for Depth Camera capturing.
class DepthOptions {
  /// Whether to return raw point cloud data.
  final bool enablePointCloud;

  /// Whether to return a depth map (distance matrix).
  final bool enableDepthMap;

  /// Creates [DepthOptions].
  DepthOptions({this.enablePointCloud = true, this.enableDepthMap = false});

  /// Converts to Map.
  Map<String, dynamic> toMap() => {
        'enablePointCloud': enablePointCloud,
        'enableDepthMap': enableDepthMap,
      };
}
