import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexora_sdk/nexora_sdk.dart';
import 'package:nexora_sdk/nexora_sdk_platform_interface.dart';
import '../mocks/mock_platform.dart';

class MockStoragePlatform extends MockNexoraSdkPlatform {
  final Map<String, dynamic> files = {};
  bool cacheCleared = false;

  @override
  Future<StorageInfo?> getStorageInfo() async {
    return StorageInfo(
      internalTotal: 1000,
      internalFree: 500,
      externalTotal: 2000,
      externalFree: 1000,
      appCacheSize: 100,
      appDataSize: 200,
    );
  }

  @override
  Future<String?> writeFile(String fileName, String content) async {
    files[fileName] = content;
    return '/app/$fileName';
  }

  @override
  Future<String?> appendFile(String fileName, String content) async {
    final existing = files[fileName] as String? ?? '';
    files[fileName] = existing + content;
    return '/app/$fileName';
  }

  @override
  Future<String?> readFile(String fileName) async {
    if (!files.containsKey(fileName)) return null;
    final value = files[fileName];
    if (value is Uint8List) {
      return utf8.decode(value);
    }
    return value as String?;
  }

  @override
  Future<bool> deleteFile(String fileName) async {
    if (!files.containsKey(fileName)) return false;
    files.remove(fileName);
    return true;
  }

  @override
  Future<bool> fileExists(String fileName) async {
    return files.containsKey(fileName);
  }

  @override
  Future<List<FileInfo>> listFiles() async {
    return files.entries.map((e) {
      final isBytes = e.value is Uint8List;
      final size = isBytes ? (e.value as Uint8List).length : (e.value as String).length;
      return FileInfo(
        name: e.key,
        size: size,
        isDirectory: false,
        lastModified: DateTime.now(),
      );
    }).toList();
  }

  @override
  Future<String?> writeBytes(String fileName, dynamic bytes) async {
    files[fileName] = Uint8List.fromList(bytes as List<int>);
    return '/app/$fileName';
  }

  @override
  Future<Uint8List?> readBytes(String fileName) async {
    if (!files.containsKey(fileName)) return null;
    final val = files[fileName];
    if (val is String) {
      return Uint8List.fromList(utf8.encode(val));
    }
    return val as Uint8List?;
  }

  @override
  Future<bool> clearCache() async {
    cacheCleared = true;
    return true;
  }

  @override
  Future<String?> getAppDirectory() async => '/app';

  @override
  Future<String?> getCacheDirectory() async => '/cache';

  @override
  Future<String?> getExternalDirectory() async => '/external';
}

void main() {
  late MockStoragePlatform mockPlatform;

  setUp(() {
    mockPlatform = MockStoragePlatform();
    NexoraSdkPlatform.instance = mockPlatform;
  });

  group('StorageModule Tests', () {
    test('getStorageInfo() success', () async {
      final storage = StorageModule();
      final info = await storage.getStorageInfo();
      expect(info, isNotNull);
      expect(info!.internalTotal, 1000);
      expect(info.internalFree, 500);
      expect(info.internalUsage, 0.5);
    });

    test('file operations success', () async {
      final storage = StorageModule();
      expect(await storage.writeFile('test.txt', 'hello'), '/app/test.txt');
      expect(await storage.fileExists('test.txt'), true);
      expect(await storage.readFile('test.txt'), 'hello');

      expect(await storage.appendFile('test.txt', ' world'), '/app/test.txt');
      expect(await storage.readFile('test.txt'), 'hello world');

      final list = await storage.listFiles();
      expect(list.length, 1);
      expect(list.first.name, 'test.txt');

      expect(await storage.deleteFile('test.txt'), true);
      expect(await storage.fileExists('test.txt'), false);
    });

    test('deleteIfExists logic', () async {
      final storage = StorageModule();
      // If it doesn't exist, returns true directly
      expect(await storage.deleteIfExists('absent.txt'), true);

      await storage.writeFile('exists.txt', 'content');
      expect(await storage.deleteIfExists('exists.txt'), true);
      expect(await storage.fileExists('exists.txt'), false);
    });

    test('JSON serialization & parsing', () async {
      final storage = StorageModule();
      final data = {'key': 'value', 'num': 42};
      await storage.writeJson('data.json', data);
      final readData = await storage.readJson<Map<dynamic, dynamic>>('data.json');
      expect(readData, isNotNull);
      expect(readData!['key'], 'value');
      expect(readData['num'], 42);

      // Attempt to read as different type
      final invalidType = await storage.readJson<List<dynamic>>('data.json');
      expect(invalidType, isNull);

      // Read missing file
      final missing = await storage.readJson<Map<dynamic, dynamic>>('absent.json');
      expect(missing, isNull);
    });

    test('Bytes read & write', () async {
      final storage = StorageModule();
      final bytes = Uint8List.fromList([10, 20, 30, 40]);
      await storage.writeBytes('data.bin', bytes);
      final read = await storage.readBytes('data.bin');
      expect(read, equals(bytes));

      final empty = await storage.readBytes('absent.bin');
      expect(empty, isNull);
    });

    test('cache and directories', () async {
      final storage = StorageModule();
      expect(await storage.clearCache(), true);
      expect(mockPlatform.cacheCleared, true);

      expect(await storage.getAppDirectory(), '/app');
      expect(await storage.getCacheDirectory(), '/cache');
      expect(await storage.getExternalDirectory(), '/external');
    });

    test('fileName validation checks', () async {
      final storage = StorageModule();
      expect(() => storage.readFile(''), throwsArgumentError);
      expect(() => storage.readFile('a/b.txt'), throwsArgumentError);
      expect(() => storage.readFile('a\\b.txt'), throwsArgumentError);
      expect(() => storage.readFile('.'), throwsArgumentError);
      expect(() => storage.readFile('..'), throwsArgumentError);
      expect(() => storage.readFile('a' * 121), throwsArgumentError);
    });

    test('migrateStorage schema logic', () async {
      final storage = StorageModule();
      final List<int> migratedVersions = [];

      // Migrate version 0 -> 2
      await storage.migrateStorage(0, 2, (version) async {
        migratedVersions.add(version);
      });

      expect(migratedVersions, [1, 2]);

      final versionInfo = await storage.readJson<Map<String, dynamic>>('_schema_version.json');
      expect(versionInfo, isNotNull);
      expect(versionInfo!['version'], 2);

      // Migrate 2 -> 3 (only runs version 3)
      migratedVersions.clear();
      await storage.migrateStorage(2, 3, (version) async {
        migratedVersions.add(version);
      });
      expect(migratedVersions, [3]);
    });
  });
}
