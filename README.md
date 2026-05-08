# Nexora SDK

Nexora SDK is a cross-platform Flutter plugin for hardware features. It provides a single Dart API for camera preview, native vision results, audio capture with FFT data, BLE scanning and GATT operations, location updates, geofencing, biometrics, haptics, device health, and app-private storage.

## Platform Support

| Platform | Status |
| --- | --- |
| Android | Supported |
| iOS | Supported |
| Web | Supported with safe Dart fallbacks |
| macOS, Windows, Linux | Supported with safe Dart fallbacks |

Android and iOS use native hardware implementations. Web and desktop register lightweight Dart implementations so apps compile and run on every Flutter platform; hardware APIs that need platform-native integrations return safe unsupported values such as `false`, `null`, or an empty list. Desktop storage uses local files, and web storage uses an in-memory fallback.

## Permissions

Nexora SDK does not depend on `permission_handler`. Runtime permissions are requested by the native Android and iOS plugin code through:

```dart
final sdk = NexoraSdk.instance;
final granted = await sdk.requestPermissions();
```

The native request covers camera, microphone, foreground location, and Bluetooth runtime permissions where Android or iOS requires them. Apps must still provide the normal Android manifest entries and iOS usage descriptions. The bundled example app shows the required iOS `Info.plist` keys.

You can also request one module at a time:

```dart
await sdk.requestCameraPermission();
await sdk.requestAudioPermission();
await sdk.requestLocationPermission();
await sdk.requestBluetoothPermission();
```

Background location is disabled by default. If your app needs geofencing in the background, enable it explicitly and add the platform-specific background permission, background mode, and review disclosures in the host app.

```dart
await sdk.location.setBackgroundEnabled(true);
await sdk.addGeofence('office', 37.422, -122.084, 100);
```

## Quick Start

```dart
final sdk = NexoraSdk.instance;

final granted = await sdk.requestPermissions();
if (!granted) {
  return;
}

final textureId = await sdk.camera.start();
await sdk.setVisionMode(face: true, barcode: true);
```

The default camera preview request is HD (1280x720). You can choose a preset or pass a custom size:

```dart
final textureId = await sdk.camera.start(quality: CameraQuality.fullHd);
// or
final textureId = await sdk.camera.start(width: 1920, height: 1080);
```

Show the camera preview with Flutter's `Texture` widget:

```dart
if (textureId != null) {
  Texture(textureId: textureId);
}
```

Start lightweight audio analysis. Raw PCM bytes are off by default; enable them only if your app needs waveform samples.

```dart
await sdk.startAudioWithAnalysis(updateIntervalMs: 80);

sdk.audio.stream.listen((frame) {
  final spectrum = frame.spectrum;
});
```

For waveform data:

```dart
await sdk.audio.start(streamBytes: true, updateIntervalMs: 40);
```

## Notes

Hardware APIs are permission-sensitive and device-sensitive. Methods that require permission now return a native `PERMISSION_DENIED` error instead of silently pretending to work.
