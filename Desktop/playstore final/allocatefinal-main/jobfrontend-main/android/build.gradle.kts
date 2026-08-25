import org.gradle.api.file.Directory
import org.jetbrains.kotlin.gradle.tasks.KotlinCompile

allprojects {
    repositories {
        google()
        mavenCentral()
        maven {
            url = uri("https://phonepe.mycloudrepo.io/public/repositories/phonepe-intentsdk-android")
        }
    }
    // Kotlin incremental compile breaks on Windows when Pub cache (C:) and project (e.g. F:) differ.
    tasks.withType<KotlinCompile>().configureEach {
        incremental = false
    }
}

// Flutter tooling looks for APKs under <project>/build/app/outputs/flutter-apk/ — not android/app/build/.
val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}

subprojects {
    project.evaluationDependsOn(":app")
}

subprojects {
    val configureNamespace: () -> Unit = {
        val androidExtension = project.extensions.findByName("android")
        if (androidExtension != null) {
            val hasNamespace = try {
                val getNamespace = androidExtension.javaClass.getMethod("getNamespace")
                getNamespace.invoke(androidExtension) != null
            } catch (e: Exception) {
                false
            }
            if (!hasNamespace) {
                try {
                    val setNamespace = androidExtension.javaClass.getMethod("setNamespace", String::class.java)
                    val fallbackNamespace = "com.example." + project.name.replace(":", "").replace("-", "_")
                    setNamespace.invoke(androidExtension, fallbackNamespace)
                } catch (e: Exception) {
                    // Ignore if method not found
                }
            }
        }
    }
    if (project.state.executed) {
        configureNamespace()
    } else {
        project.afterEvaluate {
            configureNamespace()
        }
    }
}



tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
