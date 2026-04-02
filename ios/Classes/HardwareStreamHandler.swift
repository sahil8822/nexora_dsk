import Flutter
import UIKit

/**
 * Unified Stream Hub for all iOS hardware subsystems.
 * Directs global event delivery and manages native lifecycle connections.
 */
public class HardwareStreamHandler: NSObject, FlutterStreamHandler {
    private var eventSink: FlutterEventSink?
    
    // Subsystems
    private let camera: HardwareCameraManager
    private let bluetooth: HardwareBluetoothManager
    private let location: HardwareLocationManager
    
    public init(camera: HardwareCameraManager, bluetooth: HardwareBluetoothManager, location: HardwareLocationManager) {
        self.camera = camera
        self.bluetooth = bluetooth
        self.location = location
    }
    
    public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        self.eventSink = events
        camera.setEventSink(events)
        bluetooth.setEventSink(events)
        location.setEventSink(events)
        return nil
    }
    
    public func onCancel(withArguments arguments: Any?) -> FlutterError? {
        self.eventSink = nil
        camera.setEventSink(nil)
        bluetooth.setEventSink(nil)
        location.setEventSink(nil)
        return nil
    }
}
