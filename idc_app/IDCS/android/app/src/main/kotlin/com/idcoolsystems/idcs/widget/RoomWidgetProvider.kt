package com.idcoolsystems.idcs.widget

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.widget.RemoteViews
import com.idcoolsystems.idcs.MainActivity
import com.idcoolsystems.idcs.R
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

/** 홈 화면 위젯: 전체 현황 카드 격자. */
class RoomWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(context: Context, manager: AppWidgetManager, ids: IntArray) {
        render(context, manager, ids)
    }

    override fun onDisabled(context: Context) {
        // Last widget removed: nothing left to keep live.
        LiveWidgetService.stop(context)
    }

    companion object {
        fun render(context: Context, manager: AppWidgetManager, ids: IntArray) {
            val rooms = WidgetStore.rooms(context)
            val counts = rooms.groupingBy { it.condition }.eachCount()
            val summary = buildList {
                counts[WidgetStore.Condition.FAULT]?.let { add("이상 $it") }
                counts[WidgetStore.Condition.DRIFTING]?.let { add("이탈 $it") }
                counts[WidgetStore.Condition.NORMAL]?.let { add("정상 $it") }
            }.joinToString(" · ")
            val updated = WidgetStore.updatedAt(context)
            val updatedText = if (updated == 0L) "" else
                SimpleDateFormat("HH:mm:ss", Locale.KOREA).format(Date(updated))

            val openApp = PendingIntent.getActivity(
                context, 0,
                Intent(context, MainActivity::class.java).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK),
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
            )

            for (id in ids) {
                val views = RemoteViews(context.packageName, R.layout.widget_rooms)

                val adapter = Intent(context, RoomWidgetService::class.java).apply {
                    putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, id)
                    // Unique per widget so the system does not reuse one factory for all.
                    data = Uri.parse(toUri(Intent.URI_INTENT_SCHEME))
                }
                @Suppress("DEPRECATION")
                views.setRemoteAdapter(R.id.widget_grid, adapter)
                views.setEmptyView(R.id.widget_grid, R.id.widget_empty)
                views.setPendingIntentTemplate(R.id.widget_grid, openApp)
                views.setOnClickPendingIntent(R.id.widget_title, openApp)

                views.setTextViewText(R.id.widget_summary, summary)
                views.setTextViewText(R.id.widget_updated, updatedText)

                // Tapping refresh is a user interaction, so it may (re)start the
                // foreground service even while the app is closed.
                views.setOnClickPendingIntent(R.id.widget_refresh, LiveWidgetService.pendingStart(context))

                manager.updateAppWidget(id, views)
            }
        }
    }
}
