package com.nexora.sdk

import android.annotation.SuppressLint
import android.bluetooth.*
import android.bluetooth.le.AdvertiseCallback
import android.bluetooth.le.AdvertiseData
import android.bluetooth.le.AdvertiseSettings
import android.content.Context
import android.os.Handler
import android.os.ParcelUuid
import io.flutter.plugin.common.EventChannel
import java.util.UUID

/**
 * BLE Peripheral Mode with full GATT Server.
 *
 * Starts advertising with a custom service UUID and hosts a GATT service
 * containing a read/write characteristic. Incoming writes from connected
 * centrals are forwarded to the Flutter EventSink so Dart code can react
 * to incoming BLE payloads.
 */
class HardwareBlePeripheralManager(private val context: Context) {
    private val bluetoothManager: BluetoothManager =
        context.getSystemService(Context.BLUETOOTH_SERVICE) as BluetoothManager
    private val bluetoothAdapter: BluetoothAdapter? = bluetoothManager.adapter
    private var advertiseCallback: AdvertiseCallback? = null
    private var gattServer: BluetoothGattServer? = null
    private var eventSink: EventChannel.EventSink? = null

    companion object {
        /** Fixed characteristic UUID used for the hosted GATT service. */
        private val CHARACTERISTIC_UUID: UUID =
            UUID.fromString("0000ff01-0000-1000-8000-00805f9b34fb")
    }

    fun setEventSink(sink: EventChannel.EventSink?) {
        this.eventSink = sink
    }

    @SuppressLint("MissingPermission")
    fun startAdvertising(uuid: String): Boolean {
        if (bluetoothAdapter == null || !bluetoothAdapter.isMultipleAdvertisementSupported) return false

        val advertiser = bluetoothAdapter.bluetoothLeAdvertiser ?: return false
        val serviceUuid = try {
            UUID.fromString(uuid)
        } catch (_: IllegalArgumentException) {
            return false
        }

        // --- Open GATT Server ---
        gattServer = bluetoothManager.openGattServer(context, gattServerCallback)
        if (gattServer == null) return false

        val service = BluetoothGattService(
            serviceUuid,
            BluetoothGattService.SERVICE_TYPE_PRIMARY
        )

        val characteristic = BluetoothGattCharacteristic(
            CHARACTERISTIC_UUID,
            BluetoothGattCharacteristic.PROPERTY_READ or
                    BluetoothGattCharacteristic.PROPERTY_WRITE or
                    BluetoothGattCharacteristic.PROPERTY_WRITE_NO_RESPONSE,
            BluetoothGattCharacteristic.PERMISSION_READ or
                    BluetoothGattCharacteristic.PERMISSION_WRITE
        )
        service.addCharacteristic(characteristic)

        if (!gattServer!!.addService(service)) {
            gattServer?.close()
            gattServer = null
            return false
        }

        // --- Start Advertising ---
        val settings = AdvertiseSettings.Builder()
            .setAdvertiseMode(AdvertiseSettings.ADVERTISE_MODE_LOW_LATENCY)
            .setTxPowerLevel(AdvertiseSettings.ADVERTISE_TX_POWER_HIGH)
            .setConnectable(true)
            .build()

        val data = AdvertiseData.Builder()
            .setIncludeDeviceName(true)
            .addServiceUuid(ParcelUuid(serviceUuid))
            .build()

        advertiseCallback = object : AdvertiseCallback() {
            override fun onStartSuccess(settingsInEffect: AdvertiseSettings?) {
                val statusData = mapOf(
                    "module" to "blePeripheral",
                    "type" to "status",
                    "data" to mapOf("state" to "advertising")
                )
                Handler(context.mainLooper).post { eventSink?.success(statusData) }
            }

            override fun onStartFailure(errorCode: Int) {
                val statusData = mapOf(
                    "module" to "blePeripheral",
                    "type" to "status",
                    "data" to mapOf(
                        "state" to "advertisingFailed",
                        "errorCode" to errorCode
                    )
                )
                Handler(context.mainLooper).post { eventSink?.success(statusData) }
            }
        }

        advertiser.startAdvertising(settings, data, advertiseCallback)
        return true
    }

    @SuppressLint("MissingPermission")
    fun stopAdvertising() {
        val advertiser = bluetoothAdapter?.bluetoothLeAdvertiser
        if (advertiseCallback != null) {
            advertiser?.stopAdvertising(advertiseCallback)
            advertiseCallback = null
        }
        gattServer?.close()
        gattServer = null

        val statusData = mapOf(
            "module" to "blePeripheral",
            "type" to "status",
            "data" to mapOf("state" to "stopped")
        )
        Handler(context.mainLooper).post { eventSink?.success(statusData) }
    }

    // ======================== GATT Server Callback ========================

    private val gattServerCallback = object : BluetoothGattServerCallback() {

        @SuppressLint("MissingPermission")
        override fun onConnectionStateChange(device: BluetoothDevice, status: Int, newState: Int) {
            val state = if (newState == BluetoothProfile.STATE_CONNECTED) "connected" else "disconnected"
            val statusData = mapOf(
                "module" to "blePeripheral",
                "type" to "status",
                "data" to mapOf(
                    "id" to device.address,
                    "state" to state
                )
            )
            Handler(context.mainLooper).post { eventSink?.success(statusData) }
        }

        @SuppressLint("MissingPermission")
        override fun onCharacteristicReadRequest(
            device: BluetoothDevice,
            requestId: Int,
            offset: Int,
            characteristic: BluetoothGattCharacteristic
        ) {
            // Respond with the current value of the characteristic (if any).
            val value = characteristic.value ?: ByteArray(0)
            gattServer?.sendResponse(
                device,
                requestId,
                BluetoothGatt.GATT_SUCCESS,
                offset,
                if (offset < value.size) value.copyOfRange(offset, value.size) else ByteArray(0)
            )
        }

        @SuppressLint("MissingPermission")
        override fun onCharacteristicWriteRequest(
            device: BluetoothDevice,
            requestId: Int,
            characteristic: BluetoothGattCharacteristic,
            preparedWrite: Boolean,
            responseNeeded: Boolean,
            offset: Int,
            value: ByteArray?
        ) {
            // Acknowledge the write to the central.
            if (responseNeeded) {
                gattServer?.sendResponse(
                    device,
                    requestId,
                    BluetoothGatt.GATT_SUCCESS,
                    offset,
                    value
                )
            }

            // Forward the written bytes to Flutter.
            if (value != null && value.isNotEmpty()) {
                val eventData = mapOf(
                    "module" to "blePeripheral",
                    "type" to "data",
                    "data" to mapOf(
                        "id" to device.address,
                        "serviceId" to characteristic.service.uuid.toString(),
                        "charId" to characteristic.uuid.toString(),
                        "value" to value.toList()
                    )
                )
                Handler(context.mainLooper).post { eventSink?.success(eventData) }
            }
        }

        override fun onServiceAdded(status: Int, service: BluetoothGattService?) {
            val statusData = mapOf(
                "module" to "blePeripheral",
                "type" to "status",
                "data" to mapOf(
                    "state" to "serviceAdded",
                    "serviceUuid" to (service?.uuid?.toString() ?: ""),
                    "success" to (status == BluetoothGatt.GATT_SUCCESS)
                )
            )
            Handler(context.mainLooper).post { eventSink?.success(statusData) }
        }
    }
}
