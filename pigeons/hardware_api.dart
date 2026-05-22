import 'package:pigeon/pigeon.dart';

@ConfigurePigeon(PigeonOptions(
  dartOut: 'packages/nexora_sdk_platform_interface/lib/src/pigeon/hardware_api.g.dart',
  dartOptions: DartOptions(),
  kotlinOut: 'packages/nexora_sdk_android/android/src/main/kotlin/com/nexora/sdk/pigeon/HardwareApi.g.kt',
  kotlinOptions: KotlinOptions(package: 'com.nexora.sdk.pigeon'),
  swiftOut: 'packages/nexora_sdk_ios/ios/Classes/pigeon/HardwareApi.g.swift',
  swiftOptions: SwiftOptions(),
))

class PigeonCameraOptions {
  String? resolution;
  String? focusMode;
  String? exposureMode;
  double? exposureCompensation;
  bool? mirrorFrontCamera;
}

class CustomClassifierOptions {
  String? modelAssetPath;
  List<String?>? labels;
  double? threshold;
}

class VisionModeOptions {
  bool? barcode;
  bool? face;
}

@HostApi()
abstract class HardwareApi {
  @async
  int startCamera(int width, int height);
  
  @async
  int startCameraWithOptions(PigeonCameraOptions options);
  
  @async
  bool stopCamera();
  
  @async
  bool setVisionMode(VisionModeOptions options);
  
  @async
  bool registerCustomClassifier(CustomClassifierOptions options);
  
  @async
  bool setFlash(bool on);
  
  @async
  bool setZoom(double level);
  
  @async
  bool flipCamera();
  
  @async
  String? takePhoto(String? fileName);
  
  @async
  String? startVideoRecording(String? fileName);
  
  @async
  String? stopVideoRecording();
  
  @async
  bool applyCameraFilterShader(String shaderType);
}

class BasicAudioOptions {
  bool? enableFFT;
  bool? streamBytes;
  int? updateIntervalMs;
}

class PigeonAudioOptions {
  int? sampleRate;
  String? channels;
  bool? enableEchoCancellation;
  bool? enableNoiseSuppression;
}

@HostApi()
abstract class AudioApi {
  @async
  bool startAudio(BasicAudioOptions options);
  
  @async
  bool startAudioWithOptions(PigeonAudioOptions options);
  
  @async
  bool stopAudio();
  
  @async
  bool routeAudioOutput(String route);
  
  @async
  double getAudioVolume();
  
  @async
  bool setAudioVolume(double level);
  
  @async
  bool selectAudioInput(String device);
  
  @async
  bool setAudioGain(double gain);
}
