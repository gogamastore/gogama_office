import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("com.google.gms.google-services")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

// Baca file properti keystore
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "store.gogama.office"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    // Konfigurasi untuk menandatangani aplikasi (TIDAK DIUBAH)
    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties["keyAlias"] as String?
            keyPassword = keystoreProperties["keyPassword"] as String?
            storeFile = if (keystoreProperties["storeFile"] != null) rootProject.file(keystoreProperties["storeFile"] as String) else null
            storePassword = keystoreProperties["storePassword"] as String?
        }
    }

    // --- PERUBAHAN 1: Mengaktifkan desugaring dan menyetel ke Java 8 ---
    compileOptions {
        isCoreLibraryDesugaringEnabled = true // Sintaks yang benar untuk KTS
        sourceCompatibility = JavaVersion.VERSION_1_8
        targetCompatibility = JavaVersion.VERSION_1_8
    }

    // --- PERUBAHAN 2: Menyesuaikan target JVM Kotlin ---
    kotlinOptions {
        jvmTarget = "1.8"
    }

    defaultConfig {
        applicationId = "store.gogama.office" // (TIDAK DIUBAH)
        minSdk = flutter.minSdkVersion // Set ke 21 untuk kompatibilitas desugaring
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        multiDexEnabled = true // (TIDAK DIUBAH)
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release") // (TIDAK DIUBAH)
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    implementation("androidx.multidex:multidex:2.0.1")

    // --- PERUBAHAN 3: Menambahkan dependensi untuk desugaring ---
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")
}
