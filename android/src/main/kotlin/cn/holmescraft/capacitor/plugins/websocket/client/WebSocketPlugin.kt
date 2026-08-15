package cn.holmescraft.capacitor.plugins.websocket.client

import com.getcapacitor.Plugin
import com.getcapacitor.PluginCall
import com.getcapacitor.PluginMethod
import com.getcapacitor.annotation.CapacitorPlugin

@CapacitorPlugin(name = "WebSocket")
class WebSocketPlugin : Plugin() {
    @PluginMethod(returnType = PluginMethod.RETURN_NONE)
    fun connect(call: PluginCall) {
        val id = call.getString("id") ?: "default"
        val url = getStringForCall(call, "url") ?: return

        WebSocket.createConnect(id, url, getBridge())
        call.resolve()
    }

    @PluginMethod(returnType = PluginMethod.RETURN_NONE)
    fun close(call: PluginCall){
        val id = call.getString("id") ?: "default"
        val code = call.getInt("code") ?: 1000
        val reason = call.getString("reason") ?: ""

        val result = WebSocket.close(id, code, reason)
        if (result) {
            call.resolve()
        } else {
            call.reject("Close fail")
        }
    }

    @PluginMethod(returnType = PluginMethod.RETURN_NONE)
    fun send(call: PluginCall) {
        val id = call.getString("id") ?: "default"
        val data = getStringForCall(call, "data") ?: return
        val result = WebSocket.sendMessage(id, data)
        if (result) {
            call.resolve()
        } else {
            call.reject("send message fail")
        }
    }

    @PluginMethod(returnType = PluginMethod.RETURN_CALLBACK)
    fun onOpen(call: PluginCall) {
        val id = call.getString("id") ?: "default"
        call.setKeepAlive(true)
        WebSocket.onOpen(id, call.callbackId)
    }

    @PluginMethod(returnType = PluginMethod.RETURN_CALLBACK)
    fun onClose(call: PluginCall) {
        val id = call.getString("id") ?: "default"
        call.setKeepAlive(true)
        WebSocket.onClosed(id, call.callbackId)
    }

    @PluginMethod(returnType = PluginMethod.RETURN_CALLBACK)
    fun onMessage(call: PluginCall) {
        val id = call.getString("id") ?: "default"
        call.setKeepAlive(true)
        WebSocket.onMessage(id, call.callbackId)
    }

    @PluginMethod(returnType = PluginMethod.RETURN_CALLBACK)
    fun onError(call: PluginCall) {
        val id = call.getString("id") ?: "default"
        call.setKeepAlive(true)
        WebSocket.onFailure(id, call.callbackId)
    }

    override fun handleOnDestroy() {
        WebSocket.reset()
        super.handleOnDestroy()
    }

    private fun getStringForCall(call: PluginCall, name: String): String? {
        val id = call.getString(name)
        if (id == null) call.reject("$name can not null.");
        return id
    }
}
