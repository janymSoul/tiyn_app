package kz.tiyn.app

import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Context
import android.os.Build

object NotificationChannels {
    // Must match default_notification_channel_id in AndroidManifest.xml.
    const val ID = "tiyn"

    // Safe to call on every launch: re-creating a channel with the same id
    // only refreshes its (localised) name.
    fun create(context: Context) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val channel = NotificationChannel(
            ID,
            context.getString(R.string.notification_channel_name),
            NotificationManager.IMPORTANCE_HIGH,
        )
        context.getSystemService(NotificationManager::class.java)
            .createNotificationChannel(channel)
    }
}
