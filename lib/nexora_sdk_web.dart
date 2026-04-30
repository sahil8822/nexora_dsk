import 'dart:async';
// ignore: deprecated_member_use
import 'dart:html' as html;

import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'nexora_sdk_platform_interface.dart';
import 'models/hardware_models.dart';
import 'core/hardware_core.dart';

/// The Web implementation of the NexoraSdk platform.
class NexoraSdkWeb extends NexoraSdkPlatform {
  /// Factory method to register the web implementation.
  static void registerWith(Registrar registrar) {
    NexoraSdkPlatform.instance = NexoraSdkWeb();
  }

  final _eventStreamController = StreamController<HardwareEvent>.broadcast();
  final Map<String, StreamSubscription> _subscriptions = {};
  html.MediaStream? _cameraStream;

  @override
  Stream<HardwareEvent> get unifiedStream => _eventStreamController.stream;

  // --- Location Implementation ---
  @override
  Future<bool> startLocation() async {
    try {
      await _subscriptions['location']?.cancel();
      _subscriptions['location'] = html.window.navigator.geolocation
          .watchPosition(enableHighAccuracy: true)
          .listen((position) {
        _eventStreamController.add(HardwareEvent(
          module: 'gps',
          type: 'data',
          timestamp: DateTime.now(),
          data: {
            'latitude': position.coords?.latitude ?? 0.0,
            'longitude': position.coords?.longitude ?? 0.0,
            'altitude': position.coords?.altitude ?? 0.0,
            'accuracy': position.coords?.accuracy ?? 0.0,
            'speed': position.coords?.speed ?? 0.0,
          },
        ));
      });
      return true;
    } catch (e) {
      _sendError('gps', e.toString());
      return false;
    }
  }

  @override
  Future<bool> stopLocation() async {
    await _subscriptions['location']?.cancel();
    _subscriptions.remove('location');
    return true;
  }

  // --- Camera Implementation ---
  @override
  Future<bool> startCamera({int width = 640, int height = 480}) async {
    try {
      final constraints = {
        'video': {
          'width': width,
          'height': height,
          'facingMode': 'environment'
        }
      };
      _cameraStream = await html.window.navigator.mediaDevices?.getUserMedia(constraints);
      return _cameraStream != null;
    } catch (e) {
      _sendError('camera', e.toString());
      return false;
    }
  }

  @override
  Future<bool> stopCamera() async {
    _cameraStream?.getTracks().forEach((track) => track.stop());
    _cameraStream = null;
    return true;
  }

  // --- Sensor Implementation ---
  @override
  Future<bool> startSensor({int frequencyHz = 60}) async {
    try {
      await _subscriptions['sensor']?.cancel();
      _subscriptions['sensor'] = html.window.onDeviceMotion.listen((event) {
        _eventStreamController.add(HardwareEvent(
          module: 'sensor',
          type: 'data',
          timestamp: DateTime.now(),
          data: {
            'x': event.accelerationIncludingGravity?.x ?? 0.0,
            'y': event.accelerationIncludingGravity?.y ?? 0.0,
            'z': event.accelerationIncludingGravity?.z ?? 0.0,
          },
        ));
      });
      return true;
    } catch (e) {
      _sendError('sensor', e.toString());
      return false;
    }
  }

  @override
  Future<bool> stopSensor() async {
    await _subscriptions['sensor']?.cancel();
    _subscriptions.remove('sensor');
    return true;
  }

  @override
  Future<bool> startBluetoothScan() async => false;

  @override
  Future<bool> stopBluetoothScan() async => true;

  @override
  Future<bool> connectDevice(String id) async => false;

  @override
  Future<WifiInfo?> getWifiInfo() async => null;

  @override
  Future<bool> requestPermissions() async => true;

  @override
  Future<String?> getPlatformVersion() async {
    return 'Web: ${html.window.navigator.userAgent}';
  }

  void _sendError(String module, String message) {
    _eventStreamController.add(HardwareEvent(
      module: module,
      type: 'error',
      timestamp: DateTime.now(),
      data: {'message': message},
    ));
  }
}
