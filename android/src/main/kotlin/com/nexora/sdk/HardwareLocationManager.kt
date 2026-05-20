package com.nexora.sdk

import android.annotation.SuppressLint
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.hardware.SensorManager
import android.location.Location
import android.os.Build
import android.os.Handler
import android.os.Looper
import com.google.android.gms.location.*
import io.flutter.plugin.common.EventChannel
import java.io.File

/**
 * High-accuracy Location Manager with Geofencing and Kalman-filtered Dead Reckoning.
 */
class HardwareLocationManager(private val context: Context) {
    private var fusedLocationClient: FusedLocationProviderClient = LocationServices.getFusedLocationProviderClient(context)
    private var geofencingClient: GeofencingClient = LocationServices.getGeofencingClient(context)
    private var eventSink: EventChannel.EventSink? = null
    private var backgroundEnabled = false

    // Kalman Filter & Dead Reckoning
    private var isDeadReckoningEnabled = false
    private var lastSensorTimestamp: Long = 0
    private var referenceLat = 0.0
    private var referenceLon = 0.0
    private var referenceAlt = 0.0
    private var referenceAccuracy = 0.0f
    private var referenceSpeed = 0.0f
    private var lastGpsTimestamp: Long = 0

    private var stateX = DoubleArray(4) // x, y, vx, vy
    private var covP = Array(4) { DoubleArray(4) }
    private var headingYaw = 0.0

    private var sensorManager: SensorManager? = null
    private var accelSensor: Sensor? = null
    private var gyroSensor: Sensor? = null

    private val sensorEventListener = object : SensorEventListener {
        override fun onSensorChanged(event: SensorEvent) {
            if (!isDeadReckoningEnabled) return
            val timestamp = event.timestamp
            if (lastSensorTimestamp == 0L) {
                lastSensorTimestamp = timestamp
                return
            }
            val dt = (timestamp - lastSensorTimestamp) / 1e9
            lastSensorTimestamp = timestamp

            if (event.sensor.type == Sensor.TYPE_GYROSCOPE) {
                val gyroZ = event.values[2]
                headingYaw += gyroZ * dt
            } else if (event.sensor.type == Sensor.TYPE_LINEAR_ACCELERATION) {
                val axDevice = event.values[0].toDouble()
                val ayDevice = event.values[1].toDouble()

                val axWorld = axDevice * Math.cos(headingYaw) - ayDevice * Math.sin(headingYaw)
                val ayWorld = axDevice * Math.sin(headingYaw) + ayDevice * Math.cos(headingYaw)

                predict(dt, axWorld, ayWorld)

                val timeSinceLastGps = System.currentTimeMillis() - lastGpsTimestamp
                if (timeSinceLastGps > 2000) {
                    val newLat = referenceLat + (stateX[1] / 111111.0)
                    val newLon = referenceLon + (stateX[0] / (111111.0 * Math.cos(Math.toRadians(referenceLat))))
                    sendEstimatedLocationEvent(newLat, newLon, stateX[2], stateX[3])
                }
            }
        }
        override fun onAccuracyChanged(sensor: Sensor?, accuracy: Int) {}
    }

    private val locationRequest = LocationRequest.Builder(Priority.PRIORITY_HIGH_ACCURACY, 1000).build()
    private val locationCallback = object : LocationCallback() {
        override fun onLocationResult(result: LocationResult) {
            val location = result.lastLocation ?: return
            if (isDeadReckoningEnabled) {
                if (referenceLat == 0.0 && referenceLon == 0.0) {
                    initKalman(location.latitude, location.longitude, location.speed)
                } else {
                    updateGps(location.latitude, location.longitude, location.accuracy)
                }
                referenceAlt = location.altitude
                referenceAccuracy = location.accuracy
                referenceSpeed = location.speed
            }
            sendLocationEvent(location)
        }
    }

    fun setEventSink(sink: EventChannel.EventSink?) {
        this.eventSink = sink
    }

