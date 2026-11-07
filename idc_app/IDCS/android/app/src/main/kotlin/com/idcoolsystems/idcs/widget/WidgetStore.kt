package com.idcoolsystems.idcs.widget

import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import com.idcoolsystems.idcs.R
import org.json.JSONArray
import org.json.JSONObject
import kotlin.math.abs

/**
 * What the home-screen widget shows, kept in plain SharedPreferences so the
 * launcher process, the live service and the Flutter app all read one copy.
 *
 * The app publishes a snapshot (facility/room names, open alarm counts, the
 * last live values). The live service overlays fresher values on top of it.
 */
object WidgetStore {
    private const val PREFS = "idcs_home_widget"
    private const val KEY_ROOMS = "rooms"
    private const val KEY_UPDATED = "updated_at"
    private const val KEY_WS_URL = "ws_url"
    private const val KEY_LIVE = "live_enabled"
    private const val KEY_LAYOUT_PREFIX = "layout_"
    private const val KEY_SLOTS_PREFIX = "slots_"

    /**
     * 위젯 한 칸의 격자 모양. ALL은 지금까지의 기본 동작(보고된 순서대로 전부,
     * 2열) 그대로이고, 나머지는 사용자가 설정 화면에서 칸마다 호실을 직접
     * 고른다 — count는 고른 숫자, cols/rows는 그 숫자를 담는 격자 모양이다.
     */
    enum class Layout(val count: Int, val cols: Int) {
        ALL(0, 2),
        SIX(6, 3),
        EIGHT(8, 4),
        NINE(9, 3),
        TWELVE(12, 4);

        companion object {
            fun from(count: Int): Layout = entries.firstOrNull { it.count == count } ?: ALL
        }
    }

    /** Same threshold as RoomStatus.driftThreshold in the app. */
    private const val DRIFT_THRESHOLD = 2.0

    enum class Condition { NORMAL, DRIFTING, FAULT, OFFLINE }

    data class Room(
        val id: Int,
        val facility: String,
        val name: String,
        val alarms: Int,
        val fields: MutableMap<String, String>,
    ) {
        private fun number(key: String) = fields[key]?.trim()?.toDoubleOrNull()

        val temp: Double? get() = number("temp_pv")
        val setpoint: Double? get() = number("temp_sv")

        val faultCount: Int
            get() = alarms + fields.count { (k, v) -> k.startsWith("emergency_") && asSwitch(v) == true }

        /** Port of RoomStatus.from so a room is the same colour in the app and here. */
        val condition: Condition
            get() {
                val t = temp
                val sp = setpoint
                val defrosting = asSwitch(fields["deforest_def"]) ?: false
                return when {
                    faultCount > 0 -> Condition.FAULT
                    t == null -> Condition.OFFLINE
                    // Rising during defrost is normal operation, not drift.
                    !defrosting && sp != null && abs(t - sp) >= DRIFT_THRESHOLD -> Condition.DRIFTING
                    else -> Condition.NORMAL
                }
            }
    }

    /** ON/OFF, 1/0, 0.0 … Unknown → null so a value that never came is not "off". */
    fun asSwitch(raw: String?): Boolean? {
        val v = raw?.trim()?.uppercase() ?: return null
        if (v.isEmpty() || v == "NA" || v == "-") return null
        if (v == "ON" || v == "TRUE") return true
        if (v == "OFF" || v == "FALSE") return false
        return v.toDoubleOrNull()?.let { it != 0.0 }
    }

