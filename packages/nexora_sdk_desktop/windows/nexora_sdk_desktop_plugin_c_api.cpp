#include "include/nexora_sdk_desktop/nexora_sdk_desktop_plugin_c_api.h"

#include <flutter/plugin_registrar_windows.h>

#include "nexora_sdk_desktop_plugin.h"

void NexoraSdkDesktopPluginCApiRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  nexora_sdk_desktop::NexoraSdkDesktopPlugin::RegisterWithRegistrar(
      flutter::PluginRegistrarManager::GetInstance()
          ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
}
