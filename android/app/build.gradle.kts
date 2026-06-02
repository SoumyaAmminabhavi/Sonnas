import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.sonnas.app"
    compileSdk = flutter.compileSdkVersion
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
        applicationId = "com.sonnas.app"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }
    val keystoreProperties = Properties()
    val keystorePropertiesFile = rootProject.file("key.properties")
    if (keystorePropertiesFile.exists()) {
        keystoreProperties.load(FileInputStream(keystorePropertiesFile))
    }

    signingConfigs {
        create("release") {
            val keyPath = keystoreProperties["storeFile"] as String? ?: System.getenv("KEYSTORE_PATH") ?: "release.keystore"
            storeFile = file(keyPath)
            storePassword = keystoreProperties["storePassword"] as String? ?: System.getenv("KEYSTORE_PASSWORD")
            keyAlias = keystoreProperties["keyAlias"] as String? ?: System.getenv("KEY_ALIAS")
            keyPassword = keystoreProperties["keyPassword"] as String? ?: System.getenv("KEY_PASSWORD")
        }
    }

    // Move validation to task execution time
    gradle.taskGraph.whenReady {
        val releaseTasks = tasks.matching { 
            it.name.contains("Release", ignoreCase = true) && 
            (it.name.startsWith("assemble") || it.name.startsWith("bundle"))
        }
        
        if (releaseTasks.isNotEmpty()) {
            val keystorePassword = keystoreProperties["storePassword"] ?: System.getenv("KEYSTORE_PASSWORD")
            val keyAlias = keystoreProperties["keyAlias"] ?: System.getenv("KEY_ALIAS")
            val keyPassword = keystoreProperties["keyPassword"] ?: System.getenv("KEY_PASSWORD")
            
            if (keystorePassword == null || keyAlias == null || keyPassword == null) {
                val missing = mutableListOf<String>()
                if (keystorePassword == null) missing.add("KEYSTORE_PASSWORD (or storePassword in key.properties)")
                if (keyAlias == null) missing.add("KEY_ALIAS (or keyAlias in key.properties)")
                if (keyPassword == null) missing.add("KEY_PASSWORD (or keyPassword in key.properties)")
                
                throw GradleException("Release build failed: Missing signing configuration. ${missing.joinToString(", ")}. Please set them in your environment or android/key.properties.")
            }
        }
    }

    buildTypes {
        release {
            // Using release signing config for release builds
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
}

flutter {
    source = "../.."
}
