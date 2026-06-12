allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

rootProject.layout.buildDirectory.value(rootProject.layout.projectDirectory.dir("../build"))

subprojects {
    val subprojectBuildDir = rootProject.layout.buildDirectory.dir(project.name)
    project.layout.buildDirectory.value(subprojectBuildDir)
}

subprojects {
    project.evaluationDependsOn(":app")
}

subprojects {
    val project = this
    fun applyNamespaceFix() {
        if (project.hasProperty("android")) {
            val android = project.extensions.getByName("android")
            try {
                val getNamespace = android.javaClass.getMethod("getNamespace")
                val setNamespace = android.javaClass.getMethod("setNamespace", String::class.java)
                if (getNamespace.invoke(android) == null) {
                    setNamespace.invoke(android, "com.example.cinemanow.fallback.${project.name.replace("-", "_")}")
                }
            } catch (e: Exception) {
                // Extension might not have the methods or property
            }
        }
    }

    if (project.state.executed) {
        applyNamespaceFix()
    } else {
        project.afterEvaluate {
            applyNamespaceFix()
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
