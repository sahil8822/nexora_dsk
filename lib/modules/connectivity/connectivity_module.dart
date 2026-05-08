import '../../models/device_models.dart';
import '../../nexora_sdk_platform_interface.dart';

/// Native connectivity diagnostics for adapting app behavior.
class ConnectivityModule {
  /// Returns the current network route and connection hints.
  Future<ConnectivityInfo> getInfo() =>
      NexoraSdkPlatform.instance.getConnectivityInfo();

  /// Convenience helper for quick online/offline checks.
  Future<bool> get isConnected async => (await getInfo()).isConnected;

  /// Polls connectivity changes and emits only changed snapshots.
  Stream<ConnectivityInfo> watch({
    Duration interval = const Duration(seconds: 2),
  }) async* {
    if (interval.inMilliseconds <= 0) {
      throw ArgumentError.value(interval, 'interval', 'Must be positive.');
    }

    ConnectivityInfo? previous;
    while (true) {
      final current = await getInfo();
      if (previous == null ||
          current.isConnected != previous.isConnected ||
          current.networkType != previous.networkType ||
          current.isMetered != previous.isMetered ||
          current.isVpn != previous.isVpn) {
        yield current;
        previous = current;
      }
      await Future<void>.delayed(interval);
    }
  }
}
