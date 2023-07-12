package cn.holmescraft.capacitor.plugins.websocket.client

import android.util.Log
import com.getcapacitor.Bridge
import com.getcapacitor.JSObject
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
        val wsClient = okClient.newWebSocket(Request.Builder().url(url).build(), object : WebSocketListener() {
            override fun onOpen(webSocket: WebSocket, response: Response) {
                Log.v(TAG, "client onOpen called, id: $id")

                if (openCallId[id] != null) {
                    val ret = JSObject()
                    ret.put("id", id)
                    bridge.getSavedCall(openCallId[id]).successCallback(PluginResult(ret))
                }
            }

            override fun onMessage(webSocket: WebSocket, text: String) {
                Log.v(TAG, "client onMessage called, id: $id, text: $text")

                if (messageCallId[id] != null) {
                    val ret = JSObject()
                    ret.put("id", id)
                    ret.put("data", text)
                    bridge.getSavedCall(messageCallId[id]).successCallback(PluginResult(ret))
                }
            }

            override fun onClosed(webSocket: WebSocket, code: Int, reason: String) {
                Log.v(TAG, "client onClosed called, id: $id, code: $code, reason: $reason")

                if (closedCallId[id] != null) {
                    val ret = JSObject()
                    ret.put("id", id)
                    ret.put("code", code)
                    ret.put("reason", reason)
                    bridge.getSavedCall(closedCallId[id]).successCallback(PluginResult(ret))
                }
            }

            override fun onFailure(webSocket: WebSocket, t: Throwable, response: Response?) {
                Log.v(TAG, "client onFailure called, id: $id")
                Log.e(TAG, t.message, t)

                if (failureCallId[id] != null) {
                    val ret = JSObject()
                    ret.put("id", id)
                    ret.put("error", t.message)
                    bridge.getSavedCall(failureCallId[id]).successCallback(PluginResult(ret))
                }
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
        println(client)
        return client?.close(code, reason)?:false
    }
}
