package com.ahmedalassar.babyvax

import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, SETTINGS_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "openNotificationSettings" -> result.success(openNotificationSettings())
                    else -> result.notImplemented()
                }
            }
    }

    /**
     * Opens this app's own notification settings page. Falls back to the
     * app's details page if the device has no such screen.
     */
    private fun openNotificationSettings(): Boolean {
        val notificationSettings =
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                Intent(Settings.ACTION_APP_NOTIFICATION_SETTINGS)
                    .putExtra(Settings.EXTRA_APP_PACKAGE, packageName)
            } else {
                null
            }
        val appDetails = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS)
            .setData(Uri.fromParts("package", packageName, null))

        for (intent in listOfNotNull(notificationSettings, appDetails)) {
            try {
                startActivity(intent)
                return true
            } catch (_: Exception) {
                // Try the next screen.
            }
        }
        return false
    }

    private companion object {
        const val SETTINGS_CHANNEL = "com.ahmedalassar.babyvax/settings"
    }
}
