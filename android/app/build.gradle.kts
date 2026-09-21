import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Firma de release. El keystore y su password viven en android/key.properties,
// que está en .gitignore: nunca entra al repo. Si el archivo no existe —un clone
// limpio, o una PC que todavía no copió el keystore— se cae a la firma de debug
// para que `flutter run --release` siga funcionando; ese APK sirve para probar,
// no para distribuir.
val propiedadesFirma = rootProject.file("key.properties")
val firmaConfigurada = propiedadesFirma.exists()
val firma = Properties().apply {
    if (firmaConfigurada) FileInputStream(propiedadesFirma).use { load(it) }
}

android {
    namespace = "io.github.t4toh.contadordetruco"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "io.github.t4toh.contadordetruco"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (firmaConfigurada) {
            create("release") {
                storeFile = file(firma.getProperty("storeFile"))
                storePassword = firma.getProperty("storePassword")
                keyAlias = firma.getProperty("keyAlias")
                keyPassword = firma.getProperty("keyPassword")
            }
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName(
                if (firmaConfigurada) "release" else "debug"
            )
        }
    }
}

flutter {
    source = "../.."
}
