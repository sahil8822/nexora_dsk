#include "nexora_core.h"
#include <vector>
#include <mutex>

static std::vector<double> sensor_data(6, 0.0);
static std::mutex sensor_mutex;

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

}
