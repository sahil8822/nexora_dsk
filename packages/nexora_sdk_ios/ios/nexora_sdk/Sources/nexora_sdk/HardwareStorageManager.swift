import Foundation
import Flutter

/// Lightweight iOS Storage Manager.
/// Provides safe file I/O, storage diagnostics, and cache management.
public class HardwareStorageManager {

    /// Returns storage information for the device.
    public func getStorageInfo() -> [String: Any] {
        let fileManager = FileManager.default
        var internalTotal: Int64 = 0
        var internalFree: Int64 = 0

        if let attributes = try? fileManager.attributesOfFileSystem(forPath: NSHomeDirectory()) {
            internalTotal = (attributes[.systemSize] as? Int64) ?? 0
            internalFree = (attributes[.systemFreeSize] as? Int64) ?? 0
        }

        return [
            "internalTotal": internalTotal,
            "internalFree": internalFree,
            "externalTotal": 0,  // iOS has no external storage
            "externalFree": 0,
            "appCacheSize": getDirSize(getCacheDir()),
            "appDataSize": getDirSize(getAppDir())
        ]
    }

    /// Writes text content to a file in the Documents directory.
    public func writeFile(fileName: String, content: String) -> String? {
        guard let url = safeFileURL(fileName: fileName) else { return nil }
        do {
            try content.write(to: url, atomically: true, encoding: .utf8)
            return url.path
        } catch { return nil }
    }

    /// Appends text content to a file in the Documents directory.
    public func appendFile(fileName: String, content: String) -> String? {
        guard let url = safeFileURL(fileName: fileName) else { return nil }
        guard let data = content.data(using: .utf8) else { return nil }
        
        if FileManager.default.fileExists(atPath: url.path) {
            do {
                let fileHandle = try FileHandle(forWritingTo: url)
                defer { try? fileHandle.close() }
                try fileHandle.seekToEnd()
                try fileHandle.write(contentsOf: data)
                return url.path
            } catch {
                return nil
            }
        } else {
            do {
                try content.write(to: url, atomically: true, encoding: .utf8)
                return url.path
            } catch { return nil }
        }
    }

    /// Reads a text file from the Documents directory.
    public func readFile(fileName: String) -> String? {
        guard let url = safeFileURL(fileName: fileName) else { return nil }
        return try? String(contentsOf: url, encoding: .utf8)
    }

    /// Deletes a file from the Documents directory.
    public func deleteFile(fileName: String) -> Bool {
        guard let url = safeFileURL(fileName: fileName) else { return false }
        do {
            try FileManager.default.removeItem(at: url)
            return true
        } catch { return false }
    }

    /// Checks if a file exists in the Documents directory.
    public func fileExists(fileName: String) -> Bool {
        guard let url = safeFileURL(fileName: fileName) else { return false }
        return FileManager.default.fileExists(atPath: url.path)
    }

    /// Lists all files in the Documents directory.
    public func listFiles() -> [[String: Any]] {
        let dir = getAppDir()
        guard let contents = try? FileManager.default.contentsOfDirectory(at: dir, includingPropertiesForKeys: [.fileSizeKey, .isDirectoryKey, .contentModificationDateKey]) else {
            return []
        }
        return contents.map { url in
            let attrs = try? url.resourceValues(forKeys: [.fileSizeKey, .isDirectoryKey, .contentModificationDateKey])
            return [
                "name": url.lastPathComponent,
                "size": attrs?.fileSize ?? 0,
                "isDirectory": attrs?.isDirectory ?? false,
                "lastModified": Int64((attrs?.contentModificationDate?.timeIntervalSince1970 ?? 0) * 1000)
            ]
        }
    }

    /// Writes raw bytes to a file.
    public func writeBytes(fileName: String, bytes: FlutterStandardTypedData) -> String? {
        guard let url = safeFileURL(fileName: fileName) else { return nil }
        do {
            try bytes.data.write(to: url)
            return url.path
        } catch { return nil }
    }

    /// Reads raw bytes from a file.
    public func readBytes(fileName: String) -> FlutterStandardTypedData? {
        guard let url = safeFileURL(fileName: fileName) else { return nil }
        guard let data = try? Data(contentsOf: url) else { return nil }
        return FlutterStandardTypedData(bytes: data)
    }

    /// Clears the app cache directory.
    public func clearCache() -> Bool {
        let cacheDir = getCacheDir()
        guard let contents = try? FileManager.default.contentsOfDirectory(at: cacheDir, includingPropertiesForKeys: nil) else {
            return false
        }
        for url in contents {
            try? FileManager.default.removeItem(at: url)
        }
        return true
    }

    /// Returns the app Documents directory path.
    public func getAppDirectory() -> String {
        return getAppDir().path
    }

    /// Returns the app cache directory path.
    public func getCacheDirectory() -> String {
        return getCacheDir().path
    }

    /// Returns nil on iOS (no external storage).
    public func getExternalDirectory() -> String? {
        return nil
    }

    // MARK: - Private Helpers

    private func safeFileURL(fileName: String) -> URL? {
        guard isSafeFileName(fileName) else { return nil }
        let base = getAppDir().standardizedFileURL
        let url = base.appendingPathComponent(fileName, isDirectory: false).standardizedFileURL
        guard url.path.hasPrefix(base.path + "/") else { return nil }
        return url
    }

    private func isSafeFileName(_ fileName: String) -> Bool {
        return !fileName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
            fileName.count <= 120 &&
            !fileName.contains("/") &&
            !fileName.contains("\\") &&
            fileName != "." &&
            fileName != ".."
    }

    private func getAppDir() -> URL {
        return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    private func getCacheDir() -> URL {
        return FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
    }

    private func getDirSize(_ url: URL) -> Int64 {
        var size: Int64 = 0
        guard let enumerator = FileManager.default.enumerator(at: url, includingPropertiesForKeys: [.fileSizeKey]) else {
            return 0
        }
        for case let fileURL as URL in enumerator {
            let attrs = try? fileURL.resourceValues(forKeys: [.fileSizeKey])
            size += Int64(attrs?.fileSize ?? 0)
        }
        return size
    }
}
