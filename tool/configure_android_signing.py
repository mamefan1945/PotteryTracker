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

# Enable R8 code shrinking and Android resource shrinking for release APKs.
release_block = '''    buildTypes {
        release {
'''
optimized_block = '''    buildTypes {
        release {
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
'''
if optimized_block not in text:
    if release_block not in text:
        raise SystemExit("Could not find release buildTypes block; refusing unsafe optimization patch.")
    text = text.replace(release_block, optimized_block, 1)

gradle.write_text(text)

# Keep the Flutter entry-point annotation and Java/Kotlin metadata needed by
# reflective/plugin integrations while allowing R8 to shrink unused code.
rules = Path("android/app/proguard-rules.pro")
if not rules.exists():
    rules.write_text("""# Preserve runtime annotations and signatures used by Android/plugin integrations.
-keepattributes *Annotation*,Signature,InnerClasses,EnclosingMethod

# Flutter entry points may be referenced by generated or reflective integration code.
-keep class io.flutter.embedding.engine.FlutterJNI { *; }
-keep class io.flutter.embedding.engine.dart.DartExecutor { *; }
-keep class io.flutter.plugin.** { *; }

# Preserve native method declarations.
-keepclasseswithmembernames,includedescriptorclasses class * {
    native <methods>;
}
""")

print("Configured persistent release signing, R8 code shrinking, and Android resource shrinking.")
