# Reflection & Annotations
-keepattributes *Annotation*
-keep class androidx.annotation.Keep { *; }
-dontwarn androidx.annotation.Keep
-keepclassmembers class * {
  @android.webkit.JavascriptInterface <methods>;
}

# Agora SDK
-keep class io.agora.** { *; }
-dontwarn io.agora.**

