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
  Future<bool> addGeofence(String id, double lat, double lon, double radius) =>
      NexoraSdkPlatform.instance.addGeofence(id, lat, lon, radius);

  /// A stream of real-time [LocationData] telemetry.
  Stream<LocationData> get stream => NexoraSdkPlatform.instance.locationStream;
}
