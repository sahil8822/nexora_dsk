import 'dart:typed_data';
import 'modules/camera/camera_module.dart';
import 'modules/bluetooth/bluetooth_module.dart';
import 'core/hardware_core.dart';
import 'my_hardware_plugin_platform_interface.dart';

export 'models/hardware_models.dart';
export 'core/hardware_core.dart';
export 'modules/camera/camera_module.dart';
export 'modules/bluetooth/bluetooth_module.dart';

/// The Entry Point for the High-Performance Modular Hardware SDK.
class MyHardwarePlugin {
  static final MyHardwarePlugin instance = MyHardwarePlugin._();
  MyHardwarePlugin._();

  // Specialized Modules
  final CameraModule camera = CameraModule();
  final BluetoothModule bluetooth = BluetoothModule();

  /// Returns the platform version string.
  Future<String?> getPlatformVersion() {
    return MyHardwarePluginPlatform.instance.getPlatformVersion();
  }

  /// Low-level unified listener for all hardware events.
  Stream<HardwareEvent> get unifiedStream => MyHardwarePluginPlatform.instance.unifiedStream;

  /// Performance monitoring: Track FPS of the binary stream
  double _fps = 0;
  double get currentFps => _fps;

  void trackPerformance(Uint8List frame) {
    // Logic to calculate FPS
  }
}
