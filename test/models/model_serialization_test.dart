import 'package:flutter_test/flutter_test.dart';
import 'package:nexora_sdk/nexora_sdk.dart';

void main() {
  group('Model Serialization & copyWith / toString Tests', () {
    test('DeviceInfo round-trip', () {
      const device = DeviceInfo(
        platform: 'Android',
        manufacturer: 'Google',
        model: 'Pixel 8',
        osVersion: '14',
        sdkVersion: '34',
        isPhysicalDevice: true,
        totalRamBytes: 8000000000,
        availableRamBytes: 4000000000,
        cpuArchitecture: 'arm64-v8a',
        screenRefreshRate: 120,
        thermalState: 'nominal',
      );

      final map = device.toMap();
      final roundTrip = DeviceInfo.fromMap(map);

      expect(roundTrip.platform, device.platform);
      expect(roundTrip.manufacturer, device.manufacturer);
      expect(roundTrip.model, device.model);
      expect(roundTrip.osVersion, device.osVersion);
      expect(roundTrip.sdkVersion, device.sdkVersion);
      expect(roundTrip.isPhysicalDevice, device.isPhysicalDevice);
      expect(roundTrip.totalRamBytes, device.totalRamBytes);
      expect(roundTrip.availableRamBytes, device.availableRamBytes);
      expect(roundTrip.cpuArchitecture, device.cpuArchitecture);
      expect(roundTrip.screenRefreshRate, device.screenRefreshRate);
      expect(roundTrip.thermalState, device.thermalState);

      expect(device.toString(), contains('Pixel 8'));
      expect(device == roundTrip, true);
      expect(device.hashCode, roundTrip.hashCode);
    });

    test('ConnectivityInfo round-trip & copyWith', () {
      const conn = ConnectivityInfo(
        isConnected: true,
        networkType: 'wifi',
        isMetered: false,
        isVpn: true,
        signalStrength: -30,
        ipAddress: '192.168.0.1',
      );

      final map = conn.toMap();
      final roundTrip = ConnectivityInfo.fromMap(map);

      expect(roundTrip.isConnected, conn.isConnected);
      expect(roundTrip.networkType, conn.networkType);
      expect(roundTrip.isMetered, conn.isMetered);
      expect(roundTrip.isVpn, conn.isVpn);
      expect(roundTrip.signalStrength, conn.signalStrength);
      expect(roundTrip.ipAddress, conn.ipAddress);

      expect(conn.toString(), contains('wifi'));
      expect(conn == roundTrip, true);
      expect(conn.hashCode, roundTrip.hashCode);
    });

    test('LocationData round-trip', () {
      final loc = LocationData(
        latitude: 37.7749,
        longitude: -122.4194,
        altitude: 10,
        accuracy: 5,
        speed: 1.2,
      );

      final map = loc.toMap();
      final roundTrip = LocationData.fromMap(map);

      expect(roundTrip.latitude, loc.latitude);
      expect(roundTrip.longitude, loc.longitude);
      expect(roundTrip.altitude, loc.altitude);
      expect(roundTrip.accuracy, loc.accuracy);
      expect(roundTrip.speed, loc.speed);

      expect(loc.toString(), contains('37.7749'));
    });

    test('BatteryInfo round-trip', () {
      final bat = BatteryInfo(
        level: 0.95,
        isCharging: true,
        status: 'charging',
        temperature: 30.5,
      );

      final map = bat.toMap();
      final roundTrip = BatteryInfo.fromMap(map);

      expect(roundTrip.level, bat.level);
      expect(roundTrip.isCharging, bat.isCharging);
      expect(roundTrip.status, bat.status);
      expect(roundTrip.temperature, bat.temperature);

      expect(bat.toString(), contains('0.95'));
    });

    test('WifiInfo round-trip', () {
      final wifi = WifiInfo(
        ssid: 'Home_WiFi',
        bssid: '00:11:22:33:44:55',
        signalStrength: -60,
        ipAddress: '192.168.1.100',
      );

      final map = wifi.toMap();
      final roundTrip = WifiInfo.fromMap(map);

      expect(roundTrip.ssid, wifi.ssid);
      expect(roundTrip.bssid, wifi.bssid);
      expect(roundTrip.signalStrength, wifi.signalStrength);
      expect(roundTrip.ipAddress, wifi.ipAddress);

      expect(wifi.toString(), contains('Home_WiFi'));
    });

    test('StorageInfo round-trip & copyWith', () {
      final storage = StorageInfo(
        internalTotal: 128000,
        internalFree: 64000,
        externalTotal: 32000,
        externalFree: 16000,
        appCacheSize: 500,
        appDataSize: 1500,
      );

      final map = storage.toMap();
      final roundTrip = StorageInfo.fromMap(map);

      expect(roundTrip.internalTotal, storage.internalTotal);
      expect(roundTrip.internalFree, storage.internalFree);
      expect(roundTrip.externalTotal, storage.externalTotal);
      expect(roundTrip.externalFree, storage.externalFree);
      expect(roundTrip.appCacheSize, storage.appCacheSize);
      expect(roundTrip.appDataSize, storage.appDataSize);

      final copied = storage.copyWith(internalFree: 1000);
      expect(copied.internalFree, 1000);
      expect(copied.internalTotal, storage.internalTotal);

      expect(storage.toString(), contains('128000'));
    });

    test('FileInfo round-trip & copyWith', () {
      final file = FileInfo(
        name: 'notes.txt',
        size: 1024,
        isDirectory: false,
        lastModified: DateTime.fromMillisecondsSinceEpoch(1700000000000),
      );

      final map = file.toMap();
      final roundTrip = FileInfo.fromMap(map);

      expect(roundTrip.name, file.name);
      expect(roundTrip.size, file.size);
      expect(roundTrip.isDirectory, file.isDirectory);
      expect(roundTrip.lastModified, file.lastModified);

      final copied = file.copyWith(size: 2048);
      expect(copied.size, 2048);
      expect(copied.name, file.name);

      expect(file.toString(), contains('notes.txt'));
    });

    test('SensorData round-trip', () {
      final now = DateTime.now();
      final sensor = SensorData(
        x: 0.1,
        y: 0.2,
        z: 9.8,
        timestamp: now,
      );

      final map = sensor.toMap();
      final roundTrip = SensorData.fromMap(map);

      expect(roundTrip.x, sensor.x);
      expect(roundTrip.y, sensor.y);
      expect(roundTrip.z, sensor.z);
      expect(
        roundTrip.timestamp.millisecondsSinceEpoch,
        sensor.timestamp.millisecondsSinceEpoch,
      );

      expect(sensor.toString(), contains('x: 0.1'));
    });

    test('HardwarePermissionSnapshot & Report tests', () {
      const snapshot = HardwarePermissionSnapshot({
        HardwarePermission.camera: HardwarePermissionStatus(
          permission: HardwarePermission.camera,
          state: HardwarePermissionState.granted,
        ),
        HardwarePermission.audio: HardwarePermissionStatus(
          permission: HardwarePermission.audio,
          state: HardwarePermissionState.denied,
        ),
      });

      final map = snapshot.toMap();
      expect(map.containsKey('camera'), true);
      expect(map.containsKey('audio'), true);
      expect(snapshot.toString(), contains('allGranted: false'));

      const report = HardwarePermissionReport(
        camera: true,
        audio: false,
        location: false,
        bluetooth: true,
      );

      expect(report.camera, true);
      expect(report.audio, false);
      expect(report.deniedPermissions, contains('audio'));
      expect(report.toMap()['bluetooth'], true);
      expect(report.toString(), contains('camera: true'));
    });

    test('LogConfig copyWith & toString', () {
      final config = LogConfig(fileName: 'test.log', intervalMs: 250);
      final copied = config.copyWith(fileName: 'new.log');
      expect(copied.fileName, 'new.log');
      expect(copied.intervalMs, 250);
      expect(config.toString(), contains('test.log'));
    });

    test('Options classes copyWith & toString', () {
      const cam = CameraOptions(resolution: CameraQuality.fullHd);
      expect(
        cam.copyWith(resolution: CameraQuality.hd).resolution,
        CameraQuality.hd,
      );
      expect(cam.toString(), contains('resolution'));

      const aud = AudioOptions(sampleRate: 16000);
      expect(aud.copyWith(sampleRate: 44100).sampleRate, 44100);
      expect(aud.toString(), contains('sampleRate'));

      const sens = SensorOptions(lowPassAlpha: 0.2);
      expect(sens.copyWith(lowPassAlpha: 0.5).lowPassAlpha, 0.5);
      expect(sens.toString(), contains('lowPassAlpha'));

      const ble = BluetoothScanOptions(allowDuplicates: true);
      expect(ble.copyWith(allowDuplicates: false).allowDuplicates, false);
      expect(ble.toString(), contains('allowDuplicates'));

      const loc = LocationOptions(distanceFilterMeters: 10);
      expect(loc.copyWith(distanceFilterMeters: 5).distanceFilterMeters, 5.0);
      expect(loc.toString(), contains('distanceFilter'));

      const bio = BiometricPromptOptions(title: 'Auth');
      expect(bio.copyWith(title: 'New').title, 'New');
      expect(bio.toString(), contains('title'));

      const hap = HapticOptions(durationMs: 100);
      expect(hap.copyWith(durationMs: 200).durationMs, 200);
      expect(hap.toString(), contains('duration'));
    });
  });
}
