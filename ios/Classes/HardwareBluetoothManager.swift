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
    
    private var connectedPeripheral: CBPeripheral?

    public func setEventSink(_ sink: FlutterEventSink?) {
        self.eventSink = sink
    }
    
    public func startScan() {
        centralManager?.scanForPeripherals(withServices: nil, options: nil)
    }
    
    public func stopScan() {
        centralManager?.stopScan()
    }

    public func connect(deviceId: String) {
        guard let uuid = UUID(uuidString: deviceId),
              let peripherals = centralManager?.retrievePeripherals(withIdentifiers: [uuid]),
              let peripheral = peripherals.first else { return }
        
        self.connectedPeripheral = peripheral
        peripheral.delegate = self
        centralManager?.connect(peripheral, options: nil)
    }

    public func disconnect() {
        if let peripheral = connectedPeripheral {
            centralManager?.cancelPeripheralConnection(peripheral)
        }
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

    public func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        sendBluetoothStatus(id: peripheral.identifier.uuidString, state: "connected")
        peripheral.discoverServices(nil)
    }

    public func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        sendBluetoothStatus(id: peripheral.identifier.uuidString, state: "disconnected")
        connectedPeripheral = nil
    }

    private func sendBluetoothStatus(id: String, state: String) {
        let statusData: [String: Any] = [
            "type": "bluetooth_status",
            "timestamp": Int64(Date().timeIntervalSince1970 * 1000),
            "data": [
                "id": id,
                "state": state
            ]
        ]
        DispatchQueue.main.async {
            self.eventSink?(statusData)
        }
    }
}

extension HardwareBluetoothManager: CBPeripheralDelegate {
    // Add peripheral delegate methods if needed for characteristics
}
