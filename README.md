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
final plugin = MyHardwarePlugin.instance;
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

## ⚡ Performance Optimization & Advanced (C++/FFI)
To achieve zero-copy camera streaming or high-speed data parsing for enterprise applications:
1. **NDK Integration**: Move `processPixelBuffer` to `native-lib.cpp` (included in `/android/src/main/cpp`).
2. **Dart FFI**: Access shared memory buffers directly from Dart to avoid serialization overhead.
3. **Throttling**: The SDK includes internal rate limiting for high-frequency GPS/Sensor data (default 60Hz).

---

## 🧪 Example App
Run the provided `example/` project to see the live dashboard with all toggles and real-time data streams.
