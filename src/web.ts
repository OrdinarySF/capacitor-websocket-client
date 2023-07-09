import {WebPlugin} from '@capacitor/core';

import type {
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

    async send(options: SendMessageOptions): Promise<void> {
        if (options.id === undefined) options.id = "default"
        await websocket.send(options.data, options.id)
    }

    async onOpen(callback: OnOpenCallback, options: OnOpenOptions = {}): Promise<void> {
        if (options.id === undefined) options.id = "default"
        websocket.openCalls.set(options.id, () => {
            callback.call(this, {id: options.id})
        })
    }

    async onClose(callback: OnCloseCallback, options: OnCloseOptions = {}): Promise<void> {
        if (options.id === undefined) options.id = "default"
        websocket.closedCalls.set(options.id, (ev) => {
            callback.call(this, {id: options.id, code: ev.code, reason: ev.reason})
        })
    }

    async onError(callback: OnErrorCallback, options: OnErrorOptions = {}): Promise<void> {
        if (options.id === undefined) options.id = "default"
        websocket.failureCalls.set(options.id, (ev) => {
            callback.call(this, {id: options.id, error: JSON.stringify(ev)})
        })
    }

    async onMessage(callback: OnMessageCallback, options: OnMessageOptions = {}): Promise<void> {
        if (options.id === undefined) options.id = "default"
        websocket.messageCalls.set(options.id, (ev) => {
            callback.call(this, {id: options.id, data: ev.data})
        })
    }
}
