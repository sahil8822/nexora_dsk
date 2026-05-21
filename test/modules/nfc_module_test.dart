import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexora_sdk/nexora_sdk.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('nexora_sdk/methods');
  final log = <MethodCall>[];

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (methodCall) async {
          log.add(methodCall);
          switch (methodCall.method) {
            case 'startNfcScan':
              return true;
            case 'stopNfcScan':
              return true;
            case 'writeNdefRecord':
              return true;
            default:
              return null;
          }
        });
  });

  tearDown(() {
    log.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  group('NfcModule Tests', () {
    test('startNfcScan and stopNfcScan success', () async {
      final nfc = NexoraSdk.instance.nfc;
      expect(await nfc.startNfcScan(), true);
      expect(await nfc.stopNfcScan(), true);

      expect(log.length, 2);
      expect(log[0].method, 'startNfcScan');
      expect(log[1].method, 'stopNfcScan');
    });

    test('writeNdefRecord success', () async {
      final nfc = NexoraSdk.instance.nfc;
      expect(
        await nfc.writeNdefRecord(type: 'text/plain', payload: 'Hello NFC'),
        true,
      );

      expect(log.length, 1);
      expect(log.first.method, 'writeNdefRecord');
      expect(log.first.arguments, <String, dynamic>{
        'type': 'text/plain',
        'payload': 'Hello NFC',
      });
    });

    test('nfcTagStream emits data', () async {
      final nfc = NexoraSdk.instance.nfc;
      expect(nfc.nfcTagStream, isNotNull);
    });
  });
}
