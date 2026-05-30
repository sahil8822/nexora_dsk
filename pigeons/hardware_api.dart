import 'package:pigeon/pigeon.dart';

@ConfigurePigeon(PigeonOptions(
  dartOut: 'packages/nexora_sdk_platform_interface/lib/src/pigeon/hardware_api.g.dart',
  dartOptions: DartOptions(),
  kotlinOut: 'packages/nexora_sdk_android/android/src/main/kotlin/com/nexora/sdk/pigeon/HardwareApi.g.kt',
  kotlinOptions: KotlinOptions(package: 'com.nexora.sdk.pigeon'),
  swiftOut: 'packages/nexora_sdk_ios/ios/Classes/pigeon/HardwareApi.g.swift',
  swiftOptions: SwiftOptions(),
))

// --- Camera ---

class NexoraCameraOptions {
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
  int startCameraWithOptions(NexoraCameraOptions options);
  
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

// --- Audio ---

class BasicAudioOptions {
  bool? enableFFT;
  bool? streamBytes;
  int? updateIntervalMs;
}

class NexoraAudioOptions {
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
  bool startAudioWithOptions(NexoraAudioOptions options);
  
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

// --- Location ---

class NexoraLocationOptions {
  String? accuracy;
  double? distanceFilter;
  int? intervalMs;
}

@HostApi()
abstract class LocationApi {
  @async
  bool startLocation();
  
  @async
  bool startLocationWithOptions(NexoraLocationOptions options);
  
  @async
  bool stopLocation();
  
  @async
  bool setBackgroundLocationEnabled(bool enabled);
}

// --- Sensors ---

class NexoraSensorOptions {
  int? frequencyHz;
}

@HostApi()
abstract class SensorApi {
  @async
  bool startSensor(int frequencyHz);
  
  @async
  bool startSensorWithOptions(NexoraSensorOptions options);
  
  @async
  bool stopSensor();
  
  @async
  bool enableDeadReckoning(bool enabled);
}

// --- Biometrics ---

class NexoraBiometricOptions {
  String? title;
  String? subtitle;
  String? description;
  String? negativeButtonText;
}

@HostApi()
abstract class BiometricsApi {
  @async
  bool authenticate(String reason);
  
  @async
  bool authenticateWithOptions(NexoraBiometricOptions options);
  
  @async
  bool canAuthenticate();
}

// --- Bluetooth ---

class NexoraBluetoothScanOptions {
  List<String?>? serviceUuids;
  String? scanMode;
}

@HostApi()
abstract class BluetoothApi {
  @async
  bool startBluetoothScan();
  
  @async
  bool startBluetoothScanWithOptions(NexoraBluetoothScanOptions options);
  
  @async
  bool stopBluetoothScan();
  
  @async
  bool connectDevice(String id);
  
  @async
  bool disconnectDevice(String id);
  
  @async
  List<String?> discoverServices(String deviceId);
  
  @async
  bool sendData(String deviceId, String serviceId, String charId, List<int?> data);
  
  @async
  Uint8List? readData(String deviceId, String serviceId, String charId);
  
  @async
  bool subscribeToCharacteristic(String deviceId, String serviceId, String charId, bool enable);
  
  @async
  bool requestMtu(String deviceId, int mtu);
  
  @async
  bool startBlePeripheral(String uuid);
  
  @async
  void stopBlePeripheral();
}

// --- Secure Storage ---

class NexoraStorageInfo {
  int? internalTotal;
  int? internalFree;
  int? externalTotal;
  int? externalFree;
  int? appCacheSize;
  int? appDataSize;
}

class NexoraFileInfo {
  String? name;
  int? size;
  bool? isDirectory;
  int? lastModifiedMs;
}

@HostApi()
abstract class SecureStorageApi {
  @async
  NexoraStorageInfo? getStorageInfo();
  
  @async
  String? writeFile(String fileName, String content);
  
  @async
  String? appendFile(String fileName, String content);
  
