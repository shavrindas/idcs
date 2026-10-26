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
