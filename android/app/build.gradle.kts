plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    id("com.google.gms.google-services")        
    id("dev.flutter.flutter-gradle-plugin")     
}

android {
    namespace = "at.isha.nexxchat_firebase"    
    compileSdk = 36                            

    defaultConfig {
        applicationId = "at.isha.nexxchat_firebase"   
        minSdk = flutter.minSdkVersion                                   
        targetSdk = 36                                
        versionCode = 1                               
        versionName = "1.0"                           
        multiDexEnabled = true
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
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
