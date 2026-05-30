// ignore_for_file: avoid_catches_without_on_clauses, avoid_web_libraries_in_flutter
import 'dart:async';
import 'dart:ui_web' as ui_web;
import 'dart:convert';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'dart:typed_data';

import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:nexora_sdk_platform_interface/core/hardware_core.dart';
import 'package:nexora_sdk_platform_interface/models/device_models.dart';
import 'package:nexora_sdk_platform_interface/models/hardware_exception.dart';
import 'package:nexora_sdk_platform_interface/models/hardware_models.dart';
import 'package:nexora_sdk_platform_interface/models/permission_models.dart';
import 'package:nexora_sdk_platform_interface/nexora_sdk_platform_interface.dart';
import 'package:web/web.dart' as web;

/// Web implementation for browsers.
class NexoraSdkWeb extends NexoraSdkPlatform {
  final StreamController<HardwareEvent> _eventController =
      StreamController<HardwareEvent>.broadcast();

  int? _watchId;
  web.MediaStream? _cameraStream;
  web.HTMLVideoElement? _cameraVideoElement;
  int? _cameraViewId;
  web.MediaStream? _audioStream;
  web.AudioContext? _audioContext;
  web.AnalyserNode? _audioAnalyser;
  Timer? _audioTimer;
  web.ScriptProcessorNode? _audioScriptNode;

  /// API Documentation for registerWith.
  static void registerWith(Registrar registrar) {
    NexoraSdkPlatform.instance = NexoraSdkWeb();
  }

  @override
  Stream<HardwareEvent> get unifiedStream => _eventController.stream;

  @override
  Future<String?> getPlatformVersion() async {
    return 'Web';
  }

