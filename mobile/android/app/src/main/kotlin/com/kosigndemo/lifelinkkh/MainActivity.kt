package com.kosigndemo.lifelinkkh

import android.app.NotificationChannel
import android.app.NotificationManager
import android.os.Build
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        createUrgentRequestsChannel()
        endSystemSplashWithoutFade()
    }

    /**
     * Android 12+ fades its own splash out when the first Flutter frame is ready. That frame
     * is `LaunchSplash` — the same badge, same size, same place — so the fade only put a blank
     * frame between two identical pictures. Removing the splash view at once makes the hand-off
     * invisible; the spinner simply appears under the badge.
     */
    private fun endSystemSplashWithoutFade() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.S) return
        splashScreen.setOnExitAnimationListener { view -> view.remove() }
    }

    /**
     * The channel every LifeLink push is sent on (`push.js` ANDROID_CHANNEL_ID, and the manifest's
     * default_notification_channel_id). Until this existed, FCM had no such channel and fell back
     * to its own "Miscellaneous" one at default importance: the push was filed silently in the
     * tray, so an alert sent while the app was in the background was never seen.
     *
     * IMPORTANCE_HIGH is what makes Android pop the alert over the screen, with sound. Android
     * fixes a channel's importance the first time it is created — after that only the user can
     * change it in Settings — so this call is a no-op on every later launch.
     */
    private fun createUrgentRequestsChannel() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val channel = NotificationChannel(
            URGENT_REQUESTS_CHANNEL_ID,
            getString(R.string.notification_channel_name),
            NotificationManager.IMPORTANCE_HIGH,
        ).apply {
            description = getString(R.string.notification_channel_description)
            setShowBadge(true)
            enableVibration(true)
        }
        getSystemService(NotificationManager::class.java).createNotificationChannel(channel)
    }

    private companion object {
        const val URGENT_REQUESTS_CHANNEL_ID = "lifelink_urgent_requests"
    }
}
