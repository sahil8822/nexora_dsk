package com.nexora.sdk

import android.annotation.SuppressLint
import android.bluetooth.*
import android.bluetooth.le.ScanCallback
import android.bluetooth.le.ScanResult
import android.content.Context
import android.os.Handler
import android.os.Build
import io.flutter.plugin.common.EventChannel
import java.util.*

/**
 * Production-ready Bluetooth LE Manager.
 * Supports Nexora Pro: GATT Service Discovery and Characteristic Read/Write operations.
 */
class HardwareBluetoothManager(private val context: Context) {
    private var bluetoothAdapter: BluetoothAdapter? = null
    private var eventSink: EventChannel.EventSink? = null
    private var bluetoothGatt: BluetoothGatt? = null
    private var discoveredServicesCallback: ((List<String>) -> Unit)? = null
    private var readCallback: ((ByteArray?) -> Unit)? = null

    init {
        val manager = context.getSystemService(Context.BLUETOOTH_SERVICE) as BluetoothManager
        bluetoothAdapter = manager.adapter
    }

    fun setEventSink(sink: EventChannel.EventSink?) {
        this.eventSink = sink
    }

    @SuppressLint("MissingPermission")
    fun startScan(): Boolean {
        val adapter = bluetoothAdapter ?: return false
        if (!adapter.isEnabled) return false
        val scanner = adapter.bluetoothLeScanner ?: return false
        scanner.startScan(scanCallback)
        return true
    }

    @SuppressLint("MissingPermission")
    fun stopScan(): Boolean {
        bluetoothAdapter?.bluetoothLeScanner?.stopScan(scanCallback)
        return true
    }

    @SuppressLint("MissingPermission")
    fun connect(deviceId: String): Boolean {
        val adapter = bluetoothAdapter ?: return false
        if (!adapter.isEnabled || deviceId.isBlank()) return false
        val device = try {
            adapter.getRemoteDevice(deviceId)
        } catch (_: IllegalArgumentException) {
            return false
        }
        bluetoothGatt?.close()
        bluetoothGatt = device.connectGatt(context, false, gattCallback)
        return bluetoothGatt != null
    }

    @SuppressLint("MissingPermission")
    fun discoverServices(deviceId: String, callback: (List<String>) -> Unit) {
        discoveredServicesCallback = callback
        if (bluetoothGatt?.discoverServices() != true) {
            discoveredServicesCallback = null
            callback(emptyList())
        }
    }

