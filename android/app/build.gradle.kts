import java.util.Base64
import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val validationApp = providers.gradleProperty("dart-defines").orNull.orEmpty()
    .split(",").filter { it.isNotBlank() }.any {
        runCatching { String(Base64.getDecoder().decode(it), Charsets.UTF_8) == "MAMBA_VALIDATION_APP=true" }
            .getOrDefault(false)
    }

// CI supplies credentials only to the release build step. Local signing may use
// the ignored android/key.properties file documented by Flutter.
val localSigning = Properties().apply {
    val propertiesFile = rootProject.file("key.properties")
    if (propertiesFile.isFile) propertiesFile.inputStream().use { load(it) }
}
fun signingValue(environmentName: String, propertyName: String): String? =
    providers.environmentVariable(environmentName).orNull
        ?: localSigning.getProperty(propertyName)
val releaseStore = signingValue("MAMBA_KEYSTORE_PATH", "storeFile")
val releaseStorePassword = signingValue("MAMBA_KEYSTORE_PASSWORD", "storePassword")
val releaseAlias = signingValue("MAMBA_KEY_ALIAS", "keyAlias")
val releaseKeyPassword = signingValue("MAMBA_KEY_PASSWORD", "keyPassword")
val releaseSigningReady = listOf(
    releaseStore, releaseStorePassword, releaseAlias, releaseKeyPassword
).all { !it.isNullOrBlank() }

android {
    namespace = "app.mamba.mambatv"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = if (validationApp) "app.mamba.mambatv.validation" else "app.mamba.mambatv"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = 24
        targetSdk = flutter.targetSdkVersion
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (releaseSigningReady) {
            create("release") {
                storeFile = rootProject.file(releaseStore!!)
                storePassword = releaseStorePassword
                keyAlias = releaseAlias
                keyPassword = releaseKeyPassword
            }
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.findByName("release")
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

tasks.matching { it.name == "preReleaseBuild" }.configureEach {
    doFirst {
        check(!validationApp) { "Release builds must use the product application ID." }
        check(releaseSigningReady) {
            "Release signing is required. Configure MAMBA_KEYSTORE_* / MAMBA_KEY_* or android/key.properties."
        }
        check(rootProject.file(releaseStore!!).isFile) { "Release keystore file is missing." }
    }
}
