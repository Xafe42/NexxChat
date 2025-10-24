import org.gradle.api.tasks.Delete
import org.gradle.api.file.Directory


allprojects {
    repositories {
        google()
        mavenCentral()
    }
}


plugins {
    id("com.android.application") version "8.9.1" apply false
    id("org.jetbrains.kotlin.android") apply false
    id("com.google.gms.google-services") version "4.3.15" apply false
    id("dev.flutter.flutter-gradle-plugin")  apply false
}


val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
    project.evaluationDependsOn(":app")
}

// clean task
tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}