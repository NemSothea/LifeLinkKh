import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    // Must come after the Android plugin. The build fails outright if
    // android/app/google-services.json is missing, which is the failure we want: Google
    // Sign-In failing silently at runtime is the alternative, and it is much worse.
    id("com.google.gms.google-services")
}

// docs/tech-lead/deploy-runbook.md Step 2. Unlike google-services.json, a missing
// key.properties does NOT fail the build — most local/CI runs (`flutter run --release`,
// PR checks) have no reason to hold the upload key, and forcing every teammate to fetch it
// just to smoke-test a release build would send it around outside the password manager.
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
val hasReleaseSigning = keystorePropertiesFile.exists()
if (hasReleaseSigning) {
    keystoreProperties.load(keystorePropertiesFile.inputStream())
}

android {
    namespace = "com.kosign.lifelinkkh"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.kosign.lifelinkkh"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        // Pinned rather than inherited: firebase_auth requires API 23, and a Flutter SDK
        // whose default drops below that would break the build in a way that reads as a
        // Firebase problem.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (hasReleaseSigning) {
            create("release") {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }

    buildTypes {
        release {
            // Real upload key when key.properties is present (Play Store builds — see the
            // deploy runbook); debug key otherwise so `flutter run --release` still works
            // for everyone without it. A build signed with the wrong one is never
            // installable over the other, so this must not silently produce a debug-signed
            // AAB that looks release-ready.
            signingConfig = if (hasReleaseSigning) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
