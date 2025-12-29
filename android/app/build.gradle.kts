plugins {
    id("com.android.application")
    id("com.google.gms.google-services") // FlutterFire
    kotlin("android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.task_management_application"
    compileSdk = 36
    ndkVersion = "27.0.12077973"

    defaultConfig {
        applicationId = "com.example.task_management_application"
        minSdk = flutter.minSdkVersion
        targetSdk = 34
        versionCode = 1
        versionName = "1.0"
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
        isCoreLibraryDesugaringEnabled = true // Kotlin DSL syntax
    }

    kotlinOptions {
        jvmTarget = "11"
    }

    buildTypes {
        getByName("release") {
            signingConfig = signingConfigs.getByName("debug")
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }
}
dependencies {
    implementation(kotlin("stdlib"))

    // Core library desugaring
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.3")

    // ✅ Firebase BoM (manages all Firebase versions safely)
    implementation(platform("com.google.firebase:firebase-bom:32.7.0"))

    // ✅ Firebase libraries (NO versions here)
    implementation("com.google.firebase:firebase-analytics")
    implementation("com.google.firebase:firebase-messaging")

    // AndroidX
    implementation("androidx.core:core-ktx:1.12.0")
}


