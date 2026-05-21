import 'package:nexora_sdk_platform_interface/models/permission_models.dart';
import 'package:nexora_sdk_platform_interface/nexora_sdk_platform_interface.dart';

/// Permission status checks and settings helpers.
class PermissionsModule {
  /// Returns the current status for one hardware permission without prompting.
  Future<HardwarePermissionStatus> status(HardwarePermission permission) {
    return NexoraSdkPlatform.instance.getPermissionStatus(permission);
  }

  /// Returns a snapshot of all core hardware permissions.
  Future<HardwarePermissionSnapshot> snapshot() async {
    final entries = await Future.wait(
      HardwarePermission.values.map((permission) async {
        return MapEntry(permission, await status(permission));
      }),
    );
    return HardwarePermissionSnapshot(
      Map<HardwarePermission, HardwarePermissionStatus>.fromEntries(entries),
    );
  }

  /// Opens the host app settings page.
  Future<bool> openAppSettings() =>
      NexoraSdkPlatform.instance.openAppSettings();
}
