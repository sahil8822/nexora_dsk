import Flutter
import CoreMotion
import QuartzCore

@_silgen_name("update_imu_filter")
func update_imu_filter(_ ax: Double, _ ay: Double, _ az: Double, _ gx: Double, _ gy: Double, _ gz: Double, _ dt: Double)

/// High-performance Sensor Manager for iOS using CoreMotion.
/// Features throttling and battery-efficient activation.
public class HardwareSensorManager {
    private let motionManager = CMMotionManager()
    private var eventSink: FlutterEventSink?
    private var sensorTypes: [String] = ["accelerometer", "gyroscope"]
    private var updateIntervalSeconds: Double?
    private var useDeviceMotionFusion = true

    private var lastAccX: Double = 0.0
    private var lastAccY: Double = 0.0
    private var lastAccZ: Double = 0.0
    private var lastGyroX: Double = 0.0
    private var lastGyroY: Double = 0.0
    private var lastGyroZ: Double = 0.0
    private var lastTimestamp: Double = 0.0
    
    func setEventSink(_ sink: FlutterEventSink?) {
        self.eventSink = sink
        if !motionManager.isAccelerometerAvailable && sink != nil {
             sink?(FlutterError(code: "HARDWARE_UNAVAILABLE", message: "Accelerometer not available on this device", details: nil))
        }
    }

    func configure(options: [String: Any]) {
        sensorTypes = options["sensorTypes"] as? [String] ?? ["accelerometer", "gyroscope"]
        updateIntervalSeconds = options["updateIntervalSeconds"] as? Double
        useDeviceMotionFusion = options["useDeviceMotionFusion"] as? Bool ?? true
    }
    
    private func runFilterUpdate() {
        let now = CACurrentMediaTime()
        if lastTimestamp > 0 {
            let dt = now - lastTimestamp
            if dt > 0 && dt < 1.0 {
                update_imu_filter(
                    lastAccX, lastAccY, lastAccZ,
                    lastGyroX, lastGyroY, lastGyroZ,
                    dt
                )
            }
        }
        lastTimestamp = now
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
                self.lastAccX = accelData.acceleration.x * 9.81
                self.lastAccY = accelData.acceleration.y * 9.81
                self.lastAccZ = accelData.acceleration.z * 9.81
                self.runFilterUpdate()
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
                self.lastGyroX = gyroData.rotationRate.x
                self.lastGyroY = gyroData.rotationRate.y
                self.lastGyroZ = gyroData.rotationRate.z
                self.runFilterUpdate()
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
