#include "include/nexora_sdk/nexora_sdk_plugin.h"
#include <flutter_linux/flutter_linux.h>
#include <gtk/gtk.h>

#define NEXORA_SDK_PLUGIN(obj) \
  (G_TYPE_CHECK_INSTANCE_CAST((obj), nexora_sdk_plugin_get_type(), \
                              NexoraSdkPlugin))

struct _NexoraSdkPlugin {
  GObject parent_instance;
};

G_DEFINE_TYPE(NexoraSdkPlugin, nexora_sdk_plugin, g_object_get_type())

static void nexora_sdk_plugin_handle_method_call(NexoraSdkPlugin* self, FlMethodCall* method_call) {
  g_autoptr(FlMethodResponse) response = nullptr;
  const gchar* method = fl_method_call_get_name(method_call);
  if (strcmp(method, "getPlatformVersion") == 0) {
    response = FL_METHOD_RESPONSE(fl_method_success_response_new(fl_value_new_string("Linux")));
  } else {
    response = FL_METHOD_RESPONSE(fl_method_not_implemented_response_new());
  }
  fl_method_call_respond(method_call, response, nullptr);
}

static void nexora_sdk_plugin_dispose(GObject* object) {
  G_OBJECT_CLASS(nexora_sdk_plugin_parent_class)->dispose(object);
}

static void nexora_sdk_plugin_class_init(NexoraSdkPluginClass* klass) {
  G_OBJECT_CLASS(klass)->dispose = nexora_sdk_plugin_dispose;
}

static void nexora_sdk_plugin_init(NexoraSdkPlugin* self) {}

void nexora_sdk_plugin_register_with_registrar(FlPluginRegistrar* registrar) {
  NexoraSdkPlugin* plugin = NEXORA_SDK_PLUGIN(g_object_new(nexora_sdk_plugin_get_type(), nullptr));
  g_autoptr(FlStandardMethodCodec) codec = fl_standard_method_codec_new();
  g_autoptr(FlMethodChannel) channel = fl_method_channel_new(fl_plugin_registrar_get_messenger(registrar), "nexora_sdk/methods", FL_METHOD_CODEC(codec));
  fl_method_channel_set_method_call_handler(channel, (FlMethodCallHandler)nexora_sdk_plugin_handle_method_call, g_object_ref(plugin), g_object_unref);
  g_object_unref(plugin);
}
