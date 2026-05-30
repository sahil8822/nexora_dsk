#ifndef NEXORA_CORE_H
#define NEXORA_CORE_H

#ifdef _WIN32
#define EXPORT __declspec(dllexport)
#else
#define EXPORT __attribute__((visibility("default"))) __attribute__((used))
#endif

extern "C" {

EXPORT double* get_live_sensor_data();
EXPORT void initialize_sensor_core();
EXPORT void update_imu_filter(double ax, double ay, double az, double gx, double gy, double gz, double dt);
EXPORT double* get_fused_orientation();

}

#endif // NEXORA_CORE_H
