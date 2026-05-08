# Nexora SDK Architecture

This document describes the high-level architecture of the lightweight native hardware SDK.

## 1. System Architecture
The SDK follows a layered modular architecture designed for low latency, clear permission boundaries, and small publish size.

### Diagram
```mermaid
graph TD
    App[Flutter App] --> API[Modular API Layer]
    API --> Modules[Camera | BLE | GPS | WiFi | Sensors]
    
    subgraph Bridge Layer
        Modules -- EventChannel --> StreamingBridge[Stream Dispatcher]
        Modules -- MethodChannel --> ControlBridge[Command Dispatcher]
    end

    subgraph Native iOS (Swift)
        StreamingBridge --> iOSManagers[iOS Subsystem Managers]
        iOSManagers --> CoreOS[CoreBluetooth | CoreLocation | AVFoundation]
    end

    subgraph Native Android (Kotlin)
        StreamingBridge --> AndroidManagers[Android Subsystem Managers]
        AndroidManagers --> AndroidOS[Camera2 | BLE | LocationManager | AudioRecord]
    end

    subgraph Web and Desktop Fallbacks (Dart)
        API --> Fallbacks[Safe Unsupported Hardware Responses | Storage Fallbacks]
    end
```

## 2. Component Design

### A. Modular Isolation
Each hardware component (Camera, Bluetooth, GPS) is an independent module with its own:
- **Interface**: Platform-specific implementation selection.
- **Manager**: Native handling and queuing.
- **Channel**: Shared command and event dispatch with module tags.

### B. Lightweight Streaming
Camera preview uses native textures instead of raw frame copies. Audio raw bytes are disabled by default, FFT events are throttled, and camera vision results are sampled to keep bridge traffic low.

### C. Native permissions
The plugin requests Android and iOS runtime permissions directly without depending on `permission_handler`. Host apps still own manifest entries, iOS usage descriptions, and any required background disclosures.

### D. Web and desktop fallbacks
Web, macOS, Windows, and Linux are registered with Dart-only implementations. Hardware APIs that need native platform integrations return safe unsupported values instead of throwing missing-plugin errors. Desktop storage writes local files; web storage uses an in-memory fallback.

### E. Background location opt-in
Background geofencing is disabled by default. Apps must explicitly enable it and configure the platform background permission/mode before adding geofences that need background execution.

## 3. Performance choices
- **Native textures** keep camera preview fast and memory efficient.
- **Throttled vision and audio events** reduce Dart bridge pressure.
- **App-private storage only** avoids broad storage permissions.
- **Lifecycle cleanup** stops native hardware managers when the plugin detaches.
