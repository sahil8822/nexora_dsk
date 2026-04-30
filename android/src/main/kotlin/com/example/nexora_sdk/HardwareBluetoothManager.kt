package com.example.nexora_sdk

import android.annotation.SuppressLint
import android.bluetooth.*
import android.bluetooth.le.ScanCallback
import android.bluetooth.le.ScanResult
import android.content.Context
import android.os.Handler
import io.flutter.plugin.common.EventChannel
import java.util.*

/**
 * Production-ready Bluetooth LE Manager.
 * Supports Nexora Pro: GATT Service Discovery and Characteristic Write operations.
 */
class HardwareBluetoothManager(private val context: Context) {
    private var bluetoothAdapter: BluetoothAdapter? = null
    private var eventSink: EventChannel.EventSink? = null
    private var bluetoothGatt: BluetoothGatt? = null
    private var discoveredServicesCallback: ((List<String>) -> Unit)? = null

    init {
        val manager = context.getSystemService(Context.BLUETOOTH_SERVICE) as BluetoothManager
        bluetoothAdapter = manager.adapter
    }

    fun setEventSink(sink: EventChannel.EventSink?) {
        this.eventSink = sink
    }

    @SuppressLint("MissingPermission")
    fun startScan() {
        bluetoothAdapter?.bluetoothLeScanner?.startScan(scanCallback)
    }

    @SuppressLint("MissingPermission")
    fun stopScan() {
        bluetoothAdapter?.bluetoothLeScanner?.stopScan(scanCallback)
    }

    @SuppressLint("MissingPermission")
    fun connect(deviceId: String) {
        val device = bluetoothAdapter?.getRemoteDevice(deviceId) ?: return
        bluetoothGatt = device.connectGatt(context, false, gattCallback)
    }

    @SuppressLint("MissingPermission")
    fun discoverServices(deviceId: String, callback: (List<String>) -> Unit) {
        discoveredServicesCallback = callback
        bluetoothGatt?.discoverServices()
    }

    @SuppressLint("MissingPermission")
    fun sendData(deviceId: String, serviceId: String, charId: String, data: ByteArray) {
        val gatt = bluetoothGatt ?: return
        val service = gatt.getService(UUID.fromString(serviceId)) ?: return
        val char = service.getCharacteristic(UUID.fromString(charId)) ?: return
        
        char.value = data
        gatt.writeCharacteristic(char)
    }

    @SuppressLint("MissingPermission")
    fun disconnect() {
        bluetoothGatt?.disconnect()
        bluetoothGatt?.close()
        bluetoothGatt = null
    }

    private val gattCallback = object : BluetoothGattCallback() {
        @SuppressLint("MissingPermission")
        override fun onConnectionStateChange(gatt: BluetoothGatt, status: Int, newState: Int) {
            val state = when (newState) {
                BluetoothProfile.STATE_CONNECTED -> "connected"
                BluetoothProfile.STATE_CONNECTING -> "connecting"
                BluetoothProfile.STATE_DISCONNECTED -> "disconnected"
                else -> "unknown"
            }
            
            val statusData = mapOf(
                "module" to "bluetooth",
                "type" to "status",
                "data" to mapOf(
                    "id" to gatt.device.address,
                    "state" to state
                )
            )
            Handler(context.mainLooper).post { eventSink?.success(statusData) }
        }

        override fun onServicesDiscovered(gatt: BluetoothGatt, status: Int) {
            if (status == BluetoothGatt.GATT_SUCCESS) {
                val serviceUuids = gatt.services.map { it.uuid.toString() }
                Handler(context.mainLooper).post {
                    discoveredServicesCallback?.invoke(serviceUuids)
                    discoveredServicesCallback = null
                }
            }
        }
    }

    private val scanCallback = object : ScanCallback() {
        @SuppressLint("MissingPermission")
        override fun onScanResult(callbackType: Int, result: ScanResult) {
            val device = result.device
            val scanData = mapOf(
                "module" to "bluetooth",
                "type" to "data",
                "data" to mapOf(
                    "id" to device.address,
                    "name" to (device.name ?: "Unknown"),
                    "rssi" to result.rssi
                )
            )
            Handler(context.mainLooper).post { eventSink?.success(scanData) }
        }
    }
}
