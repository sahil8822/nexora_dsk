package com.nexora.sdk

import android.annotation.SuppressLint
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.location.Location
import android.os.Handler
import android.os.Looper
import com.google.android.gms.location.*
import io.flutter.plugin.common.EventChannel

/**
 * High-accuracy Location Manager with Geofencing support.
 */
class HardwareLocationManager(private val context: Context) {
    private var fusedLocationClient: FusedLocationProviderClient = LocationServices.getFusedLocationProviderClient(context)
    private var geofencingClient: GeofencingClient = LocationServices.getGeofencingClient(context)
    private var eventSink: EventChannel.EventSink? = null
    private var backgroundEnabled = false

    private val locationRequest = LocationRequest.Builder(Priority.PRIORITY_HIGH_ACCURACY, 1000).build()
    private val locationCallback = object : LocationCallback() {
        override fun onLocationResult(result: LocationResult) {
            val location = result.lastLocation ?: return
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
    }

    fun setBackgroundEnabled(enabled: Boolean) {
        backgroundEnabled = enabled
    }

    @SuppressLint("MissingPermission")
    fun addGeofence(id: String, lat: Double, lon: Double, radius: Float): Boolean {
        if (!backgroundEnabled) return false
        val geofence = Geofence.Builder()
            .setRequestId(id)
            .setCircularRegion(lat, lon, radius)
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
}
