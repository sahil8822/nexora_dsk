package com.nexora.sdk

import android.app.Activity
import android.content.Context
import androidx.biometric.BiometricManager
import androidx.biometric.BiometricPrompt
import androidx.core.content.ContextCompat
import androidx.fragment.app.FragmentActivity

/**
 * Manages native biometric authentication using AndroidX Biometric library.
 */
class HardwareBiometricManager(private val context: Context) {
    private var authenticators = BiometricManager.Authenticators.BIOMETRIC_STRONG
    private var allowDeviceCredential = true
    private var confirmationRequired = true

    fun configure(options: Map<String, Any?>) {
        allowDeviceCredential = options["allowDeviceCredential"] as? Boolean ?: true
        confirmationRequired = options["confirmationRequired"] as? Boolean ?: true
        val strength = when (options["strength"] as? String) {
            "weak" -> BiometricManager.Authenticators.BIOMETRIC_WEAK
            "strong" -> BiometricManager.Authenticators.BIOMETRIC_STRONG
            else -> BiometricManager.Authenticators.BIOMETRIC_STRONG
        }
        authenticators = if (allowDeviceCredential) {
            strength or BiometricManager.Authenticators.DEVICE_CREDENTIAL
        } else {
            strength
        }
    }

    fun canAuthenticate(): Boolean {
        val biometricManager = BiometricManager.from(context)
        return biometricManager.canAuthenticate(authenticators) == BiometricManager.BIOMETRIC_SUCCESS
    }

    fun authenticate(activity: Activity, reason: String, callback: (Boolean) -> Unit) {
        if (activity !is FragmentActivity) {
            callback(false)
            return
        }

        val executor = ContextCompat.getMainExecutor(context)
        val biometricPrompt = BiometricPrompt(activity, executor, object : BiometricPrompt.AuthenticationCallback() {
            override fun onAuthenticationSucceeded(result: BiometricPrompt.AuthenticationResult) {
                super.onAuthenticationSucceeded(result)
                callback(true)
            }

            override fun onAuthenticationError(errorCode: Int, errString: CharSequence) {
                super.onAuthenticationError(errorCode, errString)
                callback(false)
            }

            override fun onAuthenticationFailed() {
                super.onAuthenticationFailed()
                callback(false)
            }
        })

        val promptInfo = BiometricPrompt.PromptInfo.Builder()
            .setTitle("Authentication Required")
            .setSubtitle(reason)
            .setConfirmationRequired(confirmationRequired)
            .setAllowedAuthenticators(authenticators)

        if (!allowDeviceCredential) {
            promptInfo.setNegativeButtonText("Cancel")
        }

        biometricPrompt.authenticate(promptInfo.build())
    }
}
