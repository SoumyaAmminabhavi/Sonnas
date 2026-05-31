# Flutter
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.embedding.**  { *; }
-keep class io.flutter.embedding.engine.** { *; }

# Razorpay
-keep class com.razorpay.** { *; }
-keep class de.greenrobot.** { *; }
-dontwarn com.razorpay.**

# Google Play Core (Flutter Deferred Components)
-dontwarn com.google.android.play.core.**
