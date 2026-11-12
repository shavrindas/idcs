package com.idcoolsystems.idcs.widget

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.graphics.Color
import android.os.Build
import android.util.TypedValue
import android.view.View
import android.widget.RemoteViews
import androidx.core.content.ContextCompat
import com.idcoolsystems.idcs.MainActivity
import com.idcoolsystems.idcs.R
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale
import kotlin.math.abs

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
        private fun color(context: Context, res: Int) = ContextCompat.getColor(context, res)

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

                views.setTextViewText(R.id.widget_summary, summary)
                views.setTextViewText(R.id.widget_updated, updatedText)
                views.setOnClickPendingIntent(R.id.widget_title, openApp)
                views.setOnClickPendingIntent(R.id.widget_settings, configurePendingIntent(context, id))

                // Tapping refresh is a user interaction, so it may (re)start the
                // foreground service even while the app is closed.
                views.setOnClickPendingIntent(R.id.widget_refresh, LiveWidgetService.pendingStart(context))

                val cols = WidgetStore.widgetLayout(context, id).cols
                val placed = WidgetStore.roomsForWidget(context, id)
                // 위젯이 지금 실제로 몇 dp 폭인지 — 마지막 줄 칸을 몇 dp로 넓힐지
                // 계산하는 데 쓴다. 아직 모르면(0) 그 줄은 그냥 기본(1/cols)으로 둔다.
                val minWidthDp = manager.getAppWidgetOptions(id)
                    .getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH, 0)

                views.removeAllViews(R.id.widget_rows)
                if (placed.isEmpty()) {
                    views.setViewVisibility(R.id.widget_rows, View.GONE)
                    views.setViewVisibility(R.id.widget_empty, View.VISIBLE)
                } else {
                    views.setViewVisibility(R.id.widget_rows, View.VISIBLE)
                    views.setViewVisibility(R.id.widget_empty, View.GONE)
                    placed.chunked(cols).forEach { row ->
                        views.addView(R.id.widget_rows, buildRow(context, row, cols, minWidthDp))
                    }
                }

                manager.updateAppWidget(id, views)
            }
        }

        /**
         * 칸 수를 못 채운 줄은 칸 너비를 다시 계산해 빈자리 없이 채운다. GridView에는
         * 칸마다 비율로 늘어나는 기능이 없어서, 줄을 직접 쌓고 칸 너비를 dp로 지정한다.
         */
        private fun buildRow(context: Context, row: List<WidgetStore.Room?>, cols: Int, minWidthDp: Int): RemoteViews {
            val rowViews = RemoteViews(context.packageName, R.layout.widget_room_row)
            val stretchedWidthDp = stretchedItemWidthDp(minWidthDp, cols, row.size)
            row.forEachIndexed { index, room ->
                if (index > 0) {
                    rowViews.addView(R.id.row_root, RemoteViews(context.packageName, R.layout.widget_spacer_h))
                }
                rowViews.addView(R.id.row_root, buildItem(context, room, stretchedWidthDp))
            }
            return rowViews
        }

        /** 꽉 찬 줄이면 null(=XML 기본값인 1/cols 그대로). 아니면 그 줄의 칸이 가질 dp 너비. */
        private fun stretchedItemWidthDp(minWidthDp: Int, cols: Int, rowSize: Int): Float? {
            if (rowSize >= cols || minWidthDp <= 0) return null
            val outerPaddingDp = 20f // widget_root 좌우 패딩(10dp) 합
            val spacerDp = 6f
            val contentWidthDp = minWidthDp - outerPaddingDp
            if (contentWidthDp <= 0f) return null
            val itemsWidthDp = contentWidthDp - (rowSize - 1) * spacerDp
            val perItemDp = itemsWidthDp / rowSize
            return perItemDp.takeIf { it > 0f }
        }

        /** 칸 하나. room이 null이면 사용자가 아직 안 고른 고정 칸(빈 칸 안내만 보여줌). */
        private fun buildItem(context: Context, room: WidgetStore.Room?, stretchedWidthDp: Float?): RemoteViews {
            val views = RemoteViews(context.packageName, R.layout.widget_room_item)
            // setViewLayoutWidth는 API 31부터 있다 — 그 밑에서는 XML 기본값(1/cols)
            // 그대로라 마지막 줄이 안 넓어질 뿐, 깨지지는 않는다.
            if (stretchedWidthDp != null && Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                views.setViewLayoutWidth(R.id.item_root, stretchedWidthDp, TypedValue.COMPLEX_UNIT_DIP)
            }

            if (room == null) {
                views.setTextViewText(R.id.item_name, context.getString(R.string.widget_config_slot_empty))
                views.setTextColor(R.id.item_name, color(context, R.color.widget_text_secondary))
                views.setViewVisibility(R.id.item_faults, View.GONE)
                views.setTextViewText(R.id.item_temp, "")
                views.setTextColor(R.id.item_minus, Color.TRANSPARENT)
                views.setViewVisibility(R.id.item_unit, View.GONE)
                views.setTextViewText(R.id.item_detail, "")
                views.setInt(R.id.item_rail, "setBackgroundColor", Color.TRANSPARENT)
                return views
            }

            val condition = room.condition
            val accent = when (condition) {
                WidgetStore.Condition.FAULT -> color(context, R.color.widget_error)
                WidgetStore.Condition.DRIFTING -> color(context, R.color.widget_warning)
                WidgetStore.Condition.NORMAL -> color(context, R.color.widget_success)
                WidgetStore.Condition.OFFLINE -> color(context, R.color.widget_text_secondary)
            }
            val digits = if (condition == WidgetStore.Condition.OFFLINE) color(context, R.color.widget_text) else accent

            views.setTextViewText(R.id.item_name, room.name)

            val faults = room.faultCount
            if (faults > 0) {
                views.setTextViewText(R.id.item_faults, faults.toString())
                views.setViewVisibility(R.id.item_faults, View.VISIBLE)
            } else {
                views.setViewVisibility(R.id.item_faults, View.GONE)
            }

            val temp = room.temp
            if (temp == null) {
                views.setTextViewText(R.id.item_temp, "—")
                views.setTextColor(R.id.item_temp, color(context, R.color.widget_text_secondary))
                views.setTextColor(R.id.item_minus, Color.TRANSPARENT)
                views.setViewVisibility(R.id.item_unit, View.GONE)
            } else {
                views.setTextViewText(R.id.item_temp, String.format(Locale.US, "%.1f", abs(temp)))
                views.setTextColor(R.id.item_temp, digits)
                // Minus keeps its slot: lit below zero, faint (unlit LED) above.
                val minusAlpha = if (temp < 0) 0xFF else 0x1A
                views.setTextColor(R.id.item_minus, (digits and 0x00FFFFFF) or (minusAlpha shl 24))
                views.setViewVisibility(R.id.item_unit, View.VISIBLE)
            }

            val sp = room.setpoint
            val detail = buildList {
                add(room.facility)
                if (sp != null) add(String.format(Locale.US, "목표 %.1f", sp))
                if (sp != null && temp != null) {
                    val d = temp - sp
                    add(String.format(Locale.US, "Δ %s%.1f", if (d >= 0) "+" else "", d))
                }
            }.filter { it.isNotBlank() }.joinToString("  ")
            views.setTextViewText(R.id.item_detail, detail)

            views.setInt(
                R.id.item_rail, "setBackgroundColor",
                if (condition == WidgetStore.Condition.OFFLINE) (accent and 0x00FFFFFF) or (0x40 shl 24) else accent,
            )

            // Tap opens the app on this room. Request code must be unique per
            // room so distinct rooms don't share (and overwrite) one PendingIntent.
            val itemIntent = Intent(context, MainActivity::class.java)
                .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                .putExtra("room_id", room.id)
            val itemPendingIntent = PendingIntent.getActivity(
                context, room.id, itemIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
            )
            views.setOnClickPendingIntent(R.id.item_root, itemPendingIntent)
            return views
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
