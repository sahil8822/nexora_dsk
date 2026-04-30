package com.example.nexora_sdk

import android.annotation.SuppressLint
import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothManager
import android.bluetooth.le.ScanCallback
import android.bluetooth.le.ScanResult
import android.content.Context
import android.os.Handler
import io.flutter.plugin.common.EventChannel

/**
 * Production-ready Bluetooth LE Manager.
 * Scanning and connecting to peripheral devices.
 */
class HardwareBluetoothManager(private val context: Context) {
    private var bluetoothAdapter: BluetoothAdapter? = null
    private var eventSink: EventChannel.EventSink? = null

    init {
        val manager = context.getSystemService(Context.BLUETOOTH_SERVICE) as BluetoothManager
        bluetoothAdapter = manager.adapter
    }

    private var bluetoothGatt: android.bluetooth.BluetoothGatt? = null

    fun setEventSink(sink: EventChannel.EventSink?) {
        this.eventSink = sink
    }

    @SuppressLint("MissingPermission")
    fun startScan() {
        val scanner = bluetoothAdapter?.bluetoothLeScanner
        scanner?.startScan(scanCallback)
    }

    @SuppressLint("MissingPermission")
    fun stopScan() {
        val scanner = bluetoothAdapter?.bluetoothLeScanner
        scanner?.stopScan(scanCallback)
    }

    @SuppressLint("MissingPermission")
    fun connect(deviceId: String) {
        val device = bluetoothAdapter?.getRemoteDevice(deviceId) ?: return
        bluetoothGatt = device.connectGatt(context, false, gattCallback)
    }

    @SuppressLint("MissingPermission")
    fun disconnect() {
        bluetoothGatt?.disconnect()
        bluetoothGatt?.close()
        bluetoothGatt = null
    }

    private val gattCallback = object : android.bluetooth.BluetoothGattCallback() {
        @SuppressLint("MissingPermission")
        override fun onConnectionStateChange(gatt: android.bluetooth.BluetoothGatt, status: Int, newState: Int) {
            val state = when (newState) {
                android.bluetooth.BluetoothProfile.STATE_CONNECTED -> "connected"
                android.bluetooth.BluetoothProfile.STATE_CONNECTING -> "connecting"
                android.bluetooth.BluetoothProfile.STATE_DISCONNECTED -> "disconnected"
                else -> "unknown"
            }
            
            val statusData = mapOf(
                "type" to "bluetooth_status",
                "timestamp" to System.currentTimeMillis(),
                "data" to mapOf(
                    "id" to gatt.device.address,
                    "state" to state
                )
            )
            
            Handler(context.mainLooper).post { eventSink?.success(statusData) }
            
            if (newState == android.bluetooth.BluetoothProfile.STATE_CONNECTED) {
                gatt.discoverServices()
            }
        }
    }

    private val scanCallback = object : ScanCallback() {
        @SuppressLint("MissingPermission")
        override fun onScanResult(callbackType: Int, result: ScanResult) {
            val device = result.device
            val scanData = mapOf(
                "type" to "bluetooth",
                "timestamp" to System.currentTimeMillis(),
                "data" to mapOf(
                    "id" to device.address,
                    "name" to (device.name ?: "Unknown"),
                    "rssi" to result.rssi
                )
            )
            
            Handler(context.mainLooper).post {
                eventSink?.success(scanData)
            }
        }
    }
}
