import Foundation
import CoreNFC
import Flutter

/// iOS NFC Manager supporting NDEF scanning and writing using CoreNFC.
public class HardwareNfcManager: NSObject, NFCNDEFReaderSessionDelegate {
    private var eventSink: FlutterEventSink?
    private var session: NFCNDEFReaderSession?
    private var writePendingMessage: NFCNDEFMessage?
    private var writeCallback: ((Bool) -> Void)?

    public func setEventSink(_ sink: FlutterEventSink?) {
        self.eventSink = sink
    }

    public func startScan() -> Bool {
        guard NFCNDEFReaderSession.readingAvailable else { return false }
        
        session = NFCNDEFReaderSession(delegate: self, queue: nil, invalidateAfterFirstRead: false)
        session?.alertMessage = "Hold your device near an NFC tag to scan."
        session?.begin()
        return true
    }

    public func stopScan() -> Bool {
        session?.invalidate()
        session = nil
        return true
    }

    public func writeNdef(type: String, payload: String, callback: @escaping (Bool) -> Void) {
        guard NFCNDEFReaderSession.readingAvailable else {
            callback(false)
            return
        }
        
        guard let typeData = type.data(using: .utf8),
              let payloadData = payload.data(using: .utf8) else {
            callback(false)
            return
        }
        
        let record = NFCNDEFPayload(
            format: .mediaType,
            type: typeData,
            identifier: Data(),
            payload: payloadData
        )
        writePendingMessage = NFCNDEFMessage(records: [record])
        writeCallback = callback
        
        session = NFCNDEFReaderSession(delegate: self, queue: nil, invalidateAfterFirstRead: false)
        session?.alertMessage = "Hold your device near an NFC tag to write."
        session?.begin()
    }

    // MARK: - NFCNDEFReaderSessionDelegate

    public func readerSession(_ session: NFCNDEFReaderSession, didInvalidateWithError error: Error) {
        self.session = nil
        writeCallback?(false)
        writeCallback = nil
    }

    public func readerSession(_ session: NFCNDEFReaderSession, didDetectNDEFs messages: [NFCNDEFMessage]) {
        var recordsList: [[String: String]] = []
        for message in messages {
            for record in message.records {
                let typeStr = String(data: record.type, encoding: .utf8) ?? ""
                let payloadStr = String(data: record.payload, encoding: .utf8) ?? ""
                recordsList.append([
                    "type": typeStr,
                    "payload": payloadStr
                ])
            }
        }
        
        let data: [String: Any] = [
            "module": "nfc",
            "type": "tag_discovered",
            "data": [
                "id": "",
                "techList": ["NDEF"],
                "records": recordsList
            ]
        ]
        
        DispatchQueue.main.async {
            self.eventSink?(data)
        }
    }

    public func readerSession(_ session: NFCNDEFReaderSession, didDetect tags: [NFCNDEFTag]) {
        guard let tag = tags.first else { return }
        
        session.connect(to: tag) { [weak self] (error) in
            guard let self = self, error == nil else {
                session.invalidate(errorMessage: "Connection failed.")
                return
            }
            
            tag.queryNDEFStatus { (status, capacity, error) in
                guard error == nil else {
                    session.invalidate(errorMessage: "Query failed.")
                    return
                }
                
                if status == .readWrite {
                    if let pendingMsg = self.writePendingMessage {
                        self.writePendingMessage = nil
                        tag.writeNDEF(pendingMsg) { (error) in
                            if error == nil {
                                session.alertMessage = "Write successful!"
                                session.invalidate()
                                self.writeCallback?(true)
                            } else {
                                session.invalidate(errorMessage: "Write failed.")
                                self.writeCallback?(false)
                            }
                            self.writeCallback = nil
                        }
                    } else {
                        tag.readNDEF { (message, error) in
                            if error == nil, let message = message {
                                self.readerSession(session, didDetectNDEFs: [message])
                                session.alertMessage = "Tag read successful!"
                                session.invalidate()
                            } else {
                                session.invalidate(errorMessage: "Read failed.")
                            }
                        }
                    }
                } else {
                    session.invalidate(errorMessage: "Tag is not writable.")
                }
            }
        }
    }
}
