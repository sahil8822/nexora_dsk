import UIKit

/// iOS Health Manager with Automated Hardware Logging.
public class HardwareHealthManager {
    private var isLogging = false
    private var logTimer: Timer?
    private var logFileURL: URL?
    private var smartSync: SmartSyncManager?

    public func setSmartSyncManager(_ sync: SmartSyncManager) {
        self.smartSync = sync
    }

    public func getBatteryInfo() -> [String: Any] {
        UIDevice.current.isBatteryMonitoringEnabled = true
        let state = UIDevice.current.batteryState
        let rawLevel = UIDevice.current.batteryLevel // -1.0 to 1.0
        let level = rawLevel < 0 ? 0 : Int(rawLevel * 100) // Convert to 0-100%
        let stateString: String
        switch state {
        case .charging: stateString = "charging"
        case .full: stateString = "full"
        case .unplugged: stateString = "discharging"
        default: stateString = "unknown"
        }
        return [
            "level": level,
            "isCharging": state == .charging || state == .full,
            "status": stateString,
            "temperature": 0.0  // iOS does not expose battery temperature
        ]
    }

    public func getWifiInfo() -> [String: Any]? {
        // Note: iOS requires Entitlements for real WiFi info (NEHotspotNetwork)
        return ["ssid": "Unknown", "bssid": "Unknown", "signalStrength": 0, "ipAddress": getIPAddress()]
    }

    public func startLogging(fileName: String, interval: Double) -> Bool {
        guard !isLogging else { return true }
        guard isSafeFileName(fileName) else { return false }
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        logFileURL = paths[0].appendingPathComponent(fileName)

        // Write CSV header
        if let url = logFileURL {
            try? "timestamp,battery_level,is_charging,status\n".write(to: url, atomically: true, encoding: .utf8)
        }

        isLogging = true
        logTimer = Timer.scheduledTimer(withTimeInterval: interval / 1000.0, repeats: true) { _ in
            self.writeLogEntry()
        }
        return true
    }

    public func stopLogging() {
        isLogging = false
        logTimer?.invalidate()
        logTimer = nil
    }

    private func writeLogEntry() {
        let battery = getBatteryInfo()
        let timestamp = ISO8601DateFormatter().string(from: Date())
        let entry = "\(timestamp),\(battery["level"] ?? 0),\(battery["isCharging"] ?? false),\(battery["status"] ?? "")\n"
        
        if let data = entry.data(using: .utf8), let url = logFileURL {
            if FileManager.default.fileExists(atPath: url.path) {
                if let fileHandle = try? FileHandle(forWritingTo: url) {
                    fileHandle.seekToEndOfFile()
                    fileHandle.write(data)
                    fileHandle.closeFile()
                }
            } else {
                try? entry.write(to: url, atomically: true, encoding: .utf8)
            }
            smartSync?.queueData(data: entry.trimmingCharacters(in: .whitespacesAndNewlines))
        }
    }

    private func getIPAddress() -> String {
        var address = "0.0.0.0"
        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifaddr) == 0, let firstAddr = ifaddr else { return address }
        defer { freeifaddrs(ifaddr) }
        for ptr in sequence(first: firstAddr, next: { $0.pointee.ifa_next }) {
            let interface = ptr.pointee
            let addrFamily = interface.ifa_addr.pointee.sa_family
            if addrFamily == UInt8(AF_INET) {
                let name = String(cString: interface.ifa_name)
                if name == "en0" {
                    var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                    getnameinfo(interface.ifa_addr, socklen_t(interface.ifa_addr.pointee.sa_len),
                                &hostname, socklen_t(hostname.count), nil, 0, NI_NUMERICHOST)
                    address = String(cString: hostname)
                }
            }
        }
        return address
    }

    private func isSafeFileName(_ fileName: String) -> Bool {
        return !fileName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
            fileName.count <= 120 &&
            !fileName.contains("/") &&
            !fileName.contains("\\") &&
            fileName != "." &&
            fileName != ".."
    }
}
