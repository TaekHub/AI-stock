// android/settings.gradle.kts

pluginManagement {
    // local.properties 읽기
    val localProps = java.util.Properties()
    val localPropsFile = java.io.File(rootDir, "local.properties")
    check(localPropsFile.exists()) {
        "local.properties not found at ${localPropsFile.absolutePath}"
    }
    localPropsFile.inputStream().use { localProps.load(it) }

    val flutterSdkPath = localProps.getProperty("flutter.sdk")
        ?: throw org.gradle.api.GradleException("flutter.sdk not set in local.properties")

    // Flutter Gradle 플러그인 로더 연결 (이게 있어야 flutter.* 확장이 살아납니다)
    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")

    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"

    // 버전은 환경에 맞게 (예시)
    id("com.android.application") version "8.5.0" apply false
    id("org.jetbrains.kotlin.android") version "2.0.0" apply false
    id("com.google.gms.google-services") version "4.4.2" apply false
    // (선택) id("com.google.firebase.appdistribution") version "5.1.1" apply false
}

include(":app")
