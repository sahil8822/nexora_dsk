# High-Performance Unified Hardware SDK (Production Grade)

A professional Flutter SDK providing deep, high-performance access to multiple hardware components (Camera, Bluetooth, WiFi, GPS, Sensors) using a hybrid, federated architecture.

## 🏗️ Architecture Design
The SDK uses a **Modular Hybrid Architecture** to ensure near-native performance:
- **Dart Layer**: High-level API and event dispatching.
- **Native Managers**: Subsystems for Camera2 (Android), AVFoundation (iOS), BLE, and FusedLocation.
- **Unified Event Hub**: Single `EventChannel` with tagged data types (`camera`, `bluetooth`, `gps`, `sensor`).
- **C++ (NDK)**: Advanced pixel processing for ultra-high FPS camera streaming.

---

## 🛠️ Features & Usage

### 1. Camera Frame Streaming
Streams raw frames with 32BGRA (iOS) or YUV_420 (Android) formatting.
```dart
final plugin = NexoraSdk.instance;
await plugin.startCamera();
plugin.cameraStream.listen((frame) {
  // Use frame.bytes (Uint8List), width, height
});
```

### 2. Bluetooth (BLE) Scanning
Real-time BLE discovery with RSSI and metadata.
```dart
await plugin.startBluetoothScan();
plugin.bluetoothStream.listen((device) {
  // id, name, rssi
});
```

### 3. High-Accuracy GPS
Uses FusedLocationProvider (Android) and CoreLocation (iOS).
```dart
await plugin.startLocation();
plugin.locationStream.listen((loc) {
  // lat, lon, altitude, accuracy
});
```

---

## 🔐 Permissions & Setup

### Android (`AndroidManifest.xml`)
```xml
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.BLUETOOTH_SCAN" />
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_WIFI_STATE" />
```

### iOS (`Info.plist`)
```xml
<key>NSCameraUsageDescription</key><string>Camera Access</string>
<key>NSBluetoothAlwaysUsageDescription</key><string>BLE Scanning</string>
<key>NSLocationWhenInUseUsageDescription</key><string>GPS Tracking</string>
```

---

## ⚡ Performance & Production Grade Features
1.  **Sensor Throttling**: Automatic 60Hz throttling on the native side to prevent UI jank.
2.  **Battery Optimization**: Hardware modules only activate when explicitly called via `start()`.
3.  **Background Reliability**: Integrated **Android Foreground Service** ensures the app isn't killed during long-running GPS or Bluetooth tasks.
4.  **Robust Error Handling**: Unified error reporting via `EventChannel` for hardware unavailability.

## 🛠️ Usage (Updated)
```dart
final sdk = NexoraSdk.instance;

// 1. Start explicit module
await sdk.location.start(); 

// 2. Listen to stream
sdk.location.stream.listen((data) { ... });

// 3. Stop to save battery
await sdk.location.stop();
```

---

## 🧪 Example App
Run the `example/` project to see the live dashboard with real-time FPS monitoring, background-safe GPS, and throttled sensor streams.
