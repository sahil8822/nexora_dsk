# Modular Hardware SDK Architecture (High-Performance Layered)

This document describes the high-level architecture of the modular hardware SDK.

## 1. System Architecture
The SDK follows a **Layered & Modular Messaging** architecture designed for low latency and high throughput.

### Diagram
```mermaid
graph TD
    App[Flutter App] --> API[Modular API Layer]
    API --> Modules[Camera | BLE | GPS | WiFi | Sensors]
    
    subgraph Bridge Layer
        Modules -- BasicMessageChannel --> BinaryBridge[Binary Message Channel]
        Modules -- EventChannel --> StreamingBridge[Stream Dispatcher]
        Modules -- MethodChannel --> ControlBridge[Command Dispatcher]
    end

    subgraph Native iOS (Swift)
        StreamingBridge --> iOSManagers[iOS Subsystem Managers]
        BinaryBridge --> iOSMetal[Metal / CoreMedia Processor]
        iOSManagers --> CoreOS[CoreBluetooth | CoreLocation | AVFoundation]
    end

    subgraph Native Android (Kotlin)
        StreamingBridge --> AndroidManagers[Android Subsystem Managers]
        BinaryBridge --> AndroidNDK[C++ NDK Pixel Processor]
        AndroidManagers --> AndroidOS[Camera2 | BLE | FusedLocation]
    end
```

## 2. Component Design

### A. Modular Isolation
Each hardware component (Camera, Bluetooth, GPS) is an independent module with its own:
- **Interface**: Platform-specific implementation selection.
- **Manager**: Native handling and queuing.
- **Channel**: Dedicated communication path.

### B. High-Performance Bridge (`BasicMessageChannel`)
Used for **Camera Frame Streaming**. Instead of JSON-like maps (MethodChannel), raw `Uint8List` (Binary) is sent across the bridge to avoid serialization overhead.

### C. Background execution
- **Android**: Implements a `Foreground Service` to maintain active scanning/tracking when the UI is detached.
- **iOS**: Uses `Background Modes` (Location, BLE-Peripheral) enabled in the Capability settings.

### D. Buffering & Throttling
- **Batching**: GPS coordinates are buffered and sent in batches every 500ms to reduce bridge traffic.
- **Throttling**: High-frequency sensors (Gyroscope) are throttled to 60Hz.

## 3. Advanced C++/Native Layer
- **Android NDK**: Handled via JNI to perform zero-copy image manipulation.
- **iOS Bridge**: Objective-C++ bridging for SIMD/Metal optimization.
