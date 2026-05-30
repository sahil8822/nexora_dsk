import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// A native-like camera preview widget.
/// Renders the hardware camera stream from the underlying texture ID.
class NexoraCameraPreview extends StatelessWidget {
  /// The unique texture ID returned by `startCamera`.
  final int textureId;

  /// API Documentation for NexoraCameraPreview.
  const NexoraCameraPreview({super.key, required this.textureId});

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return HtmlElementView(viewType: 'nexora_camera_preview_$textureId');
    }
    return Texture(textureId: textureId);
  }
}
