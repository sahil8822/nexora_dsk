#include "include/nexora_sdk/nexora_sdk_plugin.h"
#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>
#include <memory>

namespace nexora_sdk {
class NexoraSdkPlugin : public flutter::Plugin {
 public:
  static void RegisterWithRegistrar(flutter::PluginRegistrarWindows *registrar);
  NexoraSdkPlugin();
  virtual ~NexoraSdkPlugin();
 private:
  void HandleMethodCall(const flutter::MethodCall<flutter::EncodableValue> &method_call,
                        std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
};

void NexoraSdkPlugin::RegisterWithRegistrar(flutter::PluginRegistrarWindows *registrar) {
  auto channel = std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
      registrar->messenger(), "nexora_sdk/methods", &flutter::StandardMethodCodec::GetInstance());
  auto plugin = std::make_unique<NexoraSdkPlugin>();
  channel->SetMethodCallHandler([plugin_pointer = plugin.get()](const auto &call, auto result) {
    plugin_pointer->HandleMethodCall(call, std::move(result));
  });
  registrar->AddPlugin(std::move(plugin));
}

NexoraSdkPlugin::NexoraSdkPlugin() {}
NexoraSdkPlugin::~NexoraSdkPlugin() {}

void NexoraSdkPlugin::HandleMethodCall(const flutter::MethodCall<flutter::EncodableValue> &method_call,
                                       std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  if (method_call.method_name().compare("getPlatformVersion") == 0) {
    result->Success(flutter::EncodableValue("Windows"));
  } else {
    result->NotImplemented();
  }
}
}
