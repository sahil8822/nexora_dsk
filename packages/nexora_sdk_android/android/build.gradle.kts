group = "com.nexora.sdk"
version = "3.1.2"

buildscript {
    val kotlinVersion = "2.0.21"
    repositories {
        google()
        mavenCentral()
    }

    dependencies {
    implementation("org.tensorflow:tensorflow-lite:2.14.0")
    implementation("androidx.work:work-runtime-ktx:2.9.0")

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

android {
    namespace = "com.nexora.sdk"
    compileSdk = 34
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
        getByName("main") { java.srcDirs("src/main/kotlin") }
    }

    defaultConfig {
        minSdk = 24
    }
}

dependencies {
    implementation("org.tensorflow:tensorflow-lite:2.14.0")
    implementation("androidx.work:work-runtime-ktx:2.9.0")

    // Core Hardware
    implementation("com.google.android.gms:play-services-location:21.3.0")
    implementation("androidx.biometric:biometric:1.2.0-alpha05")
    
    // ML Kit (Vision) - Efficient & Lightweight
    implementation("com.google.mlkit:barcode-scanning:17.3.0")
    implementation("com.google.mlkit:face-detection:16.1.7")
    
    // Audio Analysis (Native FFT Helper) - Hosted on JitPack
    implementation("com.github.paramsen:noise:2.0.0")
    
    implementation("androidx.core:core-ktx:1.12.0")
}
