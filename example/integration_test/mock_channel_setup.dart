import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Sets up a mock method channel handler to intercept calls to the native backend.
/// This allows the integration tests to run purely in Dart while verifying that the
/// correct method calls and arguments are dispatched to the native side.
void setupMockMethodChannel() {
  const MethodChannel channel = MethodChannel('nexora_sdk/methods');
  
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, (MethodCall methodCall) async {
    switch (methodCall.method) {
      case 'getPlatformVersion':
        return 'Mock Native Version';
      case 'startCamera':
      case 'startCameraWithOptions':
        return 42; // mock texture ID
      case 'stopCamera':
      case 'setVisionMode':
      case 'setFlash':
      case 'setZoom':
      case 'flipCamera':
      case 'stopAudio':
      case 'setAudioVolume':
      case 'stopBluetoothScan':
      case 'connectDevice':
      case 'disconnectDevice':
      case 'startLocation':
      case 'startLocationWithOptions':
      case 'stopLocation':
      case 'setBackgroundLocationEnabled':
      case 'addGeofence':
      case 'startSensor':
      case 'startSensorWithOptions':
      case 'stopSensor':
      case 'stopLogging':
        return true;
      case 'startAudio':
      case 'startAudioWithOptions':
        return true;
      case 'getAudioVolume':
        return 0.75;
      case 'startBluetoothScan':
      case 'startBluetoothScanWithOptions':
        return true;
      case 'discoverServices':
        return ['service_1', 'service_2'];
      case 'readData':
        return [0x01, 0x02, 0x03];
      case 'sendData':
        return true;
      case 'authenticate':
      case 'authenticateWithOptions':
      case 'canAuthenticate':
        return true;
      case 'vibrate':
      case 'hapticFeedback':
      case 'performHapticWithOptions':
        return null;
      case 'getBatteryInfo':
        return {
          'level': 0.85,
          'isCharging': true,
          'status': 'charging',
          'temperature': 35.5,
        };
      case 'getWifiInfo':
        return {
          'ssid': 'MockWiFi',
          'bssid': '00:11:22:33:44:55',
          'signalStrength': -50,
          'ipAddress': '192.168.1.100',
        };
      case 'startLogging':
        return true;
      case 'getStorageInfo':
        return {
          'internalTotal': 1024 * 1024 * 1024 * 128,
          'internalFree': 1024 * 1024 * 1024 * 10,
          'externalTotal': 0,
          'externalFree': 0,
          'appCacheSize': 1024 * 1024 * 10,
          'appDataSize': 1024 * 1024 * 50,
        };
      case 'writeFile':
      case 'appendFile':
      case 'writeBytes':
        return '/mock/path/${methodCall.arguments['fileName']}';
      case 'readFile':
        return 'mock file content';
      case 'readBytes':
        return [0x04, 0x05, 0x06];
      case 'deleteFile':
      case 'fileExists':
      case 'clearCache':
        return true;
      case 'listFiles':
        return ['file1.txt', 'file2.jpg'];
      case 'getAppDirectory':
        return '/mock/app/dir';
      case 'getCacheDirectory':
        return '/mock/cache/dir';
      case 'getExternalDirectory':
        return '/mock/ext/dir';
      case 'startNfcScan':
      case 'stopNfcScan':
        return true;
      case 'writeNdefRecord':
        return true;
      case 'writeSecureFile':
      case 'deleteSecureFile':
        return true;
      case 'readSecureFile':
        return 'secure mock content';
      case 'getDeviceInfo':
        return {
          'name': 'Mock Device',
          'model': 'Mock Model',
          'os': 'Mock OS',
          'osVersion': '1.0',
          'manufacturer': 'Mock Manufacturer',
          'isSimulator': true,
        };
      case 'getConnectivityInfo':
        return {
          'type': 'wifi',
          'isConnected': true,
          'isMetered': false,
          'isVpn': false,
        };
      case 'getPermissionStatus':
        return {
          'state': 'granted',
          'canRequest': false,
        };
      case 'openAppSettings':
      case 'copyText':
      case 'openUrl':
      case 'shareText':
      case 'requestPermissions':
      case 'requestPermission':
        return true;
      case 'pasteText':
        return 'mock pasted text';
      default:
        throw PlatformException(
          code: 'Unimplemented',
          message: 'Method ${methodCall.method} is not implemented in the mock.',
        );
    }
  });
}
