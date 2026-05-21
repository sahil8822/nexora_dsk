import 'package:flutter_test/flutter_test.dart';
import 'package:nexora_sdk/nexora_sdk.dart';
import 'package:nexora_sdk_platform_interface/nexora_sdk_platform_interface.dart';
import '../mocks/mock_platform.dart';

class MockConnectivityPlatform extends MockNexoraSdkPlatform {
  ConnectivityInfo mockInfo = const ConnectivityInfo(
    isConnected: true,
    networkType: 'wifi',
    isMetered: false,
    isVpn: false,
    signalStrength: -50,
    ipAddress: '192.168.1.1',
  );

  @override
  Future<ConnectivityInfo> getConnectivityInfo() async => mockInfo;
}

void main() {
  late MockConnectivityPlatform mockPlatform;

  setUp(() {
    mockPlatform = MockConnectivityPlatform();
    NexoraSdkPlatform.instance = mockPlatform;
  });

  group('ConnectivityModule Tests', () {
    test('getInfo() & isConnected', () async {
      final connectivity = ConnectivityModule();
      final info = await connectivity.getInfo();
      expect(info.isConnected, true);
      expect(info.networkType, 'wifi');
      expect(await connectivity.isConnected, true);
    });

    test('watch() emits on changes', () async {
      final connectivity = ConnectivityModule();
      final stream = connectivity.watch(
        interval: const Duration(milliseconds: 5),
      );

      final itemsFuture = stream.take(2).toList();

      // Emit first item
      await Future<void>.delayed(const Duration(milliseconds: 10));

      // Change connectivity info
      mockPlatform.mockInfo = const ConnectivityInfo(
        isConnected: false,
        networkType: 'none',
        isMetered: false,
        isVpn: false,
        signalStrength: 0,
        ipAddress: '0.0.0.0',
      );

      final items = await itemsFuture;
      expect(items.length, 2);
      expect(items[0].isConnected, true);
      expect(items[1].isConnected, false);
    });

    test('watch() validation', () {
      final connectivity = ConnectivityModule();
      expect(
        connectivity.watch(interval: Duration.zero),
        emitsError(isA<ArgumentError>()),
      );
      expect(
        connectivity.watch(interval: const Duration(seconds: -1)),
        emitsError(isA<ArgumentError>()),
      );
    });
  });
}
