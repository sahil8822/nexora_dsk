import 'package:flutter/material.dart';
import 'dart:async';
import 'package:nexora_sdk/nexora_sdk.dart';

void main() {
  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: IntelligenceDashboard(),
    ),
  );
}

class IntelligenceDashboard extends StatefulWidget {
  const IntelligenceDashboard({super.key});

  @override
  State<IntelligenceDashboard> createState() => _IntelligenceDashboardState();
}

class _IntelligenceDashboardState extends State<IntelligenceDashboard> {
  final _sdk = NexoraSdk.instance;

  StreamSubscription? _cameraSub;
  StreamSubscription? _audioSub;
  StreamSubscription? _locationSub;

  int? _textureId;
  bool _isCameraRunning = false;
  bool _isVisionFace = false;
  bool _isVisionBarcode = false;
  bool _isAudioRunning = false;
  bool _isLogging = false;

  List<double> _audioSpectrum = [];
  int _faceCount = 0;
  String _lastBarcode = "None";
  LocationData? _currentLocation;
  BatteryInfo? _batteryInfo;
  StorageInfo? _storageInfo;
  DeviceInfo? _deviceInfo;
  ConnectivityInfo? _connectivityInfo;
  HardwarePermissionSnapshot? _permissionSnapshot;
  HardwareLifecycleController? _lifecycleController;
  String _lastNativeAction = "Ready";
  List<FileInfo> _files = [];
  Timer? _healthTimer;

  @override
  void initState() {
    super.initState();
    _lifecycleController = _sdk.attachLifecycleController(stopLogging: false);
    _requestAllPermissions();
    _startPeriodicHealthCheck();
  }

  Future<void> _requestAllPermissions() async {
    await _sdk.requestPermissions();
    _setupListeners();
    _loadStorageInfo();
    _loadProInfo();
  }

  void _setupListeners() {
    _cameraSub = _sdk.camera.stream.listen((frame) {
      if (!mounted) return;
      setState(() {
        if (frame.vision != null) {
          _faceCount = frame.vision!.faces.length;
          if (frame.vision!.barcodes.isNotEmpty) {
            _lastBarcode = frame.vision!.barcodes.first;
          }
        }
      });
    });

    _audioSub = _sdk.audio.stream.listen((frame) {
      if (!mounted || !_isAudioRunning) return;
      setState(() {
        _audioSpectrum = frame.spectrum;
      });
    });

    _locationSub = _sdk.location.stream.listen((loc) {
      if (!mounted) return;
      setState(() {
        _currentLocation = loc;
      });
    });
  }

