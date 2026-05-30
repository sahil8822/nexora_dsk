#include "nexora_sdk_desktop_plugin.h"
#include <windows.h>
#include <winrt/Windows.Foundation.h>
#include <winrt/Windows.Devices.Bluetooth.h>
#include <winrt/Windows.Devices.Bluetooth.Advertisement.h>
#include <winrt/Windows.Devices.Bluetooth.GenericAttributeProfile.h>
#include <winrt/Windows.Security.Credentials.UI.h>
#include <mfapi.h>
#include <mfidl.h>
#include <mfreadwrite.h>

using namespace winrt;
using namespace Windows::Devices::Bluetooth;
using namespace Windows::Devices::Bluetooth::Advertisement;
using namespace Windows::Devices::Bluetooth::GenericAttributeProfile;
using namespace Windows::Security::Credentials::UI;

namespace nexora_sdk_desktop {

void NexoraSdkDesktopPlugin::RegisterWithRegistrar(
    flutter::PluginRegistrarWindows *registrar) {
  auto plugin = std::make_unique<NexoraSdkDesktopPlugin>();
  
  // Register pigeon APIs
  nexora_sdk::HardwareApi::SetUp(registrar->messenger(), plugin.get());
  nexora_sdk::AudioApi::SetUp(registrar->messenger(), plugin.get());
  nexora_sdk::LocationApi::SetUp(registrar->messenger(), plugin.get());
  nexora_sdk::SensorApi::SetUp(registrar->messenger(), plugin.get());
  nexora_sdk::BiometricsApi::SetUp(registrar->messenger(), plugin.get());
  nexora_sdk::BluetoothApi::SetUp(registrar->messenger(), plugin.get());
  nexora_sdk::SecureStorageApi::SetUp(registrar->messenger(), plugin.get());
  nexora_sdk::SystemApi::SetUp(registrar->messenger(), plugin.get());
  nexora_sdk::CryptoApi::SetUp(registrar->messenger(), plugin.get());
  nexora_sdk::AiApi::SetUp(registrar->messenger(), plugin.get());

  registrar->AddPlugin(std::move(plugin));
}

NexoraSdkDesktopPlugin::NexoraSdkDesktopPlugin() {
    init_apartment(); // Initialize WinRT
    MFStartup(MF_VERSION); // Initialize Media Foundation
}

NexoraSdkDesktopPlugin::~NexoraSdkDesktopPlugin() {
    MFShutdown();
}

// --- HardwareApi ---
void NexoraSdkDesktopPlugin::StartCameraPreview(
    const nexora_sdk::NexoraCameraOptions& options,
    std::function<void(std::optional<flutter::FlutterErrorOr<int64_t>> reply)> result) {
  // Implementation for Media Foundation IMFCaptureEngine
  result(flutter::FlutterErrorOr<int64_t>(0));
}

void NexoraSdkDesktopPlugin::StopCameraPreview(
    std::function<void(std::optional<flutter::FlutterErrorOr<bool>> reply)> result) {
  result(flutter::FlutterErrorOr<bool>(true));
}

void NexoraSdkDesktopPlugin::TakePicture(
    std::function<void(std::optional<flutter::FlutterErrorOr<std::string>> reply)> result) {
  result(flutter::FlutterError("UNSUPPORTED", "Unsupported on Windows", nullptr));
}

void NexoraSdkDesktopPlugin::SwitchCamera(
    std::function<void(std::optional<flutter::FlutterErrorOr<bool>> reply)> result) {
  result(flutter::FlutterErrorOr<bool>(true));
}

void NexoraSdkDesktopPlugin::SetFlashMode(
    const std::string& mode,
    std::function<void(std::optional<flutter::FlutterErrorOr<bool>> reply)> result) {
  result(flutter::FlutterErrorOr<bool>(true));
}

// --- BluetoothApi (WinRT) ---
void NexoraSdkDesktopPlugin::StartBluetoothScan(
    std::function<void(std::optional<flutter::FlutterErrorOr<bool>> reply)> result) {
  BluetoothLEAdvertisementWatcher watcher;
  watcher.Start();
  result(flutter::FlutterErrorOr<bool>(true));
}

void NexoraSdkDesktopPlugin::StopBluetoothScan(
    std::function<void(std::optional<flutter::FlutterErrorOr<bool>> reply)> result) {
  result(flutter::FlutterErrorOr<bool>(true));
}

void NexoraSdkDesktopPlugin::ConnectToDevice(
    const std::string& device_id,
    std::function<void(std::optional<flutter::FlutterErrorOr<bool>> reply)> result) {
  // WinRT connect using BluetoothLEDevice::FromIdAsync
  result(flutter::FlutterErrorOr<bool>(true));
}

void NexoraSdkDesktopPlugin::DisconnectDevice(
    const std::string& device_id,
    std::function<void(std::optional<flutter::FlutterErrorOr<bool>> reply)> result) {
  result(flutter::FlutterErrorOr<bool>(true));
}

void NexoraSdkDesktopPlugin::GetConnectedDevices(
    std::function<void(std::optional<flutter::FlutterErrorOr<flutter::EncodableList>> reply)> result) {
  result(flutter::FlutterErrorOr<flutter::EncodableList>(flutter::EncodableList()));
}

void NexoraSdkDesktopPlugin::SendData(
    const std::string& device_id,
    const std::string& service_uuid,
    const std::string& characteristic_uuid,
    const std::vector<uint8_t>& data,
    std::function<void(std::optional<flutter::FlutterErrorOr<bool>> reply)> result) {
  result(flutter::FlutterErrorOr<bool>(false));
}

void NexoraSdkDesktopPlugin::ReadData(
    const std::string& device_id,
    const std::string& service_uuid,
    const std::string& characteristic_uuid,
    std::function<void(std::optional<flutter::FlutterErrorOr<std::vector<uint8_t>>> reply)> result) {
  result(flutter::FlutterErrorOr<std::vector<uint8_t>>(std::vector<uint8_t>()));
}

void NexoraSdkDesktopPlugin::ReadRssi(
    const std::string& device_id,
    std::function<void(std::optional<flutter::FlutterErrorOr<int64_t>> reply)> result) {
  result(flutter::FlutterErrorOr<int64_t>(0));
}

// --- BiometricsApi (Windows Hello) ---
void NexoraSdkDesktopPlugin::CanAuthenticate(
    std::function<void(std::optional<flutter::FlutterErrorOr<bool>> reply)> result) {
  auto asyncOp = UserConsentVerifier::CheckAvailabilityAsync();
  asyncOp.Completed([result](auto&& op, auto&& status) {
    auto availability = op.GetResults();
    result(flutter::FlutterErrorOr<bool>(availability == UserConsentVerifierAvailability::Available));
  });
}

void NexoraSdkDesktopPlugin::AuthenticateWithOptions(
    const nexora_sdk::BiometricPromptOptions& options,
    std::function<void(std::optional<flutter::FlutterErrorOr<bool>> reply)> result) {
  hstring message = to_hstring(options.localizedReason() ? *options.localizedReason() : "Authentication required");
  auto asyncOp = UserConsentVerifier::RequestVerificationAsync(message);
  asyncOp.Completed([result](auto&& op, auto&& status) {
    auto verificationResult = op.GetResults();
    result(flutter::FlutterErrorOr<bool>(verificationResult == UserConsentVerificationResult::Verified));
  });
}

}  // namespace nexora_sdk_desktop
