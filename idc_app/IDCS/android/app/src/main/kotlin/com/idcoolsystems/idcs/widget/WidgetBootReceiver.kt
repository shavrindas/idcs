package com.idcoolsystems.idcs.widget

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

/** After a reboot, resume live widget updates if they were on. */
class WidgetBootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == Intent.ACTION_BOOT_COMPLETED) LiveWidgetService.start(context)
    }
}
