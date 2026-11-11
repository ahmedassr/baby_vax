package com.ahmedalassar.babyvax

import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * The app's only activity. Hosts Flutter and answers the
 * [SETTINGS_CHANNEL] method channel, which lets the Dart side open the
 * system screen where the user can turn reminders back on.
 */
class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, SETTINGS_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "openNotificationSettings" -> result.success(openNotificationSettingsOrAppDetails())
                    else -> result.notImplemented()
                }
            }
    }

    private fun openNotificationSettingsOrAppDetails(): Boolean {
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
