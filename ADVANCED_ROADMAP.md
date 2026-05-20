# Nexora SDK Advanced Roadmap

This roadmap keeps the plugin honest: every advanced feature should be either
implemented, explicitly experimental, or reported as unsupported at runtime.

## 1. Native Production Backends

- [x] Add video recording on Android with `MediaRecorder` or CameraX VideoCapture. (Completed in v3.2.1)
- [x] Add video recording on iOS with `AVCaptureMovieFileOutput`. (Completed in v3.2.1)
- [x] Add camera shader filters using Android GPU/CameraX effects and iOS Core Image. (Completed in v3.2.1)
- [x] Add Smart Sync with offline queueing, file rollovers, retries, backoff, and upload status events. (Completed in v3.2.1)
- [x] Add BLE L2CAP on Android and iOS. (Completed in v3.2.1)
- [x] Add dead reckoning with a documented sensor-fusion model (Kalman filter) and confidence score. (Completed in v3.2.1)
- [x] Add NFC (NDEF read/write) support on Android and iOS. (Completed in v3.2.1)
- [x] Add Secure Storage (AES-256 file encryption with KeyStore/Keychain) on Android and iOS. (Completed in v3.2.1)

## 2. Web Backends

- Add optional camera preview via `navigator.mediaDevices.getUserMedia`.
- Add optional microphone capture through Web Audio APIs.
- Add optional geolocation through browser geolocation APIs.
- Add clipboard paste through the async Clipboard API when browser permissions allow it.
- Keep Web Bluetooth behind capability checks because support is browser-dependent.

## 3. Desktop Backends

- Split desktop from Dart-only fallback into federated native plugins when needed.
- macOS: AVFoundation camera/audio, CoreBluetooth, CoreLocation, LocalAuthentication.
- Windows: Media Foundation camera/audio, WinRT Bluetooth, Windows Hello where possible.
- Linux: PipeWire/V4L2 camera/audio and BlueZ Bluetooth support where installed.

## 4. Developer Experience

- Keep `featureMatrix` as the source of truth for platform support.
- Add integration tests per module instead of only a single broad smoke test.
- Add native Android unit/instrumentation tests for permissions, storage, camera startup, and BLE guards.
- Add iOS/macOS CI build checks with current Xcode images.
- Add examples for each module with graceful unsupported UI states.

## 5. Release Quality

- Bump minor version when public API or platform support changes.
- Bump patch version for build fixes, docs, and fallback behavior fixes.
- Run before release:
  - `flutter analyze`
  - `flutter test`
  - `flutter build apk --debug` from `example`
  - `flutter build web --wasm` from `example`
  - `flutter build macos` from `example`
  - `flutter pub publish --dry-run`
