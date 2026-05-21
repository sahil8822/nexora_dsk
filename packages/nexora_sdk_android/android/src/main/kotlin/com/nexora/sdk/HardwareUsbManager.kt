package com.nexora.sdk

import android.content.Context
import android.hardware.usb.UsbManager
import android.hardware.usb.UsbDeviceConnection
import android.hardware.usb.UsbDevice

class HardwareUsbManager(private val context: Context) {
    private var usbManager: UsbManager? = null
    private var connection: UsbDeviceConnection? = null
    private var activeDevice: UsbDevice? = null

    init {
        usbManager = context.getSystemService(Context.USB_SERVICE) as UsbManager
    }

    fun getConnectedUsbDevices(): List<Map<String, Any>> {
        val manager = usbManager ?: return emptyList()
        val devices = mutableListOf<Map<String, Any>>()
        for ((_, device) in manager.deviceList) {
            devices.add(mapOf(
                "deviceId" to device.deviceName,
                "name" to (device.productName ?: "Unknown Device"),
                "manufacturer" to (device.manufacturerName ?: "Unknown Manufacturer")
            ))
        }
        return devices
    }

    fun openUsbConnection(deviceId: String): Boolean {
        val manager = usbManager ?: return false
        val device = manager.deviceList[deviceId] ?: return false
        
        if (manager.hasPermission(device)) {
            connection = manager.openDevice(device)
            if (connection != null) {
                activeDevice = device
                return true
            }
        }
        return false
    }

    fun writeUsbData(deviceId: String, data: ByteArray): Boolean {
        val conn = connection ?: return false
        val device = activeDevice ?: return false
        if (device.deviceName != deviceId) return false
        
        if (device.interfaceCount > 0) {
            val intf = device.getInterface(0)
            conn.claimInterface(intf, true)
            if (intf.endpointCount > 0) {
                val endpoint = intf.getEndpoint(0)
                val bytesWritten = conn.bulkTransfer(endpoint, data, data.size, 1000)
                return bytesWritten == data.size
            }
        }
        return false
    }
}
