import 'package:nexora_sdk_platform_interface/nexora_sdk_platform_interface.dart';

/// Native convenience APIs that make Flutter apps feel platform-integrated.
class NativeModule {
  /// Copies [text] into the system clipboard.
  Future<bool> copyText(String text) {
    if (text.isEmpty) {
      throw ArgumentError.value(text, 'text', 'Text cannot be empty.');
    }
    return NexoraSdkPlatform.instance.copyText(text);
  }

  /// Reads plain text from the system clipboard.
  Future<String?> pasteText() => NexoraSdkPlatform.instance.pasteText();

  /// Opens a URL or platform deep link.
  Future<bool> openUrl(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null || !uri.hasScheme) {
      throw ArgumentError.value(url, 'url', 'Use a valid absolute URL.');
    }
    return NexoraSdkPlatform.instance.openUrl(url);
  }

  /// Opens the platform share sheet with text and an optional subject.
  Future<bool> shareText(String text, {String? subject}) {
    if (text.trim().isEmpty) {
      throw ArgumentError.value(text, 'text', 'Text cannot be empty.');
    }
    return NexoraSdkPlatform.instance.shareText(text, subject: subject);
  }
}