    @SuppressLint("MissingPermission")
    fun startUpdates() {
        fusedLocationClient.requestLocationUpdates(locationRequest, locationCallback, Looper.getMainLooper())
    }

    fun stopUpdates() {
        fusedLocationClient.removeLocationUpdates(locationCallback)
        enableDeadReckoning(false)
    }

    fun setBackgroundEnabled(enabled: Boolean) {
        backgroundEnabled = enabled
    }

    fun enableDeadReckoning(enabled: Boolean) {
        if (isDeadReckoningEnabled == enabled) return
        isDeadReckoningEnabled = enabled

        if (enabled) {
            sensorManager = context.getSystemService(Context.SENSOR_SERVICE) as SensorManager
            accelSensor = sensorManager?.getDefaultSensor(Sensor.TYPE_LINEAR_ACCELERATION)
            gyroSensor = sensorManager?.getDefaultSensor(Sensor.TYPE_GYROSCOPE)

            sensorManager?.registerListener(sensorEventListener, accelSensor, SensorManager.SENSOR_DELAY_GAME)
            sensorManager?.registerListener(sensorEventListener, gyroSensor, SensorManager.SENSOR_DELAY_GAME)

            lastSensorTimestamp = 0L
            referenceLat = 0.0
            referenceLon = 0.0
            lastGpsTimestamp = System.currentTimeMillis()
        } else {
            sensorManager?.unregisterListener(sensorEventListener)
            sensorManager = null
            accelSensor = null
            gyroSensor = null
        }
    }

    private fun initKalman(lat: Double, lon: Double, speed: Float) {
        referenceLat = lat
        referenceLon = lon
        stateX[0] = 0.0
        stateX[1] = 0.0
        stateX[2] = speed * Math.sin(headingYaw)
        stateX[3] = speed * Math.cos(headingYaw)

        for (i in 0..3) {
            for (j in 0..3) {
                covP[i][j] = if (i == j) 1.0 else 0.0
            }
        }
    }

    private fun predict(dt: Double, ax: Double, ay: Double) {
        stateX[0] += stateX[2] * dt + 0.5 * ax * dt * dt
        stateX[1] += stateX[3] * dt + 0.5 * ay * dt * dt
        stateX[2] += ax * dt
        stateX[3] += ay * dt

        val qVal = 0.1
        val Q = Array(4) { DoubleArray(4) }
        Q[0][0] = qVal * dt * dt * dt * dt / 4.0
        Q[1][1] = qVal * dt * dt * dt * dt / 4.0
        Q[2][2] = qVal * dt * dt
        Q[3][3] = qVal * dt * dt

        val nextP = Array(4) { DoubleArray(4) }
        nextP[0][0] = covP[0][0] + 2 * dt * covP[0][2] + dt * dt * covP[2][2] + Q[0][0]
        nextP[0][1] = covP[0][1] + dt * covP[0][3] + dt * covP[2][1] + dt * dt * covP[2][3]
        nextP[0][2] = covP[0][2] + dt * covP[2][2]
        nextP[0][3] = covP[0][3] + dt * covP[2][3]
        
        nextP[1][0] = covP[1][0] + dt * covP[1][2] + dt * covP[3][0] + dt * dt * covP[3][2]
        nextP[1][1] = covP[1][1] + 2 * dt * covP[1][3] + dt * dt * covP[3][3] + Q[1][1]
        nextP[1][2] = covP[1][2] + dt * covP[3][2]
        nextP[1][3] = covP[1][3] + dt * covP[3][3]
        
        nextP[2][0] = covP[2][0] + dt * covP[2][2]
        nextP[2][1] = covP[2][1] + dt * covP[2][3]
        nextP[2][2] = covP[2][2] + Q[2][2]
        nextP[2][3] = covP[2][3]
        
        nextP[3][0] = covP[3][0] + dt * covP[3][2]
        nextP[3][1] = covP[3][1] + dt * covP[3][3]
        nextP[3][2] = covP[3][2]
        nextP[3][3] = covP[3][3] + Q[3][3]

        covP = nextP
    }

