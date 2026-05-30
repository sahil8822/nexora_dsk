import CoreBluetooth
import Flutter

/**
 * BLE Peripheral Mode with GATT Server for iOS.
 *
 * Uses CBPeripheralManager to advertise a custom GATT service containing a
 * read/write characteristic. Incoming writes from connected centrals are
 * forwarded to the Flutter EventSink so Dart code can react to BLE payloads.
 */
public class HardwareBlePeripheralManager: NSObject, CBPeripheralManagerDelegate {

    private var peripheralManager: CBPeripheralManager?
    private var eventSink: FlutterEventSink?
    private var serviceUUID: CBUUID?
    private var mutableService: CBMutableService?
    private var writeCharacteristic: CBMutableCharacteristic?

    /// Fixed characteristic UUID matching the Android implementation.
    private static let characteristicUUID = CBUUID(string: "0000FF01-0000-1000-8000-00805F9B34FB")

    public func setEventSink(_ sink: FlutterEventSink?) {
        self.eventSink = sink
    }

    /// Start advertising a BLE peripheral with a GATT service.
    /// Returns `true` if advertising was initiated successfully.
    public func startAdvertising(uuid: String) -> Bool {
        guard let cbuuid = CBUUID(string: uuid) as CBUUID? else { return false }
        self.serviceUUID = cbuuid

        peripheralManager = CBPeripheralManager(delegate: self, queue: nil)
        // Advertising will start once the manager reaches .poweredOn state
        return true
    }

    /// Stop advertising and tear down the GATT service.
    public func stopAdvertising() {
        peripheralManager?.stopAdvertising()
        if let service = mutableService {
            peripheralManager?.remove(service)
        }
        peripheralManager = nil
        mutableService = nil
        writeCharacteristic = nil

        let statusData: [String: Any] = [
            "module": "blePeripheral",
            "type": "status",
            "data": ["state": "stopped"]
        ]
        DispatchQueue.main.async { self.eventSink?(statusData) }
    }

    // MARK: - CBPeripheralManagerDelegate

    public func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        guard peripheral.state == .poweredOn, let uuid = serviceUUID else { return }

        // Create the writable characteristic
        let characteristic = CBMutableCharacteristic(
            type: HardwareBlePeripheralManager.characteristicUUID,
            properties: [.read, .write, .writeWithoutResponse],
            value: nil,
            permissions: [.readable, .writeable]
        )
        self.writeCharacteristic = characteristic

        // Create the service
        let service = CBMutableService(type: uuid, primary: true)
        service.characteristics = [characteristic]
        self.mutableService = service

        peripheral.add(service)
    }

    public func peripheralManager(_ peripheral: CBPeripheralManager, didAdd service: CBService, error: Error?) {
        guard error == nil, let uuid = serviceUUID else {
            let errorData: [String: Any] = [
                "module": "blePeripheral",
                "type": "status",
                "data": [
                    "state": "advertisingFailed",
                    "message": error?.localizedDescription ?? "Failed to add service"
                ]
            ]
            DispatchQueue.main.async { self.eventSink?(errorData) }
            return
        }

        // Start advertising the service
        peripheral.startAdvertising([
            CBAdvertisementDataServiceUUIDsKey: [uuid],
            CBAdvertisementDataLocalNameKey: "NexoraSDK"
        ])
    }

    public func peripheralManagerDidStartAdvertising(_ peripheral: CBPeripheralManager, error: Error?) {
        let state: String
        if let error = error {
            state = "advertisingFailed"
            let errorData: [String: Any] = [
                "module": "blePeripheral",
                "type": "status",
                "data": [
                    "state": state,
                    "message": error.localizedDescription
                ]
            ]
            DispatchQueue.main.async { self.eventSink?(errorData) }
        } else {
            state = "advertising"
            let statusData: [String: Any] = [
                "module": "blePeripheral",
                "type": "status",
                "data": ["state": state]
            ]
            DispatchQueue.main.async { self.eventSink?(statusData) }
        }
    }

    public func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveRead request: CBATTRequest) {
        // Respond with the current characteristic value
        if let value = writeCharacteristic?.value {
            if request.offset > value.count {
                peripheral.respond(to: request, withResult: .invalidOffset)
            } else {
                request.value = value.subdata(in: request.offset..<value.count)
                peripheral.respond(to: request, withResult: .success)
            }
        } else {
            request.value = Data()
            peripheral.respond(to: request, withResult: .success)
        }
    }

    public func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveWrite requests: [CBATTRequest]) {
        for request in requests {
            if let value = request.value {
                // Store the value on the characteristic
                writeCharacteristic?.value = value

                // Forward the written bytes to Flutter
                let eventData: [String: Any] = [
                    "module": "blePeripheral",
                    "type": "data",
                    "data": [
                        "id": request.central.identifier.uuidString,
                        "serviceId": serviceUUID?.uuidString ?? "",
                        "charId": request.characteristic.uuid.uuidString,
                        "value": [UInt8](value)
                    ]
                ]
                DispatchQueue.main.async { self.eventSink?(eventData) }
            }
        }
        // Respond to the first request (all must share the same response)
        peripheral.respond(to: requests[0], withResult: .success)
    }

    public func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didSubscribeTo characteristic: CBCharacteristic) {
        let statusData: [String: Any] = [
            "module": "blePeripheral",
            "type": "status",
            "data": [
                "id": central.identifier.uuidString,
                "state": "subscribed",
                "charId": characteristic.uuid.uuidString
            ]
        ]
        DispatchQueue.main.async { self.eventSink?(statusData) }
    }

    public func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didUnsubscribeFrom characteristic: CBCharacteristic) {
        let statusData: [String: Any] = [
            "module": "blePeripheral",
            "type": "status",
            "data": [
                "id": central.identifier.uuidString,
                "state": "unsubscribed",
                "charId": characteristic.uuid.uuidString
            ]
        ]
        DispatchQueue.main.async { self.eventSink?(statusData) }
    }
}
