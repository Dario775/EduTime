# ProGuard/R8 Rules for EduTime
# ================================
# These rules ensure proper code obfuscation while maintaining
# functionality for critical components.

# ============================================================
# GENERAL ANDROID RULES
# ============================================================

# Keep annotations
-keepattributes *Annotation*
-keepattributes Signature
-keepattributes Exceptions
-keepattributes InnerClasses
-keepattributes EnclosingMethod
-keepattributes SourceFile,LineNumberTable

# Keep native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# Keep Parcelable implementations
-keepclassmembers class * implements android.os.Parcelable {
    public static final ** CREATOR;
}

# Keep Serializable classes
-keepclassmembers class * implements java.io.Serializable {
    static final long serialVersionUID;
    private static final java.io.ObjectStreamField[] serialPersistentFields;
    !static !transient <fields>;
    private void writeObject(java.io.ObjectOutputStream);
    private void readObject(java.io.ObjectInputStream);
    java.lang.Object writeReplace();
    java.lang.Object readResolve();
}

# Keep R classes
-keepclassmembers class **.R$* {
    public static <fields>;
}

# ============================================================
# FLUTTER SPECIFIC RULES
# ============================================================

# Keep Flutter engine
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class io.flutter.embedding.** { *; }

# Keep Flutter plugin registrants
-keep class io.flutter.plugins.GeneratedPluginRegistrant { *; }

# Keep Flutter method channels
-keepclassmembers class * {
    @io.flutter.plugin.common.MethodChannel$MethodCallHandler <methods>;
}

# ============================================================
# FIREBASE RULES
# ============================================================

# Firebase Core
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }

# Firebase Auth
-keep class com.google.firebase.auth.** { *; }
-keepclassmembers class com.google.firebase.auth.** { *; }

# Firestore
-keep class com.google.firebase.firestore.** { *; }
-keepclassmembers class com.google.firebase.firestore.** { *; }

# Firebase Messaging (FCM)
-keep class com.google.firebase.messaging.** { *; }
-keepclassmembers class com.google.firebase.messaging.** { *; }

# Firebase Analytics
-keep class com.google.android.gms.measurement.** { *; }

# ============================================================
# EDUTIME APP SPECIFIC RULES
# ============================================================

# Keep EduTime services (Accessibility, Overlay)
-keep class com.edutime.app.services.** { *; }
-keepclassmembers class com.edutime.app.services.** { *; }

# Keep EduTime receivers
-keep class com.edutime.app.receivers.** { *; }
-keepclassmembers class com.edutime.app.receivers.** { *; }

# Keep MainActivity for Flutter binding
-keep class com.edutime.app.MainActivity { *; }
-keepclassmembers class com.edutime.app.MainActivity { *; }

# Keep model classes that may be serialized
-keep class com.edutime.app.models.** { *; }
-keepclassmembers class com.edutime.app.models.** { *; }

# ============================================================
# ACCESSIBILITY SERVICE PROTECTION
# ============================================================

# Ensure accessibility service is not stripped
-keep public class * extends android.accessibilityservice.AccessibilityService {
    public <init>(...);
}

# Keep accessibility event handling
-keepclassmembers class * extends android.accessibilityservice.AccessibilityService {
    public void onAccessibilityEvent(android.view.accessibility.AccessibilityEvent);
    public void onInterrupt();
    public void onServiceConnected();
}

# ============================================================
# OVERLAY SERVICE PROTECTION
# ============================================================

# Keep overlay service
-keep public class * extends android.app.Service {
    public <init>(...);
}

# Keep window manager interactions
-keepclassmembers class * {
    void addView(android.view.View, android.view.WindowManager$LayoutParams);
    void removeView(android.view.View);
}

# ============================================================
# SECURITY HARDENING
# ============================================================

# Remove logging in release builds
-assumenosideeffects class android.util.Log {
    public static int v(...);
    public static int d(...);
    public static int i(...);
    public static int w(...);
    public static int e(...);
    public static int wtf(...);
}

# Remove debug-only code
-assumenosideeffects class kotlin.jvm.internal.Intrinsics {
    public static void checkNotNull(...);
    public static void checkExpressionValueIsNotNull(...);
    public static void checkNotNullExpressionValue(...);
    public static void checkParameterIsNotNull(...);
    public static void checkNotNullParameter(...);
}

# Obfuscate package names for security
-repackageclasses 'com.edutime.app.internal'
-allowaccessmodification

# ============================================================
# CRYPTO & SECURITY LIBRARIES
# ============================================================

# Android Keystore
-keep class android.security.** { *; }
-keep class javax.crypto.** { *; }
-keep class java.security.** { *; }

# Keep key generation and cipher classes
-keepclassmembers class * {
    @android.security.keystore.* <methods>;
}

# ============================================================
# JSON SERIALIZATION
# ============================================================

# Gson (if used)
-keepattributes Signature
-keep class com.google.gson.** { *; }
-keep class * implements com.google.gson.TypeAdapterFactory
-keep class * implements com.google.gson.JsonSerializer
-keep class * implements com.google.gson.JsonDeserializer

# Moshi (if used)
-keep class com.squareup.moshi.** { *; }
-keepclassmembers class * {
    @com.squareup.moshi.* <methods>;
}

# ============================================================
# NETWORKING
# ============================================================

# OkHttp
-dontwarn okhttp3.**
-dontwarn okio.**
-keep class okhttp3.** { *; }
-keep interface okhttp3.** { *; }

# Retrofit (if used)
-keep class retrofit2.** { *; }
-keepclasseswithmembers class * {
    @retrofit2.http.* <methods>;
}

# ============================================================
# KOTLIN SPECIFIC
# ============================================================

# Kotlin Coroutines
-keepclassmembernames class kotlinx.** {
    volatile <fields>;
}
-keep class kotlinx.coroutines.** { *; }

# Kotlin Metadata
-keep class kotlin.Metadata { *; }
-keepclassmembers class kotlin.Metadata {
    public <methods>;
}

# ============================================================
# ANTI-TAMPER PROTECTION
# ============================================================

# Keep signature verification classes
-keep class com.edutime.app.security.** { *; }

# Protect hash calculation methods
-keepclassmembers class * {
    *** calculateHash(...);
    *** verifySignature(...);
    *** validateIntegrity(...);
}

# ============================================================
# WARNINGS TO SUPPRESS
# ============================================================

-dontwarn org.conscrypt.**
-dontwarn org.bouncycastle.**
-dontwarn org.openjsse.**
-dontwarn java.lang.invoke.**
-dontwarn sun.misc.**

# ============================================================
# OPTIMIZATION SETTINGS
# ============================================================

# Enable aggressive optimization
-optimizations !code/simplification/arithmetic,!code/simplification/cast,!field/*,!class/merging/*
-optimizationpasses 5

# Remove unused code
-dontshrink
-dontoptimize

# Keep line numbers for crash reports
-renamesourcefileattribute SourceFile
