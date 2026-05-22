# Nexora SDK

Nexora SDK is a cross-platform Flutter plugin for hardware features. It provides a single Dart API for camera preview, native vision results, audio capture with FFT data, BLE scanning and GATT operations, location updates, geofencing, biometrics, haptics, device health, and app-private storage.

## Platform Support

| Platform | Status |
| --- | --- |
| Android | Supported |
| iOS | Supported |
| Web | Supported with safe Dart fallbacks |
| macOS, Windows, Linux | Supported with safe Dart fallbacks |

Android and iOS use native hardware implementations. Web and desktop register lightweight Dart implementations so apps compile and run on every Flutter platform; hardware APIs that need platform-native integrations return safe unsupported values such as `false`, `null`, or an empty list. Desktop storage uses local files, and web storage uses browser `localStorage`.

The web fallback uses `package:web` instead of `dart:html`, so it is ready for
Flutter WebAssembly builds.

Feature status is also available at runtime:

```dart
final support = NexoraSdk.instance.supportFor(HardwareFeature.camera);

if (!support.isAvailable) {
  debugPrint('${support.feature.name}: ${support.reason}');
}
```

| Feature group | Android/iOS | Web | Desktop |
| --- | --- | --- | --- |
| Camera, audio, BLE, GPS, biometrics, sensors, haptics, health | Native | Unsupported fallback | Unsupported fallback |
| Storage | Native | Browser `localStorage` fallback | Local file fallback |
| Clipboard, open URL, share text | Native | Best-effort browser fallback | Best-effort OS fallback |
| Video, Smart Sync, camera filters, BLE L2CAP, Dead Reckoning | Experimental / guarded | Experimental / guarded | Experimental / guarded |

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

if (!sdk.supports(HardwareFeature.camera)) {
  return;
}

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

## Capability and Lifecycle Helpers

Use `capabilities` when you want to hide unsupported hardware controls before
calling into native APIs:

```dart
final capabilities = sdk.capabilities;

if (capabilities.isMobile && capabilities.bluetooth) {
  await sdk.bluetooth.startScan();
}
```

Request permissions one-by-one and get a detailed result for your UI:

```dart
final report = await sdk.requestPermissionReport();

if (!report.allGranted) {
  debugPrint('Missing: ${report.deniedPermissions.join(', ')}');
}
```

Check current permission state without showing a system prompt, and guide users
to app settings when the OS requires it:

```dart
final cameraStatus = await sdk.permissions.status(HardwarePermission.camera);

if (cameraStatus.needsSettings) {
  await sdk.openAppSettings();
}

final snapshot = await sdk.getPermissionSnapshot();
debugPrint(snapshot.toMap().toString());
```

Collect a diagnostics snapshot for support screens, debug logs, or issue
reports:

```dart
final diagnostics = await sdk.collectDiagnostics();
debugPrint(diagnostics.toMap().toString());
```

Read native device and connectivity details to make your Flutter app adapt like
a platform app:

```dart
final device = await sdk.device.getInfo();
final network = await sdk.connectivity.getInfo();

if (device.thermalState == 'serious' || network.isMetered) {
  await sdk.audio.start(updateIntervalMs: 250);
}
```

Attach lifecycle cleanup so hardware sessions are released when the app moves
to the background:

```dart
final lifecycle = sdk.attachLifecycleController(
  stopCamera: true,
  stopAudio: true,
  stopLocation: true,
);

// Later, usually in dispose:
lifecycle.dispose();
```

When your app is paused, closed, or the user signs out, stop active hardware
sessions with one call:

```dart
final result = await sdk.stopAll();

if (!result.success) {
  debugPrint('Could not stop: ${result.failedModules.join(', ')}');
}
```

Filter the unified event stream without manually parsing every event:

```dart
sdk.eventsFor('camera').listen((event) {
  debugPrint('Camera event: ${event.type}');
});

sdk.errors.listen((event) {
  debugPrint('Hardware error: ${event.data}');
});
```

Camera Pro adds native still-photo capture and forward-compatible video APIs. Video recording is exposed for API stability, but currently reports `NOT_SUPPORTED` on native platforms until the camera recorder backends are added:

```dart
final photoPath = await sdk.camera.takePhoto();

try {
  await sdk.camera.startVideoRecording();
} on HardwareException catch (error) {
  debugPrint('Video not available yet: ${error.code}');
}
```

Use native platform utilities for small but important app integrations:

```dart
await sdk.native.copyText('Copied from Nexora');
final pasted = await sdk.native.pasteText();
await sdk.native.openUrl('https://flutter.dev');
await sdk.native.shareText('Shared from Nexora SDK');
```

Some experimental Pro APIs, including Smart Sync, camera shader filters, BLE L2CAP, and Dead Reckoning, are intentionally guarded. Platforms without a real implementation return `false` or a `NOT_SUPPORTED` error instead of reporting fake success.

Connectivity can be watched with a lightweight polling stream:

```dart
sdk.connectivity.watch().listen((info) {
  debugPrint('${info.networkType}: ${info.isConnected}');
});
```

Storage includes convenience helpers for app settings and lightweight logs:

```dart
await sdk.storage.writeJson('settings.json', {'audioFft': true});
final settings = await sdk.storage.readJson<Map<String, dynamic>>(
  'settings.json',
);

await sdk.storage.appendFile('session.log', 'Started\n');
```

## Advanced Features (v3.4.0)

### 1. Smart Sync & Telemetry Logging
Enables background logging of battery, connectivity, and custom metrics into rolled files, with automatic upload retry and exponential backoff.
```dart
await sdk.health.startLogging('telemetry.csv', 1000);
await sdk.health.enableSmartSync(
  uploadEndpointUrl: 'https://api.nexora.com/telemetry',
  rollLimitBytes: 1 * 1024 * 1024, // Roll file at 1MB
  requireWifi: true,
);
```

### 2. NFC (NDEF Reader & Writer)
Scan and write NDEF data to NFC tags. Supports foreground dispatch on Android and custom NDEF sessions on iOS.
```dart
// Scan tag
await sdk.nfc.startNfcScan();
sdk.nfc.nfcTagStream.listen((tag) {
  print('Tag payload: ${tag['payload']}');
});

// Write to tag
await sdk.nfc.writeNdefRecord(type: 'text/plain', payload: 'Hello Nexora');
```

### 3. Secure Storage (AES-256)
Enables reading and writing files and JSON payloads using hardware-backed AES encryption (Android KeyStore and iOS Keychain).
```dart
await sdk.secureStorage.writeSecureFile('credentials.enc', 'my_secret_token');
final secret = await sdk.secureStorage.readSecureFile('credentials.enc');
```

### 4. Background Isolates
Perform heavy CPU tasks (like cryptographic verification or parsing large logs) off the main UI thread using the background isolate runner.
```dart
final result = await BackgroundIsolateWrapper.compute((data) {
  // Heavy computation here
  return data.toUpperCase();
}, 'heavy payload');
```

## Notes

Hardware APIs are permission-sensitive and device-sensitive. Methods that require permission now return a native `PERMISSION_DENIED` error instead of silently pretending to work.

High-level Dart APIs validate common bad inputs before crossing the platform
channel, including empty Bluetooth IDs, invalid geofence coordinates, invalid
camera sizes, unsupported haptic names, and non-positive sensor/audio intervals.
