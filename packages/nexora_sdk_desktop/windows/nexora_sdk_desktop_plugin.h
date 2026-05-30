#ifndef FLUTTER_PLUGIN_NEXORA_SDK_DESKTOP_PLUGIN_H_
#define FLUTTER_PLUGIN_NEXORA_SDK_DESKTOP_PLUGIN_H_

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>
#include <memory>

#include "pigeon/hardware_api.g.h"

namespace nexora_sdk_desktop {

class NexoraSdkDesktopPlugin : public flutter::Plugin,
                               public nexora_sdk::HardwareApi,
                               public nexora_sdk::AudioApi,
                               public nexora_sdk::LocationApi,
                               public nexora_sdk::SensorApi,
                               public nexora_sdk::BiometricsApi,
                               public nexora_sdk::BluetoothApi,
                               public nexora_sdk::SecureStorageApi,
                               public nexora_sdk::SystemApi,
                               public nexora_sdk::CryptoApi,
                               public nexora_sdk::AiApi {
 public:
  static void RegisterWithRegistrar(flutter::PluginRegistrarWindows *registrar);

  NexoraSdkDesktopPlugin();
  virtual ~NexoraSdkDesktopPlugin();

  // Disallow copy and assign.
  NexoraSdkDesktopPlugin(const NexoraSdkDesktopPlugin&) = delete;
  NexoraSdkDesktopPlugin& operator=(const NexoraSdkDesktopPlugin&) = delete;

  // --- HardwareApi ---
  void StartCameraPreview(
      const nexora_sdk::NexoraCameraOptions& options,
      std::function<void(std::optional<flutter::FlutterErrorOr<int64_t>> reply)> result) override;
  void StopCameraPreview(
      std::function<void(std::optional<flutter::FlutterErrorOr<bool>> reply)> result) override;
  void TakePicture(
      std::function<void(std::optional<flutter::FlutterErrorOr<std::string>> reply)> result) override;
  void SwitchCamera(
      std::function<void(std::optional<flutter::FlutterErrorOr<bool>> reply)> result) override;
  void SetFlashMode(
      const std::string& mode,
      std::function<void(std::optional<flutter::FlutterErrorOr<bool>> reply)> result) override;

  // --- BluetoothApi ---
  void StartBluetoothScan(
      std::function<void(std::optional<flutter::FlutterErrorOr<bool>> reply)> result) override;
  void StopBluetoothScan(
      std::function<void(std::optional<flutter::FlutterErrorOr<bool>> reply)> result) override;
  void ConnectToDevice(
      const std::string& device_id,
      std::function<void(std::optional<flutter::FlutterErrorOr<bool>> reply)> result) override;
  void DisconnectDevice(
      const std::string& device_id,
      std::function<void(std::optional<flutter::FlutterErrorOr<bool>> reply)> result) override;
  void GetConnectedDevices(
      std::function<void(std::optional<flutter::FlutterErrorOr<flutter::EncodableList>> reply)> result) override;
  void SendData(
      const std::string& device_id,
      const std::string& service_uuid,
      const std::string& characteristic_uuid,
      const std::vector<uint8_t>& data,
      std::function<void(std::optional<flutter::FlutterErrorOr<bool>> reply)> result) override;
  void ReadData(
      const std::string& device_id,
      const std::string& service_uuid,
      const std::string& characteristic_uuid,
      std::function<void(std::optional<flutter::FlutterErrorOr<std::vector<uint8_t>>> reply)> result) override;
  void ReadRssi(
      const std::string& device_id,
      std::function<void(std::optional<flutter::FlutterErrorOr<int64_t>> reply)> result) override;

  // --- BiometricsApi ---
  void CanAuthenticate(
      std::function<void(std::optional<flutter::FlutterErrorOr<bool>> reply)> result) override;
  void AuthenticateWithOptions(
      const nexora_sdk::BiometricPromptOptions& options,
      std::function<void(std::optional<flutter::FlutterErrorOr<bool>> reply)> result) override;

  // [Other Pigeon interfaces are stubbed in .cpp]
};

}  // namespace nexora_sdk_desktop

#endif  // FLUTTER_PLUGIN_NEXORA_SDK_DESKTOP_PLUGIN_H_
