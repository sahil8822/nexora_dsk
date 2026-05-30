import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';

class NexoraArView extends StatelessWidget {
  final Map<String, dynamic> creationParams;

  const NexoraArView({Key? key, this.creationParams = const {}})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    const String viewType = 'nexora_ar_view';

    if (Platform.isAndroid) {
      return AndroidView(
        viewType: viewType,
        layoutDirection: TextDirection.ltr,
        creationParams: creationParams,
        creationParamsCodec: const StandardMessageCodec(),
      );
    } else if (Platform.isIOS) {
      return UiKitView(
        viewType: viewType,
        layoutDirection: TextDirection.ltr,
        creationParams: creationParams,
        creationParamsCodec: const StandardMessageCodec(),
      );
    }

    return const Center(child: Text('AR View not supported on this platform'));
  }
}
