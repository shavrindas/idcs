package com.idcoolsystems.idcs.widget

import android.app.Activity
import android.appwidget.AppWidgetManager
import android.content.Intent
import android.graphics.Typeface
import android.os.Bundle
import android.view.Gravity
import android.view.View
import android.widget.AdapterView
import android.widget.ArrayAdapter
import android.widget.Button
import android.widget.LinearLayout
import android.widget.ScrollView
import android.widget.Spinner
import android.widget.TextView
import androidx.core.content.ContextCompat
import com.idcoolsystems.idcs.R

/**
 * 위젯 설정 화면. 위젯을 처음 놓을 때 자동으로 뜨고, 헤더의 톱니 아이콘으로도
 * 다시 열 수 있다(room_widget_info.xml의 widgetFeatures="reconfigurable").
 *
 * 칸 수를 "전체"로 두면 지금까지처럼 보고된 순서대로 전부 보여준다. 6/8/9/12
 * 중 하나를 고르면 칸마다 어떤 호실을 놓을지 직접 고를 수 있다.
 */
class RoomWidgetConfigureActivity : Activity() {
    private var widgetId = AppWidgetManager.INVALID_APPWIDGET_ID
    private var rooms: List<WidgetStore.Room> = emptyList()
    private val layoutOptions = WidgetStore.Layout.entries.toList()
    private val slotSpinners = mutableListOf<Spinner>()