  void _startPeriodicHealthCheck() {
    _healthTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      final info = await _sdk.health.getBatteryInfo();
      if (mounted) {
        setState(() {
          _batteryInfo = info;
        });
      }
    });
  }

  Future<void> _loadStorageInfo() async {
    final info = await _sdk.storage.getStorageInfo();
    final files = await _sdk.storage.listFiles();
    if (mounted) {
      setState(() {
        _storageInfo = info;
        _files = files;
      });
    }
  }

  Future<void> _loadProInfo() async {
    final device = await _sdk.device.getInfo();
    final connectivity = await _sdk.connectivity.getInfo();
    final permissions = await _sdk.getPermissionSnapshot();
    if (mounted) {
      setState(() {
        _deviceInfo = device;
        _connectivityInfo = connectivity;
        _permissionSnapshot = permissions;
      });
    }
  }

  @override
  void dispose() {
    _cameraSub?.cancel();
    _audioSub?.cancel();
    _locationSub?.cancel();
    _healthTimer?.cancel();
    _lifecycleController?.dispose();
    _sdk.camera.stop();
    _sdk.audio.stop();
    _sdk.location.stop();
    super.dispose();
  }

  void _toggleCamera() async {
    if (_isCameraRunning) {
      await _sdk.camera.stop();
      setState(() {
        _isCameraRunning = false;
        _textureId = null;
      });
    } else {
      final id = await _sdk.camera.start();
      setState(() {
        _isCameraRunning = true;
        _textureId = id;
      });
    }
  }

  void _toggleVision(String type) async {
    if (type == 'face') _isVisionFace = !_isVisionFace;
    if (type == 'barcode') _isVisionBarcode = !_isVisionBarcode;
    await _sdk.setVisionMode(face: _isVisionFace, barcode: _isVisionBarcode);
    setState(() {});
  }

  void _toggleLogging() async {
    if (_isLogging) {
      await _sdk.stopLogging();
      setState(() => _isLogging = false);
    } else {
      await _sdk.startLogging(LogConfig(fileName: "nexora_telemetry.csv"));
      setState(() => _isLogging = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: CustomScrollView(
        slivers: [
          _buildAppBar(),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  _buildQuickStats(),
                  const SizedBox(height: 20),
                  _buildCameraCard(),
                  const SizedBox(height: 20),
                  _buildAudioCard(),
                  const SizedBox(height: 20),
                  _buildLocationCard(),
                  const SizedBox(height: 20),
                  _buildStorageCard(),
                  const SizedBox(height: 20),
                  _buildProCard(),
                  const SizedBox(height: 20),
                  _buildLoggingCard(),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 120,
      pinned: true,
      backgroundColor: const Color(0xFF1E293B),
      flexibleSpace: FlexibleSpaceBar(
        title: const Text(
          "NEXORA INTELLIGENCE",
          style: TextStyle(
            letterSpacing: 2,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue.shade900, Colors.black],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickStats() {
    return Row(
      children: [
        _buildStatItem("Faces", "$_faceCount", Icons.face, Colors.orange),
        const SizedBox(width: 12),
        _buildStatItem(
          "Battery",
          "${_batteryInfo?.level.toInt() ?? '--'}%",
          Icons.battery_charging_full,
          Colors.green,
        ),
        const SizedBox(width: 12),
        _buildStatItem(
          "Storage",
          _storageInfo?.internalFreeFormatted ?? '--',
          Icons.sd_storage,
          Colors.purple,
        ),
      ],
    );
  }

  Widget _buildStatItem(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: const TextStyle(color: Colors.white54, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCameraCard() {
    return _buildDashboardCard(
      title: "Vision AI Control",
      icon: Icons.auto_awesome,
      child: Column(
        children: [
          Container(
            height: 250,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(12),
            ),
            child: _textureId != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Texture(textureId: _textureId!),
                  )
                : const Center(
                    child: Icon(
                      Icons.videocam_off,
                      color: Colors.white24,
                      size: 48,
                    ),
                  ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildToggleButton(
                "FACE",
                _isVisionFace,
                () => _toggleVision('face'),
              ),
              _buildToggleButton(
                "BARCODE",
                _isVisionBarcode,
                () => _toggleVision('barcode'),
              ),
              ElevatedButton(
                onPressed: _toggleCamera,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isCameraRunning ? Colors.red : Colors.blue,
                ),
                child: Text(_isCameraRunning ? "STOP" : "START"),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isCameraRunning
                      ? () async {
                          final path = await _sdk.camera.takePhoto();
                          if (mounted) {
                            setState(() => _lastNativeAction = path ?? "Photo failed");
                          }
                        }
                      : null,
                  icon: const Icon(Icons.photo_camera),
                  label: const Text("PHOTO"),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () async {
                    await _sdk.native.shareText("Nexora SDK hardware demo");
                  },
                  icon: const Icon(Icons.ios_share),
                  label: const Text("SHARE"),
                ),
              ),
            ],
          ),
          if (_isVisionBarcode)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                "Last Barcode: $_lastBarcode",
                style: const TextStyle(color: Colors.cyanAccent, fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAudioCard() {
    return _buildDashboardCard(
      title: "Audio FFT Visualizer",
      icon: Icons.graphic_eq,
      child: Column(
        children: [
          SizedBox(
            height: 80,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: _audioSpectrum.isEmpty
                  ? [
                      const Expanded(
                        child: Center(
                          child: Text(
                            "Start Audio to see FFT",
                            style: TextStyle(color: Colors.white24),
                          ),
                        ),
                      ),
                    ]
                  : _audioSpectrum
                        .take(40)
                        .map(
                          (v) => Expanded(
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 1),
                              height: (v * 100).clamp(2.0, 80.0),
                              color: Colors.cyanAccent,
                            ),
                          ),
                        )
                        .toList(),
            ),
          ),
          const SizedBox(height: 16),
          _buildToggleButton("REAL-TIME FFT", _isAudioRunning, () async {
            if (_isAudioRunning) {
              await _sdk.audio.stop();
              setState(() => _isAudioRunning = false);
            } else {
              await _sdk.startAudioWithAnalysis();
              setState(() => _isAudioRunning = true);
            }
          }),
        ],
      ),
    );
  }

  Widget _buildLocationCard() {
    return _buildDashboardCard(
      title: "Geospatial Data",
      icon: Icons.location_on,
      child: Column(
        children: [
          _buildDataRow(
            "Lat",
            _currentLocation?.latitude.toStringAsFixed(5) ?? '--',
          ),
          _buildDataRow(
            "Lon",
            _currentLocation?.longitude.toStringAsFixed(5) ?? '--',
          ),
          _buildDataRow(
            "Alt",
            "${_currentLocation?.altitude.toStringAsFixed(2) ?? '--'} m",
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () => _sdk.location.start(),
            child: const Text("START GPS UPDATES"),
          ),
        ],
      ),
    );
  }

  Widget _buildStorageCard() {
    return _buildDashboardCard(
      title: "Device Storage",
      icon: Icons.sd_storage,
      child: Column(
        children: [
          if (_storageInfo != null) ...[
            // Storage usage bar
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: _storageInfo!.internalUsage,
                minHeight: 8,
                backgroundColor: Colors.white10,
                valueColor: AlwaysStoppedAnimation(
                  _storageInfo!.internalUsage > 0.9 ? Colors.red : Colors.blue,
                ),
              ),
            ),
            const SizedBox(height: 12),
            _buildDataRow("Total", _storageInfo!.internalTotalFormatted),
            _buildDataRow("Free", _storageInfo!.internalFreeFormatted),
            _buildDataRow(
              "App Cache",
              StorageInfo.formatBytes(_storageInfo!.appCacheSize),
            ),
            _buildDataRow(
              "App Data",
              StorageInfo.formatBytes(_storageInfo!.appDataSize),
            ),
          ] else
            const Text("Loading...", style: TextStyle(color: Colors.white24)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildToggleButton("WRITE TEST", false, () async {
                await _sdk.storage.writeFile(
                  "test_note.txt",
                  "Hello from Nexora SDK! ${DateTime.now()}",
                );
                _loadStorageInfo();
              }),
              _buildToggleButton("READ TEST", false, () async {
                final content = await _sdk.storage.readFile("test_note.txt");
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(content ?? "File not found"),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }),
              _buildToggleButton("CLEAR CACHE", false, () async {
                await _sdk.storage.clearCache();
                _loadStorageInfo();
              }),
            ],
          ),
          if (_files.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "App Files:",
                style: TextStyle(color: Colors.white54, fontSize: 11),
              ),
            ),
            const SizedBox(height: 4),
            ...(_files
                .take(5)
                .map(
                  (f) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      children: [
                        Icon(
                          f.isDirectory
                              ? Icons.folder
                              : Icons.insert_drive_file,
                          color: Colors.white24,
                          size: 14,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            f.name,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 11,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          f.sizeFormatted,
                          style: const TextStyle(
                            color: Colors.white38,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                )),
          ],
        ],
      ),
    );
  }

  Widget _buildLoggingCard() {
    return _buildDashboardCard(
      title: "Diagnostics & Telemetry",
      icon: Icons.terminal,
      child: ListTile(
        title: const Text(
          "Background CSV Logging",
          style: TextStyle(color: Colors.white),
        ),
        subtitle: const Text(
          "Records battery & wifi every 1s",
          style: TextStyle(color: Colors.white54, fontSize: 11),
        ),
        trailing: Switch(value: _isLogging, onChanged: (_) => _toggleLogging()),
      ),
    );
  }

  Widget _buildProCard() {
    return _buildDashboardCard(
      title: "Native Pro Layer",
      icon: Icons.settings_input_component,
      child: Column(
        children: [
          _buildDataRow("Device", _deviceInfo?.model ?? '--'),
          _buildDataRow("CPU", _deviceInfo?.cpuArchitecture ?? '--'),
          _buildDataRow(
            "Network",
            "${_connectivityInfo?.networkType ?? '--'} ${_connectivityInfo?.isMetered == true ? '(metered)' : ''}",
          ),
          _buildDataRow(
            "Permissions",
            _permissionSnapshot?.allGranted == true ? "Granted" : "Needs review",
          ),
          _buildDataRow("Last Action", _lastNativeAction),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildToggleButton("REFRESH", false, _loadProInfo),
              _buildToggleButton("COPY", false, () async {
                await _sdk.native.copyText("Copied from Nexora SDK");
                setState(() => _lastNativeAction = "Copied text");
              }),
              _buildToggleButton("OPEN SETTINGS", false, () async {
                await _sdk.openAppSettings();
              }),
              _buildToggleButton("OPEN WEB", false, () async {
                await _sdk.native.openUrl("https://flutter.dev");
              }),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.blue, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const Divider(color: Colors.white10, height: 24),
          child,
        ],
      ),
    );
  }

  Widget _buildDataRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white54)),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleButton(String label, bool active, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: active ? Colors.blue : Colors.white10,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? Colors.white : Colors.white54,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
