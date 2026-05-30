package com.nexora.sdk

import android.app.Activity
import android.os.Build
import android.security.keystore.KeyGenParameterSpec
import android.security.keystore.KeyProperties
import androidx.biometric.BiometricPrompt
import androidx.core.content.ContextCompat
import androidx.fragment.app.FragmentActivity
import java.security.*
import javax.crypto.Cipher
import javax.crypto.KeyGenerator
import javax.crypto.SecretKey
import javax.crypto.spec.GCMParameterSpec

/**
 * Production-grade Biometric Cryptography Manager.
 *
 * Manages hardware-backed cryptographic keys in the Android Keystore with optional
 * biometric authentication requirements and StrongBox TEE backing.
 *
 * Key strategy per alias:
 *   - `{alias}_ec`  → EC P-256 key pair for signing
 *   - `{alias}_aes` → AES-256-GCM secret key for encrypt/decrypt
 */
class HardwareCryptoManager {

    companion object {
        private const val KEYSTORE_PROVIDER = "AndroidKeyStore"
        private const val AES_TRANSFORMATION = "AES/GCM/NoPadding"
        private const val GCM_IV_LENGTH = 12
        private const val GCM_TAG_LENGTH = 128
        private const val EC_SUFFIX = "_ec"
        private const val AES_SUFFIX = "_aes"
    }

    private var activityRef: Activity? = null

    fun setActivity(activity: Activity?) {
        this.activityRef = activity
    }

    // ======================== Key Generation ========================

    /**
     * Generates both an EC P-256 key pair (for signing) and an AES-256 key
     * (for encrypt/decrypt) under the given alias, with optional biometric
     * lock and StrongBox TEE backing.
     */
    fun generateBiometricKey(
        alias: String,
        requireBiometric: Boolean,
        useStrongBox: Boolean
    ): Boolean {
        return try {
            generateEcKeyPair(alias + EC_SUFFIX, requireBiometric, useStrongBox)
            generateAesKey(alias + AES_SUFFIX, requireBiometric, useStrongBox)
            true
        } catch (_: Exception) {
            false
        }
    }

    private fun generateEcKeyPair(
        keyAlias: String,
        requireBiometric: Boolean,
        useStrongBox: Boolean
    ) {
        val builder = KeyGenParameterSpec.Builder(
            keyAlias,
            KeyProperties.PURPOSE_SIGN or KeyProperties.PURPOSE_VERIFY
        )
            .setDigests(KeyProperties.DIGEST_SHA256)
            .setAlgorithmParameterSpec(
                java.security.spec.ECGenParameterSpec("secp256r1")
            )

        if (requireBiometric) {
            builder.setUserAuthenticationRequired(true)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                builder.setUserAuthenticationParameters(
                    0, KeyProperties.AUTH_BIOMETRIC_STRONG
                )
            }
        }

        if (useStrongBox && Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            builder.setIsStrongBoxBacked(true)
        }

