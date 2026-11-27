#!/usr/bin/env python3
"""Configure the generated Flutter Android project to use the persistent release key."""
from pathlib import Path

gradle = Path("android/app/build.gradle.kts")
if not gradle.is_file():
    raise SystemExit(f"Expected generated Gradle file: {gradle}")

text = gradle.read_text()
debug_line = 'signingConfig = signingConfigs.getByName("debug")'
release_line = 'signingConfig = signingConfigs.getByName("release")'
if release_line in text:
    print("Release signing is already configured.")
    raise SystemExit(0)
if debug_line not in text:
    raise SystemExit("Could not find Flutter template debug signing line; refusing unsafe patch.")

imports = "import java.io.FileInputStream\nimport java.util.Properties\n\n"
if "import java.util.Properties" not in text:
    text = imports + text

properties = """val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (!keystorePropertiesFile.exists()) {
    throw GradleException("Missing android/key.properties; release signing is not configured.")
}
keystoreProperties.load(FileInputStream(keystorePropertiesFile))

"""
marker = "android {"
if marker not in text:
    raise SystemExit("Could not find android { block.")
text = text.replace(marker, properties + marker, 1)

signing = """    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties["keyAlias"] as String
            keyPassword = keystoreProperties["keyPassword"] as String
            storeFile = file(keystoreProperties["storeFile"] as String)
            storePassword = keystoreProperties["storePassword"] as String
        }
    }

"""
build_types = "    buildTypes {"
if build_types not in text:
    raise SystemExit("Could not find buildTypes block.")
text = text.replace(build_types, signing + build_types, 1)
text = text.replace(debug_line, release_line, 1)
gradle.write_text(text)
print("Configured release build to use the persistent Pottery Manager signing key.")
