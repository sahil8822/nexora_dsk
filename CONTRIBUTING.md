# Contributing to Nexora SDK

Thank you for your interest in contributing to Nexora SDK! We welcome contributions of all forms—bug fixes, new features, model updates, and documentation improvements.

Follow this guide to get set up and start contributing.

---

## Code of Conduct

Please be respectful and professional in all communications and code reviews.

## Getting Started

### 1. Prerequisites
- **Flutter SDK**: Make sure you have the latest stable Flutter version installed.
- **Dart SDK**: Bundled with Flutter.
- **Android / iOS Toolchain**: Required if you plan to modify native platform code.

### 2. Setup the Workspace
Clone the repository and fetch dependencies:
```bash
git clone https://github.com/nexora/my_hardware_plugin.git
cd my_hardware_plugin
flutter pub get
```

---

## Development Guidelines

### 1. Architecture Overview
Nexora SDK uses a federated plugin architecture:
- `lib/nexora_sdk.dart`: Main library entry point exposing the unified singleton `NexoraSdk.instance`.
- `lib/nexora_sdk_platform_interface.dart`: Abstract interface extending `PlatformInterface`. All platform implementations must implement this contract.
- `lib/nexora_sdk_method_channel.dart`: Default MethodChannel implementation interacting with native Android/iOS engines.
- `lib/modules/`: High-level domain wrappers (e.g., `CameraModule`, `AudioModule`, `StorageModule`).

### 2. State-Sensitive Module Guards
When implementing or modifying a hardware module, ensure that any state-sensitive operations are protected by guard variables (e.g., `_isRunning`). Attempting to use a module that is not initialized or running should throw a `StateError` rather than failing cryptically at the native layer.
Example:
```dart
Future<bool> applyFilterShader(String shaderType) {
  if (!_isRunning) throw StateError('Camera is not running.');
  // ...
}
```

### 3. Data Models Requirements
All data models in Nexora SDK must:
- Override equality (`==`) and `hashCode` for proper value-based comparisons.
- Support `copyWith()` for immutable state derivation.
- Implement `toString()` to output meaningful diagnostic descriptions.
- Provide a resilient `.fromMap()`/`.toMap()` factory mapping.

### 4. Storage & Migrations
When persisting configuration schemas locally in `StorageModule`, utilize `migrateStorage(int oldVersion, int newVersion, MigrationCallback callback)` to ensure smooth transitions when file formats or structures evolve.

---

## Code Style

- Enforce standard Dart formatting:
  ```bash
  dart format .
  ```
- Make sure analyzer checks pass cleanly:
  ```bash
  flutter analyze
  ```

---

## Testing

Every contribution must be accompanied by comprehensive tests under the `test/` directory.

### 1. Mocking Platform Interface
Do NOT mock individual modules. Instead, extend `MockNexoraSdkPlatform` defined in `test/mocks/mock_platform.dart` and override the specific platform method responses to validate your module's logic.

### 2. Running Unit Tests
Execute the entire test suite locally:
```bash
flutter test
```
Verify that all unit tests pass (100% success rate) before submitting a Pull Request.

---

## Submitting Pull Requests

1. **Create a Branch**: Form a descriptive branch name (e.g., `feature/custom-ble-read` or `fix/camera-zoom-guard`).
2. **Commit Messages**: Write clear, imperative commits (e.g., "Add isRunning guard to CameraModule.takePhoto").
3. **Verify Everything**: Ensure `flutter analyze` and `flutter test` both pass cleanly.
4. **Open a PR**: Describe your changes, outline the testing done, and reference any corresponding issues.
