import 'dart:ffi';
import 'dart:io';

typedef InitializeSensorCoreC = Void Function();
typedef InitializeSensorCoreDart = void Function();

typedef GetLiveSensorDataC = Pointer<Double> Function();
typedef GetLiveSensorDataDart = Pointer<Double> Function();

typedef UpdateImuFilterC =
    Void Function(
      Double ax,
      Double ay,
      Double az,
      Double gx,
      Double gy,
      Double gz,
      Double dt,
    );
typedef UpdateImuFilterDart =
    void Function(
      double ax,
      double ay,
      double az,
      double gx,
      double gy,
      double gz,
      double dt,
    );

typedef GetFusedOrientationC = Pointer<Double> Function();
typedef GetFusedOrientationDart = Pointer<Double> Function();

class NexoraFfi {
  static late DynamicLibrary _lib;
  static late InitializeSensorCoreDart _initializeSensorCore;
  static late GetLiveSensorDataDart _getLiveSensorData;
  static late UpdateImuFilterDart _updateImuFilter;
  static late GetFusedOrientationDart _getFusedOrientation;

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

    _updateImuFilter = _lib
        .lookup<NativeFunction<UpdateImuFilterC>>('update_imu_filter')
        .asFunction();

    _getFusedOrientation = _lib
        .lookup<NativeFunction<GetFusedOrientationC>>('get_fused_orientation')
        .asFunction();

    _initializeSensorCore();
  }

  static List<double> getLiveSensorData() {
    final ptr = _getLiveSensorData();
    return [ptr[0], ptr[1], ptr[2], ptr[3], ptr[4], ptr[5]];
  }

  static void updateImuFilter({
    required double ax,
    required double ay,
    required double az,
    required double gx,
    required double gy,
    required double gz,
    required double dt,
  }) {
    _updateImuFilter(ax, ay, az, gx, gy, gz, dt);
  }

  static List<double> getFusedOrientation() {
    final ptr = _getFusedOrientation();
    return [ptr[0], ptr[1], ptr[2]];
  }
}
