package com.nexora.sdk

import android.app.Activity
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.nfc.NdefMessage
import android.nfc.NdefRecord
import android.nfc.NfcAdapter
import android.nfc.Tag
import android.nfc.tech.Ndef
import android.os.Handler
import android.os.Looper
import io.flutter.plugin.common.EventChannel

class HardwareNfcManager(private val context: Context) {
    private var nfcAdapter: NfcAdapter? = NfcAdapter.getDefaultAdapter(context)
    private var eventSink: EventChannel.EventSink? = null
    private var isScanning = false
    private var writePendingMessage: NdefMessage? = null
    private var writeCallback: ((Boolean) -> Unit)? = null

    fun setEventSink(sink: EventChannel.EventSink?) {
        this.eventSink = sink
    }

    fun startScan(activity: Activity): Boolean {
        val adapter = nfcAdapter ?: return false
        if (!adapter.isEnabled) return false
        
        isScanning = true
        val intent = Intent(context, activity.javaClass).apply {
            addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP)
        }
        val pendingIntent = PendingIntent.getActivity(
            context, 0, intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_MUTABLE
        )
        
        val ndefFilter = IntentFilter(NfcAdapter.ACTION_NDEF_DISCOVERED).apply {
            try {
                addDataScheme("http")
                addDataScheme("https")
            } catch (e: Exception) {}
        }
        val filters = arrayOf(ndefFilter, IntentFilter(NfcAdapter.ACTION_TECH_DISCOVERED), IntentFilter(NfcAdapter.ACTION_TAG_DISCOVERED))
        
        activity.runOnUiThread {
            adapter.enableForegroundDispatch(activity, pendingIntent, filters, null)
        }
        return true
    }

    fun stopScan(activity: Activity): Boolean {
        val adapter = nfcAdapter ?: return false
        isScanning = false
        activity.runOnUiThread {
            adapter.disableForegroundDispatch(activity)
        }
        return true
    }

    fun writeNdef(type: String, payload: String, callback: (Boolean) -> Unit) {
        try {
            val record = NdefRecord.createMime(type, payload.toByteArray(Charsets.UTF_8))
            writePendingMessage = NdefMessage(arrayOf(record))
            writeCallback = callback
        } catch (e: Exception) {
            callback(false)
        }
    }

    fun handleIntent(intent: Intent): Boolean {
        if (!isScanning) return false
        val action = intent.action
        if (NfcAdapter.ACTION_NDEF_DISCOVERED == action ||
            NfcAdapter.ACTION_TECH_DISCOVERED == action ||
            NfcAdapter.ACTION_TAG_DISCOVERED == action) {
            
            val tag = intent.getParcelableExtra<Tag>(NfcAdapter.EXTRA_TAG) ?: return false
            
            val pendingMsg = writePendingMessage
            val callback = writeCallback
            if (pendingMsg != null && callback != null) {
                writePendingMessage = null
                writeCallback = null
                val success = writeTag(tag, pendingMsg)
                callback(success)
                return true
            }
            
            val rawMsgs = intent.getParcelableArrayExtra(NfcAdapter.EXTRA_NDEF_MESSAGES)
            val recordsList = mutableListOf<Map<String, String>>()
            if (rawMsgs != null) {
                for (rawMsg in rawMsgs) {
                    val msg = rawMsg as NdefMessage
                    for (record in msg.records) {
                        recordsList.add(mapOf(
                            "type" to String(record.type),
                            "payload" to String(record.payload)
                        ))
                    }
                }
            }
            
            val data = mapOf(
                "module" to "nfc",
                "type" to "tag_discovered",
                "data" to mapOf(
                    "id" to tag.id.joinToString("") { String.format("%02X", it) },
                    "techList" to tag.techList.toList(),
                    "records" to recordsList
                )
            )
            
            Handler(Looper.getMainLooper()).post {
                try { eventSink?.success(data) } catch (e: Exception) {}
            }
            return true
        }
        return false
    }

    private fun writeTag(tag: Tag, message: NdefMessage): Boolean {
        try {
            val ndef = Ndef.get(tag)
            if (ndef != null) {
                ndef.connect()
                if (!ndef.isWritable) return false
                if (ndef.maxSize < message.byteArrayLength) return false
                ndef.writeNdefMessage(message)
                ndef.close()
                return true
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }
        return false
    }
}
