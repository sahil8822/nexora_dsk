import Foundation
import CoreBluetooth

class HardwareBluetoothManager: NSObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    private var centralManager: CBCentralManager!
    private var discoveredPeripherals = [CBPeripheral]()
    
    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    func startScan() {
        if centralManager.state == .poweredOn {
            centralManager.scanForPeripherals(withServices: nil, options: nil)
        }
    }
    
    func stopScan() {
        centralManager.stopScan()
    }
    
    func connect(deviceId: String) {
        if let peripheral = discoveredPeripherals.first(where: { $0.identifier.uuidString == deviceId }) {
            centralManager.connect(peripheral, options: nil)
        }
    }
    
    func disconnect(deviceId: String) {
        if let peripheral = discoveredPeripherals.first(where: { $0.identifier.uuidString == deviceId }) {
            centralManager.cancelPeripheralConnection(peripheral)
        }
    }
    
    func getConnectedDevices() -> [String] {
        return centralManager.retrieveConnectedPeripherals(withServices: []).map { $0.identifier.uuidString }
    }
    
    func sendData(deviceId: String, data: Data) -> Bool {
        // Implementation for writing to GATT characteristics
        return false
    }
    
    // MARK: - CBCentralManagerDelegate
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        // Handle state changes
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        if !discoveredPeripherals.contains(where: { $0.identifier == peripheral.identifier }) {
            discoveredPeripherals.append(peripheral)
        }
    }
}