    @SuppressLint("MissingPermission")
    fun sendData(deviceId: String, serviceId: String, charId: String, data: ByteArray): Boolean {
        val gatt = bluetoothGatt ?: return false
        val serviceUuid = parseUuid(serviceId) ?: return false
        val charUuid = parseUuid(charId) ?: return false
        val service = gatt.getService(serviceUuid) ?: return false
        val char = service.getCharacteristic(charUuid) ?: return false
        
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            gatt.writeCharacteristic(char, data, BluetoothGattCharacteristic.WRITE_TYPE_DEFAULT) == BluetoothStatusCodes.SUCCESS
        } else {
            @Suppress("DEPRECATION")
            char.value = data
            @Suppress("DEPRECATION")
            gatt.writeCharacteristic(char)
        }
    }

    @SuppressLint("MissingPermission")
    fun readData(deviceId: String, serviceId: String, charId: String, callback: (ByteArray?) -> Unit): Boolean {
        val gatt = bluetoothGatt ?: return false
        val serviceUuid = parseUuid(serviceId) ?: return false
        val charUuid = parseUuid(charId) ?: return false
        val service = gatt.getService(serviceUuid) ?: return false
        val char = service.getCharacteristic(charUuid) ?: return false
        
        readCallback = callback
        val success = gatt.readCharacteristic(char)
        if (!success) {
            readCallback = null
        }
        return success
    }

    @SuppressLint("MissingPermission")
    
    @SuppressLint("MissingPermission")
    fun requestMtu(deviceId: String, mtu: Int, callback: (Boolean) -> Unit) {
        val gatt = bluetoothGatt ?: run { callback(false); return }
        val success = gatt.requestMtu(mtu)
        callback(success)
    }

    @SuppressLint("MissingPermission")
    fun subscribeToCharacteristic(deviceId: String, serviceId: String, charId: String, enable: Boolean, callback: (Boolean) -> Unit) {
        val gatt = bluetoothGatt ?: run { callback(false); return }
        val serviceUuid = parseUuid(serviceId) ?: run { callback(false); return }
        val charUuid = parseUuid(charId) ?: run { callback(false); return }
        val service = gatt.getService(serviceUuid) ?: run { callback(false); return }
        val char = service.getCharacteristic(charUuid) ?: run { callback(false); return }

        val success = gatt.setCharacteristicNotification(char, enable)
        if (success) {
            val descriptor = char.getDescriptor(UUID.fromString("00002902-0000-1000-8000-00805f9b34fb"))
            if (descriptor != null) {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                    val value = if (enable) BluetoothGattDescriptor.ENABLE_NOTIFICATION_VALUE else BluetoothGattDescriptor.DISABLE_NOTIFICATION_VALUE
                    gatt.writeDescriptor(descriptor, value)
                } else {
                    @Suppress("DEPRECATION")
                    descriptor.value = if (enable) BluetoothGattDescriptor.ENABLE_NOTIFICATION_VALUE else BluetoothGattDescriptor.DISABLE_NOTIFICATION_VALUE
                    @Suppress("DEPRECATION")
                    gatt.writeDescriptor(descriptor)
                }
            }
        }
        callback(success)
    }

    @SuppressLint("MissingPermission")
    fun disconnect() {
        bluetoothGatt?.disconnect()
        bluetoothGatt?.close()
        bluetoothGatt = null
    }

    private fun parseUuid(value: String): UUID? {
        return try {
            UUID.fromString(value)
        } catch (_: IllegalArgumentException) {
            null
        }
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

        @Suppress("DEPRECATION")
        override fun onCharacteristicRead(gatt: BluetoothGatt, characteristic: BluetoothGattCharacteristic, status: Int) {
            val data = if (status == BluetoothGatt.GATT_SUCCESS) characteristic.value else null
            Handler(context.mainLooper).post {
                readCallback?.invoke(data)
                readCallback = null
            }
        }

        override fun onCharacteristicRead(gatt: BluetoothGatt, characteristic: BluetoothGattCharacteristic, value: ByteArray, status: Int) {
            val data = if (status == BluetoothGatt.GATT_SUCCESS) value else null
            Handler(context.mainLooper).post {
                readCallback?.invoke(data)
                readCallback = null
            }
        }
    }

    
        @Suppress("DEPRECATION")
        override fun onCharacteristicChanged(gatt: BluetoothGatt, characteristic: BluetoothGattCharacteristic) {
            val data = mapOf(
                "module" to "bluetooth",
                "type" to "data",
                "data" to mapOf(
                    "id" to gatt.device.address,
                    "serviceId" to characteristic.service.uuid.toString(),
                    "charId" to characteristic.uuid.toString(),
                    "value" to characteristic.value
                )
            )
            Handler(context.mainLooper).post { eventSink?.success(data) }
        }

        override fun onCharacteristicChanged(gatt: BluetoothGatt, characteristic: BluetoothGattCharacteristic, value: ByteArray) {
            val data = mapOf(
                "module" to "bluetooth",
                "type" to "data",
                "data" to mapOf(
                    "id" to gatt.device.address,
                    "serviceId" to characteristic.service.uuid.toString(),
                    "charId" to characteristic.uuid.toString(),
                    "value" to value
                )
            )
            Handler(context.mainLooper).post { eventSink?.success(data) }
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
