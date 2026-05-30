#include "nexora_core.h"
#include <vector>
#include <mutex>
#include <cmath>

#ifndef M_PI
#define M_PI 3.14159265358979323846
#endif

static std::vector<double> sensor_data(6, 0.0);
static std::mutex sensor_mutex;

static double filter_roll = 0.0;
static double filter_pitch = 0.0;
static double filter_yaw = 0.0;
static bool filter_initialized = false;
static double fused_orientation[3] = {0.0, 0.0, 0.0};

extern "C" {

EXPORT void initialize_sensor_core() {
    std::lock_guard<std::mutex> lock(sensor_mutex);
    sensor_data = { 0.1, 0.2, 0.3, 0.4, 0.5, 0.6 };
}

EXPORT double* get_live_sensor_data() {
    // We lock the mutex to ensure the buffer is not being actively written to
    // by the hardware NDK thread during the memory read.
    std::lock_guard<std::mutex> lock(sensor_mutex);
    return sensor_data.data();
}

EXPORT void update_imu_filter(double ax, double ay, double az, double gx, double gy, double gz, double dt) {
    std::lock_guard<std::mutex> lock(sensor_mutex);
    
    // Calculate roll and pitch from accelerometer
    double roll_acc = atan2(ay, az) * 180.0 / M_PI;
    double pitch_acc = atan2(-ax, sqrt(ay * ay + az * az)) * 180.0 / M_PI;
    
    if (!filter_initialized) {
        filter_roll = roll_acc;
        filter_pitch = pitch_acc;
        filter_yaw = 0.0;
        filter_initialized = true;
    } else {
        // Convert gyro rates from radians/sec to degrees/sec
        double gx_deg = gx * 180.0 / M_PI;
        double gy_deg = gy * 180.0 / M_PI;
        double gz_deg = gz * 180.0 / M_PI;
        
        double alpha = 0.98;
        filter_roll = alpha * (filter_roll + gx_deg * dt) + (1.0 - alpha) * roll_acc;
        filter_pitch = alpha * (filter_pitch + gy_deg * dt) + (1.0 - alpha) * pitch_acc;
        filter_yaw = filter_yaw + gz_deg * dt;
    }
    
    fused_orientation[0] = filter_roll;
    fused_orientation[1] = filter_pitch;
    fused_orientation[2] = filter_yaw;
}

EXPORT double* get_fused_orientation() {
    std::lock_guard<std::mutex> lock(sensor_mutex);
    return fused_orientation;
}

}

#ifdef __ANDROID__
#include <jni.h>
extern "C" {
JNIEXPORT void JNICALL Java_com_nexora_sdk_HardwareSensorManager_updateImuFilter(
    JNIEnv* env, jobject thiz, jdouble ax, jdouble ay, jdouble az, jdouble gx, jdouble gy, jdouble gz, jdouble dt
) {
    update_imu_filter(ax, ay, az, gx, gy, gz, dt);
}
}
#endif