    private fun updateGps(gpsLat: Double, gpsLon: Double, gpsAccuracy: Float) {
        lastGpsTimestamp = System.currentTimeMillis()
        val zx = (gpsLon - referenceLon) * 111111.0 * Math.cos(Math.toRadians(referenceLat))
        val zy = (gpsLat - referenceLat) * 111111.0

        val rVal = (gpsAccuracy * gpsAccuracy).toDouble().coerceAtLeast(1.0)
        val s00 = covP[0][0] + rVal
        val s01 = covP[0][1]
        val s10 = covP[1][0]
        val s11 = covP[1][1] + rVal

        val det = s00 * s11 - s01 * s10
        if (Math.abs(det) < 1e-9) return
        val invS00 = s11 / det
        val invS01 = -s01 / det
        val invS10 = -s10 / det
        val invS11 = s00 / det

        val K = Array(4) { DoubleArray(2) }
        for (i in 0..3) {
            K[i][0] = covP[i][0] * invS00 + covP[i][1] * invS10
            K[i][1] = covP[i][0] * invS01 + covP[i][1] * invS11
        }

        val y0 = zx - stateX[0]
        val y1 = zy - stateX[1]

        stateX[0] += K[0][0] * y0 + K[0][1] * y1
        stateX[1] += K[1][0] * y0 + K[1][1] * y1
        stateX[2] += K[2][0] * y0 + K[2][1] * y1
        stateX[3] += K[3][0] * y0 + K[3][1] * y1

        val nextP = Array(4) { DoubleArray(4) }
        for (i in 0..3) {
            for (j in 0..3) {
                var sum = covP[i][j]
                sum -= K[i][0] * covP[0][j]
                sum -= K[i][1] * covP[1][j]
                nextP[i][j] = sum
            }
        }
        covP = nextP
    }

    @SuppressLint("MissingPermission")
    fun addGeofence(id: String, lat: Double, lon: Double, radius: Double): Boolean {
        if (!backgroundEnabled) return false
        val geofence = Geofence.Builder()
            .setRequestId(id)
            .setCircularRegion(lat, lon, radius.toFloat())
            .setExpirationDuration(Geofence.NEVER_EXPIRE)
            .setTransitionTypes(Geofence.GEOFENCE_TRANSITION_ENTER or Geofence.GEOFENCE_TRANSITION_EXIT)
            .build()

        val request = GeofencingRequest.Builder()
            .setInitialTrigger(GeofencingRequest.INITIAL_TRIGGER_ENTER)
            .addGeofence(geofence)
            .build()

        geofencingClient.addGeofences(request, getGeofencePendingIntent())
        return true
    }

    private fun getGeofencePendingIntent(): PendingIntent {
        val intent = Intent(context, HardwareGeofenceReceiver::class.java)
        return PendingIntent.getBroadcast(context, 0, intent, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_MUTABLE)
    }

    private fun sendLocationEvent(location: Location) {
        val locData = mapOf(
            "module" to "gps",
            "type" to "data",
            "data" to mapOf(
                "latitude" to location.latitude,
                "longitude" to location.longitude,
                "altitude" to location.altitude,
                "accuracy" to location.accuracy,
                "speed" to location.speed
            )
        )
        Handler(Looper.getMainLooper()).post {
            try { eventSink?.success(locData) } catch (e: Exception) {}
        }
    }

    private fun sendEstimatedLocationEvent(lat: Double, lon: Double, vx: Double, vy: Double) {
        val estimatedSpeed = Math.sqrt(vx * vx + vy * vy).toFloat()
        val locData = mapOf(
            "module" to "gps",
            "type" to "data",
            "data" to mapOf(
                "latitude" to lat,
                "longitude" to lon,
                "altitude" to referenceAlt,
                "accuracy" to 999.0f,
                "speed" to estimatedSpeed,
                "isDeadReckoning" to true
            )
        )
        Handler(Looper.getMainLooper()).post {
            try { eventSink?.success(locData) } catch (e: Exception) {}
        }
    }
}
