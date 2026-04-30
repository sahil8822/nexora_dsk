# Nexora SDK 🚀 (v3.0.0)

[![pub package](https://img.shields.io/pub/v/nexora_sdk.svg)](https://pub.dev/packages/nexora_sdk)
[![Aesthetics](https://img.shields.io/badge/Aesthetics-Ultimate-blueviola.svg)](#)

**Nexora SDK** is a high-performance, production-ready Flutter hardware engine. It provides a unified, intelligent interface for all mobile hardware with zero-copy GPU rendering and native AI processing.

## 🧠 The Intelligence Update (v3.0)

Nexora v3.0 brings native-level intelligence to your hardware integrations:

*   **👁️ Smart Vision AI**: Native background face detection and barcode scanning (Powered by Google ML Kit & Apple Vision).
*   **📊 Audio Analysis (FFT)**: Real-time frequency spectrum analysis using native signal processing.
*   **📡 Background Geofencing**: Trigger intelligent responses when devices enter or exit geographical boundaries.
*   **⚡ Zero-Copy Preview**: Ultra-performance GPU texture rendering for camera previews with minimal CPU/Memory load.
*   **📑 Hardware Telemetry**: Automated background logging of device health, thermal, and sensor data.

## 📦 Key Features

| Module | Capability | Support |
|--------|------------|---------|
| **Camera** | 4K Streaming, AI Vision, GPU Textures, Zoom, Flash | Android, iOS, Web |
| **Bluetooth** | BLE Scanning, GATT, Multi-device connection | Android, iOS |
| **Biometrics** | FaceID, Fingerprint, Secure Auth | Android, iOS |
| **Audio** | Raw PCM, FFT Spectrum, Native processing | Android, iOS |
| **Location** | High-accuracy GPS, Geofencing, Background updates | Android, iOS |
| **Sensors** | Accelerometer, Gyroscope (Up to 100Hz) | Android, iOS |
| **Health** | Battery state, Thermal, Network diagnostics | Android, iOS |

## 🚀 Quick Start

### Initialize Intelligence
```dart
final sdk = NexoraSdk.instance;

// Request all hardware permissions at once
bool granted = await sdk.requestPermissions();
```

### Smart Vision Preview
```dart
// Start camera and get GPU Texture ID
final int? textureId = await sdk.camera.start();

// Enable AI Processing
await sdk.setVisionMode(face: true, barcode: true);

// Show in UI
Texture(textureId: textureId)
```

### Real-time Audio Spectrum
```dart
await sdk.startAudioWithAnalysis();

sdk.audio.stream.listen((frame) {
  print(frame.spectrum); // Visualizer ready!
});
```

## 🛠️ Performance & Design
Nexora is built for "Heavy Builds". It offloads all heavy computations to native worker threads, ensuring your Flutter UI stays at a consistent 60 FPS.

## 📝 License
MIT License - Created with ❤️ for the Flutter Community.