  @override
  Future<bool> requestCameraPermission() async {
    try {
      final nav = web.window.navigator;
      final mediaDevices = nav.mediaDevices;
      final constraints = {'video': true}.jsify()! as web.MediaStreamConstraints;
      final promise = mediaDevices.getUserMedia(constraints);
      final stream = (await promise.toDart)! as web.MediaStream;
      final tracks = stream.getVideoTracks().toDart;
      for (var i = 0; i < tracks.length; i++) {
        final track = tracks[i] as web.MediaStreamTrack;
        track.stop();
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> requestAudioPermission() async {
    try {
      final nav = web.window.navigator;
      final mediaDevices = nav.mediaDevices;
      final constraints = {'audio': true}.jsify()! as web.MediaStreamConstraints;
      final promise = mediaDevices.getUserMedia(constraints);
      final stream = (await promise.toDart)! as web.MediaStream;
      final tracks = stream.getAudioTracks().toDart;
      for (var i = 0; i < tracks.length; i++) {
        final track = tracks[i] as web.MediaStreamTrack;
        track.stop();
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> requestLocationPermission() async {
    try {
      final nav = web.window.navigator;
      if (!nav.hasProperty('geolocation'.toJS).toDart) {
        return false;
      }
      final geolocation = nav.getProperty('geolocation'.toJS)! as JSObject;
      final completer = Completer<bool>();
      
      final successCallback = ((JSObject position) {
        if (!completer.isCompleted) completer.complete(true);
      }).toJS;

      final errorCallback = ((JSObject error) {
        if (!completer.isCompleted) completer.complete(false);
      }).toJS;

      geolocation.callMethod(
        'getCurrentPosition'.toJS,
        successCallback,
        errorCallback,
      );
      return completer.future;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> requestBluetoothPermission() async {
    final nav = web.window.navigator;
    return nav.hasProperty('bluetooth'.toJS).toDart;
  }

  @override
  Future<bool> requestPermissions() async {
    final camera = await requestCameraPermission();
    final audio = await requestAudioPermission();
    final location = await requestLocationPermission();
    return camera && audio && location;
  }

  @override
  Future<HardwarePermissionStatus> getPermissionStatus(
    HardwarePermission permission,
  ) async {
    final name = _mapPermissionToWebName(permission);
    if (name == null) {
      return HardwarePermissionStatus(
        permission: permission,
        state: HardwarePermissionState.unsupported,
        canRequest: false,
      );
    }

    try {
      final nav = web.window.navigator;
      if (!nav.hasProperty('permissions'.toJS).toDart) {
        return HardwarePermissionStatus(
          permission: permission,
          state: HardwarePermissionState.unsupported,
          canRequest: false,
        );
      }
      final permissions = nav.getProperty('permissions'.toJS)! as JSObject;
      final descriptor = JSObject();
      descriptor.setProperty('name'.toJS, name.toJS);

      final promise = permissions.callMethod<JSPromise>('query'.toJS, descriptor);
      final status = (await promise.toDart)! as JSObject;
      final stateStr = (status.getProperty('state'.toJS)! as JSString).toDart;

      HardwarePermissionState state;
      if (stateStr == 'granted') {
        state = HardwarePermissionState.granted;
      } else if (stateStr == 'denied') {
        state = HardwarePermissionState.denied;
      } else {
        state = HardwarePermissionState.notDetermined;
      }

      return HardwarePermissionStatus(
        permission: permission,
        state: state,
        canRequest: state != HardwarePermissionState.denied,
      );
    } catch (_) {
      return HardwarePermissionStatus(
        permission: permission,
        state: HardwarePermissionState.unsupported,
        canRequest: false,
      );
    }
  }

  String? _mapPermissionToWebName(HardwarePermission permission) {
    switch (permission) {
      case HardwarePermission.camera:
        return 'camera';
      case HardwarePermission.audio:
        return 'microphone';
      case HardwarePermission.location:
        return 'geolocation';
      case HardwarePermission.bluetooth:
        return 'bluetooth';
      default:
        return null;
    }
  }

  @override
  Future<bool> openAppSettings({dynamic options}) async {
    return false;
  }

  @override
  Future<DeviceInfo> getDeviceInfo() async {
    final nav = web.window.navigator;
    final ua = nav.userAgent.toLowerCase();

    var browser = 'unknown';
    if (ua.contains('chrome') && !ua.contains('edg')) {
      browser = 'chrome';
    } else if (ua.contains('safari') && !ua.contains('chrome')) {
      browser = 'safari';
    } else if (ua.contains('firefox')) {
      browser = 'firefox';
    } else if (ua.contains('edg')) {
      browser = 'edge';
    }

    var os = 'unknown';
    if (ua.contains('win')) {
      os = 'windows';
    } else if (ua.contains('mac')) {
      os = 'macos';
    } else if (ua.contains('linux')) {
      os = 'linux';
    } else if (ua.contains('android')) {
      os = 'android';
    } else if (ua.contains('like mac os x')) {
      os = 'ios';
    }

    return DeviceInfo(
      platform: 'web',
      manufacturer: browser,
      model: os,
      osVersion: nav.appVersion,
      sdkVersion: 'web',
      isPhysicalDevice: true,
      totalRamBytes: 0,
      availableRamBytes: 0,
      cpuArchitecture: 'unknown',
      screenRefreshRate: 0,
      thermalState: 'unknown',
    );
  }

  @override
  Future<ConnectivityInfo> getConnectivityInfo() async {
    final nav = web.window.navigator;
    final isConnected = nav.onLine;
    var networkType = 'browser';
    var isMetered = false;

    if (nav.hasProperty('connection'.toJS).toDart) {
      final conn = nav.getProperty('connection'.toJS)! as JSObject;
      if (conn.hasProperty('effectiveType'.toJS).toDart) {
        networkType =
            (conn.getProperty('effectiveType'.toJS)! as JSString).toDart;
      }
      if (conn.hasProperty('saveData'.toJS).toDart) {
        isMetered = (conn.getProperty('saveData'.toJS)! as JSBoolean).toDart;
      }
    }

    return ConnectivityInfo(
      isConnected: isConnected,
      networkType: networkType,
      isMetered: isMetered,
      isVpn: false,
      signalStrength: null,
      ipAddress: null,
    );
  }

  @override
  Future<int?> startCamera({int width = 1280, int height = 720}) async {
    try {
      final nav = web.window.navigator;
      final mediaDevices = nav.mediaDevices;

      final constraints = {
        'video': {
          'width': width,
          'height': height,
        }
      }.jsify()! as web.MediaStreamConstraints;

      final promise = mediaDevices.getUserMedia(constraints);
      final stream = (await promise.toDart)! as web.MediaStream;
      _cameraStream = stream;

      final viewId = DateTime.now().millisecondsSinceEpoch;
      _cameraViewId = viewId;
      final viewType = 'nexora_camera_preview_$viewId';

      ui_web.platformViewRegistry.registerViewFactory(viewType, (int viewId) {
        final video = web.HTMLVideoElement()
          ..autoplay = true
          ..playsInline = true
          ..muted = true
          ..style.width = '100%'
          ..style.height = '100%'
          ..style.objectFit = 'cover';
        video.srcObject = stream;
        _cameraVideoElement = video;
        return video;
      });

      return viewId;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<int?> startCameraWithOptions(CameraOptions options) async {
    final width = options.resolution.width;
    final height = options.resolution.height;
    return startCamera(width: width, height: height);
  }

  @override
  Future<bool> stopCamera() async {
    try {
      final stream = _cameraStream;
      if (stream != null) {
        final tracks = stream.getTracks().toDart;
        for (var i = 0; i < tracks.length; i++) {
          final track = tracks[i] as web.MediaStreamTrack;
          track.stop();
        }
        _cameraStream = null;
      }
      _cameraVideoElement = null;
      _cameraViewId = null;
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> setVisionMode({bool barcode = false, bool face = false}) async {
    throw HardwareException.unsupported('setVisionMode');
  }

  @override
  Future<bool> registerCustomClassifier({
    required String modelAssetPath,
    required List<String> labels,
    double threshold = 0.5,
  }) async {
    throw HardwareException.unsupported('registerCustomClassifier');
  }

  @override
  Future<bool> setFlash(bool on) async =>
      throw HardwareException.unsupported('setFlash');

  @override
  Future<bool> setZoom(double level) async =>
      throw HardwareException.unsupported('setZoom');

  @override
  Future<bool> flipCamera() async =>
      throw HardwareException.unsupported('flipCamera');

  @override
  Future<String?> takePhoto({String? fileName}) async {
    final video = _cameraVideoElement;
    if (video == null) return null;

    try {
      final width = video.videoWidth;
      final height = video.videoHeight;
      
      final canvas = web.HTMLCanvasElement()
        ..width = width
        ..height = height;
        
      final ctx = canvas.getContext('2d')! as web.CanvasRenderingContext2D;
      ctx.drawImage(video, 0, 0);
      
      final dataUrl = canvas.toDataURL('image/jpeg');
      return dataUrl;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<String?> startVideoRecording({String? fileName}) async =>
      throw HardwareException.unsupported('startVideoRecording');

  @override
  Future<String?> stopVideoRecording() async =>
      throw HardwareException.unsupported('stopVideoRecording');

  @override
  Future<bool> startAudio({
    bool enableFFT = false,
    bool streamBytes = false,
    int updateIntervalMs = 80,
  }) async {
    try {
      final nav = web.window.navigator;
      final mediaDevices = nav.mediaDevices;

      final constraints = {
        'audio': true,
      }.jsify()! as web.MediaStreamConstraints;

      final promise = mediaDevices.getUserMedia(constraints);
      final stream = (await promise.toDart)! as web.MediaStream;
      _audioStream = stream;

      final audioCtx = web.AudioContext();
      _audioContext = audioCtx;

      final source = audioCtx.createMediaStreamSource(stream);

      if (enableFFT) {
        final analyser = audioCtx.createAnalyser();
        analyser.fftSize = 256; // 128 frequency bins
        source.connect(analyser);
        _audioAnalyser = analyser;

        _audioTimer = Timer.periodic(Duration(milliseconds: updateIntervalMs), (timer) {
          final bufferLength = analyser.frequencyBinCount;
          final dataArray = Uint8List(bufferLength).toJS;
          analyser.getByteFrequencyData(dataArray);

          final list = dataArray.toDart;
          final spectrum = list.map((e) => e.toDouble()).toList();

          _eventController.add(
            HardwareEvent(
              module: 'audio',
              type: 'audio_frame',
              data: AudioFrame(
                spectrum: spectrum,
                sampleRate: audioCtx.sampleRate.toInt(),
                bytes: null,
              ).toMap(),
              timestamp: DateTime.now(),
            ),
          );
        });
      }

      if (streamBytes) {
        final scriptNode = audioCtx.createScriptProcessor(4096, 1, 1);
        source.connect(scriptNode);
        scriptNode.connect(audioCtx.destination);
        _audioScriptNode = scriptNode;

        scriptNode.onaudioprocess = ((web.AudioProcessingEvent event) {
          final inputBuffer = event.inputBuffer;
          final channelData = inputBuffer.getChannelData(0).toDart;
          final length = channelData.length;
          final pcmBytes = Uint8List(length * 2);
          final pcmData = ByteData.sublistView(pcmBytes);

          for (var i = 0; i < length; i++) {
            final sample = channelData[i];
            final clamped = sample < -1.0 ? -1.0 : (sample > 1.0 ? 1.0 : sample);
            final intSample = (clamped * 32767).toInt();
            pcmData.setInt16(i * 2, intSample, Endian.little);
          }

          _eventController.add(
            HardwareEvent(
              module: 'audio',
              type: 'audio_frame',
              data: AudioFrame(
                spectrum: [],
                sampleRate: audioCtx.sampleRate.toInt(),
                bytes: pcmBytes,
              ).toMap(),
              timestamp: DateTime.now(),
            ),
          );
        }).toJS;
      }

      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> startAudioWithOptions(AudioOptions options) async {
    try {
      final nav = web.window.navigator;
      final mediaDevices = nav.mediaDevices;

      final constraints = {
        'audio': {
          'sampleRate': options.sampleRate,
          'echoCancellation': options.enableEchoCancellation,
          'noiseSuppression': options.enableNoiseSuppression,
        }
      }.jsify()! as web.MediaStreamConstraints;

      final promise = mediaDevices.getUserMedia(constraints);
      final stream = (await promise.toDart)! as web.MediaStream;
      _audioStream = stream;

      final audioCtx = web.AudioContext();
      _audioContext = audioCtx;

      final source = audioCtx.createMediaStreamSource(stream);

      final analyser = audioCtx.createAnalyser();
      analyser.fftSize = 256;
      source.connect(analyser);
      _audioAnalyser = analyser;

      _audioTimer = Timer.periodic(const Duration(milliseconds: 80), (timer) {
        final bufferLength = analyser.frequencyBinCount;
        final dataArray = Uint8List(bufferLength).toJS;
        analyser.getByteFrequencyData(dataArray);

        final list = dataArray.toDart;
        final spectrum = list.map((e) => e.toDouble()).toList();

        _eventController.add(
          HardwareEvent(
            module: 'audio',
            type: 'audio_frame',
            data: AudioFrame(
              spectrum: spectrum,
              sampleRate: audioCtx.sampleRate.toInt(),
              bytes: null,
            ).toMap(),
            timestamp: DateTime.now(),
          ),
        );
      });

      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> stopAudio() async {
    try {
      _audioTimer?.cancel();
      _audioTimer = null;

      final scriptNode = _audioScriptNode;
      if (scriptNode != null) {
        scriptNode.disconnect();
        _audioScriptNode = null;
      }

      final stream = _audioStream;
      if (stream != null) {
        final tracks = stream.getTracks().toDart;
        for (var i = 0; i < tracks.length; i++) {
          final track = tracks[i] as web.MediaStreamTrack;
          track.stop();
        }
        _audioStream = null;
      }

      final ctx = _audioContext;
      if (ctx != null) {
        ctx.close();
        _audioContext = null;
      }

      _audioAnalyser = null;
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> routeAudioOutput(AudioOutputRoute route) async => true;

  @override
  Future<double> getAudioVolume() async => 0.5;

  @override
  Future<bool> setAudioVolume(double level) async => true;

  @override
  Future<bool> selectAudioInput(AudioInputDevice device) async => true;

  @override
  Future<bool> setAudioGain(double gain) async => true;

  @override
  Future<bool> startHardwareLogging(LogConfig config) async => false;

  @override
  Future<bool> stopHardwareLogging() async => true;

  @override
  Future<bool> addGeofence(
    String id,
    double lat,
    double lon,
    double radius,
  ) async {
    throw HardwareException.unsupported('addGeofence');
  }

  @override
  Future<bool> startBluetoothScan() async =>
      throw HardwareException.unsupported('startBluetoothScan');

  @override
  Future<bool> startBluetoothScanWithOptions(
    BluetoothScanOptions options,
  ) async =>
      throw HardwareException.unsupported('startBluetoothScanWithOptions');

  @override
  Future<bool> stopBluetoothScan() async => true;

  @override
  Future<bool> connectDevice(String id) async =>
      throw HardwareException.unsupported('connectDevice');

  @override
  Future<bool> disconnectDevice(String id) async =>
      throw HardwareException.unsupported('disconnectDevice');

  @override
  Future<List<String>> discoverServices(String deviceId) async =>
      throw HardwareException.unsupported('discoverServices');

  @override
  Future<bool> sendData(
    String deviceId,
    String serviceId,
    String charId,
    List<int> data,
  ) async {
    throw HardwareException.unsupported('sendData');
  }

  @override
  Future<Uint8List?> readData(
    String deviceId,
    String serviceId,
    String charId,
  ) async {
    throw HardwareException.unsupported('readData');
  }

  @override
  Future<bool> authenticate(String reason) async =>
      throw HardwareException.unsupported('authenticate');

  @override
  Future<bool> authenticateWithOptions(BiometricPromptOptions options) async =>
      throw HardwareException.unsupported('authenticateWithOptions');

  @override
  Future<bool> canAuthenticate() async =>
      throw HardwareException.unsupported('canAuthenticate');

  void _vibrateWeb(dynamic pattern) {
    try {
      final nav = web.window.navigator;
      if (nav.hasProperty('vibrate'.toJS).toDart) {
        if (pattern is int) {
          nav.callMethod('vibrate'.toJS, pattern.toJS);
        } else if (pattern is List<int>) {
          final jsArray = pattern.map((e) => e.toJS).toList().toJS;
          nav.callMethod('vibrate'.toJS, jsArray);
        }
      }
    } catch (_) {}
  }

  @override
  Future<void> vibrate(int durationMs) async {
    _vibrateWeb(durationMs);
  }

  @override
  Future<void> hapticFeedback(String type) async {
    switch (type.toLowerCase()) {
      case 'success':
        _vibrateWeb([10, 50, 10]);
        break;
      case 'warning':
        _vibrateWeb([15, 100, 15]);
        break;
      case 'error':
        _vibrateWeb([20, 120, 20, 100, 20]);
        break;
      case 'light':
        _vibrateWeb(10);
        break;
      case 'medium':
        _vibrateWeb(15);
        break;
      case 'heavy':
        _vibrateWeb(20);
        break;
      default:
        _vibrateWeb(10);
    }
  }

  @override
  Future<void> performHapticWithOptions(HapticOptions options) async {
    await hapticFeedback(options.type.name);
  }

  @override
  Future<BatteryInfo?> getBatteryInfo() async {
    try {
      final nav = web.window.navigator;
      if (!nav.hasProperty('getBattery'.toJS).toDart) {
        return null;
      }
      final promise = nav.callMethod<JSPromise>('getBattery'.toJS);
      final batteryManager = (await promise.toDart)! as JSObject;

      final levelJS = batteryManager.getProperty('level'.toJS)! as JSNumber;
      final chargingJS =
          batteryManager.getProperty('charging'.toJS)! as JSBoolean;

      return BatteryInfo(
        level: levelJS.toDartDouble,
        isCharging: chargingJS.toDart,
        status: chargingJS.toDart ? 'charging' : 'discharging',
        temperature: 0, // Unavailable on web
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Future<WifiInfo?> getWifiInfo() async => null;

  @override
  Future<bool> startLocation() async {
    try {
      final nav = web.window.navigator;
      if (!nav.hasProperty('geolocation'.toJS).toDart) {
        return false;
      }
      final geolocation = nav.getProperty('geolocation'.toJS)! as JSObject;

      await stopLocation();

      final successCallback = ((JSObject position) {
        final coords = position.getProperty('coords'.toJS)! as JSObject;
        final lat =
            (coords.getProperty('latitude'.toJS)! as JSNumber).toDartDouble;
        final lng =
            (coords.getProperty('longitude'.toJS)! as JSNumber).toDartDouble;
        final alt = ((coords.getProperty('altitude'.toJS)) as JSNumber?)
                ?.toDartDouble ??
            0.0;
        final acc =
            (coords.getProperty('accuracy'.toJS)! as JSNumber).toDartDouble;
        final spd =
            ((coords.getProperty('speed'.toJS)) as JSNumber?)?.toDartDouble ??
                0.0;

        _eventController.add(
          HardwareEvent(
            module: 'location',
            type: 'location_update',
            data: LocationData(
              latitude: lat,
              longitude: lng,
              altitude: alt,
              accuracy: acc,
              speed: spd,
            ).toMap(),
            timestamp: DateTime.now(),
          ),
        );
      }).toJS;

      final errorCallback = ((JSObject error) {
        _eventController.add(
          HardwareEvent(
            module: 'location',
            type: 'location_error',
            data: {'error': 'Failed to get position'},
            timestamp: DateTime.now(),
          ),
        );
      }).toJS;

      final watchIdJS = geolocation.callMethod<JSNumber>(
        'watchPosition'.toJS,
        successCallback,
        errorCallback,
      );
      _watchId = watchIdJS.toDartInt;
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> startLocationWithOptions(LocationOptions options) async {
    return startLocation();
  }

  @override
  Future<bool> stopLocation() async {
    if (_watchId != null) {
      try {
        final nav = web.window.navigator;
        final geolocation = nav.getProperty('geolocation'.toJS)! as JSObject;
        geolocation.callMethod('clearWatch'.toJS, _watchId!.toJS);
        _watchId = null;
      } catch (_) {}
    }
    return true;
  }

  @override
  Future<bool> setBackgroundLocationEnabled(bool enabled) async =>
      throw HardwareException.unsupported('setBackgroundLocationEnabled');

  @override
  Future<bool> startSensor({int frequencyHz = 60}) async =>
      throw HardwareException.unsupported('startSensor');

  @override
  Future<bool> startSensorWithOptions(SensorOptions options) async =>
      throw HardwareException.unsupported('startSensorWithOptions');

  @override
  Future<bool> stopSensor() async => true;

  @override
  Future<StorageInfo?> getStorageInfo() async {
    final size = _storageEntries().fold<int>(
      0,
      (total, entry) => total + entry.key.length + _valueSize(entry.value),
    );
    return StorageInfo(
      internalTotal: 0,
      internalFree: 0,
      externalTotal: 0,
      externalFree: 0,
      appCacheSize: 0,
      appDataSize: size,
    );
  }

  @override
  Future<String?> writeFile(String fileName, String content) async {
    web.window.localStorage.setItem(
      _key(fileName),
      jsonEncode({
        'type': 'text',
        'value': content,
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      }),
    );
    return fileName;
  }

  @override
  Future<String?> appendFile(String fileName, String content) async {
    final key = _key(fileName);
    final current = await readFile(fileName) ?? '';
    web.window.localStorage.setItem(
      key,
      jsonEncode({
        'type': 'text',
        'value': '$current$content',
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      }),
    );
    return fileName;
  }

  @override
  Future<String?> readFile(String fileName) async {
    final value = _decodeStoredValue(fileName);
    return value != null && value['type'] == 'text'
        ? value['value'] as String?
        : null;
  }

  @override
  Future<bool> deleteFile(String fileName) async {
    final key = _key(fileName);
    final existed = web.window.localStorage.getItem(key) != null;
    web.window.localStorage.removeItem(key);
    return existed;
  }

  @override
  Future<bool> fileExists(String fileName) async {
    return web.window.localStorage.getItem(_key(fileName)) != null;
  }

  @override
  Future<List<FileInfo>> listFiles() async {
    return _storageEntries().map((entry) {
      final decoded = _decodeRawValue(entry.value);
      return FileInfo(
        name: entry.key.substring(_storagePrefix.length),
        size: _valueSize(entry.value),
        isDirectory: false,
        lastModified: DateTime.fromMillisecondsSinceEpoch(
          decoded?['updatedAt'] as int? ?? 0,
        ),
      );
    }).toList();
  }

  @override
  Future<String?> writeBytes(String fileName, Uint8List bytes) async {
    web.window.localStorage.setItem(
      _key(fileName),
      jsonEncode({
        'type': 'bytes',
        'value': base64Encode(bytes),
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      }),
    );
    return fileName;
  }

  @override
  Future<Uint8List?> readBytes(String fileName) async {
    final value = _decodeStoredValue(fileName);
    if (value == null || value['type'] != 'bytes') return null;
    return base64Decode(value['value']! as String);
  }

  @override
  Future<bool> clearCache() async {
    final keys = _storageKeys().toList(growable: false);
    for (final key in keys) {
      web.window.localStorage.removeItem(key);
    }
    return true;
  }

  @override
  Future<String?> getAppDirectory() async => 'localStorage://nexora_sdk';

  @override
  Future<String?> getCacheDirectory() async => 'memory://nexora_sdk/cache';

  @override
  Future<String?> getExternalDirectory() async => null;

  @override
  Future<bool> copyText(String text) async {
    try {
      final clipboard = web.window.navigator.clipboard;
      await clipboard.writeText(text).toDart;
      return true;
    } catch (_) {
      try {
        final textArea = web.HTMLTextAreaElement()..value = text;
        textArea.style
          ..position = 'fixed'
          ..left = '-9999px';
        web.document.body?.appendChild(textArea);
        textArea.select();
        final success = web.document.execCommand('copy');
        textArea.remove();
        return success;
      } catch (_) {
        return false;
      }
    }
  }

  @override
  Future<String?> pasteText() async {
    try {
      final nav = web.window.navigator;
      if (!nav.hasProperty('clipboard'.toJS).toDart) return null;
      final clipboard = nav.getProperty('clipboard'.toJS)! as JSObject;
      final promise = clipboard.callMethod<JSPromise>('readText'.toJS);
      final textJs = (await promise.toDart)! as JSString;
      return textJs.toDart;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<bool> openUrl(String url) async {
    web.window.open(url, '_blank');
    return true;
  }

  @override
  Future<bool> shareText(String text, {String? subject}) => copyText(text);

  // ==================== WebUSB Support ====================

  @override
  Future<List<String>> getConnectedUsbDevices() async {
    try {
      final nav = web.window.navigator;
      // Check if WebUSB API is available
      if (!nav.hasProperty('usb'.toJS).toDart) {
        throw HardwareException.unsupported('getConnectedUsbDevices: WebUSB not available');
      }
      final usb = nav.getProperty('usb'.toJS)! as JSObject;
      final promise = usb.callMethod<JSPromise>('getDevices'.toJS);
      final result = (await promise.toDart)! as JSArray;
      final devices = result.toDart;
      final List<String> deviceNames = [];
      for (var i = 0; i < devices.length; i++) {
        final device = devices[i] as JSObject;
        final productName = (device.getProperty('productName'.toJS) as JSString?)?.toDart ?? '';
        final vendorId = (device.getProperty('vendorId'.toJS) as JSNumber?)?.toDartInt ?? 0;
        final productId = (device.getProperty('productId'.toJS) as JSNumber?)?.toDartInt ?? 0;
        deviceNames.add('$productName (VID:0x${vendorId.toRadixString(16).padLeft(4, '0')} PID:0x${productId.toRadixString(16).padLeft(4, '0')})');
      }
      return deviceNames;
    } catch (e) {
      if (e is HardwareException) rethrow;
      return [];
    }
  }

  // ==================== BLE Peripheral (Unsupported on Web) ====================

  @override
  Future<bool> startBlePeripheral(String uuid) async =>
      throw HardwareException.unsupported('startBlePeripheral');

  @override
  Future<void> stopBlePeripheral() async =>
      throw HardwareException.unsupported('stopBlePeripheral');

  @override
  Future<bool> enableSmartSync({
    required String uploadEndpointUrl,
    required Map<String, String> headers,
    int rollLimitBytes = 2 * 1024 * 1024,
    bool requireWifi = true,
  }) async =>
      throw HardwareException.unsupported('enableSmartSync');

  @override
  Future<bool> applyCameraFilterShader(String shaderType) async =>
      throw HardwareException.unsupported('applyCameraFilterShader');

  @override
  Stream<Uint8List> openL2capStream(String deviceId, int psm) =>
      throw HardwareException.unsupported('openL2capStream');

  @override
  Future<bool> enableDeadReckoning(bool enabled) async =>
      throw HardwareException.unsupported('enableDeadReckoning');

  @override
  Future<void> setEcoModeEnabled(bool enabled) async {
    throw HardwareException.unsupported('setEcoModeEnabled');
  }

  @override
  Future<bool> isEcoModeActive() async =>
      throw HardwareException.unsupported('isEcoModeActive');

  @override
  Future<DeviceThermalState> getThermalState() async =>
      throw HardwareException.unsupported('getThermalState');

  static const String _storagePrefix = 'nexora_sdk:file:';

  String _key(String fileName) => '$_storagePrefix$fileName';

  Map<String, Object?>? _decodeStoredValue(String fileName) {
    return _decodeRawValue(web.window.localStorage.getItem(_key(fileName)));
  }

  Map<String, Object?>? _decodeRawValue(String? value) {
    if (value == null) return null;
    try {
      final decoded = jsonDecode(value);
      return decoded is Map ? decoded.cast<String, Object?>() : null;
    } catch (_) {
      return null;
    }
  }

  int _valueSize(Object value) {
    if (value is String) return value.length;
    return 0;
  }

  Iterable<String> _storageKeys() sync* {
    final storage = web.window.localStorage;
    for (var index = 0; index < storage.length; index += 1) {
      final key = storage.key(index);
      if (key != null && key.startsWith(_storagePrefix)) {
        yield key;
      }
    }
  }

  Iterable<MapEntry<String, String>> _storageEntries() sync* {
    final storage = web.window.localStorage;
    for (final key in _storageKeys()) {
      final value = storage.getItem(key);
      if (value != null) {
        yield MapEntry<String, String>(key, value);
      }
    }
  }
}
