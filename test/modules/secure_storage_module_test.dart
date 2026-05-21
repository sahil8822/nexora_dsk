import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexora_sdk/nexora_sdk.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('nexora_sdk/methods');
  final log = <MethodCall>[];
  final secureStorage = <String, String>{};

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (methodCall) async {
          log.add(methodCall);
          switch (methodCall.method) {
            case 'writeSecureFile':
              final name = methodCall.arguments['fileName'] as String;
              final content = methodCall.arguments['content'] as String;
              secureStorage[name] = content;
              return true;
            case 'readSecureFile':
              final name = methodCall.arguments['fileName'] as String;
              return secureStorage[name];
            case 'deleteSecureFile':
              final name = methodCall.arguments['fileName'] as String;
              final removed = secureStorage.remove(name) != null;
              return removed;
            default:
              return null;
          }
        });
  });

  tearDown(() {
    log.clear();
    secureStorage.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  group('SecureStorageModule Tests', () {
    test('write, read, delete success', () async {
      final ss = NexoraSdk.instance.secureStorage;
      final success = await ss.writeSecureFile(
        'secret.txt',
        'super_secret_key',
      );
      expect(success, true);

      final exists = await ss.readSecureFile('secret.txt');
      expect(exists, 'super_secret_key');

      final deleted = await ss.deleteSecureFile('secret.txt');
      expect(deleted, true);

      final nonExistent = await ss.readSecureFile('secret.txt');
      expect(nonExistent, isNull);
    });

    test('writeSecureJson and readSecureJson success', () async {
      final ss = NexoraSdk.instance.secureStorage;
      final mapData = {'token': 'jwt_123', 'expires': 3600};
      final success = await ss.writeSecureJson('token.json', mapData);
      expect(success, true);

      final readData = await ss.readSecureJson<Map<dynamic, dynamic>>(
        'token.json',
      );
      expect(readData, isNotNull);
      expect(readData!['token'], 'jwt_123');
      expect(readData['expires'], 3600);

      final invalidType = await ss.readSecureJson<List<dynamic>>('token.json');
      expect(invalidType, isNull);
    });

    test('filename validation checks', () {
      final ss = NexoraSdk.instance.secureStorage;
      expect(() => ss.writeSecureFile('', 'data'), throwsArgumentError);
      expect(
        () => ss.writeSecureFile('dir/file.txt', 'data'),
        throwsArgumentError,
      );
      expect(
        () => ss.writeSecureFile(r'dir\file.txt', 'data'),
        throwsArgumentError,
      );
      expect(() => ss.writeSecureFile('.', 'data'), throwsArgumentError);
      expect(() => ss.writeSecureFile('..', 'data'), throwsArgumentError);
      expect(() => ss.writeSecureFile('a' * 121, 'data'), throwsArgumentError);
    });
  });
}
