import {WebPlugin} from '@capacitor/core';

import type {
    CloseOptions,
    ConnectionOptions,
    OnCloseCallback,
    OnCloseOptions,
    OnErrorCallback,
    OnErrorOptions,
    OnMessageCallback,
    OnMessageOptions,
    OnOpenCallback,
    OnOpenOptions,
    SendMessageOptions,
    WebSocketPlugin
} from './definitions';
import websocket from "./websocket";

export class WebSocketWeb extends WebPlugin implements WebSocketPlugin {

    async connect(options: ConnectionOptions): Promise<void> {
        if (options.id === undefined) options.id = "default"
        await websocket.connect(options.url, options.id)
    }

    async close(options?: CloseOptions): Promise<void> {
        if (options === undefined) options = {id: "default"}
        if (options.id === undefined) options.id = "default"
        await websocket.close(options.id, options.code, options.reason)
    }

    async send(options: SendMessageOptions): Promise<void> {
        if (options.id === undefined) options.id = "default"
        await websocket.send(options.data, options.id)
    }

    async onOpen(options: OnOpenOptions, callback: OnOpenCallback): Promise<void> {
        if (options.id === undefined) options.id = "default"
        websocket.openCalls.set(options.id, () => {
            callback.call(this, {id: options.id})
        })
    }

    async onClose(options: OnCloseOptions, callback: OnCloseCallback): Promise<void> {
        if (options.id === undefined) options.id = "default"
        websocket.closedCalls.set(options.id, (ev) => {
            callback.call(this, {id: options.id, code: ev.code, reason: ev.reason})
        })
    }

    async onError(options: OnErrorOptions, callback: OnErrorCallback): Promise<void> {
        if (options.id === undefined) options.id = "default"
        websocket.failureCalls.set(options.id, (ev) => {
            callback.call(this, {id: options.id, error: JSON.stringify(ev)})
        })
    }

    async onMessage(options: OnMessageOptions, callback: OnMessageCallback): Promise<void> {
        if (options.id === undefined) options.id = "default"
        websocket.messageCalls.set(options.id, (ev) => {
            callback.call(this, {id: options.id, data: ev.data})
        })
    }
}
