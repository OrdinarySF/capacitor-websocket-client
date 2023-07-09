package cn.holmescraft.capacitor.plugins.websocket.client;

import android.util.Log;

public class WebSocket {

    public String echo(String value) {
        Log.i("Echo", value);
        return value;
    }
}
