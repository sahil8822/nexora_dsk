package com.nexora.sdk

import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothManager
import android.bluetooth.le.AdvertiseCallback
import android.bluetooth.le.AdvertiseData
import android.bluetooth.le.AdvertiseSettings
import android.content.Context
import android.os.ParcelUuid
import java.util.UUID

class HardwareBlePeripheralManager(private val context: Context) {
    private val bluetoothAdapter: BluetoothAdapter? = (context.getSystemService(Context.BLUETOOTH_SERVICE) as BluetoothManager).adapter
    private var advertiseCallback: AdvertiseCallback? = null

    fun startAdvertising(uuid: String): Boolean {
        if (bluetoothAdapter == null || !bluetoothAdapter.isMultipleAdvertisementSupported) return false

        val advertiser = bluetoothAdapter.bluetoothLeAdvertiser ?: return false
        val settings = AdvertiseSettings.Builder()
            .setAdvertiseMode(AdvertiseSettings.ADVERTISE_MODE_LOW_LATENCY)
            .setTxPowerLevel(AdvertiseSettings.ADVERTISE_TX_POWER_HIGH)
            .setConnectable(true)
            .build()

        val data = AdvertiseData.Builder()
            .setIncludeDeviceName(true)
            .addServiceUuid(ParcelUuid(UUID.fromString(uuid)))
            .build()

        advertiseCallback = object : AdvertiseCallback() {
            override fun onStartSuccess(settingsInEffect: AdvertiseSettings?) {}
            override fun onStartFailure(errorCode: Int) {}
        }

        advertiser.startAdvertising(settings, data, advertiseCallback)
        return true
    }

    fun stopAdvertising() {
        val advertiser = bluetoothAdapter?.bluetoothLeAdvertiser
        if (advertiseCallback != null) {
            advertiser?.stopAdvertising(advertiseCallback)
            advertiseCallback = null
        }
    }
}
