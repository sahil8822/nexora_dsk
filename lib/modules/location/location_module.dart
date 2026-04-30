import 'dart:async';
import 'package:nexora_sdk/models/hardware_models.dart';
import '../../nexora_sdk_platform_interface.dart';

/// Module for high-accuracy GPS and location tracking.
/// Uses fused location providers for better battery efficiency.
class LocationModule {
  /// Internal constructor.
  LocationModule();

  /// Stream of real-time [LocationData] (latitude, longitude, etc.).
  Stream<LocationData> get stream => NexoraSdkPlatform.instance.locationStream;

  /// Starts the location tracking service.
  /// May request background execution if configured.
  Future<bool> start() => NexoraSdkPlatform.instance.startLocation();

  /// Stops location updates and releases hardware resources.
  Future<bool> stop() => NexoraSdkPlatform.instance.stopLocation();
}
