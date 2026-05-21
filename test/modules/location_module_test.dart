import 'package:flutter_test/flutter_test.dart';
import 'package:nexora_sdk/nexora_sdk.dart';
import 'package:nexora_sdk_platform_interface/nexora_sdk_platform_interface.dart';
import '../mocks/mock_platform.dart';

class MockLocationPlatform extends MockNexoraSdkPlatform {
  bool isRunning = false;
  bool requestPermissionResult = true;
  bool backgroundEnabled = false;
  bool deadReckoningEnabled = false;
  String lastGeofenceId = '';
  double lastLat = 0;
  double lastLon = 0;
  double lastRadius = 0;

  @override
  Future<bool> requestLocationPermission() async => requestPermissionResult;

  @override
  Future<bool> startLocation() async {
    isRunning = true;
    return true;
  }

  @override
  Future<bool> startLocationWithOptions(LocationOptions options) async {
    isRunning = true;
    return true;
  }

  @override
  Future<bool> stopLocation() async {
    isRunning = false;
    return true;
  }

  @override
  Future<bool> setBackgroundLocationEnabled(bool enabled) async {
    backgroundEnabled = enabled;
    return true;
  }

  @override
  Future<bool> enableDeadReckoning(bool enabled) async {
    deadReckoningEnabled = enabled;
    return true;
  }

  @override
  Future<bool> addGeofence(
    String id,
    double lat,
    double lon,
    double radius,
  ) async {
    lastGeofenceId = id;
    lastLat = lat;
    lastLon = lon;
    lastRadius = radius;
    return true;
  }
}

void main() {
  late MockLocationPlatform mockPlatform;

  setUp(() {
    mockPlatform = MockLocationPlatform();
    NexoraSdkPlatform.instance = mockPlatform;
  });

  group('LocationModule Tests', () {
    test('start() & stop() success', () async {
      final location = LocationModule();
      expect(location.isRunning, false);
      expect(await location.start(), true);
      expect(location.isRunning, true);
      expect(await location.stop(), true);
      expect(location.isRunning, false);
    });

    test('startWithOptions() permission denied', () async {
      mockPlatform.requestPermissionResult = false;
      final location = LocationModule();
      final success = await location.startWithOptions(const LocationOptions());
      expect(success, false);
      expect(location.isRunning, false);
    });

    test('setBackgroundEnabled() & enableDeadReckoning()', () async {
      final location = LocationModule();
      expect(await location.setBackgroundEnabled(true), true);
      expect(mockPlatform.backgroundEnabled, true);

      expect(await location.enableDeadReckoning(true), true);
      expect(mockPlatform.deadReckoningEnabled, true);
    });

    test('addGeofence() validation & success', () async {
      final location = LocationModule();

      expect(
        () => location.addGeofence('', 45, 90, 100),
        throwsArgumentError,
      );
      expect(
        () => location.addGeofence('gf', -95, 90, 100),
        throwsArgumentError,
      );
      expect(
        () => location.addGeofence('gf', 45, 200, 100),
        throwsArgumentError,
      );
      expect(
        () => location.addGeofence('gf', 45, 90, 0),
        throwsArgumentError,
      );
      expect(
        () => location.addGeofence('gf', 45, 90, -10),
        throwsArgumentError,
      );

      expect(await location.addGeofence('g-1', 12.34, 56.78, 250), true);
      expect(mockPlatform.lastGeofenceId, 'g-1');
      expect(mockPlatform.lastLat, 12.34);
      expect(mockPlatform.lastLon, 56.78);
      expect(mockPlatform.lastRadius, 250.0);
    });
  });
}
