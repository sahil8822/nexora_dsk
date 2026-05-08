import 'dart:typed_data';
import '../../nexora_sdk_platform_interface.dart';
import '../../models/hardware_models.dart';

/// Lightweight storage access module.
///
/// Provides secure app-private file I/O, storage diagnostics,
/// and cache management without heavy third-party dependencies.
class StorageModule {
  /// Returns device storage metrics (total, free, cache size, etc.).
  Future<StorageInfo?> getStorageInfo() =>
      NexoraSdkPlatform.instance.getStorageInfo();

  /// Writes a text file to app-private storage.
  /// Returns the absolute path of the written file.
  Future<String?> writeFile(String fileName, String content) {
    _validateFileName(fileName);
    return NexoraSdkPlatform.instance.writeFile(fileName, content);
  }

  /// Reads a text file from app-private storage.
  /// Returns null if the file does not exist.
  Future<String?> readFile(String fileName) {
    _validateFileName(fileName);
    return NexoraSdkPlatform.instance.readFile(fileName);
  }

  /// Deletes a file from app-private storage.
  Future<bool> deleteFile(String fileName) {
    _validateFileName(fileName);
    return NexoraSdkPlatform.instance.deleteFile(fileName);
  }

  /// Checks if a file exists in app-private storage.
  Future<bool> fileExists(String fileName) {
    _validateFileName(fileName);
    return NexoraSdkPlatform.instance.fileExists(fileName);
  }

  /// Lists all files and directories in app-private storage.
  Future<List<FileInfo>> listFiles() => NexoraSdkPlatform.instance.listFiles();

  /// Writes raw bytes to a file in app-private storage.
  Future<String?> writeBytes(String fileName, Uint8List bytes) {
    _validateFileName(fileName);
    return NexoraSdkPlatform.instance.writeBytes(fileName, bytes);
  }

  /// Reads raw bytes from a file. Returns null if not found.
  Future<Uint8List?> readBytes(String fileName) {
    _validateFileName(fileName);
    return NexoraSdkPlatform.instance.readBytes(fileName);
  }

  /// Clears the app cache directory to free space.
  Future<bool> clearCache() => NexoraSdkPlatform.instance.clearCache();

  /// Returns the app-private files directory path.
  Future<String?> getAppDirectory() =>
      NexoraSdkPlatform.instance.getAppDirectory();

  /// Returns the app cache directory path.
  Future<String?> getCacheDirectory() =>
      NexoraSdkPlatform.instance.getCacheDirectory();

  /// Returns the external storage directory path (null if unavailable).
  Future<String?> getExternalDirectory() =>
      NexoraSdkPlatform.instance.getExternalDirectory();

  void _validateFileName(String fileName) {
    if (fileName.trim().isEmpty ||
        fileName.length > 120 ||
        fileName == '.' ||
        fileName == '..' ||
        fileName.contains('/') ||
        fileName.contains(r'\')) {
      throw ArgumentError.value(
        fileName,
        'fileName',
        'Use a simple file name without path separators.',
      );
    }
  }
}
