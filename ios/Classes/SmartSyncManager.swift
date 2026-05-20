import Foundation
import Network

/// iOS Smart Sync Manager for offline queueing and background upload with exponential backoff.
public class SmartSyncManager {
    public static let shared = SmartSyncManager()
    
    private var isEnabled = false
    private var uploadUrl = ""
    private var headersMap: [String: String] = [:]
    private var requireWifiConnection = true
    private var rollLimit = 2 * 1024 * 1024
    
    private let monitor = NWPathMonitor()
    private var isNetworkAvailable = false
    private var isWifi = false
    
    private let queue = DispatchQueue(label: "com.nexora.sdk.smartsync", qos: .background)
    
    private var syncDirectory: URL {
        let paths = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)
        let dir = paths[0].appendingPathComponent("smart_sync", isDirectory: true)
        if !FileManager.default.fileExists(atPath: dir.path) {
            try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        return dir
    }
    
    private init() {
        monitor.pathUpdateHandler = { [weak self] path in
            self?.isNetworkAvailable = (path.status == .satisfied)
            self?.isWifi = path.usesInterfaceType(.wifi)
        }
        monitor.start(queue: queue)
    }
    
    public func enable(url: String, headers: [String: String], limit: Int, wifiOnly: Bool) {
        self.uploadUrl = url
        self.headersMap = headers
        self.rollLimit = limit
        self.requireWifiConnection = wifiOnly
        
        if !isEnabled {
            isEnabled = true
            startSyncQueue()
        }
    }
    
    public func queueData(data: String) {
        guard isEnabled else { return }
        queue.async {
            let activeFile = self.syncDirectory.appendingPathComponent("active_log.txt")
            if FileManager.default.fileExists(atPath: activeFile.path) {
                if let attrs = try? FileManager.default.attributesOfItem(atPath: activeFile.path),
                   let size = attrs[.size] as? Int, size >= self.rollLimit {
                    let rolledFile = self.syncDirectory.appendingPathComponent("rolled_\(Int(Date().timeIntervalSince1970 * 1000)).txt")
                    try? FileManager.default.moveItem(at: activeFile, to: rolledFile)
                }
            }
            
            if let dataToWrite = (data + "\n").data(using: .utf8) {
                if FileManager.default.fileExists(atPath: activeFile.path) {
                    if let fileHandle = try? FileHandle(forWritingTo: activeFile) {
                        defer { try? fileHandle.close() }
                        try? fileHandle.seekToEnd()
                        fileHandle.write(dataToWrite)
                    }
                } else {
                    try? dataToWrite.write(to: activeFile)
                }
            }
        }
    }
    
    private func startSyncQueue() {
        queue.async {
            var backoffMs = 5000
            while self.isEnabled {
                let canUpload = self.isNetworkAvailable && (!self.requireWifiConnection || self.isWifi)
                if canUpload {
                    let fileManager = FileManager.default
                    if let files = try? fileManager.contentsOfDirectory(at: self.syncDirectory, includingPropertiesForKeys: nil) {
                        let rolledFiles = files.filter { $0.lastPathComponent.hasPrefix("rolled_") }.sorted(by: { $0.lastPathComponent < $1.lastPathComponent })
                        var uploadedAny = false
                        
                        for file in rolledFiles {
                            if self.uploadFile(file) {
                                try? fileManager.removeItem(at: file)
                                uploadedAny = true
                                backoffMs = 5000
                            } else {
                                break
                            }
                        }
                        
                        let activeFile = self.syncDirectory.appendingPathComponent("active_log.txt")
                        if fileManager.fileExists(atPath: activeFile.path), !uploadedAny {
                            if let attrs = try? fileManager.attributesOfItem(atPath: activeFile.path),
                               let size = attrs[.size] as? Int, size > 0 {
                                let rolledFile = self.syncDirectory.appendingPathComponent("rolled_\(Int(Date().timeIntervalSince1970 * 1000)).txt")
                                try? fileManager.moveItem(at: activeFile, to: rolledFile)
                                continue
                            }
                        }
                    }
                }
                
                Thread.sleep(forTimeInterval: Double(backoffMs) / 1000.0)
                if backoffMs < 300000 {
                    backoffMs *= 2
                }
            }
        }
    }
    
    private func uploadFile(_ file: URL) -> Bool {
        guard let content = try? Data(contentsOf: file) else { return false }
        guard let url = URL(string: uploadUrl) else { return false }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = content
        
        for (key, value) in headersMap {
            request.setValue(value, forHTTPHeaderField: key)
        }
        if headersMap["Content-Type"] == nil {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }
        
        let semaphore = DispatchSemaphore(value: 0)
        var success = false
        
        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            if error == nil, let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode >= 200 && httpResponse.statusCode < 300 {
                success = true
            }
            semaphore.signal()
        }
        task.resume()
        _ = semaphore.wait(timeout: .now() + 15.0)
        
        return success
    }
    
    public func disable() {
        self.isEnabled = false
    }
}
