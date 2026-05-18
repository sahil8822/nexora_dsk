import '../../nexora_sdk_platform_interface.dart';
import '../../models/hardware_models.dart';

/// Module for managing system energy levels, battery status, and thermal thresholds.
class UtilityModule {
  /// Enables or disables system-wide power-saving EcoMode.
  Future<void> setEcoModeEnabled(bool enabled) {
    return NexoraSdkPlatform.instance.setEcoModeEnabled(enabled);
  }

  /// Returns whether EcoMode is currently active (auto-triggered by battery status).
  Future<bool> isEcoModeActive() {
    return NexoraSdkPlatform.instance.isEcoModeActive();
  }

  /// Gets the current physical device thermal state.
  Future<DeviceThermalState> getThermalState() {
    return NexoraSdkPlatform.instance.getThermalState();
  }
}
