import Flutter
import CoreMotion

/// High-performance Sensor Manager for iOS using CoreMotion.
/// Features throttling and battery-efficient activation.
public class HardwareSensorManager {
    private let motionManager = CMMotionManager()
    private var eventSink: FlutterEventSink?
    private var sensorTypes: [String] = ["accelerometer"]
    private var updateIntervalSeconds: Double?
    private var useDeviceMotionFusion = true
    
    func setEventSink(_ sink: FlutterEventSink?) {
        self.eventSink = sink
        if !motionManager.isAccelerometerAvailable && sink != nil {
             sink?(FlutterError(code: "HARDWARE_UNAVAILABLE", message: "Accelerometer not available on this device", details: nil))
        }
    }

    func configure(options: [String: Any]) {
        sensorTypes = options["sensorTypes"] as? [String] ?? ["accelerometer"]
        updateIntervalSeconds = options["updateIntervalSeconds"] as? Double
        useDeviceMotionFusion = options["useDeviceMotionFusion"] as? Bool ?? true
    }
    
    func start(frequencyHz: Int = 60) {
        let interval = updateIntervalSeconds ?? (1.0 / Double(frequencyHz))
        if useDeviceMotionFusion && sensorTypes.contains("deviceMotion") &&
            motionManager.isDeviceMotionAvailable {
            motionManager.deviceMotionUpdateInterval = interval
            motionManager.startDeviceMotionUpdates(to: .main) { [weak self] data, _ in
                guard let self = self, let data = data else { return }
                self.emit(
                    sensorType: "deviceMotion",
                    x: data.userAcceleration.x,
                    y: data.userAcceleration.y,
                    z: data.userAcceleration.z
                )
            }
            return
        }

        if sensorTypes.contains("accelerometer") && motionManager.isAccelerometerAvailable {
            motionManager.accelerometerUpdateInterval = interval
            motionManager.startAccelerometerUpdates(to: .main) { [weak self] data, _ in
                guard let self = self, let accelData = data else { return }
                self.emit(
                    sensorType: "accelerometer",
                    x: accelData.acceleration.x,
                    y: accelData.acceleration.y,
                    z: accelData.acceleration.z
                )
            }
        }

        if sensorTypes.contains("gyroscope") && motionManager.isGyroAvailable {
            motionManager.gyroUpdateInterval = interval
            motionManager.startGyroUpdates(to: .main) { [weak self] data, _ in
                guard let self = self, let gyroData = data else { return }
                self.emit(
                    sensorType: "gyroscope",
                    x: gyroData.rotationRate.x,
                    y: gyroData.rotationRate.y,
                    z: gyroData.rotationRate.z
                )
            }
        }
    }

    private func emit(sensorType: String, x: Double, y: Double, z: Double) {
        let timestamp = Int64(Date().timeIntervalSince1970 * 1000)
        let result: [String: Any] = [
            "module": "sensor",
            "type": "data",
            "timestamp": timestamp,
            "data": [
                "sensorType": sensorType,
                "x": x,
                "y": y,
                "z": z
            ]
        ]
        eventSink?(result)
    }
    
    func stop() {
        motionManager.stopAccelerometerUpdates()
        motionManager.stopGyroUpdates()
        motionManager.stopDeviceMotionUpdates()
    }
}
