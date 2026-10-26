package com.idcoolsystems.idcs

import com.idcoolsystems.idcs.widget.LiveWidgetService
import com.idcoolsystems.idcs.widget.WidgetStore
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Bridge for the home-screen widget (lib/services/common/home_widget_bridge.dart).
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "idcs/home_widget")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "publish" -> {
                        WidgetStore.saveSnapshot(this, call.argument<String>("rooms") ?: "[]")
                        WidgetStore.refreshWidgets(this)
                        result.success(null)
                    }
                    "configure" -> {
                        WidgetStore.setWsUrl(this, call.argument<String>("wsUrl"))
                        // The app is in the foreground here, so starting the
                        // foreground service is allowed.
                        LiveWidgetService.start(this)
                        result.success(null)
                    }
                    "setLive" -> {
                        val on = call.argument<Boolean>("enabled") ?: false
                        WidgetStore.setLiveEnabled(this, on)
                        if (on) LiveWidgetService.start(this) else LiveWidgetService.stop(this)
                        result.success(null)
                    }
                    "isLive" -> result.success(WidgetStore.liveEnabled(this))
                    "hasWidgets" -> result.success(WidgetStore.hasWidgets(this))
                    else -> result.notImplemented()
                }
            }
    }
}
