// <<< START DES HINZUGEFÜGTEN CODES FÜR DIE SIGNIERUNG >>>
def localProperties = new Properties()
def localPropertiesFile = rootProject.file('local.properties')
if (localPropertiesFile.exists()) {
    localPropertiesFile.withReader('UTF-8') { reader ->
        localProperties.load(reader)
    }
}

// Lade die Passwörter aus der neu erstellten key.properties
def keystoreProperties = new Properties()
def keystorePropertiesFile = rootProject.file('key.properties')
if (keystorePropertiesFile.exists()) {
    keystoreProperties.withReader('UTF-8') { reader ->
        keystoreProperties.load(reader)
    }
}
// <<< ENDE DES HINZUGEFÜGTEN CODES FÜR DIE SIGNIERUNG >>>


plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    id("com.google.gms.google-services") 
    id("dev.flutter.flutter-gradle-plugin") 
}

android {
    namespace = "at.isha.nexxchat_firebase" 
    compileSdk = 36 

    // <<< START DER HINZUGEFÜGTEN SIGNIERUNGSKONFIGURATION >>>
    signingConfigs {
        release {
            // Nutze die geladenen Werte aus key.properties
            storeFile file(keystoreProperties['storeFile'])
            storePassword keystoreProperties['storePassword']
            keyAlias keystoreProperties['keyAlias']
            keyPassword keystoreProperties['keyPassword']
        }
    }
    // <<< ENDE DER HINZUGEFÜGTEN SIGNIERUNGSKONFIGURATION >>>

    defaultConfig {
        applicationId = "at.isha.nexxchat_firebase" 
        minSdk = flutter.minSdkVersion 
        targetSdk = 36 
        versionCode = 1 
        versionName = "1.0" 
        multiDexEnabled = true
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = "17"
    }

    buildTypes {
        getByName("release") {
            // ALT: signingConfig = signingConfigs.getByName("debug")
            
            // NEU: Verwende die neu erstellte 'release' signing config
            signingConfig = signingConfigs.getByName("release") // Wichtig!
            isMinifyEnabled = false
            isShrinkResources = false
        }
        getByName("debug") {
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // Kotlin stdlib
    implementation("org.jetbrains.kotlin:kotlin-stdlib-jdk7:1.9.24")

    // MultiDex
    implementation("androidx.multidex:multidex:2.0.1")

    
    implementation(platform("com.google.firebase:firebase-bom:34.4.0"))

    
    implementation("com.google.firebase:firebase-auth")
    implementation("com.google.firebase:firebase-firestore")
    
}