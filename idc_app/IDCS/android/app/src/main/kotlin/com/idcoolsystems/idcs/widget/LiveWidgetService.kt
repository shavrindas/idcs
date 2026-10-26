package com.idcoolsystems.idcs.widget

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import androidx.core.app.NotificationCompat
import androidx.core.app.ServiceCompat
import androidx.core.content.ContextCompat
import com.idcoolsystems.idcs.MainActivity
import com.idcoolsystems.idcs.R
import okhttp3.OkHttpClient
import okhttp3.Request
import okhttp3.Response
import okhttp3.WebSocket
import okhttp3.WebSocketListener
import org.json.JSONObject
import java.util.concurrent.TimeUnit

/**
 * Keeps the home-screen widget live while the app is closed.
 *
 * Android only lets an app keep a network connection open in the background
 * from a foreground service, and a foreground service must show a notification
 * — so this is opt-in from settings (위젯 실시간 갱신) and stops by itself when
 * no widget is left on the home screen. It listens to the same overview feed
 * the app does (/facilities/data/outget/{userId}) and redraws the widget at
 * most every [FLUSH_MS].
 */
class LiveWidgetService : Service() {

    private val main = Handler(Looper.getMainLooper())
    private val client = OkHttpClient.Builder()
        .pingInterval(20, TimeUnit.SECONDS)
        .readTimeout(0, TimeUnit.MILLISECONDS)
        .build()
    private var socket: WebSocket? = null
    private var stopped = false

    /** Values received since the last redraw: roomId → field → value. */
    private val pending = HashMap<Int, HashMap<String, String>>()

    private val flush = object : Runnable {
        override fun run() {
            val batch: Map<Int, Map<String, String>>
            synchronized(pending) {
                batch = pending.mapValues { HashMap(it.value) }
                pending.clear()
            }
            if (batch.isNotEmpty()) {
                WidgetStore.mergeLive(this@LiveWidgetService, batch)
                WidgetStore.refreshWidgets(this@LiveWidgetService)
            }
            if (!stopped) main.postDelayed(this, FLUSH_MS)
        }
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        goForeground()

        val url = WidgetStore.wsUrl(this)
        if (!WidgetStore.liveEnabled(this) || url == null || !WidgetStore.hasWidgets(this)) {
            // Refresh button with live updates off: redraw what we have and leave.
            WidgetStore.refreshWidgets(this)
            stopSelf()
            return START_NOT_STICKY
        }

        if (socket == null) {
            stopped = false
            connect(url)
            main.removeCallbacks(flush)
            main.postDelayed(flush, FLUSH_MS)
        }
        return START_STICKY
    }

    private fun connect(url: String) {
        socket = client.newWebSocket(Request.Builder().url(url).build(), object : WebSocketListener() {
            override fun onMessage(webSocket: WebSocket, text: String) {
                try {
                    val msg = JSONObject(text)
                    val datas = msg.optJSONObject("datas") ?: msg
                    synchronized(pending) {
                        for (key in datas.keys()) {
                            val parts = key.split('.')
                            if (parts.size != 2) continue
                            val roomId = parts[0].toIntOrNull() ?: continue
                            pending.getOrPut(roomId) { HashMap() }[parts[1]] = datas.optString(key)
                        }
                    }
                } catch (_: Exception) {
                    // One broken frame must not take the widget down.
                }
            }

            override fun onFailure(webSocket: WebSocket, t: Throwable, response: Response?) = retry(url)
            override fun onClosed(webSocket: WebSocket, code: Int, reason: String) = retry(url)
        })
    }

    private fun retry(url: String) {
        socket = null
        if (stopped) return
        main.postDelayed({ if (!stopped && socket == null) connect(url) }, RETRY_MS)
    }

    private fun goForeground() {
        val nm = getSystemService(NotificationManager::class.java)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            nm.createNotificationChannel(
                NotificationChannel(CHANNEL, getString(R.string.widget_live_channel), NotificationManager.IMPORTANCE_MIN).apply {
                    setShowBadge(false)
                }
            )
        }
        val open = PendingIntent.getActivity(
            this, 0, Intent(this, MainActivity::class.java),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        val notification = NotificationCompat.Builder(this, CHANNEL)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentTitle(getString(R.string.widget_title))
            .setContentText(getString(R.string.widget_live_notice))
            .setContentIntent(open)
            .setOngoing(true)
            .setSilent(true)
            .setPriority(NotificationCompat.PRIORITY_MIN)
            .build()
        val type = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
            ServiceInfo.FOREGROUND_SERVICE_TYPE_SPECIAL_USE
        } else 0
        ServiceCompat.startForeground(this, NOTIFICATION_ID, notification, type)
    }

    override fun onDestroy() {
        stopped = true
        main.removeCallbacksAndMessages(null)
        socket?.close(1000, null)
        socket = null
        super.onDestroy()
    }

    companion object {
        private const val CHANNEL = "widget_live"
        private const val NOTIFICATION_ID = 4107
        private const val FLUSH_MS = 3_000L
        private const val RETRY_MS = 5_000L

        /** Start from a foreground context (the app, a widget tap, boot). */
        fun start(context: Context) {
            if (!WidgetStore.liveEnabled(context) || !WidgetStore.hasWidgets(context)) return
            if (WidgetStore.wsUrl(context) == null) return
            try {
                ContextCompat.startForegroundService(context, Intent(context, LiveWidgetService::class.java))
            } catch (_: Exception) {
                // Background start refused (Android 12+). The next app open or
                // widget tap starts it instead.
            }
        }

        fun stop(context: Context) {
            context.stopService(Intent(context, LiveWidgetService::class.java))
        }

        /** For the widget's refresh button — a tap may start the service from the background. */
        fun pendingStart(context: Context): PendingIntent {
            val intent = Intent(context, LiveWidgetService::class.java)
            val flags = PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                PendingIntent.getForegroundService(context, 1, intent, flags)
            } else {
                PendingIntent.getService(context, 1, intent, flags)
            }
        }
    }
}