        val keyPairGen = KeyPairGenerator.getInstance(
            KeyProperties.KEY_ALGORITHM_EC, KEYSTORE_PROVIDER
        )
        keyPairGen.initialize(builder.build())
        keyPairGen.generateKeyPair()
    }

    private fun generateAesKey(
        keyAlias: String,
        requireBiometric: Boolean,
        useStrongBox: Boolean
    ) {
        val builder = KeyGenParameterSpec.Builder(
            keyAlias,
            KeyProperties.PURPOSE_ENCRYPT or KeyProperties.PURPOSE_DECRYPT
        )
            .setBlockModes(KeyProperties.BLOCK_MODE_GCM)
            .setEncryptionPaddings(KeyProperties.ENCRYPTION_PADDING_NONE)
            .setKeySize(256)

        if (requireBiometric) {
            builder.setUserAuthenticationRequired(true)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                builder.setUserAuthenticationParameters(
                    0, KeyProperties.AUTH_BIOMETRIC_STRONG
                )
            }
        }

        if (useStrongBox && Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            builder.setIsStrongBoxBacked(true)
        }

        val keyGen = KeyGenerator.getInstance(
            KeyProperties.KEY_ALGORITHM_AES, KEYSTORE_PROVIDER
        )
        keyGen.init(builder.build())
        keyGen.generateKey()
    }

    // ======================== Key Management ========================

    fun deleteKey(alias: String): Boolean {
        return try {
            val ks = KeyStore.getInstance(KEYSTORE_PROVIDER)
            ks.load(null)
            ks.deleteEntry(alias + EC_SUFFIX)
            ks.deleteEntry(alias + AES_SUFFIX)
            true
        } catch (_: Exception) {
            false
        }
    }

    fun keyExists(alias: String): Boolean {
        return try {
            val ks = KeyStore.getInstance(KEYSTORE_PROVIDER)
            ks.load(null)
            ks.containsAlias(alias + EC_SUFFIX) || ks.containsAlias(alias + AES_SUFFIX)
        } catch (_: Exception) {
            false
        }
    }

    // ======================== Signing ========================

    /**
     * Signs data with the biometric-locked EC key.
     * If the key requires biometric auth, displays the BiometricPrompt.
     */
    fun signWithBiometricKey(
        alias: String,
        data: ByteArray,
        callback: (ByteArray?) -> Unit
    ) {
        try {
            val ks = KeyStore.getInstance(KEYSTORE_PROVIDER)
            ks.load(null)
            val privateKey = ks.getKey(alias + EC_SUFFIX, null) as? PrivateKey
                ?: run { callback(null); return }

            val signature = Signature.getInstance("SHA256withECDSA")

            // Try without biometric first — if the key is not biometric-locked
            // this will succeed. If it IS locked, we need CryptoObject.
            try {
                signature.initSign(privateKey)
                signature.update(data)
                callback(signature.sign())
            } catch (_: UserNotAuthenticatedException) {
                // Key requires biometric auth
                authenticateWithCryptoSignature(signature, privateKey, data, callback)
            } catch (e: java.security.InvalidKeyException) {
                // Also can happen when user auth is required
                authenticateWithCryptoSignature(signature, privateKey, data, callback)
            }
        } catch (e: Exception) {
            callback(null)
        }
    }

    private fun authenticateWithCryptoSignature(
        signature: Signature,
        privateKey: PrivateKey,
        data: ByteArray,
        callback: (ByteArray?) -> Unit
    ) {
        val activity = activityRef as? FragmentActivity
            ?: run { callback(null); return }

        signature.initSign(privateKey)
        val cryptoObject = BiometricPrompt.CryptoObject(signature)
        val executor = ContextCompat.getMainExecutor(activity)

        val prompt = BiometricPrompt(activity, executor,
            object : BiometricPrompt.AuthenticationCallback() {
                override fun onAuthenticationSucceeded(result: BiometricPrompt.AuthenticationResult) {
                    try {
                        val authedSignature = result.cryptoObject?.signature
                            ?: run { callback(null); return }
                        authedSignature.update(data)
                        callback(authedSignature.sign())
                    } catch (_: Exception) {
                        callback(null)
                    }
                }

                override fun onAuthenticationError(errorCode: Int, errString: CharSequence) {
                    callback(null)
                }

                override fun onAuthenticationFailed() {
                    // Don't callback yet — user can retry
                }
            }
        )

        val promptInfo = BiometricPrompt.PromptInfo.Builder()
            .setTitle("Authentication Required")
            .setSubtitle("Authenticate to use cryptographic key")
            .setNegativeButtonText("Cancel")
            .build()

        prompt.authenticate(promptInfo, cryptoObject)
    }

    // ======================== Encryption ========================

    /**
     * Encrypts plaintext with the biometric-locked AES-GCM key.
     * Returns IV (12 bytes) || ciphertext.
     */
    fun encryptWithBiometricKey(
        alias: String,
        plaintext: ByteArray,
        callback: (ByteArray?) -> Unit
    ) {
        try {
            val ks = KeyStore.getInstance(KEYSTORE_PROVIDER)
            ks.load(null)
            val secretKey = ks.getKey(alias + AES_SUFFIX, null) as? SecretKey
                ?: run { callback(null); return }

            val cipher = Cipher.getInstance(AES_TRANSFORMATION)

            try {
                cipher.init(Cipher.ENCRYPT_MODE, secretKey)
                val iv = cipher.iv
                val ciphertext = cipher.doFinal(plaintext)
                // Prepend IV to ciphertext
                callback(iv + ciphertext)
            } catch (_: UserNotAuthenticatedException) {
                authenticateWithCryptoEncrypt(cipher, secretKey, plaintext, callback)
            } catch (_: java.security.InvalidKeyException) {
                authenticateWithCryptoEncrypt(cipher, secretKey, plaintext, callback)
            }
        } catch (_: Exception) {
            callback(null)
        }
    }

    private fun authenticateWithCryptoEncrypt(
        cipher: Cipher,
        secretKey: SecretKey,
        plaintext: ByteArray,
        callback: (ByteArray?) -> Unit
    ) {
        val activity = activityRef as? FragmentActivity
            ?: run { callback(null); return }

        cipher.init(Cipher.ENCRYPT_MODE, secretKey)
        val cryptoObject = BiometricPrompt.CryptoObject(cipher)
        val executor = ContextCompat.getMainExecutor(activity)

        val prompt = BiometricPrompt(activity, executor,
            object : BiometricPrompt.AuthenticationCallback() {
                override fun onAuthenticationSucceeded(result: BiometricPrompt.AuthenticationResult) {
                    try {
                        val authedCipher = result.cryptoObject?.cipher
                            ?: run { callback(null); return }
                        val iv = authedCipher.iv
                        val ciphertext = authedCipher.doFinal(plaintext)
                        callback(iv + ciphertext)
                    } catch (_: Exception) {
                        callback(null)
                    }
                }

                override fun onAuthenticationError(errorCode: Int, errString: CharSequence) {
                    callback(null)
                }

                override fun onAuthenticationFailed() {}
            }
        )

        val promptInfo = BiometricPrompt.PromptInfo.Builder()
            .setTitle("Authentication Required")
            .setSubtitle("Authenticate to encrypt data")
            .setNegativeButtonText("Cancel")
            .build()

        prompt.authenticate(promptInfo, cryptoObject)
    }

    // ======================== Decryption ========================

    /**
     * Decrypts ciphertext with the biometric-locked AES-GCM key.
     * Expects input format: IV (12 bytes) || ciphertext.
     */
    fun decryptWithBiometricKey(
        alias: String,
        ciphertext: ByteArray,
        callback: (ByteArray?) -> Unit
    ) {
        try {
            if (ciphertext.size <= GCM_IV_LENGTH) {
                callback(null)
                return
            }

            val iv = ciphertext.copyOfRange(0, GCM_IV_LENGTH)
            val encrypted = ciphertext.copyOfRange(GCM_IV_LENGTH, ciphertext.size)

            val ks = KeyStore.getInstance(KEYSTORE_PROVIDER)
            ks.load(null)
            val secretKey = ks.getKey(alias + AES_SUFFIX, null) as? SecretKey
                ?: run { callback(null); return }

            val cipher = Cipher.getInstance(AES_TRANSFORMATION)
            val spec = GCMParameterSpec(GCM_TAG_LENGTH, iv)

            try {
                cipher.init(Cipher.DECRYPT_MODE, secretKey, spec)
                callback(cipher.doFinal(encrypted))
            } catch (_: UserNotAuthenticatedException) {
                authenticateWithCryptoDecrypt(cipher, secretKey, spec, encrypted, callback)
            } catch (_: java.security.InvalidKeyException) {
                authenticateWithCryptoDecrypt(cipher, secretKey, spec, encrypted, callback)
            }
        } catch (_: Exception) {
            callback(null)
        }
    }

    private fun authenticateWithCryptoDecrypt(
        cipher: Cipher,
        secretKey: SecretKey,
        spec: GCMParameterSpec,
        encrypted: ByteArray,
        callback: (ByteArray?) -> Unit
    ) {
        val activity = activityRef as? FragmentActivity
            ?: run { callback(null); return }

        cipher.init(Cipher.DECRYPT_MODE, secretKey, spec)
        val cryptoObject = BiometricPrompt.CryptoObject(cipher)
        val executor = ContextCompat.getMainExecutor(activity)

        val prompt = BiometricPrompt(activity, executor,
            object : BiometricPrompt.AuthenticationCallback() {
                override fun onAuthenticationSucceeded(result: BiometricPrompt.AuthenticationResult) {
                    try {
                        val authedCipher = result.cryptoObject?.cipher
                            ?: run { callback(null); return }
                        callback(authedCipher.doFinal(encrypted))
                    } catch (_: Exception) {
                        callback(null)
                    }
                }

                override fun onAuthenticationError(errorCode: Int, errString: CharSequence) {
                    callback(null)
                }

                override fun onAuthenticationFailed() {}
            }
        )

        val promptInfo = BiometricPrompt.PromptInfo.Builder()
            .setTitle("Authentication Required")
            .setSubtitle("Authenticate to decrypt data")
            .setNegativeButtonText("Cancel")
            .build()

        prompt.authenticate(promptInfo, cryptoObject)
    }

    // ======================== Legacy (non-biometric) ========================

    fun generateSecureKeyPair(alias: String): Boolean {
        return generateBiometricKey(alias, requireBiometric = false, useStrongBox = false)
    }

    fun signData(alias: String, data: ByteArray): ByteArray? {
        var result: ByteArray? = null
        signWithBiometricKey(alias, data) { result = it }
        return result
    }
}
