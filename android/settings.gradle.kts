// Read local.properties early so we can include the Flutter tooling build
// before Gradle attempts plugin resolution. This ensures plugins provided by
// the local Flutter SDK (such as dev.flutter.flutter-plugin-loader) are
// available to the settings script.
import java.util.Properties
import java.io.FileInputStream

pluginManagement {
    // Load flutter.sdk from local.properties when available (avoids using hard-coded paths)
    val localPropertiesFile = java.io.File(rootDir, "local.properties")
    val flutterSdkFromLocal = if (localPropertiesFile.exists()) {
        val localProperties = java.util.Properties()
        java.io.FileInputStream(localPropertiesFile).use { fis ->
            localProperties.load(fis)
        }
        localProperties.getProperty("flutter.sdk")
    } else null
    val envFlutterRoot = System.getenv("FLUTTER_ROOT")
    val flutterSdkPath = flutterSdkFromLocal ?: envFlutterRoot ?: "/usr/local/flutter"

    // Use the derived flutterSdkPath to include the gradle tooling
    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")

    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    id("com.android.application") version "8.9.1" apply false
    id("org.jetbrains.kotlin.android") version "2.1.0" apply false
}

include(":app")
