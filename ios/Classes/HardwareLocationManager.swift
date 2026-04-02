import CoreLocation
import Flutter

/**
 * CoreLocation management for high-accuracy GPS tracking.
 * Configured for real-time streaming and battery efficiency.
 */
public class HardwareLocationManager: NSObject, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager()
    private var eventSink: FlutterEventSink?
    
    public override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 1.0 // 1 meter
    }
    
    public func setEventSink(_ sink: FlutterEventSink?) {
        self.eventSink = sink
    }
    
    public func startUpdates() {
        locationManager.requestAlwaysAuthorization()
        locationManager.startUpdatingLocation()
    }
    
    public func stopUpdates() {
        locationManager.stopUpdatingLocation()
    }
    
    public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        let gpsData: [String: Any] = [
            "type": "gps",
            "timestamp": Int64(Date().timeIntervalSince1970 * 1000),
            "data": [
                "latitude": location.coordinate.latitude,
                "longitude": location.coordinate.longitude,
                "altitude": location.altitude,
                "accuracy": location.horizontalAccuracy,
                "speed": location.speed
            ]
        ]
        
        DispatchQueue.main.async {
            self.eventSink?(gpsData)
        }
    }
}
