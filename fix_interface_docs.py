with open('packages/nexora_sdk_platform_interface/lib/nexora_sdk_platform_interface.dart', 'r') as f:
    text = f.read()

text = text.replace(
"""  /// API Documentation for subscribeToCharacteristic.
  Future<bool> subscribeToCharacteristic(
    String deviceId,
    String serviceId,
    String charId,
    bool enable,
  ) {""",
"""  /// API Documentation for subscribeToCharacteristic.
  Future<bool> subscribeToCharacteristic(
    String deviceId,
    String serviceId,
    String charId, {
    required bool enable,
  }) {""")

with open('packages/nexora_sdk_platform_interface/lib/nexora_sdk_platform_interface.dart', 'w') as f:
    f.write(text)

with open('packages/nexora_sdk_platform_interface/lib/nexora_sdk_method_channel.dart', 'r') as f:
    text2 = f.read()

text2 = text2.replace(
"""  @override
  Future<bool> subscribeToCharacteristic(
    String deviceId,
    String serviceId,
    String charId,
    bool enable,
  ) async {""",
"""  @override
  Future<bool> subscribeToCharacteristic(
    String deviceId,
    String serviceId,
    String charId, {
    required bool enable,
  }) async {""")

with open('packages/nexora_sdk_platform_interface/lib/nexora_sdk_method_channel.dart', 'w') as f:
    f.write(text2)