    private lateinit var layoutSpinner: Spinner
    private lateinit var slotContainer: LinearLayout
    private lateinit var hintText: TextView

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        rooms = WidgetStore.rooms(this)
        setContentView(buildView())
        layoutSpinner.adapter = ArrayAdapter(this, android.R.layout.simple_spinner_dropdown_item, layoutOptions.map(::layoutLabel))
        layoutSpinner.onItemSelectedListener = object : AdapterView.OnItemSelectedListener {
            override fun onItemSelected(parent: AdapterView<*>?, view: View?, position: Int, id: Long) {
                rebuildSlots(layoutOptions[position])
            }
            override fun onNothingSelected(parent: AdapterView<*>?) {}
        }
        loadForIntent(intent)
    }

    // 톱니 아이콘으로 이미 떠 있는 설정 화면을 다시 열면(OS가 태스크를 재사용하면)
    // onCreate 가 아니라 여기로 들어온다 — widgetId 와 화면을 그때마다 새로 읽어야
    // 전에 저장 안 하고 나간 값이 남아있지 않는다.
    override fun onNewIntent(newIntent: Intent) {
        super.onNewIntent(newIntent)
        setIntent(newIntent)
        loadForIntent(newIntent)
    }

    private fun loadForIntent(source: Intent) {
        // 위젯 설정 규약: 사용자가 저장 없이 뒤로 나가면 OS가 막 추가된 위젯을
        // 지운다. 그래서 저장 전에는 항상 CANCELED로 둔다.
        setResult(RESULT_CANCELED)

        widgetId = source.getIntExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, AppWidgetManager.INVALID_APPWIDGET_ID)
        if (widgetId == AppWidgetManager.INVALID_APPWIDGET_ID) {
            finish()
            return
        }

        val savedLayout = WidgetStore.widgetLayout(this, widgetId)
        layoutSpinner.setSelection(layoutOptions.indexOf(savedLayout).coerceAtLeast(0))
        rebuildSlots(savedLayout)
    }

    private fun layoutLabel(layout: WidgetStore.Layout) = if (layout == WidgetStore.Layout.ALL) {
        getString(R.string.widget_config_layout_all)
    } else {
        getString(R.string.widget_config_layout_n, layout.count)
    }

    private fun dp(value: Int) = (value * resources.displayMetrics.density).toInt()

    private fun textColor(res: Int) = ContextCompat.getColor(this, res)

    private fun spacer(height: Int) = View(this).apply {
        layoutParams = LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, height)
    }

    private fun buildView(): View {
        val pad = dp(16)
        val root = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            setPadding(pad, pad, pad, pad)
            setBackgroundColor(textColor(R.color.widget_bg))
        }

        root.addView(TextView(this).apply {
            text = getString(R.string.widget_config_title)
            textSize = 18f
            setTextColor(textColor(R.color.widget_text))
            setTypeface(typeface, Typeface.BOLD)
        })
        root.addView(spacer(dp(16)))

        root.addView(TextView(this).apply {
            text = getString(R.string.widget_config_layout_label)
            textSize = 13f
            setTextColor(textColor(R.color.widget_text_secondary))
        })
        layoutSpinner = Spinner(this)
        root.addView(layoutSpinner)
        root.addView(spacer(dp(8)))

        hintText = TextView(this).apply {
            text = getString(R.string.widget_config_all_hint)
            textSize = 12f
            setTextColor(textColor(R.color.widget_text_secondary))
        }
        root.addView(hintText)
        root.addView(spacer(dp(8)))

        slotContainer = LinearLayout(this).apply { orientation = LinearLayout.VERTICAL }
        val scroll = ScrollView(this).apply {
            layoutParams = LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, 0, 1f)
            addView(slotContainer)
        }
        root.addView(scroll)

        root.addView(Button(this).apply {
            text = getString(R.string.widget_config_save)
            setOnClickListener { save() }
        })
        return root
    }

    /** 칸 수가 바뀔 때마다 그만큼의 호실 선택 줄을 다시 그린다. */
    private fun rebuildSlots(layout: WidgetStore.Layout) {
        slotContainer.removeAllViews()
        slotSpinners.clear()
        hintText.visibility = if (layout == WidgetStore.Layout.ALL) View.VISIBLE else View.GONE
        if (layout == WidgetStore.Layout.ALL) return

        val savedSlots = WidgetStore.widgetSlots(this, widgetId)
        val roomLabels = listOf(getString(R.string.widget_config_slot_empty)) +
            rooms.map { "${it.facility} - ${it.name}" }

        for (i in 0 until layout.count) {
            val row = LinearLayout(this).apply {
                orientation = LinearLayout.HORIZONTAL
                gravity = Gravity.CENTER_VERTICAL
                setPadding(0, dp(6), 0, 0)
            }
            row.addView(TextView(this).apply {
                text = getString(R.string.widget_config_slot_label, i + 1)
                setTextColor(textColor(R.color.widget_text))
                layoutParams = LinearLayout.LayoutParams(0, LinearLayout.LayoutParams.WRAP_CONTENT, 1f)
            })

            val savedRoomId = savedSlots.getOrNull(i)
            // 0번은 "비워두기", 1번부터 방 목록 — 저장된 id를 못 찾으면(방이 지워짐) 비워두기로 되돌린다.
            val savedIndex = if (savedRoomId == null) 0 else {
                rooms.indexOfFirst { it.id == savedRoomId }.let { if (it == -1) 0 else it + 1 }
            }
            val spinner = Spinner(this).apply {
                adapter = ArrayAdapter(this@RoomWidgetConfigureActivity, android.R.layout.simple_spinner_dropdown_item, roomLabels)
                setSelection(savedIndex)
                layoutParams = LinearLayout.LayoutParams(0, LinearLayout.LayoutParams.WRAP_CONTENT, 2f)
            }
            row.addView(spinner)
            slotContainer.addView(row)
            slotSpinners.add(spinner)
        }
    }

    private fun save() {
        val layout = layoutOptions[layoutSpinner.selectedItemPosition]
        val slots: List<Int?> = if (layout == WidgetStore.Layout.ALL) {
            emptyList()
        } else {
            slotSpinners.map { spinner ->
                val idx = spinner.selectedItemPosition
                if (idx <= 0) null else rooms.getOrNull(idx - 1)?.id
            }
        }
        WidgetStore.saveWidgetConfig(this, widgetId, layout, slots)

        val manager = AppWidgetManager.getInstance(this)
        RoomWidgetProvider.render(this, manager, intArrayOf(widgetId))
        @Suppress("DEPRECATION")
        manager.notifyAppWidgetViewDataChanged(widgetId, R.id.widget_grid)

        setResult(RESULT_OK, Intent().putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, widgetId))
        finish()
    }
}
