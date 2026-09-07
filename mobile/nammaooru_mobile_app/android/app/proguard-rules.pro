# Flutter Wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Firebase
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }

# Google Maps
-keep class com.google.android.gms.maps.** { *; }
-keep interface com.google.android.gms.maps.** { *; }

# Google Play Core (required for split/deferred components)
-keep class com.google.android.play.core.** { *; }

# Preserve annotations and signatures
-keepattributes *Annotation*
-keepattributes Signature
-keepattributes InnerClasses
-keepattributes EnclosingMethod

# Keep native methods
-keepclassmembers class * {
    native <methods>;
}

# Play Core classes are referenced by Flutter's deferred-components support but
# not bundled — tell R8 not to fail on them ("Missing classes" error)
-dontwarn com.google.android.play.core.**

# Razorpay (known R8 issues without these)
-dontwarn com.razorpay.**
-keep class com.razorpay.** { *; }
-optimizations !method/inlining/*
-keepclasseswithmembers class * { public void onPayment*(...); }
-dontwarn proguard.annotation.Keep
-dontwarn proguard.annotation.KeepClassMembers
-keep class proguard.annotation.Keep { *; }
-keep class proguard.annotation.KeepClassMembers { *; }
