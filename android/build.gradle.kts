allprojects {
    repositories {
        google()
        mavenCentral()
        maven { url = uri("https://jitpack.io") }
    }
}


val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)

    // Ensure AGP 8+ library modules have a namespace (needed for isar_flutter_libs)
    plugins.withId("com.android.library") {
        // Force modern SDK levels for all library modules (e.g., isar_flutter_libs) to avoid
        // missing newer attributes like android:attr/lStar during resource linking.
        extensions.configure<com.android.build.gradle.LibraryExtension>("android") {
            compileSdk = 36
            defaultConfig { targetSdk = 36 }
            if (namespace.isNullOrEmpty()) {
                namespace = "com.extrotarget.extropos.${project.name.replace('-', '_')}"
            }
        }
    }

    // Patch isar_flutter_libs manifest to remove deprecated package attribute (AGP 8 requirement)
    if (project.name == "isar_flutter_libs") {
        // Force modern SDK levels for isar_flutter_libs which defaults to API 30
        afterEvaluate {
            extensions.configure<com.android.build.gradle.LibraryExtension>("android") {
                compileSdk = 36
                defaultConfig { targetSdk = 36 }
            }

            tasks.withType<com.android.build.gradle.tasks.ProcessLibraryManifest>().configureEach {
                doFirst {
                    val manifestFile = file("src/main/AndroidManifest.xml")
                    if (manifestFile.exists()) {
                        val content = manifestFile.readText()
                        val updated = content.replace("package=\"dev.isar.isar_flutter_libs\"", "")
                        if (updated != content) {
                            manifestFile.writeText(updated)
                        }
                    }
                }
            }
        }
    }
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
