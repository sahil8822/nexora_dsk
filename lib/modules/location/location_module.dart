import '../../nexora_sdk_platform_interface.dart';
import '../../models/hardware_models.dart';

/// Modular Location (GPS) Module.
class LocationModule {
  Future<bool> start() async {
    return await NexoraSdkPlatform.instance.startLocation();
  }

  Future<bool> stop() async {
    return await NexoraSdkPlatform.instance.stopLocation();
  }

  /// Real-time GPS stream.
  Stream<LocationData> get stream => NexoraSdkPlatform.instance.locationStream;
}
