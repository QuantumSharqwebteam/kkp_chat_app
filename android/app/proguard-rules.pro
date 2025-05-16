# Reflection & Annotations
-keepattributes *Annotation*
-keep class androidx.annotation.Keep { *; }
-dontwarn androidx.annotation.Keep
-keepclassmembers class * {
  @android.webkit.JavascriptInterface <methods>;
}

# Flutter wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }


# flutter_local_notifications
-keep class com.dexterous.flutterlocalnotifications.** { *; }
-keep class com.dexterous.flutterlocalnotifications.models.** { *; }
-keep class com.dexterous.flutterlocalnotifications.FlutterLocalNotificationsPlugin { *; }
-keep class com.dexterous.flutterlocalnotifications.NotificationService { *; }
-dontwarn com.dexterous.flutterlocalnotifications.**

# Firebase Messaging
-keep class com.google.firebase.messaging.FirebaseMessaging { *; }
-keep class com.google.firebase.messaging.RemoteMessage { *; }
-keep class com.google.firebase.messaging.FirebaseMessagingService { *; }
-keep class * extends com.google.firebase.messaging.FirebaseMessagingService
-dontwarn com.google.firebase.messaging.**
-keep class com.google.firebase.iid.** { *; }
-dontwarn com.google.firebase.iid.**

# Permission Handler
-keep class com.baseflow.permissionhandler.** { *; }
-dontwarn com.baseflow.permissionhandler.**

# Agora SDK
-keep class io.agora.** { *; }
-dontwarn io.agora.**

