# Nexora SDK Example Application

This example application demonstrates how to use the `nexora_sdk` package to interact with device hardware APIs (Camera, Audio FFT, GPS, Storage, Telemetry, and Pro features) under a unified, cross-platform interface.

## Features Demonstrated

- **Vision AI Dashboard:** Run real-time face detection, barcode scanning, and capture photos using the native camera.
- **Audio FFT Visualizer:** Capture microphone audio stream and visualize it via real-time Fast Fourier Transform (FFT) bars.
- **Geospatial Tracking:** Stream GPS coordinate updates (latitude, longitude, altitude).
- **Device Storage & Sandboxing:** Perform read/write file I/O operations, list files, and view available disk space.
- **Diagnostics & Telemetry Logging:** Collect a system diagnostics snapshot or toggle periodic background CSV telemetry logging.
- **Native Pro Utilities:** Share text, open URLs, copy/paste from the system clipboard, and launch app settings.
- **Advanced API Helpers:** Run storage migrations and demonstrate stream throttling and retry policies.

## How to Run

1. Make sure you have a Flutter environment configured on your machine.
2. From the root directory of the plugin, navigate to the example project:
   ```bash
   cd example
   ```
3. Fetch dependencies:
   ```bash
   flutter pub get
   ```
4. Run the app on a connected device or simulator:
   ```bash
   flutter run
   ```

*Note: For full hardware features like camera preview, audio capture, and location tracking, running on a physical Android or iOS device is recommended.*
