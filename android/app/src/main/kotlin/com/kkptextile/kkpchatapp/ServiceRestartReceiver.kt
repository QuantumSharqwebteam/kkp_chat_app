package com.kkptextile.kkpchatapp

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import android.util.Log

class ServiceRestartReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent?) {
        intent?.action?.let { action ->
            Log.d("ServiceRestartReceiver", "Received action: $action")

            if (action == Intent.ACTION_BOOT_COMPLETED ||
                action == Intent.ACTION_MY_PACKAGE_REPLACED ||
                action == Intent.ACTION_PACKAGE_RESTARTED ||
                action == Intent.ACTION_REBOOT ||
                action == Intent.ACTION_LOCKED_BOOT_COMPLETED
            ) {
                restartService(context)
            }
        }
    }

    private fun restartService(context: Context) {
        Log.d("ServiceRestartReceiver", "Restarting FlutterBackgroundService")

        try {
            val serviceIntent = Intent()
            serviceIntent.setClassName(
                context.packageName,
                "com.flutter_background_service.FlutterBackgroundService"
            )

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                context.startForegroundService(serviceIntent)
            } else {
                context.startService(serviceIntent)
            }
        } catch (e: Exception) {
            Log.e("ServiceRestartReceiver", "Failed to restart service: ${e.message}")
        }
    }
}
