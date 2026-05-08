import Flutter

/**
 * Unified stream handler for iOS hardware events.
 */
public class HardwareStreamHandler: NSObject, FlutterStreamHandler {
    private let camera: HardwareCameraManager
    private let bluetooth: HardwareBluetoothManager
    private let location: HardwareLocationManager
    private let sensor: HardwareSensorManager
    private let audio: HardwareAudioManager

    init(camera: HardwareCameraManager, bluetooth: HardwareBluetoothManager, location: HardwareLocationManager, sensor: HardwareSensorManager, audio: HardwareAudioManager) {
        self.camera = camera
        self.bluetooth = bluetooth
        self.location = location
        self.sensor = sensor
        self.audio = audio
    }

    public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        camera.setEventSink(events)
        bluetooth.setEventSink(events)
        location.setEventSink(events)
        sensor.setEventSink(events)
        audio.setEventSink(events)
        return nil
    }

    public func onCancel(withArguments arguments: Any?) -> FlutterError? {
        camera.setEventSink(nil)
        bluetooth.setEventSink(nil)
        location.setEventSink(nil)
        sensor.setEventSink(nil)
        audio.setEventSink(nil)
        return nil
    }
}
