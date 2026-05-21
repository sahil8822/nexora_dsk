import 'dart:ffi';
import 'dart:io';

typedef InitializeSensorCoreC = Void Function();
typedef InitializeSensorCoreDart = void Function();

typedef GetLiveSensorDataC = Pointer<Double> Function();
typedef GetLiveSensorDataDart = Pointer<Double> Function();

class NexoraFfi {
  static late DynamicLibrary _lib;
  static late InitializeSensorCoreDart _initializeSensorCore;
  static late GetLiveSensorDataDart _getLiveSensorData;

  static void init() {
    if (Platform.isAndroid) {
      _lib = DynamicLibrary.open('libnexora_core.so');
    } else if (Platform.isIOS) {
      _lib = DynamicLibrary.process();
    } else {
      throw UnsupportedError('Unsupported platform');
    }

    _initializeSensorCore = _lib
        .lookup<NativeFunction<InitializeSensorCoreC>>('initialize_sensor_core')
        .asFunction();

    _getLiveSensorData = _lib
        .lookup<NativeFunction<GetLiveSensorDataC>>('get_live_sensor_data')
        .asFunction();
        
    _initializeSensorCore();
  }

  static List<double> getLiveSensorData() {
    final ptr = _getLiveSensorData();
    return [ptr[0], ptr[1], ptr[2], ptr[3], ptr[4], ptr[5]];
  }
}
