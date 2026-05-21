import 'package:flutter/widgets.dart';

import 'package:nexora_sdk/nexora_sdk.dart';
import 'package:nexora_sdk_platform_interface/models/hardware_capabilities.dart';

/// Controls automatic hardware cleanup during Flutter app lifecycle changes.
class HardwareLifecycleController with WidgetsBindingObserver {
  HardwareLifecycleController._({
    required NexoraSdk sdk,
    required this.autoStopOnPause,
    required this.stopCamera,
    required this.stopAudio,
    required this.stopBluetoothScan,
    required this.stopLocation,
    required this.stopSensors,
    required this.stopLogging,
  }) : _sdk = sdk;

  final NexoraSdk _sdk;

  /// API Documentation for autoStopOnPause;.
  final bool autoStopOnPause;

  /// API Documentation for stopCamera;.
  final bool stopCamera;

  /// API Documentation for stopAudio;.
  final bool stopAudio;

  /// API Documentation for stopBluetoothScan;.
  final bool stopBluetoothScan;

  /// API Documentation for stopLocation;.
  final bool stopLocation;

  /// API Documentation for stopSensors;.
  final bool stopSensors;

  /// API Documentation for stopLogging;.
  final bool stopLogging;

  bool _isStarted = false;
  HardwareShutdownResult? _lastShutdownResult;

  // Track operational states before teardown
  bool _wasCameraRunning = false;
  bool _wasAudioRunning = false;
  bool _wasLocationRunning = false;
  bool _wasSensorsRunning = false;

  // Cached module parameters for reconstruction
  bool _audioFFT = false;
  bool _audioStreamBytes = false;
  int _audioInterval = 80;
  int _sensorFrequency = 60;

  /// Last automatic shutdown result, if lifecycle cleanup has run.
  HardwareShutdownResult? get lastShutdownResult => _lastShutdownResult;

  /// Registers this controller with Flutter's binding.
  void start() {
    if (_isStarted) return;
    WidgetsBinding.instance.addObserver(this);
    _isStarted = true;
  }

  /// Removes this controller from Flutter's binding.
  void dispose() {
    if (!_isStarted) return;
    WidgetsBinding.instance.removeObserver(this);
    _isStarted = false;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!autoStopOnPause) return;
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {
      _stopSelectedHardware();
    } else if (state == AppLifecycleState.resumed) {
      _resumeSelectedHardware();
    }
  }

  Future<void> _stopSelectedHardware() async {
    // Capture state before shutting down
    _wasCameraRunning = _sdk.camera.isRunning;
    _wasAudioRunning = _sdk.audio.isRunning;
    _wasLocationRunning = _sdk.location.isRunning;
    _wasSensorsRunning = _sdk.sensors.isRunning;

    // Cache configurations
    _audioFFT = _sdk.audio.lastEnableFFT;
    _audioStreamBytes = _sdk.audio.lastStreamBytes;
    _audioInterval = _sdk.audio.lastUpdateIntervalMs;
    _sensorFrequency = _sdk.sensors.lastFrequencyHz;

    _lastShutdownResult = await _sdk.stopAll(
      camera: stopCamera,
      audio: stopAudio,
      bluetoothScan: stopBluetoothScan,
      location: stopLocation,
      sensors: stopSensors,
      logging: stopLogging,
    );
  }

  Future<void> _resumeSelectedHardware() async {
    if (stopCamera && _wasCameraRunning) {
      await _sdk.camera.start();
      _wasCameraRunning = false;
    }
    if (stopAudio && _wasAudioRunning) {
      await _sdk.audio.start(
        enableFFT: _audioFFT,
        streamBytes: _audioStreamBytes,
        updateIntervalMs: _audioInterval,
      );
      _wasAudioRunning = false;
    }
    if (stopLocation && _wasLocationRunning) {
      await _sdk.location.start();
      _wasLocationRunning = false;
    }
    if (stopSensors && _wasSensorsRunning) {
      await _sdk.sensors.start(frequencyHz: _sensorFrequency);
      _wasSensorsRunning = false;
    }
  }

  /// Creates and starts a lifecycle controller.
  static HardwareLifecycleController attach(
    NexoraSdk sdk, {
    bool autoStopOnPause = true,
    bool stopCamera = true,
    bool stopAudio = true,
    bool stopBluetoothScan = true,
    bool stopLocation = true,
    bool stopSensors = true,
    bool stopLogging = true,
  }) {
    final controller = HardwareLifecycleController._(
      sdk: sdk,
      autoStopOnPause: autoStopOnPause,
      stopCamera: stopCamera,
      stopAudio: stopAudio,
      stopBluetoothScan: stopBluetoothScan,
      stopLocation: stopLocation,
      stopSensors: stopSensors,
      stopLogging: stopLogging,
    )..start();
    return controller;
  }
}
