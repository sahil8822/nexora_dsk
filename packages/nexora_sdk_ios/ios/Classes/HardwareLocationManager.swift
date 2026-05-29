import CoreLocation
import Flutter
import CoreMotion

/**
 * iOS Location Manager with Native Geofencing and Kalman-filtered Dead Reckoning.
 */
public class HardwareLocationManager: NSObject, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager()
    private var eventSink: FlutterEventSink?
    private var backgroundEnabled = false

    // Kalman Filter & Dead Reckoning
    private var isDeadReckoningEnabled = false
    private let motionManager = CMMotionManager()
    private var lastSensorTimestamp: TimeInterval = 0
    private var referenceLat = 0.0
    private var referenceLon = 0.0
    private var referenceAlt = 0.0
    private var referenceAccuracy = 0.0
    private var referenceSpeed = 0.0
    private var lastGpsTimestamp = Date().timeIntervalSince1970

    private var stateX = [Double](repeating: 0.0, count: 4) // x, y, vx, vy
    private var covP = [[Double]](repeating: [Double](repeating: 0.0, count: 4), count: 4)
    private var headingYaw = 0.0

    public override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.allowsBackgroundLocationUpdates = false
    }

    public func setEventSink(_ sink: FlutterEventSink?) { self.eventSink = sink }

    public func configure(options: [String: Any]) {
        locationManager.allowsBackgroundLocationUpdates =
            options["allowsBackgroundLocationUpdates"] as? Bool ?? backgroundEnabled
        if #available(iOS 11.0, *) {
            locationManager.showsBackgroundLocationIndicator =
                options["showsBackgroundLocationIndicator"] as? Bool ?? false
        }
        locationManager.pausesLocationUpdatesAutomatically =
            options["pausesLocationUpdatesAutomatically"] as? Bool ?? true
        locationManager.activityType = activityType(options["activityType"] as? String)
    }

    public func setBackgroundEnabled(_ enabled: Bool) {
        backgroundEnabled = enabled
        locationManager.allowsBackgroundLocationUpdates = enabled
    }

    public func startUpdates() {
        locationManager.startUpdatingLocation()
    }

    public func stopUpdates() {
        locationManager.stopUpdatingLocation()
        enableDeadReckoning(false)
    }

    public func addGeofence(id: String, lat: Double, lon: Double, radius: Double) -> Bool {
        guard backgroundEnabled else { return false }
        let center = CLLocationCoordinate2D(latitude: lat, longitude: lon)
        let region = CLCircularRegion(center: center, radius: radius, identifier: id)
        region.notifyOnEntry = true
        region.notifyOnExit = true
        locationManager.startMonitoring(for: region)
        return true
    }

    private func activityType(_ value: String?) -> CLActivityType {
        switch value {
        case "automotiveNavigation": return .automotiveNavigation
        case "fitness": return .fitness
        case "otherNavigation": return .otherNavigation
        case "airborne":
            if #available(iOS 12.0, *) { return .airborne }
            return .other
        default: return .other
        }
    }

    public func enableDeadReckoning(_ enabled: Bool) {
        if isDeadReckoningEnabled == enabled { return }
        isDeadReckoningEnabled = enabled

        if enabled {
            lastSensorTimestamp = 0
            referenceLat = 0.0
            referenceLon = 0.0
            lastGpsTimestamp = Date().timeIntervalSince1970
            
            motionManager.deviceMotionUpdateInterval = 1.0 / 60.0
            motionManager.startDeviceMotionUpdates(to: .main) { [weak self] (motion, error) in
                guard let self = self, let motion = motion, error == nil else { return }
                
                let timestamp = motion.timestamp
                if self.lastSensorTimestamp == 0 {
                    self.lastSensorTimestamp = timestamp
                    return
                }
                let dt = timestamp - self.lastSensorTimestamp
                self.lastSensorTimestamp = timestamp
                
                let gyroZ = motion.rotationRate.z
                self.headingYaw += gyroZ * dt
                
                let axDevice = motion.userAcceleration.x * 9.81
                let ayDevice = motion.userAcceleration.y * 9.81
                
                let axWorld = axDevice * cos(self.headingYaw) - ayDevice * sin(self.headingYaw)
                let ayWorld = axDevice * sin(self.headingYaw) + ayDevice * cos(self.headingYaw)
                
                self.predict(dt: dt, ax: axWorld, ay: ayWorld)
                
                let timeSinceLastGps = Date().timeIntervalSince1970 - self.lastGpsTimestamp
                if timeSinceLastGps > 2.0 {
                    let newLat = self.referenceLat + (self.stateX[1] / 111111.0)
                    let newLon = self.referenceLon + (self.stateX[0] / (111111.0 * cos(self.referenceLat * .pi / 180.0)))
                    self.sendEstimatedLocationEvent(lat: newLat, lon: newLon, vx: self.stateX[2], vy: self.stateX[3])
                }
            }
        } else {
            motionManager.stopDeviceMotionUpdates()
        }
    }

    private func initKalman(lat: Double, lon: Double, speed: Double) {
        referenceLat = lat
        referenceLon = lon
        stateX[0] = 0.0
        stateX[1] = 0.0
        stateX[2] = speed * sin(headingYaw)
        stateX[3] = speed * cos(headingYaw)
        
        for i in 0..<4 {
            for j in 0..<4 {
                covP[i][j] = (i == j) ? 1.0 : 0.0
            }
        }
    }

    private func predict(dt: Double, ax: Double, ay: Double) {
        stateX[0] += stateX[2] * dt + 0.5 * ax * dt * dt
        stateX[1] += stateX[3] * dt + 0.5 * ay * dt * dt
        stateX[2] += ax * dt
        stateX[3] += ay * dt
        
        let qVal = 0.1
        var Q = [[Double]](repeating: [Double](repeating: 0.0, count: 4), count: 4)
        Q[0][0] = qVal * dt * dt * dt * dt / 4.0
        Q[1][1] = qVal * dt * dt * dt * dt / 4.0
        Q[2][2] = qVal * dt * dt
        Q[3][3] = qVal * dt * dt
        
        var nextP = [[Double]](repeating: [Double](repeating: 0.0, count: 4), count: 4)
        nextP[0][0] = covP[0][0] + 2.0 * dt * covP[0][2] + dt * dt * covP[2][2] + Q[0][0]
        nextP[0][1] = covP[0][1] + dt * covP[0][3] + dt * covP[2][1] + dt * dt * covP[2][3]
        nextP[0][2] = covP[0][2] + dt * covP[2][2]
        nextP[0][3] = covP[0][3] + dt * covP[2][3]
        
        nextP[1][0] = covP[1][0] + dt * covP[1][2] + dt * covP[3][0] + dt * dt * covP[3][2]
        nextP[1][1] = covP[1][1] + 2.0 * dt * covP[1][3] + dt * dt * covP[3][3] + Q[1][1]
        nextP[1][2] = covP[1][2] + dt * covP[3][2]
        nextP[1][3] = covP[1][3] + dt * covP[3][3]
        
        nextP[2][0] = covP[2][0] + dt * covP[2][2]
        nextP[2][1] = covP[2][1] + dt * covP[2][3]
        nextP[2][2] = covP[2][2] + Q[2][2]
        nextP[2][3] = covP[2][3]
        
        nextP[3][0] = covP[3][0] + dt * covP[3][2]
        nextP[3][1] = covP[3][1] + dt * covP[3][3]
        nextP[3][2] = covP[3][2]
        nextP[3][3] = covP[3][3] + Q[3][3]
        
        covP = nextP
    }

    private func updateGps(gpsLat: Double, gpsLon: Double, gpsAccuracy: Double) {
        lastGpsTimestamp = Date().timeIntervalSince1970
        let zx = (gpsLon - referenceLon) * 111111.0 * cos(referenceLat * .pi / 180.0)
        let zy = (gpsLat - referenceLat) * 111111.0
        
        let rVal = max(gpsAccuracy * gpsAccuracy, 1.0)
        let s00 = covP[0][0] + rVal
        let s01 = covP[0][1]
        let s10 = covP[1][0]
        let s11 = covP[1][1] + rVal
        
        let det = s00 * s11 - s01 * s10
        if abs(det) < 1e-9 { return }
        let invS00 = s11 / det
        let invS01 = -s01 / det
        let invS10 = -s10 / det
        let invS11 = s00 / det
        
        var K = [[Double]](repeating: [Double](repeating: 0.0, count: 2), count: 4)
        for i in 0..<4 {
            K[i][0] = covP[i][0] * invS00 + covP[i][1] * invS10
            K[i][1] = covP[i][0] * invS01 + covP[i][1] * invS11
        }
        
        let y0 = zx - stateX[0]
        let y1 = zy - stateX[1]
        
        stateX[0] += K[0][0] * y0 + K[0][1] * y1
        stateX[1] += K[1][0] * y0 + K[1][1] * y1
        stateX[2] += K[2][0] * y0 + K[2][1] * y1
        stateX[3] += K[3][0] * y0 + K[3][1] * y1
        
        var nextP = [[Double]](repeating: [Double](repeating: 0.0, count: 4), count: 4)
        for i in 0..<4 {
            for j in 0..<4 {
                var sum = covP[i][j]
                sum -= K[i][0] * covP[0][j]
                sum -= K[i][1] * covP[1][j]
                nextP[i][j] = sum
            }
        }
        covP = nextP
    }

    public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        if isDeadReckoningEnabled {
            if referenceLat == 0.0 && referenceLon == 0.0 {
                initKalman(lat: location.coordinate.latitude, lon: location.coordinate.longitude, speed: location.speed)
            } else {
                updateGps(gpsLat: location.coordinate.latitude, gpsLon: location.coordinate.longitude, gpsAccuracy: location.horizontalAccuracy)
            }
            referenceAlt = location.altitude
            referenceAccuracy = location.horizontalAccuracy
            referenceSpeed = location.speed
        }
        let data: [String: Any] = [
            "module": "gps", "type": "data",
            "data": [
                "latitude": location.coordinate.latitude,
                "longitude": location.coordinate.longitude,
                "altitude": location.altitude,
                "accuracy": location.horizontalAccuracy,
                "speed": location.speed
            ]
        ]
        DispatchQueue.main.async { self.eventSink?(data) }
    }

    private func sendEstimatedLocationEvent(lat: Double, lon: Double, vx: Double, vy: Double) {
        let estimatedSpeed = sqrt(vx * vx + vy * vy)
        let data: [String: Any] = [
            "module": "gps", "type": "data",
            "data": [
                "latitude": lat,
                "longitude": lon,
                "altitude": referenceAlt,
                "accuracy": 999.0,
                "speed": estimatedSpeed,
                "isDeadReckoning": true
            ]
        ]
        DispatchQueue.main.async { self.eventSink?(data) }
    }

    public func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        // Handle geofence entry
    }
}
