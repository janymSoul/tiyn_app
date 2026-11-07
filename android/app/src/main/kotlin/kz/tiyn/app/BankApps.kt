package kz.tiyn.app

import android.app.Activity
import android.content.ActivityNotFoundException
import android.content.Intent
import android.net.Uri

/**
 * Opens a bank app by package, or its store page if it is not installed.
 * Seeing another app on Android 11+ needs its package in the manifest's
 * <queries>; without it getLaunchIntentForPackage returns null even when the
 * app is installed.
 */
object BankApps {
    const val CHANNEL = "kz.tiyn.app/banks"

    fun open(activity: Activity, pkg: String): String {
        val launch = activity.packageManager.getLaunchIntentForPackage(pkg)
        if (launch != null) {
            return try {
                activity.startActivity(launch)
                "opened"
            } catch (e: ActivityNotFoundException) {
                store(activity, pkg)
            }
        }
        return store(activity, pkg)
    }

    private fun store(activity: Activity, pkg: String): String {
        val targets = listOf(
            "market://details?id=$pkg",
            "https://play.google.com/store/apps/details?id=$pkg",
        )
        for (uri in targets) {
            try {
                activity.startActivity(
                    Intent(Intent.ACTION_VIEW, Uri.parse(uri)).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK),
                )
                return "store"
            } catch (e: ActivityNotFoundException) {
                // Try the next one.
            }
        }
        return "unavailable"
    }
}
