package cn.holmescraft.capacitor.plugins.websocket.client

import android.util.Log
import com.getcapacitor.Bridge
import com.getcapacitor.JSObject
import com.getcapacitor.PluginCall
import com.getcapacitor.PluginResult
import okhttp3.*
import okhttp3.WebSocket
import java.util.concurrent.ConcurrentHashMap

object WebSocket {
    private val okClient = OkHttpClient.Builder().build()

    val clients = ConcurrentHashMap<String, WebSocket>()

    private var openCallId = ConcurrentHashMap<String, String>()
    private var closedCallId = ConcurrentHashMap<String, String>()
    private var messageCallId = ConcurrentHashMap<String, String>()
    private var failureCallId = ConcurrentHashMap<String, String>()

    fun createConnect(id: String, url: String, bridge: Bridge): WebSocket {
        Log.v(TAG, "createConnect")
        clients.remove(id)?.cancel()
        val wsClient = okClient.newWebSocket(Request.Builder().url(url).build(), object : WebSocketListener() {
            override fun onOpen(webSocket: WebSocket, response: Response) {
                Log.v(TAG, "client onOpen called, id: $id")
                val ret = JSObject()
                ret.put("id", id)
                emit(bridge, openCallId, id, ret)
            }

            override fun onMessage(webSocket: WebSocket, text: String) {
                Log.v(TAG, "client onMessage called, id: $id, text: $text")
                val ret = JSObject()
                ret.put("id", id)
                ret.put("data", text)
                emit(bridge, messageCallId, id, ret)
            }

            override fun onClosed(webSocket: WebSocket, code: Int, reason: String) {
                Log.v(TAG, "client onClosed called, id: $id, code: $code, reason: $reason")
                val ret = JSObject()
                ret.put("id", id)
                ret.put("code", code)
                ret.put("reason", reason)
                emit(bridge, closedCallId, id, ret)
            }

            override fun onFailure(webSocket: WebSocket, t: Throwable, response: Response?) {
                Log.v(TAG, "client onFailure called, id: $id")
                Log.e(TAG, t.message, t)
                val ret = JSObject()
                ret.put("id", id)
                ret.put("error", t.message)
                emit(bridge, failureCallId, id, ret)
            }
        })
        clients[id] = wsClient
        return wsClient
    }

    fun sendMessage(id: String, message: String): Boolean {
        Log.v(TAG, "sendMessage")
        return clients[id]?.send(message) ?: false
    }

    fun onOpen(id: String, callbackId: String) {
        Log.v(TAG, "onOpen")
        openCallId[id] = callbackId
    }

    fun onMessage(id: String, callbackId: String) {
        Log.v(TAG, "onMessage")
        messageCallId[id] = callbackId
    }

    fun onClosed(id: String, callbackId: String) {
        Log.v(TAG, "onClosed")
        closedCallId[id] = callbackId
    }

    fun onFailure(id: String, callbackId: String) {
        Log.v(TAG, "onFailure")
        failureCallId[id] = callbackId
    }

    fun close(id: String, code: Int, reason: String): Boolean {
        Log.v(TAG, "close")
        val client = clients[id]
        return client?.close(code, reason) ?: false
    }

    fun reset() {
        clients.values.forEach { it.cancel() }
        clients.clear()
        openCallId.clear()
        closedCallId.clear()
        messageCallId.clear()
        failureCallId.clear()
    }

    private fun emit(
        bridge: Bridge,
        ids: ConcurrentHashMap<String, String>,
        id: String,
        payload: JSObject
    ) {
        val callId = ids[id] ?: return
        val call: PluginCall? = bridge.getSavedCall(callId)
        if (call == null) {
            ids.remove(id)
            return
        }
        call.successCallback(PluginResult(payload))
    }
}
