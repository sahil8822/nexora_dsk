import 'package:flutter/services.dart';

/// Module to interact with Near Field Communication (NFC) hardware on the device.
class NfcModule {
  static const MethodChannel _channel = MethodChannel('nexora_sdk/methods');
  static const EventChannel _eventChannel = EventChannel('nexora_sdk/events');

  /// Starts listening/scanning for NFC tags.
  Future<bool> startNfcScan() async {
    try {
      final success = await _channel.invokeMethod<bool>('startNfcScan');
      return success ?? false;
    } on PlatformException {
      return false;
    }
  }

  /// Stops listening/scanning for NFC tags.
  Future<bool> stopNfcScan() async {
    try {
      final success = await _channel.invokeMethod<bool>('stopNfcScan');
      return success ?? false;
    } on PlatformException {
      return false;
    }
  }

  /// Writes an NDEF record to a discovered NFC tag.
  Future<bool> writeNdefRecord({
    required String type,
    required String payload,
  }) async {
    try {
      final success = await _channel.invokeMethod<bool>(
        'writeNdefRecord',
        {
          'type': type,
          'payload': payload,
        },
      );
      return success ?? false;
    } on PlatformException {
      return false;
    }
  }

  /// Returns a stream of discovered NFC tags and their payload/NDEF data.
  Stream<Map<String, dynamic>> get nfcTagStream {
    return _eventChannel
        .receiveBroadcastStream()
        .map((event) {
          if (event is Map && event['module'] == 'nfc') {
            return Map<String, dynamic>.from(event['data'] as Map);
          }
          return <String, dynamic>{};
        })
        .where((data) => data.isNotEmpty);
  }
}
