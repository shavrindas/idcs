package com.idcoolsystems.idcs.widget

import android.content.Context
import android.content.Intent
import android.graphics.Color
import android.widget.RemoteViews
import android.widget.RemoteViewsService
import androidx.core.content.ContextCompat
import com.idcoolsystems.idcs.R
import java.util.Locale
import kotlin.math.abs

/** Supplies the room cards to the widget's GridView. */
class RoomWidgetService : RemoteViewsService() {
    override fun onGetViewFactory(intent: Intent): RemoteViewsFactory = Factory(applicationContext)

    private class Factory(private val context: Context) : RemoteViewsFactory {
        private var rooms: List<WidgetStore.Room> = emptyList()

        override fun onCreate() {}
        override fun onDataSetChanged() {
            rooms = WidgetStore.orderedRooms(context)
        }
        override fun onDestroy() {}
        override fun getCount() = rooms.size
        override fun getLoadingView(): RemoteViews? = null
        override fun getViewTypeCount() = 1
        override fun getItemId(position: Int) = rooms.getOrNull(position)?.id?.toLong() ?: position.toLong()
        override fun hasStableIds() = true

        private fun color(res: Int) = ContextCompat.getColor(context, res)

        override fun getViewAt(position: Int): RemoteViews {
            val views = RemoteViews(context.packageName, R.layout.widget_room_item)
            val room = rooms.getOrNull(position) ?: return views

            val condition = room.condition
            val accent = when (condition) {
                WidgetStore.Condition.FAULT -> color(R.color.widget_error)
                WidgetStore.Condition.DRIFTING -> color(R.color.widget_warning)
                WidgetStore.Condition.NORMAL -> color(R.color.widget_success)
                WidgetStore.Condition.OFFLINE -> color(R.color.widget_text_secondary)
            }
            val digits = if (condition == WidgetStore.Condition.OFFLINE) color(R.color.widget_text) else accent

            views.setTextViewText(R.id.item_name, room.name)

            val faults = room.faultCount
            if (faults > 0) {
                views.setTextViewText(R.id.item_faults, faults.toString())
                views.setViewVisibility(R.id.item_faults, android.view.View.VISIBLE)
            } else {
                views.setViewVisibility(R.id.item_faults, android.view.View.GONE)
            }

            val temp = room.temp
            if (temp == null) {
                views.setTextViewText(R.id.item_temp, "—")
                views.setTextColor(R.id.item_temp, color(R.color.widget_text_secondary))
                views.setTextColor(R.id.item_minus, Color.TRANSPARENT)
                views.setViewVisibility(R.id.item_unit, android.view.View.GONE)
            } else {
                views.setTextViewText(R.id.item_temp, String.format(Locale.US, "%.1f", abs(temp)))
                views.setTextColor(R.id.item_temp, digits)
                // Minus keeps its slot: lit below zero, faint (unlit LED) above.
                val minusAlpha = if (temp < 0) 0xFF else 0x1A
                views.setTextColor(R.id.item_minus, (digits and 0x00FFFFFF) or (minusAlpha shl 24))
                views.setViewVisibility(R.id.item_unit, android.view.View.VISIBLE)
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

            // Tap opens the app (template set by the provider).
            views.setOnClickFillInIntent(R.id.item_root, Intent().putExtra("room_id", room.id))
            return views
        }
    }
}
