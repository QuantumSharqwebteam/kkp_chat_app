package com.kkptextile.kkpchatapp

import io.flutter.app.FlutterApplication

class MyApplication : FlutterApplication() {
    override fun onCreate() {
        super.onCreate()
        // With Flutter 3 and Android embedding v2, plugin registration in the background isolate is handled
        // automatically using DartPluginRegistrant.ensureInitialized() (which you already call in your Dart onStart).
    }
}
