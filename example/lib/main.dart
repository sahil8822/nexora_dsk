import 'package:flutter/material.dart';
import 'dart:async';
import 'package:nexora_sdk/nexora_sdk.dart';
import 'package:nexora_sdk/models/hardware_models.dart';

void main() {
  runApp(const MyApp());
}

/// Root widget of the Nexora Ultra-Performance Intelligence Demo.
class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _sdk = NexoraSdk.instance;
  
  // Performance-Optimized States
  StreamSubscription? _cameraSub;
  StreamSubscription? _audioSub;
  
  int? _textureId;
  bool _isCameraRunning = false;
  bool _isVisionFace = false;
  bool _isVisionBarcode = false;
  bool _isAudioRunning = false;
  bool _isLogging = false;
  
  List<double> _audioSpectrum = [];
  int _faceCount = 0;
  int _barcodeCount = 0;

  @override
  void initState() {
    super.initState();
    _initSDK();
  }

  /// Initializes the SDK and requests necessary permissions.
  Future<void> _initSDK() async {
    final granted = await _sdk.requestPermissions();
    if (granted) {
      _setupListeners();
    }
  }

  /// Sets up high-performance hardware event listeners.
  void _setupListeners() {
    _cameraSub = _sdk.camera.stream.listen((frame) {
      if (!mounted) return;
      setState(() {
        if (frame.vision != null) {
          _faceCount = frame.vision!.faces.length;
          _barcodeCount = frame.vision!.barcodes.length;
        }
      });
    });

    _audioSub = _sdk.audio.stream.listen((frame) {
      if (!mounted || !_isAudioRunning) return;
      // Normalizing spectrum for visual consistency
      setState(() { _audioSpectrum = frame.spectrum; });
    });
  }

  @override
  void dispose() {
    _cameraSub?.cancel();
    _audioSub?.cancel();
    _sdk.camera.stop();
    _sdk.audio.stop();
    _sdk.stopLogging();
    super.dispose();
  }

  // --- Optimized Actions ---
  
  void _toggleCamera() async {
    try {
      if (_isCameraRunning) {
        await _sdk.camera.stop();
        setState(() { _isCameraRunning = false; _textureId = null; });
      } else {
        final id = await _sdk.camera.start();
        setState(() { _isCameraRunning = true; _textureId = id; });
      }
    } catch (e) {
      _showError("Camera Initialization Failed");
    }
  }

  void _toggleVision(String mode) async {
    if (mode == 'face') _isVisionFace = !_isVisionFace;
    if (mode == 'barcode') _isVisionBarcode = !_isVisionBarcode;
    await _sdk.setVisionMode(face: _isVisionFace, barcode: _isVisionBarcode);
    setState(() {});
  }

  void _toggleLogging() async {
    try {
      if (_isLogging) {
        await _sdk.stopLogging();
        setState(() => _isLogging = false);
      } else {
        final ok = await _sdk.startLogging(LogConfig(fileName: "ultra_telemetry.csv", intervalMs: 500));
        if (ok) setState(() => _isLogging = true);
      }
    } catch (e) {
      _showError("Telemetry Logging Failed");
    }
  }

  void _showError(String msg) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(msg), 
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true, 
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueAccent, brightness: Brightness.dark)
      ),
      home: Scaffold(
        appBar: AppBar(title: const Text('Nexora v3.0 Intelligence'), centerTitle: true),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildMetricsCard(),
            const SizedBox(height: 24),
            _buildSectionHeader('Smart GPU Vision', Icons.auto_awesome),
            Card(
              clipBehavior: Clip.antiAlias,
              elevation: 4,
              child: Column(
                children: [
                  Container(
                    height: 250, width: double.infinity, color: Colors.black,
                    child: _textureId == null 
                      ? const Center(child: Icon(Icons.videocam_off, size: 64, color: Colors.white24))
                      : RepaintBoundary(child: Texture(textureId: _textureId!)),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildChip('Faces', _isVisionFace, () => _toggleVision('face')),
                      _buildChip('Barcodes', _isVisionBarcode, () => _toggleVision('barcode')),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 45)),
                      onPressed: _toggleCamera,
                      icon: Icon(_isCameraRunning ? Icons.stop_circle : Icons.play_circle_filled),
                      label: Text(_isCameraRunning ? 'STOP CAMERA' : 'START SMART VISION'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _buildSectionHeader('Native FFT Analysis', Icons.graphic_eq),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    SizedBox(
                      height: 80,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: _audioSpectrum.take(40).map((v) => Expanded(
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 1), 
                            height: (v * 200).clamp(4.0, 80.0), 
                            decoration: BoxDecoration(
                              color: Colors.cyanAccent,
                              borderRadius: BorderRadius.circular(2)
                            ),
                          ),
                        )).toList(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton(
                      onPressed: () async {
                        if (_isAudioRunning) await _sdk.audio.stop(); else await _sdk.startAudioWithAnalysis();
                        setState(() => _isAudioRunning = !_isAudioRunning);
                      }, 
                      child: Text(_isAudioRunning ? 'STOP AUDIO FFT' : 'START REAL-TIME FFT')
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            _buildSectionHeader('Hardware Telemetry', Icons.settings_remote),
            ListTile(
              tileColor: Colors.white12,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              leading: Icon(Icons.history_edu, color: _isLogging ? Colors.greenAccent : Colors.white60),
              title: const Text('Background CSV Logging'),
              subtitle: Text(_isLogging ? 'Logging to ultra_telemetry.csv' : 'Inactive'),
              trailing: Switch(value: _isLogging, onChanged: (_) => _toggleLogging()),
            ),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricsCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Colors.blue, Colors.deepPurpleAccent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight
        ), 
        borderRadius: BorderRadius.circular(28),
        boxShadow: [BoxShadow(color: Colors.blue.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 6))]
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildMetric('Faces', '$_faceCount'),
          _buildMetric('Barcodes', '$_barcodeCount'),
          _buildMetric('System', _isCameraRunning ? 'ACTIVE' : 'IDLE'),
        ],
      ),
    );
  }

  Widget _buildMetric(String l, String v) => Column(children: [Text(v, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white)), Text(l, style: const TextStyle(fontSize: 13, color: Colors.white70))]);
  
  Widget _buildSectionHeader(String t, IconData i) => Padding(padding: const EdgeInsets.fromLTRB(8, 0, 8, 12), child: Row(children: [Icon(i, size: 20, color: Colors.blueAccent), const SizedBox(width: 10), Text(t, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))]));

  Widget _buildChip(String l, bool s, VoidCallback o) => FilterChip(label: Text(l), selected: s, onSelected: (_) => o(), backgroundColor: Colors.white10);
}
