import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// The upload key. Kept out of the repository: `android/key.properties` is
// gitignored and holds the path to a keystore that only the publisher has.
// See docs/store-submission.md.
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
val hasReleaseKeystore = keystorePropertiesFile.exists()
if (hasReleaseKeystore) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "app.calmcheck.calmcheck"
    compileSdk = flutter.compileSdkVersion
    // No plugin in this app compiles native code, so the NDK is not pulled in.
    // Everything here is Kotlin, Swift, and Dart.

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        // Required by flutter_local_notifications for the java.time APIs it
        // uses on older Android versions.
        isCoreLibraryDesugaringEnabled = true
    }

    defaultConfig {
        applicationId = "app.calmcheck"
        // mobile_scanner and image_picker both need 21+; Flutter's floor is
        // higher again, so take whichever the toolchain reports.
        minSdk = maxOf(flutter.minSdkVersion, 23)
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        resourceConfigurations += listOf("en")
    }

    signingConfigs {
        if (hasReleaseKeystore) {
            create("release") {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = keystoreProperties["storeFile"]?.let { file(it) }
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }

    buildTypes {
        release {
            // A release signed with the debug key cannot be uploaded, and must
            // never be produced quietly. Without key.properties the build stops
            // and says what is missing.
            signingConfig = if (hasReleaseKeystore) {
                signingConfigs.getByName("release")
            } else {
                null
            }
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro",
            )
        }
        debug {
            applicationIdSuffix = ".debug"
            versionNameSuffix = "-debug"
        }
    }
}

// Fails the build with an explanation rather than shipping an unsignable
// artifact.
gradle.taskGraph.whenReady {
    val buildingRelease = allTasks.any {
        it.name.contains("Release") && (
            it.name.startsWith("assemble") || it.name.startsWith("bundle")
        )
    }
    if (buildingRelease && !hasReleaseKeystore) {
        throw GradleException(
            "Release builds need an upload key. Create android/key.properties " +
                "with storeFile, storePassword, keyAlias and keyPassword. " +
                "See docs/store-submission.md."
        )
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
    // LocationManagerCompat.getCurrentLocation, so one-shot location works the
    // same way back to the app's minimum API.
    implementation("androidx.core:core-ktx:1.13.1")
}

flutter {
    source = "../.."
}
