import CoreLocation
import Flutter

/**
 * iOS Location Manager with Native Geofencing.
 */
public class HardwareLocationManager: NSObject, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager()
    private var eventSink: FlutterEventSink?

    public override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.allowsBackgroundLocationUpdates = true
    }

    public func setEventSink(_ sink: FlutterEventSink?) { self.eventSink = sink }

    public func startUpdates() {
        locationManager.startUpdatingLocation()
    }

    public func stopUpdates() {
        locationManager.stopUpdatingLocation()
    }

    public func addGeofence(id: String, lat: Double, lon: Double, radius: Double) {
        let center = CLLocationCoordinate2D(latitude: lat, longitude: lon)
        let region = CLCircularRegion(center: center, radius: radius, identifier: id)
        region.notifyOnEntry = true
        region.notifyOnExit = true
        locationManager.startMonitoring(for: region)
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
