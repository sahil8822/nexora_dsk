import CoreBluetooth
import Flutter

/**
 * CoreBluetooth implementation for iOS.
 * Background scanning and device discovery.
 */
public class HardwareBluetoothManager: NSObject, CBCentralManagerDelegate {
    private var centralManager: CBCentralManager?
    private var eventSink: FlutterEventSink?
    
    public override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    public func setEventSink(_ sink: FlutterEventSink?) {
        self.eventSink = sink
    }
    
    public func startScan() {
        centralManager?.scanForPeripherals(withServices: nil, options: nil)
    }
    
    public func stopScan() {
        centralManager?.stopScan()
    }
    
    public func centralManagerDidUpdateState(_ central: CBCentralManager) {
        // Handle power states
    }
    
    public func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        let deviceData: [String: Any] = [
            "type": "bluetooth",
            "timestamp": Int64(Date().timeIntervalSince1970 * 1000),
            "data": [
                "id": peripheral.identifier.uuidString,
                "name": peripheral.name ?? "Unknown",
                "rssi": RSSI.intValue
            ]
        ]
        
        DispatchQueue.main.async {
            self.eventSink?(deviceData)
        }
    }
}
