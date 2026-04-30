import UIKit

/**
 * iOS Health Manager with Automated Hardware Logging.
 */
public class HardwareHealthManager {
    private var isLogging = false
    private var logTimer: Timer?
    private var logFileURL: URL?

    public func getBatteryInfo() -> [String: Any] {
        UIDevice.current.isBatteryMonitoringEnabled = true
        let state = UIDevice.current.batteryState
        let stateString = (state == .charging) ? "charging" : (state == .full ? "full" : "discharging")
        return [
            "level": UIDevice.current.batteryLevel,
            "isCharging": state == .charging || state == .full,
            "status": stateString,
            "temperature": 0.0
        ]
    }

    public func startLogging(fileName: String, interval: Double) {
        guard !isLogging else { return }
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        logFileURL = paths[0].appendingPathComponent(fileName)
        
        isLogging = true
        logTimer = Timer.scheduledTimer(withTimeInterval: interval / 1000.0, repeats: true) { _ in
            self.writeLogEntry()
        }
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
        }
    }

    public func getWifiInfo() -> [String: Any]? {
        return ["ssid": "iOS Network", "bssid": "Unknown", "signalStrength": 0, "ipAddress": "0.0.0.0"]
    }
}
