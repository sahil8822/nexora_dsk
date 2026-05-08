# Changelog

## 3.1.0

* Kept the package name as `nexora_sdk`.
* Removed the Dart `permission_handler` dependency.
* Added native Android and iOS permission handling for camera, microphone, foreground location, and Bluetooth runtime permissions.
* Added per-module permission request APIs.
* Made background location opt-in.
* Added storage file-name validation to keep file I/O inside app-private storage.
* Improved default camera preview quality to 1280x720 while throttling native vision processing for speed.
* Added camera quality presets, including Full HD, while keeping custom width and height support.
* Made audio streaming lighter by disabling raw audio bytes by default and adding event interval control.
* Hardened camera/audio model parsing for lightweight native events.
* Improved BLE scan/connect/write failure reporting instead of always returning success.
* Added native lifecycle cleanup for camera, audio, sensors, location, BLE, textures, and logging.
* Removed unused raw camera module files and added publish ignore rules for generated artifacts.
* Updated example Android and iOS identifiers to Nexora package IDs.
* Registered web, macOS, Windows, and Linux with safe Dart fallback implementations.
* Changed Android package/namespace from `com.example.nexora_sdk` to `com.nexora.sdk`.
* Aligned package, Android, iOS, README, and changelog metadata to version `3.1.0`.
* Removed stale publish dry-run output and unsupported placeholder platform files.

## 3.0.0

* Added camera preview, native vision hooks, audio FFT, hardware logging, geofencing, health diagnostics, and storage APIs.