  @async
  String? readFile(String fileName);
  
  @async
  bool deleteFile(String fileName);
  
  @async
  bool fileExists(String fileName);
  
  @async
  List<NexoraFileInfo?> listFiles();
  
  @async
  String? writeBytes(String fileName, Uint8List bytes);
  
  @async
  Uint8List? readBytes(String fileName);
  
  @async
  bool clearCache();
  
  @async
  String? getAppDirectory();
  
  @async
  String? getCacheDirectory();
  
  @async
  String? getExternalDirectory();
}

// --- System & Utilities ---

class NexoraDeviceInfo {
  String? platform;
  String? manufacturer;
  String? model;
  String? osVersion;
  String? sdkVersion;
  bool? isPhysicalDevice;
  int? totalRamBytes;
  int? availableRamBytes;
  String? cpuArchitecture;
  double? screenRefreshRate;
  String? thermalState;
}

class NexoraConnectivityInfo {
  bool? isConnected;
  String? networkType;
  bool? isMetered;
  bool? isVpn;
  int? signalStrength;
  String? ipAddress;
}

class NexoraBatteryInfo {
  double? level;
  bool? isCharging;
  String? status;
  double? temperature;
}

class NexoraWifiInfo {
  String? ssid;
  String? bssid;
  int? signalStrength;
  int? frequency;
  int? linkSpeed;
}

class NexoraHapticOptions {
  String? type;
}

class NexoraSdkConfig {
  bool? enableLogging;
  bool? ecoMode;
}

class NexoraPermissionStatus {
  String? permission;
  String? state;
  bool? canRequest;
}

@HostApi()
abstract class SystemApi {
  @async
  bool configureSdk(NexoraSdkConfig config);
  
  @async
  bool requestPermissions();
  
  @async
  bool requestPermission(String type);
  
  @async
  NexoraPermissionStatus getPermissionStatus(String type);
  
  @async
  bool openAppSettings();
  
  @async
  NexoraDeviceInfo getDeviceInfo();
  
  @async
  NexoraConnectivityInfo getConnectivityInfo();
  
  @async
  NexoraBatteryInfo? getBatteryInfo();
  
  @async
  NexoraWifiInfo? getWifiInfo();
  
  @async
  void vibrate(int durationMs);
  
  @async
  void hapticFeedback(String type);
  
  @async
  void performHapticWithOptions(NexoraHapticOptions options);
  
  @async
  bool copyText(String text);
  
  @async
  String? pasteText();
  
  @async
  bool openUrl(String url);
  
  @async
  bool shareText(String text, String? subject);
  
  @async
  String? saveToGallery(String filePath);
  
  @async
  bool enterPictureInPicture();
  
  @async
  List<String?> getConnectedUsbDevices();
  
  @async
  bool startForegroundService(String title, String content);
  
  @async
  bool updateForegroundService(String title, String text);
  
  @async
  bool stopForegroundService();
  
  @async
  bool enableSmartSync(String uploadEndpointUrl, Map<String?, String?> headers, int rollLimitBytes, bool requireWifi);
  
  @async
  void setEcoModeEnabled(bool enabled);
  
  @async
  bool isEcoModeActive();
  
  @async
  String getThermalState();
}

// --- Biometric Cryptography & Secure Storage ---

class NexoraCryptoKeyOptions {
  String? alias;
  bool? requireBiometric;
  bool? useStrongBox;
}

@HostApi()
abstract class CryptoApi {
  @async
  bool generateBiometricKey(NexoraCryptoKeyOptions options);
  
  @async
  bool deleteKey(String alias);
  
  @async
  bool keyExists(String alias);
  
  @async
  Uint8List? signWithBiometricKey(String alias, Uint8List data);
  
  @async
  Uint8List? encryptWithBiometricKey(String alias, Uint8List plaintext);
  
  @async
  Uint8List? decryptWithBiometricKey(String alias, Uint8List ciphertext);
}
