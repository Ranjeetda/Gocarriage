allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}

// ========== FORCE compileSdk = 36 for ALL plugins ==========
subprojects {
    afterEvaluate {
        val android = project.extensions.findByName("android")
        if (android != null) {
            try {
                // Works for most AGP versions
                android.javaClass.getMethod("setCompileSdkVersion", Int::class.javaPrimitiveType)
                    .invoke(android, 36)
            } catch (e: Exception) {
                try {
                    // Fallback
                    val field = android.javaClass.getDeclaredField("compileSdk")
                    field.isAccessible = true
                    field.set(android, 36)
                } catch (e2: Exception) {
                    println("Could not set compileSdk for ${project.name}")
                }
            }
        }
    }
}
// ==========================================================

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}