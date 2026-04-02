import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'package:my_hardware_plugin/my_hardware_plugin.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _sdk = MyHardwarePlugin.instance;
  
  bool _isCameraRunning = false;
  Uint8List? _lastFrame;
  int _frameCount = 0;
  DateTime? _start;

  void _toggleCamera() async {
    if (_isCameraRunning) {
      await _sdk.camera.stop();
      setState(() {
        _isCameraRunning = false;
        _lastFrame = null;
      });
    } else {
      await _sdk.camera.start();
      _start = DateTime.now();
      _sdk.camera.frameStream.listen((frame) {
        setState(() {
          _lastFrame = frame;
          _frameCount++;
        });
      });
      setState(() => _isCameraRunning = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: Scaffold(
        appBar: AppBar(title: const Text('Performance Modular SDK')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('FPS: ${(_frameCount / (DateTime.now().difference(_start ?? DateTime.now()).inSeconds + 1)).toStringAsFixed(1)}',
                style: const TextStyle(fontSize: 24, color: Colors.cyan)),
              const SizedBox(height: 20),
              _lastFrame == null 
                  ? const Icon(Icons.videocam_off, size: 100, color: Colors.grey)
                  : Container(
                      height: 200,
                      width: 200,
                      decoration: BoxDecoration(border: Border.all(color: Colors.cyan)),
                      child: Center(child: Text('Frame: ${_lastFrame!.lengthInBytes} bytes')),
                    ),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: _toggleCamera,
                child: Text(_isCameraRunning ? 'STOP CAMERA' : 'START CAMERA'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
