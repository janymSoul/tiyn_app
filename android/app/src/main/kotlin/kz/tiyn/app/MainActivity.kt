package kz.tiyn.app

import android.content.Intent
import android.os.Bundle
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        NotificationChannels.create(this)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "kz.tiyn.app/notifications")
            .setMethodCallHandler { call, result ->
                if (call.method == "openSettings") {
                    startActivity(
                        Intent(Settings.ACTION_APP_NOTIFICATION_SETTINGS)
                            .putExtra(Settings.EXTRA_APP_PACKAGE, packageName),
                    )
                    result.success(null)
                } else {
                    result.notImplemented()
                }
            }
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, BankApps.CHANNEL)
            .setMethodCallHandler { call, result ->
                val pkg = call.argument<String>("package")
                if (call.method == "open" && !pkg.isNullOrBlank()) {
                    result.success(BankApps.open(this, pkg))
                } else {
                    result.notImplemented()
                }
            }
    }
}
