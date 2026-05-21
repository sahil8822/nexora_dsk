# Changelog

## 4.0.0

**Massive Architecture & Quality Update**

* **Federated Architecture:** Completely restructured the plugin into a highly modular **Federated Plugin** (`nexora_sdk_platform_interface`, `nexora_sdk_android`, `nexora_sdk_ios`, `nexora_sdk_web`, `nexora_sdk_desktop`). This improves tree-shaking, separation of concerns, and drastically simplifies the platform channel method calls.
* **Deep Mocking & Testing:** Added a dedicated mock platform implementation (`MockNexoraSdkPlatform`) with comprehensive unit testing. The SDK now boasts incredibly deep, full-coverage tests that seamlessly test the main facade against the platform interface.
* **API Consistency (Exceptions):** Unified behavior across all unsupported platforms (Web & Desktop). Unsupported hardware calls now explicitly throw strongly-typed `HardwareException`s (like `HardwareUnsupportedException`) instead of silently failing or returning `false` or `null`.
* **Deep Web API Integration:** Expanded the `nexora_sdk_web` package with rich integrations:
  * Upgraded `startLocation()` to use `navigator.geolocation.watchPosition()` for true streaming.
  * Implemented real `getDeviceInfo()` parsing via `navigator.userAgent`.
  * Hooked into `navigator.connection` for `getConnectivityInfo()`.
  * Implemented `pasteText()` using `navigator.clipboard`.
  * Integrated `window.navigator.getBattery()`.
* **Zero Warnings:** Executed an exhaustive linting pass on all Dart code. The entire mono-repo (all 6 packages) now proudly scores 0 warnings and 0 errors under the `very_good_analysis` linter, with 100% public member documentation coverage.


## 3.2.1

* **Smart Sync**: Built offline telemetry database/queueing on native Android and iOS, featuring rolled file rotation, internet connectivity detection, and automated background upload with exponential retry backoff.
* **NFC Module**: Implemented Near Field Communication (NFC) scan and NDEF tag writer on both platforms with foreground dispatch on Android and reader sessions on iOS.
* **Secure Storage**: Developed AES-256 encrypted file and JSON storage using Android KeyStore and iOS Keychain.
* **Background Isolates**: Added `BackgroundIsolateWrapper` to spawn low-priority background isolates for heavy CPU/computation operations.
* **Integration & Testing**: Integrated all native and Dart parts of Phase 5, passing all 78 unit tests successfully.

* **Stability & Guards**: Added `isRunning` checks to protect state-sensitive modules (Camera, Bluetooth) and wrapped native methods to throw clean typed `HardwareException`s.
* **GATT Enhancements**: Implemented BLE device disconnect and GATT characteristic read APIs.
* **Developer Experience**: Added `NexoraSdk.initialize` pre-warming, value equality/hashcodes on models, `copyWith` on options/configs, and readable `toString` overrides.
* **Advanced Features**: Added `migrateStorage` migration engine, stream helpers (`throttle`, `debounce`, `bufferCount`), and retry helper (`withRetry`) with backoff.
* **Testing Gaps**: Expanded test coverage with comprehensive module-specific tests and serialization tests, resulting in a 72-test suite passing at 100%.

## 3.2.0

* Introduced `utility` module with EcoMode power-saver and proactive Thermal Safeguard crash prevention.
* Built custom native option builders for Camera, Sensors, Bluetooth, Location, Biometrics, and Haptic feedback.
* Refactored eager module initializers into lazy cached properties for zero startup overhead.
* Designed advanced Speaker & Microphone controllers with input gain and output routing.
* Fully verified with 21 unit tests.

## 3.1.2

* Aligned local Android, iOS, example, and Dart metadata with the published Swift Package Manager-enabled release.
* Refreshed example dependency locks for the current plugin version.

## 3.1.1

* Added iOS Swift Package Manager support for Flutter's platform scoring and SPM-enabled projects.
* Updated CocoaPods source paths to share the Swift Package Manager source layout.

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
