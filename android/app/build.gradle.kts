import java.util.Properties // Import Properties
import java.io.FileInputStream // Import FileInputStream

plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    // END: FlutterFire Configuration
    kotlin("android") // Use kotlin("android") instead of id("kotlin-android") for .kts
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// START: Load keystore properties using Kotlin syntax
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties() // Uses the imported java.util.Properties
if (keystorePropertiesFile.exists()) {
    FileInputStream(keystorePropertiesFile).use { fis -> // Ensure stream is closed
        keystoreProperties.load(fis)
    }
}


android {
    namespace = "com.example.flutterprojects"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "27.0.12077973" // Ensure this is needed/correct for Flutter

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }


    signingConfigs {
        create("release") {
            // Load properties like this for clarity and direct use with rootProject.file
            val loadedStoreFile = keystoreProperties.getProperty("storeFile")
            val loadedStorePassword = keystoreProperties.getProperty("storePassword")
            val loadedKeyAlias = keystoreProperties.getProperty("keyAlias")
            val loadedKeyPassword = keystoreProperties.getProperty("keyPassword")

            // Check if properties were loaded and storeFile is not null
            if (keystorePropertiesFile.exists() && !keystoreProperties.isEmpty && loadedStoreFile != null) {
                storeFile = rootProject.file(loadedStoreFile) // Use rootProject.file for robust path resolution
                storePassword = loadedStorePassword
                keyAlias = loadedKeyAlias
                keyPassword = loadedKeyPassword
            }
            // If properties are not loaded, the build will fail later in the signing task,
            // which is an acceptable way to indicate the problem.
        }
    }

    defaultConfig {
        applicationId = "com.project.bloodlink"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        getByName("release") { // Use getByName for Kotlin DSL
            // Assign your release signing configuration:
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }
}

flutter {
    source = "../.."
}