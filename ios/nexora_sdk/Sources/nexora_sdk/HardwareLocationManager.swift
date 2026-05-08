import CoreLocation
import Flutter

/**
 * iOS Location Manager with Native Geofencing.
 */
public class HardwareLocationManager: NSObject, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager()
    private var eventSink: FlutterEventSink?
    private var backgroundEnabled = false

    public override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.allowsBackgroundLocationUpdates = false
    }

    public func setEventSink(_ sink: FlutterEventSink?) { self.eventSink = sink }

    public func setBackgroundEnabled(_ enabled: Bool) {
        backgroundEnabled = enabled
        locationManager.allowsBackgroundLocationUpdates = enabled
    }

    public func startUpdates() {
        locationManager.startUpdatingLocation()
    }

    public func stopUpdates() {
        locationManager.stopUpdatingLocation()
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

    public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
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

    public func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        // Handle geofence entry
    }
}
