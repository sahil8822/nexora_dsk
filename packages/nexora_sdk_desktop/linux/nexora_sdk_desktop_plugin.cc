#include "nexora_sdk_desktop_plugin.h"
#include <flutter_linux/flutter_linux.h>
#include <gio/gio.h>
#include <iostream>

#define NEXORA_SDK_DESKTOP_PLUGIN(obj) \
  (G_TYPE_CHECK_INSTANCE_CAST((obj), nexora_sdk_desktop_plugin_get_type(), \
                              NexoraSdkDesktopPlugin))

struct _NexoraSdkDesktopPlugin {
  GObject parent_instance;
  GDBusConnection* dbus_connection;
};

G_DEFINE_TYPE(NexoraSdkDesktopPlugin, nexora_sdk_desktop_plugin, g_object_get_type())

static void nexora_sdk_desktop_plugin_class_init(NexoraSdkDesktopPluginClass* klass) {
}

static void nexora_sdk_desktop_plugin_init(NexoraSdkDesktopPlugin* self) {
    GError* error = nullptr;
    self->dbus_connection = g_bus_get_sync(G_BUS_TYPE_SYSTEM, nullptr, &error);
    if (error != nullptr) {
        std::cerr << "Failed to connect to system D-Bus: " << error->message << std::endl;
        g_error_free(error);
    }
}

void nexora_sdk_desktop_plugin_register_with_registrar(FlPluginRegistrar* registrar) {
  NexoraSdkDesktopPlugin* plugin = NEXORA_SDK_DESKTOP_PLUGIN(
      g_object_new(nexora_sdk_desktop_plugin_get_type(), nullptr));

  // Linux Pigeon API Registration would go here
  // Pigeon currently generates C++ headers that are not strictly GObject compatible without wrappers.
  // In a full implementation, we bridge the Pigeon C++ virtual methods to GDBus asynchronous calls.

  g_object_unref(plugin);
}

// --- BlueZ (D-Bus) ---
void scan_bluetooth_devices(NexoraSdkDesktopPlugin* self) {
    if (!self->dbus_connection) return;
    // D-Bus call to org.bluez.Adapter1.StartDiscovery
}

// --- GeoClue (D-Bus) ---
void get_location(NexoraSdkDesktopPlugin* self) {
    if (!self->dbus_connection) return;
    // D-Bus call to org.freedesktop.GeoClue2.Client.LocationUpdated
}