    private fun prefs(context: Context) = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)

    fun rooms(context: Context): List<Room> {
        val raw = prefs(context).getString(KEY_ROOMS, null) ?: return emptyList()
        return try {
            val arr = JSONArray(raw)
            (0 until arr.length()).map { i ->
                val o = arr.getJSONObject(i)
                val f = o.optJSONObject("fields") ?: JSONObject()
                Room(
                    id = o.getInt("id"),
                    facility = o.optString("facility"),
                    name = o.optString("name"),
                    alarms = o.optInt("alarms"),
                    fields = f.keys().asSequence().associateWith { f.optString(it) }.toMutableMap(),
                )
            }
        } catch (_: Exception) {
            emptyList()
        }
    }

    /**
     * Rooms in the order the widget draws them: rooms that report first, then
     * the rest — same rule as the overview screen.
     */
    fun orderedRooms(context: Context): List<Room> {
        val all = rooms(context)
        return all.filter { it.fields.isNotEmpty() } + all.filter { it.fields.isEmpty() }
    }

    fun saveSnapshot(context: Context, json: String) {
        prefs(context).edit()
            .putString(KEY_ROOMS, json)
            .putLong(KEY_UPDATED, System.currentTimeMillis())
            .apply()
    }

    /** Overlay live values ("roomId" → field → value) on the stored rooms. */
    fun mergeLive(context: Context, live: Map<Int, Map<String, String>>) {
        if (live.isEmpty()) return
        val rooms = rooms(context)
        if (rooms.isEmpty()) return
        val arr = JSONArray()
        for (r in rooms) {
            live[r.id]?.let { r.fields.putAll(it) }
            arr.put(JSONObject().apply {
                put("id", r.id)
                put("facility", r.facility)
                put("name", r.name)
                put("alarms", r.alarms)
                put("fields", JSONObject(r.fields as Map<*, *>))
            })
        }
        saveSnapshot(context, arr.toString())
    }

    fun updatedAt(context: Context): Long = prefs(context).getLong(KEY_UPDATED, 0L)

    fun wsUrl(context: Context): String? = prefs(context).getString(KEY_WS_URL, null)

    fun setWsUrl(context: Context, url: String?) = prefs(context).edit().putString(KEY_WS_URL, url).apply()

    fun liveEnabled(context: Context): Boolean = prefs(context).getBoolean(KEY_LIVE, true)

    fun setLiveEnabled(context: Context, on: Boolean) = prefs(context).edit().putBoolean(KEY_LIVE, on).apply()

    fun widgetIds(context: Context): IntArray =
        AppWidgetManager.getInstance(context)
            .getAppWidgetIds(ComponentName(context, RoomWidgetProvider::class.java))

    fun hasWidgets(context: Context) = widgetIds(context).isNotEmpty()

    fun widgetLayout(context: Context, widgetId: Int): Layout =
        Layout.from(prefs(context).getInt("$KEY_LAYOUT_PREFIX$widgetId", 0))

    /** 칸마다 고른 호실 id. 비워 둔 칸은 null. 저장된 적 없으면 빈 리스트. */
    fun widgetSlots(context: Context, widgetId: Int): List<Int?> {
        val raw = prefs(context).getString("$KEY_SLOTS_PREFIX$widgetId", null) ?: return emptyList()
        return try {
            val arr = JSONArray(raw)
            (0 until arr.length()).map { i -> if (arr.isNull(i)) null else arr.getInt(i) }
        } catch (_: Exception) {
            emptyList()
        }
    }

    fun saveWidgetConfig(context: Context, widgetId: Int, layout: Layout, slots: List<Int?>) {
        val arr = JSONArray()
        slots.forEach { arr.put(it ?: JSONObject.NULL) }
        prefs(context).edit()
            .putInt("$KEY_LAYOUT_PREFIX$widgetId", layout.count)
            .putString("$KEY_SLOTS_PREFIX$widgetId", arr.toString())
            .apply()
    }

    /** 위젯이 삭제될 때 같이 지운다. 안 지우면 같은 id가 재배치됐을 때 예전 설정이 되살아난다. */
    fun clearWidgetConfig(context: Context, widgetId: Int) {
        prefs(context).edit()
            .remove("$KEY_LAYOUT_PREFIX$widgetId")
            .remove("$KEY_SLOTS_PREFIX$widgetId")
            .apply()
    }

    /**
     * 위젯 한 개가 그릴 칸들. ALL이면 지금까지처럼 보고된 순서대로 전부이고,
     * 고정 칸 수면 사용자가 고른 순서 그대로 — 안 고른 칸은 null(빈 칸)이다.
     */
    fun roomsForWidget(context: Context, widgetId: Int): List<Room?> {
        val layout = widgetLayout(context, widgetId)
        if (layout == Layout.ALL) return orderedRooms(context)
        val all = rooms(context)
        val slots = widgetSlots(context, widgetId)
        return (0 until layout.count).map { i -> slots.getOrNull(i)?.let { id -> all.firstOrNull { it.id == id } } }
    }

    /** Redraw every placed widget: header text and the card grid. */
    fun refreshWidgets(context: Context) {
        val manager = AppWidgetManager.getInstance(context)
        val ids = widgetIds(context)
        if (ids.isEmpty()) return
        RoomWidgetProvider.render(context, manager, ids)
        @Suppress("DEPRECATION")
        manager.notifyAppWidgetViewDataChanged(ids, R.id.widget_grid)
    }
}
