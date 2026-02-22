plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.extrotarget.extropos"
    compileSdk = 36
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.extrotarget.extropos"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = 36
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    // Define flavor dimensions
    flavorDimensions += "appType"

    // Define product flavors for POS, KDS, and Backend apps
    productFlavors {
        create("posApp") {
            dimension = "appType"
            applicationIdSuffix = ".pos"
            versionNameSuffix = "-pos"
            // Optional: Set custom app name for POS variant
            resValue("string", "app_name", "FlutterPOS")
        }

        create("kdsApp") {
            dimension = "appType"
            applicationIdSuffix = ".kds"
            versionNameSuffix = "-kds"
            // Optional: Set custom app name for KDS variant
            resValue("string", "app_name", "FlutterPOS Kitchen Display")
        }

        create("backendApp") {
            dimension = "appType"
            applicationIdSuffix = ".backend"
            versionNameSuffix = "-backend"
            // Optional: Set custom app name for Backend variant
            resValue("string", "app_name", "FlutterPOS Backend Manager")
        }

        create("keygenApp") {
            dimension = "appType"
            applicationIdSuffix = ".keygen"
            versionNameSuffix = "-keygen"
            // Optional: Set custom app name for Key Generator variant
            resValue("string", "app_name", "FlutterPOS License Generator")
        }

        create("frontendApp") {
            dimension = "appType"
            applicationIdSuffix = ".frontend"
            versionNameSuffix = "-frontend"
            // Optional: Set custom app name for Frontend variant
            resValue("string", "app_name", "FlutterPOS Customer")
        }
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // ESCPOS Thermal Printer SDK for Android
    implementation("com.github.DantSu:ESCPOS-ThermalPrinter-Android:3.3.0")

    // POSMAC Printer SDK
    implementation(files("libs/posprinterconnectandsendsdk.jar"))

    // USB Serial Communication Libraries (available versions)
    implementation("com.github.mik3y:usb-serial-for-android:3.8.1")

    // Additional thermal printer support libraries
    implementation("com.github.yuriy-budiyev:code-scanner:2.3.2") // For QR code support in receipts
}

// Exclude problematic flutter_web_auth_2 plugin from Android build
configurations.all {
    exclude(group = "com.linusu", module = "flutter_web_auth_2")
}
