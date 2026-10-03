group = "com.inttegro.flutter"
version = "0.4.0"

buildscript {
    repositories {
        google()
        mavenCentral()
    }

    dependencies {
        classpath("com.android.tools.build:gradle:9.2.1")
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

apply(plugin = "com.android.library")

extensions.configure<com.android.build.api.dsl.LibraryExtension> {
    namespace = "com.inttegro.flutter"
    compileSdk = 37

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        minSdk = 26
    }
}

dependencies {
    add("implementation", "com.inttegro:inttegro-android:0.3.0")
}
