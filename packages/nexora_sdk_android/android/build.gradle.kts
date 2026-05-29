group = "com.nexora.sdk"
version = "3.1.2"

buildscript {
    val kotlinVersion = "2.0.21"
    repositories {
        google()
        mavenCentral()
    }

    dependencies {

        classpath("com.android.tools.build:gradle:8.2.2")
        classpath("org.jetbrains.kotlin:kotlin-gradle-plugin:$kotlinVersion")
    }
}

// Ensure repositories are available for the plugin's dependencies
repositories {
    google()
    mavenCentral()
    maven { url = uri("https://jitpack.io") }
}

plugins {
    id("com.android.library")
    id("kotlin-android")
}

val enableCamera = project.findProperty("nexora.camera.enabled")?.toString()?.toBoolean() ?: true
val enableBluetooth = project.findProperty("nexora.bluetooth.enabled")?.toString()?.toBoolean() ?: true
val enableLocation = project.findProperty("nexora.location.enabled")?.toString()?.toBoolean() ?: true
val enableAudio = project.findProperty("nexora.audio.enabled")?.toString()?.toBoolean() ?: true
val enableBiometric = project.findProperty("nexora.biometric.enabled")?.toString()?.toBoolean() ?: true
val enableNfc = project.findProperty("nexora.nfc.enabled")?.toString()?.toBoolean() ?: true

android {
    namespace = "com.nexora.sdk"
    compileSdk = 34
    ndkVersion = "28.2.13676358"
    externalNativeBuild {
        cmake {
            path("CMakeLists.txt")
        }
    }


    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    sourceSets {
        getByName("main") {
            java.srcDirs("src/main/kotlin")
        }
    }

    defaultConfig {
        minSdk = 24
    }
}

tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile>().configureEach {
    if (!enableCamera) exclude("**/CameraManager.kt")
    if (!enableBluetooth) {
        exclude("**/HardwareBluetoothManager.kt")
        exclude("**/HardwareBlePeripheralManager.kt")
    }
    if (!enableLocation) {
        exclude("**/HardwareLocationManager.kt")
        exclude("**/HardwareGeofenceReceiver.kt")
    }
    if (!enableAudio) exclude("**/HardwareAudioModule.kt")
    if (!enableBiometric) exclude("**/HardwareBiometricManager.kt")
    if (!enableNfc) exclude("**/HardwareNfcManager.kt")
}

dependencies {
    compileOnly("org.tensorflow:tensorflow-lite:2.14.0")
    implementation("androidx.work:work-runtime-ktx:2.9.0")

    if (enableLocation) {
        implementation("com.google.android.gms:play-services-location:21.3.0")
    }
    if (enableBiometric) {
        implementation("androidx.biometric:biometric:1.2.0-alpha05")
    }
    
    // ML Kit (Vision) - Efficient & Lightweight - Optional
    if (enableCamera) {
        compileOnly("com.google.mlkit:barcode-scanning:17.3.0")
        compileOnly("com.google.mlkit:face-detection:16.1.7")
    }
    
    // Audio Analysis (Native FFT Helper) - Hosted on JitPack
    if (enableAudio) {
        implementation("com.github.paramsen:noise:2.0.0")
    }
    
    implementation("androidx.core:core-ktx:1.12.0")
}
