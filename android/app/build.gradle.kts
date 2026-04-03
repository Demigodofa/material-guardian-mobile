import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val repoRootDir = rootProject.projectDir.parentFile
val releaseSigningPropertiesFile = listOf(
    File(repoRootDir, "release-signing.properties"),
    rootProject.file("release-signing.properties"),
).firstOrNull { it.exists() }

val releaseSigningProperties = Properties().apply {
    if (releaseSigningPropertiesFile?.exists() == true) {
        releaseSigningPropertiesFile.inputStream().use(::load)
    }
}

fun releaseSigningValue(name: String): String? {
    return System.getenv("MG_$name")?.takeIf { it.isNotBlank() }
        ?: releaseSigningProperties.getProperty(name)?.takeIf { it.isNotBlank() }
}

val releaseStoreFile = releaseSigningValue("STORE_FILE")?.let { storePath ->
    val file = File(storePath)
    if (file.isAbsolute) file else File(repoRootDir, storePath)
}
val releaseStorePassword = releaseSigningValue("STORE_PASSWORD")
val releaseKeyAlias = releaseSigningValue("KEY_ALIAS")
val releaseKeyPassword = releaseSigningValue("KEY_PASSWORD")
val hasReleaseSigning = releaseStoreFile?.exists() == true &&
    !releaseStorePassword.isNullOrBlank() &&
    !releaseKeyAlias.isNullOrBlank() &&
    !releaseKeyPassword.isNullOrBlank()

android {
    namespace = "com.asme.receiving"
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
        applicationId = "com.asme.receiving"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (hasReleaseSigning) {
            create("releaseUpload") {
                storeFile = releaseStoreFile
                storePassword = releaseStorePassword
                keyAlias = releaseKeyAlias
                keyPassword = releaseKeyPassword
            }
        }
    }

    buildTypes {
        debug {
            applicationIdSuffix = ".dev"
            versionNameSuffix = "-dev"
        }
        release {
            // Keep local release runs possible without blocking on signing setup,
            // but use the real upload key whenever release-signing.properties or
            // MG_* environment variables are configured.
            signingConfig = if (hasReleaseSigning) {
                signingConfigs.getByName("releaseUpload")
            } else {
                signingConfigs.getByName("debug")
            }
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    implementation("com.google.android.gms:play-services-mlkit-document-scanner:16.0.0")
}
