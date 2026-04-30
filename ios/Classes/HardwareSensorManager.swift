import Flutter
import CoreMotion

/**
 * High-performance Sensor Manager for iOS using CoreMotion.
 * Features throttling and battery-efficient activation.
 */
public class HardwareSensorManager {
    private let motionManager = CMMotionManager()
    private var eventSink: FlutterEventSink?
    private let throttleInterval: TimeInterval = 1.0 / 60.0 // 60Hz
    
    func setEventSink(_ sink: FlutterEventSink?) {
        self.eventSink = sink
        if !motionManager.isAccelerometerAvailable && sink != nil {
             sink?(FlutterError(code: "HARDWARE_UNAVAILABLE", message: "Accelerometer not available on this device", details: nil))
        }
    }
    
    func start(frequencyHz: Int = 60) {
        guard motionManager.isAccelerometerAvailable else { return }
        
        let interval = 1.0 / Double(frequencyHz)
        motionManager.accelerometerUpdateInterval = interval
        motionManager.startAccelerometerUpdates(to: .main) { [weak self] (data, error) in
            guard let self = self, let accelData = data else { return }
            
            let timestamp = Int64(Date().timeIntervalSince1000 * 1000)
            let result: [String: Any] = [
                "type": "sensor",
                "timestamp": timestamp,
                "data": [
                    "x": accelData.acceleration.x,
                    "y": accelData.acceleration.y,
                    "z": accelData.acceleration.z
                ]
            ]
            
            self.eventSink?(result)
        }
    }
    
    func stop() {
        motionManager.stopAccelerometerUpdates()
    }
}

extension Date {
    var timeIntervalSince1000: TimeInterval {
        return self.timeIntervalSince1970
    }
}
