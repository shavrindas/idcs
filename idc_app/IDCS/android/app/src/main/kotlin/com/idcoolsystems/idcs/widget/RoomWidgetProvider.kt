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

    override fun onDeleted(context: Context, appWidgetIds: IntArray) {
        appWidgetIds.forEach { WidgetStore.clearWidgetConfig(context, it) }
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

                // 칸 수 설정에 맞춰 열 수를 바꾼다. GridView.setNumColumns 는 public
                // setter라 RemoteViews.setInt 로 리플렉션 호출이 된다 — XML에 고정해
                // 두면 전체(2열)와 12칸(4열)이 똑같은 모양으로 눌려 버린다.
                views.setInt(R.id.widget_grid, "setNumColumns", WidgetStore.widgetLayout(context, id).cols)

                views.setTextViewText(R.id.widget_summary, summary)
                views.setTextViewText(R.id.widget_updated, updatedText)

                views.setOnClickPendingIntent(R.id.widget_settings, configurePendingIntent(context, id))

                // Tapping refresh is a user interaction, so it may (re)start the
                // foreground service even while the app is closed.
                views.setOnClickPendingIntent(R.id.widget_refresh, LiveWidgetService.pendingStart(context))

                manager.updateAppWidget(id, views)
            }
        }

        /** 톱니 아이콘 → 이 위젯 하나의 설정 화면. id별로 달라야 하므로 요청 코드로 id를 쓴다. */
        private fun configurePendingIntent(context: Context, widgetId: Int): PendingIntent {
            val intent = Intent(context, RoomWidgetConfigureActivity::class.java)
                // SINGLE_TOP 없이는 이미 떠 있는(백그라운드로 남은) 설정 화면을 다시 열 때
                // OS 가 그냥 기존 화면을 보여주기만 하고 onNewIntent 를 안 불러서,
                // 저장 안 하고 나간 이전 상태가 그대로 남아 있는 것처럼 보인다.
                .addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP)
                .putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, widgetId)
            return PendingIntent.getActivity(
                context, widgetId, intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
            )
        }
    }
}
