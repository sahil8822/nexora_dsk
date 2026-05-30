# Nexora SDK

![Nexora SDK Banner](/Users/appicsoftwares/.gemini/antigravity-ide/brain/69345341-3f62-4776-9c3a-317720f2fc0c/nexora_banner_1780133902525.png)

[![Pub Version](https://img.shields.io/pub/v/nexora_sdk)](https://pub.dev/packages/nexora_sdk)
[![Pub Points](https://img.shields.io/pub/points/nexora_sdk)](https://pub.dev/packages/nexora_sdk/score)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](https://opensource.org/licenses/MIT)

**Nexora SDK** is a powerful, beginner-friendly, cross-platform Flutter plugin that provides a single, unified Dart API for advanced hardware features. 

With Nexora SDK, you can easily implement:
*   📸 **Smart Camera Preview** (with built-in QR/Barcode & Face scanning)
*   🎙️ **Audio Capture & Analysis** (Real-time FFT spectrum data)
*   📡 **Bluetooth LE (BLE)** (Scanning, Connecting, and GATT Data reading/writing)
*   📍 **Location & Geofencing** (Foreground and background tracking)
*   📊 **Device Health & Telemetry** (Background sync of battery/network diagnostics)
*   🔒 **Secure Storage** (Hardware-backed AES encryption)

---

## 🚀 Beginner Quick Start & Installation

### Step 1: Add Dependency

Add `nexora_sdk` to your Flutter project's `pubspec.yaml`:

```bash
flutter pub add nexora_sdk
```

### Step 2: Native Platform Configuration

Hardware features require explicit permissions declared in your native files.

#### 🤖 Android Setup
Open `android/app/src/main/AndroidManifest.xml` and add:

```xml
<!-- Camera & Audio -->
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.RECORD_AUDIO" />

<!-- Bluetooth -->
<uses-permission android:name="android.permission.BLUETOOTH_SCAN" />
<uses-permission android:name="android.permission.BLUETOOTH_CONNECT" />

<!-- Location -->
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
```

#### 🍎 iOS Setup
Open `ios/Runner/Info.plist` and add:

```xml
<key>NSCameraUsageDescription</key>
<string>This app requires camera access for preview and image scanning.</string>
<key>NSMicrophoneUsageDescription</key>
<string>This app requires microphone access for audio analysis.</string>
<key>NSBluetoothAlwaysUsageDescription</key>
<string>This app requires Bluetooth access to connect to devices.</string>
<key>NSLocationWhenInUseUsageDescription</key>
<string>This app requires location access for tracking.</string>
```

---

## 📖 Detailed Use Cases

### 1. Smart Camera & AI Vision 📸
Easily start a camera preview and overlay UI elements on top of it. You can also enable AI vision modes to scan barcodes or detect faces in real-time.

```dart
final sdk = NexoraSdk.instance;

// 1. Request Permission
final granted = await sdk.requestCameraPermission();
if (!granted) return;

// 2. Start Camera (Returns a Texture ID to display in your UI)
final textureId = await sdk.camera.start(quality: CameraQuality.hd);

// 3. Enable Vision Processing
await sdk.setVisionMode(face: true, barcode: true);

// 4. Display in UI
if (textureId != null) {
  return Texture(textureId: textureId);
}
```
*Tip: Listen to `sdk.eventsFor('camera')` to receive bounding boxes for detected faces or string values for scanned QR codes!*

### 2. Audio FFT Spectrum Visualizer 🎙️
Build beautiful audio visualizers or voice recorders using real-time FFT frequency data.

```dart
// 1. Request Permission
await sdk.requestAudioPermission();

// 2. Start Audio with FFT Analysis enabled (Updates every 80ms)
await sdk.startAudioWithAnalysis(updateIntervalMs: 80);

// 3. Listen to the stream
sdk.audio.stream.listen((AudioFrame frame) {
  final spectrum = frame.spectrum; // Array of frequency magnitudes
  
  // Use 'spectrum' data to draw UI bars or waves!
  print('Loudest frequency magnitude: ${spectrum.reduce(math.max)}');
});
```

### 3. Bluetooth LE Scanner (BLE) 📡
Scan for nearby devices, connect to them, and read/write characteristic data instantly without dealing with complex native Bluetooth stacks.

```dart
// 1. Start scanning for devices
await sdk.bluetooth.startScan();

// 2. Listen for discovered devices
sdk.eventsFor('bluetooth').listen((event) {
  if (event.type == 'device_discovered') {
    final deviceName = event.data['name'];
    final deviceId = event.data['id'];
    print('Found device: $deviceName ($deviceId)');
  }
});

// 3. Connect and Read Data
await sdk.connectDevice('device_id_here');
final data = await sdk.readData(
  'device_id_here', 
  'service_uuid_here', 
  'characteristic_uuid_here'
);
print('Read bytes: $data');
```

### 4. Background Telemetry & Health 📊
Ideal for IoT or enterprise apps, log device health (battery drops, network changes) to a local file and sync it to your server automatically when WiFi is available.

```dart
// Start logging telemetry every 60 seconds
await sdk.health.startLogging('telemetry_log.csv', 60000);

// Enable Smart Sync to upload the log when it hits 1MB
await sdk.health.enableSmartSync(
  uploadEndpointUrl: 'https://your-api.com/upload-telemetry',
  rollLimitBytes: 1 * 1024 * 1024, // 1MB limit
  requireWifi: true,
);
```

---

## 🛠 Advanced Features (Pro)

*   **NFC Support:** Read and write NDEF records instantly (`sdk.nfc.startNfcScan()`).
*   **Secure Storage:** Store sensitive API keys in hardware-backed keystores (`sdk.secureStorage.writeSecureFile()`).
*   **Background Isolates:** Offload heavy computations to a background thread to keep your UI running at 60 FPS (`BackgroundIsolateWrapper.compute()`).

## ⚠️ Notes for Web & Desktop
Nexora SDK is designed to compile on **all platforms**. 
Features like Camera, Audio, and BLE use native SDKs on iOS/Android. When running on Web, Windows, macOS, or Linux, the SDK will safely return `false`, `null`, or `NOT_SUPPORTED` without crashing your app, allowing you to use a single codebase seamlessly.

## 📄 License
This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
