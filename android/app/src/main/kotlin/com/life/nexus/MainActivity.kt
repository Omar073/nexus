package com.life.nexus

import android.content.Intent
import android.os.Bundle
import android.util.Log
import io.flutter.embedding.android.FlutterActivity

/// Debug: see whether notification taps reach the Activity (filter: `NexusNotifNative`).
class MainActivity : FlutterActivity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        logIntent("onCreate", intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        // Note: Action buttons use a broadcast receiver (showsUserInterface=false),
        // so they normally do NOT reach the Activity. This is primarily for
        // debugging body taps / misrouted OEM intents.
        logIntent("onNewIntent", intent)
    }

    private fun logIntent(source: String, intent: Intent?) {
        if (intent == null) return
        val action = intent.action ?: "null"
        val extras =
            intent.extras?.keySet()?.sorted()?.joinToString(", ") { key ->
                "$key=${intent.extras?.get(key)}"
            } ?: ""
        // Use INFO so `flutter run` / Studio logcat filters often show it (DEBUG is easy to miss).
        Log.i(TAG, "$source action=$action extras=[$extras]")
    }

    companion object {
        private const val TAG = "NexusNotifNative"
    }
}
