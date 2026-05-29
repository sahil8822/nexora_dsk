package com.nexora.sdk

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.IBinder
import androidx.core.app.NotificationCompat

class NexoraForegroundService : Service() {
    private val defaultChannelId = "NexoraHardwareChannel"

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val title = intent?.getStringExtra("title") ?: "Background Processing"
        val content = intent?.getStringExtra("content") ?: "Hardware streams active"
        val channelId = intent?.getStringExtra("channelId")?.takeIf { it.isNotBlank() } ?: defaultChannelId
        val channelName = intent?.getStringExtra("channelName")?.takeIf { it.isNotBlank() }
            ?: "Hardware Background Service"

        createNotificationChannel(channelId, channelName)

        val notification = NotificationCompat.Builder(this, channelId)
            .setContentTitle(title)
            .setContentText(content)
            .setSmallIcon(android.R.drawable.ic_dialog_info)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .build()

        startForeground(7310, notification)
        return START_STICKY
    }

    override fun onBind(intent: Intent?): IBinder? = null

    private fun createNotificationChannel(channelId: String, channelName: String) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val serviceChannel = NotificationChannel(
                channelId,
                channelName,
                NotificationManager.IMPORTANCE_LOW
            )
            val manager = getSystemService(NotificationManager::class.java)
            manager.createNotificationChannel(serviceChannel)
        }
    }
}
