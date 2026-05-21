with open('packages/nexora_sdk_platform_interface/lib/nexora_sdk_platform_interface.dart', 'r') as f:
    text = f.read()

# Update startCamera
text = text.replace("Future<dynamic> startCamera({int width = 1280, int height = 720});", "Future<int?> startCamera({int width = 1280, int height = 720});")
text = text.replace("Future<dynamic> startCameraWithOptions(CameraOptions options);", "Future<int?> startCameraWithOptions(CameraOptions options);")

# Add new methods at the end of the class, before the closing brace
new_methods = """
  /// API Documentation for subscribeToCharacteristic.
  Future<bool> subscribeToCharacteristic(
    String deviceId,
    String serviceId,
    String charId,
    bool enable,
  ) {
    throw UnimplementedError(
      'subscribeToCharacteristic() has not been implemented.',
    );
  }

  /// API Documentation for requestMtu.
  Future<bool> requestMtu(String deviceId, int mtu) {
    throw UnimplementedError('requestMtu() has not been implemented.');
  }

  /// API Documentation for saveToGallery.
  Future<String?> saveToGallery(String filePath) {
    throw UnimplementedError('saveToGallery() has not been implemented.');
  }

  /// API Documentation for startForegroundService.
  Future<bool> startForegroundService({
    required String title,
    required String content,
  }) {
    throw UnimplementedError(
      'startForegroundService() has not been implemented.',
    );
  }

  /// API Documentation for stopForegroundService.
  Future<bool> stopForegroundService() {
    throw UnimplementedError(
      'stopForegroundService() has not been implemented.',
    );
  }
}"""
text = text.rsplit('}', 1)[0] + new_methods + '\n'

with open('packages/nexora_sdk_platform_interface/lib/nexora_sdk_platform_interface.dart', 'w') as f:
    f.write(text)


with open('packages/nexora_sdk_platform_interface/lib/nexora_sdk_method_channel.dart', 'r') as f:
    text2 = f.read()

text2 = text2.replace("Future<dynamic> startCamera({int width = 1280, int height = 720}) async {", "Future<int?> startCamera({int width = 1280, int height = 720}) async {")
text2 = text2.replace("return methodChannel.invokeMethod('startCamera', {", "return methodChannel.invokeMethod<int>('startCamera', {")
text2 = text2.replace("Future<dynamic> startCameraWithOptions(CameraOptions options) async {", "Future<int?> startCameraWithOptions(CameraOptions options) async {")
text2 = text2.replace("return methodChannel.invokeMethod('startCamera', options.toMap());", "return methodChannel.invokeMethod<int>('startCamera', options.toMap());")

new_methods_mc = """
  @override
  Future<bool> subscribeToCharacteristic(
    String deviceId,
    String serviceId,
    String charId,
    bool enable,
  ) async {
    final result = await methodChannel.invokeMethod<bool>(
      'subscribeToCharacteristic',
      {
        'deviceId': deviceId,
        'serviceId': serviceId,
        'charId': charId,
        'enable': enable,
      },
    );
    return result ?? false;
  }

  @override
  Future<bool> requestMtu(String deviceId, int mtu) async {
    final result = await methodChannel.invokeMethod<bool>('requestMtu', {
      'deviceId': deviceId,
      'mtu': mtu,
    });
    return result ?? false;
  }

  @override
  Future<String?> saveToGallery(String filePath) async {
    return methodChannel.invokeMethod<String>('saveToGallery', {
      'filePath': filePath,
    });
  }

  @override
  Future<bool> startForegroundService({
    required String title,
    required String content,
  }) async {
    final result = await methodChannel.invokeMethod<bool>(
      'startForegroundService',
      {'title': title, 'content': content},
    );
    return result ?? false;
  }

  @override
  Future<bool> stopForegroundService() async {
    final result =
        await methodChannel.invokeMethod<bool>('stopForegroundService');
    return result ?? false;
  }
}"""

text2 = text2.rsplit('}', 1)[0] + new_methods_mc + '\n'

with open('packages/nexora_sdk_platform_interface/lib/nexora_sdk_method_channel.dart', 'w') as f:
    f.write(text2)

