import 'package:pigeon/pigeon.dart';

@ConfigurePigeon(PigeonOptions(
  dartOut: 'packages/nexora_sdk_platform_interface/lib/src/pigeon/hardware_api.g.dart',
  dartOptions: DartOptions(),
  kotlinOut: 'packages/nexora_sdk_android/android/src/main/kotlin/com/nexora/sdk/pigeon/HardwareApi.g.kt',
  kotlinOptions: KotlinOptions(package: 'com.nexora.sdk.pigeon'),
  swiftOut: 'packages/nexora_sdk_ios/ios/Classes/pigeon/HardwareApi.g.swift',
  swiftOptions: SwiftOptions(),
))

class BasicCameraOptions {
  bool? enableFlash;
  String? resolution;
}

class StartCameraResult {
  int? textureId;
  String? error;
}

@HostApi()
abstract class HardwareApi {
  StartCameraResult startCamera(BasicCameraOptions options);
  void stopCamera();
}
