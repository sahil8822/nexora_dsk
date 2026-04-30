import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'package:nexora_sdk/nexora_sdk.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _sdk = NexoraSdk.instance;
  
  bool _isCameraRunning = false;
  bool _isLocationRunning = false;
  bool _isSensorRunning = false;
  Uint8List? _lastFrameBytes;
  String _locationInfo = 'Location: Stopped';
  String _sensorInfo = 'Sensors: Stopped';
  int _frameCount = 0;
  DateTime? _start;

  @override
  void initState() {
    super.initState();
    // Listen to unified stream for sensor data
    _sdk.sensor.stream.listen((event) {
      if (mounted && _isSensorRunning && event.module == 'sensor') {
        final data = event.data as Map;
        setState(() {
          _sensorInfo = 'Accel: x:${data['x']?.toStringAsFixed(2)}, y:${data['y']?.toStringAsFixed(2)}';
        });
      }
    });

    // Listen to location stream
    _sdk.location.stream.listen((loc) {
      if (mounted && _isLocationRunning) {
        setState(() {
          _locationInfo = 'Lat: ${loc.latitude.toStringAsFixed(4)}, Lon: ${loc.longitude.toStringAsFixed(4)}';
        });
      }
    });
  }

  void _toggleCamera() async {
    if (_isCameraRunning) {
      await _sdk.camera.stop();
      setState(() {
        _isCameraRunning = false;
        _lastFrameBytes = null;
      });
    } else {
      await _sdk.camera.start();
      _start = DateTime.now();
      _sdk.camera.stream.listen((frame) {
        if (mounted) {
          setState(() {
            _lastFrameBytes = frame.bytes;
            _frameCount++;
          });
        }
      });
      setState(() => _isCameraRunning = true);
    }
  }

  void _toggleLocation() async {
    if (_isLocationRunning) {
      await _sdk.location.stop();
      setState(() => _isLocationRunning = false);
    } else {
      await _sdk.location.start();
      setState(() => _isLocationRunning = true);
    }
  }

  void _toggleSensor() async {
    if (_isSensorRunning) {
      await _sdk.sensor.stop();
      setState(() {
        _isSensorRunning = false;
        _sensorInfo = 'Sensors: Stopped';
      });
    } else {
      await _sdk.sensor.start();
      setState(() => _isSensorRunning = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: Scaffold(
        appBar: AppBar(title: const Text('Nexora SDK Pro Dashboard')),
        body: SingleChildScrollView(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                _buildStatusCard('Camera', _isCameraRunning ? 'RUNNING' : 'STOPPED', _isCameraRunning ? Colors.green : Colors.red),
                Text('FPS: ${(_frameCount / (DateTime.now().difference(_start ?? DateTime.now()).inSeconds + 1)).toStringAsFixed(1)}'),
                const SizedBox(height: 10),
                _lastFrameBytes == null 
                    ? const Icon(Icons.videocam_off, size: 100, color: Colors.grey)
                    : Container(
                        height: 150,
                        width: 150,
                        decoration: BoxDecoration(border: Border.all(color: Colors.cyan)),
                        child: Center(child: Text('${_lastFrameBytes!.length} bytes')),
                      ),
                const SizedBox(height: 20),
                _buildStatusCard('Location', _locationInfo, _isLocationRunning ? Colors.blue : Colors.grey),
                _buildStatusCard('Sensors', _sensorInfo, _isSensorRunning ? Colors.orange : Colors.grey),
                const SizedBox(height: 30),
                ElevatedButton(
                  onPressed: _toggleCamera,
                  child: Text(_isCameraRunning ? 'STOP CAMERA' : 'START CAMERA'),
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: _toggleLocation,
                  child: Text(_isLocationRunning ? 'STOP LOCATION' : 'START LOCATION'),
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: _toggleSensor,
                  child: Text(_isSensorRunning ? 'STOP SENSOR' : 'START SENSOR'),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusCard(String title, String value, Color color) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(value, style: TextStyle(color: color)),
        ],
      ),
    );
  }
}
