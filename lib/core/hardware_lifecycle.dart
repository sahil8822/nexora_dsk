import 'package:flutter/widgets.dart';

import '../nexora_sdk.dart';

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
  final bool autoStopOnPause;
  final bool stopCamera;
  final bool stopAudio;
  final bool stopBluetoothScan;
  final bool stopLocation;
  final bool stopSensors;
  final bool stopLogging;

  bool _isStarted = false;
  HardwareShutdownResult? _lastShutdownResult;

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
    }
  }

  Future<void> _stopSelectedHardware() async {
    _lastShutdownResult = await _sdk.stopAll(
      camera: stopCamera,
      audio: stopAudio,
      bluetoothScan: stopBluetoothScan,
      location: stopLocation,
      sensors: stopSensors,
      logging: stopLogging,
    );
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
