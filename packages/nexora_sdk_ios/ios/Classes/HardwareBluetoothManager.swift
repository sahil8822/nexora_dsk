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
    private var restoreIdentifier: String?
    private var scanTimeoutMs: Int?
    private var allowDuplicates = false
    private var serviceFilters: [CBUUID]?
    private var nameFilter: String?

    // L2CAP state
    var l2capChannel: CBL2CAPChannel?
    var l2capInputStream: InputStream?
    var l2capPsm: Int?
    var l2capDeviceId: String?
    
    public override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    public func setEventSink(_ sink: FlutterEventSink?) {
        self.eventSink = sink
    }

    public func configure(options: [String: Any]) {
        restoreIdentifier = options["restoreIdentifier"] as? String
        scanTimeoutMs = options["scanTimeoutMs"] as? Int
        allowDuplicates = options["allowDuplicates"] as? Bool ?? false
        if let filters = options["filters"] as? [String: Any] {
            nameFilter = filters["deviceName"] as? String
            if let serviceUuid = filters["serviceUuid"] as? String {
                serviceFilters = [CBUUID(string: serviceUuid)]
            }
        }
        if let restoreIdentifier = restoreIdentifier {
            centralManager = CBCentralManager(
                delegate: self,
                queue: nil,
                options: [CBCentralManagerOptionRestoreIdentifierKey: restoreIdentifier]
            )
        }
    }
    
    public func isReady() -> Bool {
        return centralManager?.state == .poweredOn
    }

    public func startScan() -> Bool {
        guard isReady() else { return false }
        centralManager?.scanForPeripherals(
            withServices: serviceFilters,
            options: [CBCentralManagerScanOptionAllowDuplicatesKey: allowDuplicates]
        )
        if let scanTimeoutMs = scanTimeoutMs {
            DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(scanTimeoutMs)) {
                _ = self.stopScan()
            }
        }
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

    public 
    func subscribeToCharacteristic(deviceId: String, serviceId: String, charId: String, enable: Bool, callback: @escaping (Bool) -> Void) {
        guard let p = connectedPeripheral else {
            callback(false)
            return
        }
        
        let sId = CBUUID(string: serviceId)
        let cId = CBUUID(string: charId)
        
        guard let service = p.services?.first(where: { $0.uuid == sId }),
              let char = service.characteristics?.first(where: { $0.uuid == cId }) else {
            callback(false)
            return
        }
        
        p.setNotifyValue(enable, for: char)
        callback(true)
    }

    func disconnect() {
        if let peripheral = connectedPeripheral {
            centralManager?.cancelPeripheralConnection(peripheral)
        }
    }
    
    public func centralManagerDidUpdateState(_ central: CBCentralManager) {
        // Handle state
    }
    
    public func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        if let nameFilter = nameFilter,
           peripheral.name != nameFilter,
           advertisementData[CBAdvertisementDataLocalNameKey] as? String != nameFilter {
            return
        }
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

    public func old_peripheral_didUpdateValueFor(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        let data = (error == nil) ? characteristic.value : nil
        DispatchQueue.main.async {
            self.readCharacteristicCallback?(data)
            self.readCharacteristicCallback = nil
        }
    }

    public func centralManager(
        _ central: CBCentralManager,
        willRestoreState dict: [String : Any]
    ) {
        let peripherals = dict[CBCentralManagerRestoredStatePeripheralsKey] as? [CBPeripheral]
        connectedPeripheral = peripherals?.first
        connectedPeripheral?.delegate = self
    }
}



extension HardwareBluetoothManager {

    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if let error = error {
            return
        }
        
        if let data = characteristic.value {
            // Check if this was a read callback
            if let cb = readCharacteristicCallback {
                cb(data)
                readCharacteristicCallback = nil
            } else {
                // Otherwise it's a notification
                let eventData: [String: Any] = [
                    "module": "bluetooth",
                    "type": "data",
                    "data": [
                        "id": peripheral.identifier.uuidString,
                        "serviceId": characteristic.service?.uuid.uuidString ?? "",
                        "charId": characteristic.uuid.uuidString,
                        "value": FlutterStandardTypedData(bytes: data)
                    ]
                ]
                DispatchQueue.main.async {
                    self.eventSink?(eventData)
                }
            }
        }
    }

}

// MARK: - L2CAP Connection-Oriented Channels

extension HardwareBluetoothManager: StreamDelegate {

    /// Opens an L2CAP Connection-Oriented Channel to the connected peripheral.
    /// Requires iOS 11.0+. Incoming bytes are piped as `type: "l2cap"` events through the EventSink.
    func connectL2cap(deviceId: String, psm: Int) -> Bool {
        guard let peripheral = connectedPeripheral,
              peripheral.identifier.uuidString == deviceId else {
            return false
        }
        peripheral.openL2CAPChannel(CBL2CAPPSM(psm))
        return true
    }

    /// Close the active L2CAP channel.
    func closeL2cap() {
        l2capInputStream?.close()
        l2capInputStream?.remove(from: .current, forMode: .default)
        l2capInputStream = nil
        l2capChannel = nil
    }

    /// Called when an L2CAP channel is opened.
    public func peripheral(_ peripheral: CBPeripheral, didOpen channel: CBL2CAPChannel?, error: Error?) {
        guard let channel = channel, error == nil else {
            let errorData: [String: Any] = [
                "module": "bluetooth",
                "type": "l2capStatus",
                "data": [
                    "deviceId": peripheral.identifier.uuidString,
                    "state": "error",
                    "message": error?.localizedDescription ?? "Unknown L2CAP error"
                ]
            ]
            DispatchQueue.main.async { self.eventSink?(errorData) }
            return
        }

        l2capChannel = channel
        l2capPsm = Int(channel.psm)
        l2capDeviceId = peripheral.identifier.uuidString

        let inputStream = channel.inputStream
        l2capInputStream = inputStream
        inputStream.delegate = self
        inputStream.schedule(in: .current, forMode: .default)
        inputStream.open()

        let statusData: [String: Any] = [
            "module": "bluetooth",
            "type": "l2capStatus",
            "data": [
                "deviceId": peripheral.identifier.uuidString,
                "psm": Int(channel.psm),
                "state": "connected"
            ]
        ]
        DispatchQueue.main.async { self.eventSink?(statusData) }
    }

    /// Stream delegate to read incoming L2CAP data.
    public func stream(_ aStream: Stream, handle eventCode: Stream.Event) {
        guard let inputStream = aStream as? InputStream else { return }

        switch eventCode {
        case .hasBytesAvailable:
            let bufferSize = 4096
            let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: bufferSize)
            defer { buffer.deallocate() }

            let bytesRead = inputStream.read(buffer, maxLength: bufferSize)
            if bytesRead > 0 {
                let data = Data(bytes: buffer, count: bytesRead)
                let eventData: [String: Any] = [
                    "module": "bluetooth",
                    "type": "l2cap",
                    "data": [
                        "deviceId": l2capDeviceId ?? "",
                        "psm": l2capPsm ?? 0,
                        "bytes": [UInt8](data)
                    ]
                ]
                DispatchQueue.main.async { self.eventSink?(eventData) }
            }

        case .endEncountered:
            closeL2cap()
            let statusData: [String: Any] = [
                "module": "bluetooth",
                "type": "l2capStatus",
                "data": [
                    "deviceId": l2capDeviceId ?? "",
                    "psm": l2capPsm ?? 0,
                    "state": "disconnected"
                ]
            ]
            DispatchQueue.main.async { self.eventSink?(statusData) }

        case .errorOccurred:
            closeL2cap()

        default:
            break
        }
    }
}

