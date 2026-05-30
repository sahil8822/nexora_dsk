package com.nexora.sdk

import android.content.Context
import android.util.Log
import androidx.work.CoroutineWorker
import androidx.work.WorkerParameters

class TelemetryWorker(
    context: Context,
    params: WorkerParameters
) : CoroutineWorker(context, params) {

    override suspend fun doWork(): Result {
        Log.d("NexoraSdk", "TelemetryWorker: Running background sync...")
        return try {
            val smartSync = SmartSyncManager.getInstance(applicationContext)
            smartSync.flushPendingData()
            Result.success()
        } catch (e: Exception) {
            Log.e("NexoraSdk", "TelemetryWorker Error", e)
            Result.retry()
        }
    }
}
