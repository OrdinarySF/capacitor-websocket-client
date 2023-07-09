package cn.holmescraft.capacitor.plugins.websocket.client

import android.util.Log

class WebSocket {
    fun echo(value: String): String {
        Log.i("Echo", value)
        return value
    }
}
