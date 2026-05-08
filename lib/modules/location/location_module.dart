import '../../nexora_sdk_platform_interface.dart';
import '../../models/hardware_models.dart';

/// Module for high-accuracy GPS tracking and Geofencing.
class LocationModule {
  /// Starts real-time location updates. Coordinates are delivered via the [stream].
  Future<bool> start() => NexoraSdkPlatform.instance.startLocation();

  /// Stops all location updates and releases the GPS hardware.
  Future<bool> stop() => NexoraSdkPlatform.instance.stopLocation();

  /// Enables or disables background location support where the platform allows it.
  ///
  /// Keep this disabled unless the host app has the correct store disclosures,
  /// manifest/background modes, and user-facing reason.
  Future<bool> setBackgroundEnabled(bool enabled) =>
      NexoraSdkPlatform.instance.setBackgroundLocationEnabled(enabled);

  /// Adds a virtual circular boundary trigger at the specified coordinates.
  ///
  /// Triggers will be handled by the background intelligence system.
  Future<bool> addGeofence(String id, double lat, double lon, double radius) {
    if (id.trim().isEmpty) {
      throw ArgumentError.value(id, 'id', 'Geofence id cannot be empty.');
    }
    if (lat < -90 || lat > 90) {
      throw ArgumentError.value(lat, 'lat', 'Must be between -90 and 90.');
    }
    if (lon < -180 || lon > 180) {
      throw ArgumentError.value(lon, 'lon', 'Must be between -180 and 180.');
    }
    if (radius <= 0) {
      throw ArgumentError.value(radius, 'radius', 'Must be greater than zero.');
    }
    return NexoraSdkPlatform.instance.addGeofence(id, lat, lon, radius);
  }

  /// A stream of real-time [LocationData] telemetry.
  Stream<LocationData> get stream => NexoraSdkPlatform.instance.locationStream;
}
