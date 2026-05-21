package com.nexora.sdk

import android.content.Context
import android.hardware.usb.UsbManager

class HardwareUsbManager(private val context: Context) {
    private val usbManager = context.getSystemService(Context.USB_SERVICE) as UsbManager

    fun getConnectedDevices(): List<String> {
        return usbManager.deviceList.values.map { it.deviceName }
    }
}
