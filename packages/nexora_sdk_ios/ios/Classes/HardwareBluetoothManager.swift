import CoreBluetooth
import Flutter

/**
 * CoreBluetooth implementation for iOS.
 * Supports Nexora Pro: GATT Service Discovery and Characteristic Read/Write operations.
 */
public class HardwareBluetoothManager: NSObject, CBCentralManagerDelegate {
    private var centralManager: CBCentralManager?
    private var eventSink: FlutterEventSink?
    private var connectedPeripheral: CBPeripheral?
    private var serviceDiscoveryCallback: (([String]) -> Void)?
    private var readCharacteristicCallback: ((Data?) -> Void)?
    private var pendingServiceDiscoveries = 0
    
    public override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    public func setEventSink(_ sink: FlutterEventSink?) {
        self.eventSink = sink
    }
    
    public func isReady() -> Bool {
        return centralManager?.state == .poweredOn
    }

    public func startScan() -> Bool {
        guard isReady() else { return false }
        centralManager?.scanForPeripherals(withServices: nil, options: nil)
        return true
    }
    
    public func stopScan() -> Bool {
        centralManager?.stopScan()
        return true
    }

    public func connect(deviceId: String) -> Bool {
        guard isReady() else { return false }
        guard let uuid = UUID(uuidString: deviceId),
              let peripherals = centralManager?.retrievePeripherals(withIdentifiers: [uuid]),
              let peripheral = peripherals.first else { return false }
        
        self.connectedPeripheral = peripheral
        peripheral.delegate = self
        centralManager?.connect(peripheral, options: nil)
        return true
    }

    public func discoverServices(deviceId: String, callback: @escaping ([String]) -> Void) {
        guard let peripheral = connectedPeripheral, peripheral.identifier.uuidString == deviceId else {
            callback([])
            return
        }
        self.serviceDiscoveryCallback = callback
        peripheral.discoverServices(nil)
    }

    public func sendData(deviceId: String, serviceId: String, charId: String, data: Data) -> Bool {
        guard isReady() else { return false }
        guard let peripheral = connectedPeripheral, peripheral.identifier.uuidString == deviceId else { return false }
        
        guard let service = peripheral.services?.first(where: { $0.uuid.uuidString == serviceId }),
              let char = service.characteristics?.first(where: { $0.uuid.uuidString == charId }) else { return false }
        
        peripheral.writeValue(data, for: char, type: .withResponse)
        return true
    }

    public func readData(deviceId: String, serviceId: String, charId: String, callback: @escaping (Data?) -> Void) -> Bool {
        guard isReady() else { return false }
        guard let peripheral = connectedPeripheral, peripheral.identifier.uuidString == deviceId else { return false }
        
        guard let service = peripheral.services?.first(where: { $0.uuid.uuidString == serviceId }),
              let char = service.characteristics?.first(where: { $0.uuid.uuidString == charId }) else { return false }
        
        self.readCharacteristicCallback = callback
        peripheral.readValue(for: char)
        return true
    }

    public func disconnect() {
        if let peripheral = connectedPeripheral {
            centralManager?.cancelPeripheralConnection(peripheral)
        }
    }
    
    public func centralManagerDidUpdateState(_ central: CBCentralManager) {
        // Handle state
    }
    
    public func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        let deviceData: [String: Any] = [
            "module": "bluetooth",
            "type": "data",
            "data": [
                "id": peripheral.identifier.uuidString,
                "name": peripheral.name ?? "Unknown",
                "rssi": RSSI.intValue
            ]
        ]
        DispatchQueue.main.async { self.eventSink?(deviceData) }
    }

    public func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        sendBluetoothStatus(id: peripheral.identifier.uuidString, state: "connected")
    }

    public func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        sendBluetoothStatus(id: peripheral.identifier.uuidString, state: "disconnected")
        connectedPeripheral = nil
    }

    private func sendBluetoothStatus(id: String, state: String) {
        let statusData: [String: Any] = [
            "module": "bluetooth",
            "type": "status",
            "data": [
                "id": id,
                "state": state
            ]
        ]
        DispatchQueue.main.async { self.eventSink?(statusData) }
    }
}

extension HardwareBluetoothManager: CBPeripheralDelegate {
    public func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard error == nil, let services = peripheral.services, !services.isEmpty else {
            DispatchQueue.main.async {
                self.serviceDiscoveryCallback?([])
                self.serviceDiscoveryCallback = nil
            }
            return
        }
        pendingServiceDiscoveries = services.count
        for service in services {
            peripheral.discoverCharacteristics(nil, for: service)
        }
    }

    public func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        pendingServiceDiscoveries -= 1
        if pendingServiceDiscoveries <= 0 {
            let uuids = peripheral.services?.map { $0.uuid.uuidString } ?? []
            DispatchQueue.main.async {
                self.serviceDiscoveryCallback?(uuids)
                self.serviceDiscoveryCallback = nil
            }
        }
    }

    public func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        let data = (error == nil) ? characteristic.value : nil
        DispatchQueue.main.async {
            self.readCharacteristicCallback?(data)
            self.readCharacteristicCallback = nil
        }
    }
}
