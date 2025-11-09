## Flutter wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }
-dontwarn io.flutter.embedding.**

## Firebase
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.firebase.**
-dontwarn com.google.android.gms.**

## HTTP
-keep class okhttp3.** { *; }
-keep class retrofit2.** { *; }
-dontwarn okhttp3.**
-dontwarn retrofit2.**

## Gson
-keep class com.google.gson.** { *; }
-keepattributes Signature
-keepattributes *Annotation*

## Models - Adjust package names as needed
-keep class com.nammaooru.shop_owner_app.models.** { *; }

## Notifications
-keep class androidx.core.app.NotificationCompat** { *; }
