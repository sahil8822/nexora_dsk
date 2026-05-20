import 'dart:convert';
import 'package:flutter/services.dart';

/// Secure Storage Module supporting AES-256 encrypted file writes/reads.
/// Uses Android KeyStore (AES-GCM) on Android and iOS Keychain on iOS.
class SecureStorageModule {
  static const MethodChannel _channel = MethodChannel('nexora_sdk/methods');

  /// Writes encrypted data to a file.
  Future<bool> writeSecureFile(String fileName, String content) async {
    _validateFileName(fileName);
    try {
      final bool? success = await _channel.invokeMethod<bool>('writeSecureFile', {
        'fileName': fileName,
        'content': content,
      });
      return success ?? false;
    } on PlatformException {
      return false;
    }
  }

  /// Reads and decrypts data from a file.
  Future<String?> readSecureFile(String fileName) async {
    _validateFileName(fileName);
    try {
      final String? content = await _channel.invokeMethod<String>('readSecureFile', {
        'fileName': fileName,
      });
      return content;
    } on PlatformException {
      return null;
    }
  }

  /// Writes a JSON-serializable value securely.
  Future<bool> writeSecureJson(String fileName, Object? value) {
    return writeSecureFile(fileName, jsonEncode(value));
  }

  /// Reads a JSON value securely.
  Future<T?> readSecureJson<T extends Object>(String fileName) async {
    final content = await readSecureFile(fileName);
    if (content == null) return null;
    try {
      final value = jsonDecode(content);
      return value is T ? value : null;
    } on FormatException {
      return null;
    }
  }

  /// Deletes a secure file.
  Future<bool> deleteSecureFile(String fileName) async {
    _validateFileName(fileName);
    try {
      final bool? success = await _channel.invokeMethod<bool>('deleteSecureFile', {
        'fileName': fileName,
      });
      return success ?? false;
    } on PlatformException {
      return false;
    }
  }

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
