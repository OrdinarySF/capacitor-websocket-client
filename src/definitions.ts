export interface WebSocketPlugin {
    /**
     * Initiate a WebSocket connection.
     * @param options The options for the connection.
     * @since 0.0.1
     */
    connect(options: ConnectionOptions): Promise<void>;

    /**
     * Send a message.
     * @param options The options for the message.
     * @since 0.0.1
     */
    send(options: SendMessageOptions): Promise<void>;

    /**
     * Register a callback to be invoked when the connection is opened.
     * @param callback The callback that will be invoked.
     * @param options The options for the connection info.
     * @since 0.0.1
     */
    onOpen(callback: OnOpenCallback, options?: OnOpenOptions): Promise<void>;

    /**
     * Register a callback to be invoked when a message is received.
     * @param callback The callback that will be invoked.
     * @param options The options for the message info.
     * @since 0.0.1
     */
    onMessage(callback: OnMessageCallback, options?: OnMessageOptions): Promise<void>;

    /**
     * Register a callback to be invoked when the connection is closed.
     * @param callback The callback that will be invoked.
     * @param options The options for the connection info.
     * @since 0.0.1
     */
    onClose(callback: OnCloseCallback, options?: OnCloseOptions): Promise<void>;

    /**
     * Register a callback to be invoked when an error occurs.
     * @param callback The callback that will be invoked.
     * @param options The options for the error info.
     * @since 0.0.1
     */
    onError(callback: OnErrorCallback, options?: OnErrorOptions): Promise<void>;
}

export interface ConnectionOptions {
    /**
     * The URL to which to connect; this should be the URL to which the WebSocket server will respond.
     *
     * @since 0.0.1
     */
    url: string;
    /**
     * The ID uniquely identifies a connection; no input is required, if you do not need multiple connections.
     * @since 0.0.1
     */
    id?: string;
}

export interface SendMessageOptions {
    /**
     * The data to send to the server.
     *
     * @since 0.0.1
     */
    data: string;
    /**
     * The ID uniquely identifies a connection; no input is required, if you do not need multiple connections.
     * @since 0.0.1
     */
    id?: string;
}

export type OnOpenCallback = (message: OnOpenData | null, err?: any) => void;

export interface OnOpenOptions {
    /**
     * The ID uniquely identifies a connection; no input is required, if you do not need multiple connections.
     * @since 0.0.1
     */
    id?: string;
}

export interface OnOpenData {
    /**
     * The ID uniquely identifies a connection; no input is required, if you do not need multiple connections.
     * @since 0.0.1
     */
    id?: string;
}

export type OnMessageCallback = (message: OnMessageData | null, err?: any) => void;

export interface OnMessageOptions {
    /**
     * The ID uniquely identifies a connection; no input is required, if you do not need multiple connections.
     * @since 0.0.1
     */
    id?: string;
}

export interface OnMessageData {
    /**
     * The ID uniquely identifies a connection; no input is required, if you do not need multiple connections.
     * @since 0.0.1
     */
    id?: string;
    /**
     * The data sent by the message emitter.
     *
     * @since 0.0.1
     */
    data: string;
}

export type OnCloseCallback = (message: OnCloseData | null, err?: any) => void;

export interface OnCloseOptions {
    /**
     * The ID uniquely identifies a connection; no input is required, if you do not need multiple connections.
     * @since 0.0.1
     */
    id?: string;
}

export interface OnCloseData {
    /**
     * The ID uniquely identifies a connection; no input is required, if you do not need multiple connections.
     * @since 0.0.1
     */
    id?: string;
    /**
     * An integer WebSocket connection close code value indicating a reason for closure.
     * Status code as defined by
     * [Section 7.4 of RFC 6455](http://tools.ietf.org/html/rfc6455#section-7.4).
     * @since 0.0.1
     */
    code: number;
    /**
     * A string explaining the reason for the connection close.
     * @since 0.0.1
     */
    reason?: string;
}

export type OnErrorCallback = (message: OnErrorData | null, err?: any) => void;

export interface OnErrorOptions {
    /**
     * The ID uniquely identifies a connection; no input is required, if you do not need multiple connections.
     * @since 0.0.1
     */
    id?: string;
}

export interface OnErrorData {
    /**
     * The ID uniquely identifies a connection; no input is required, if you do not need multiple connections.
     * @since 0.0.1
     */
    id?: string;
}

export interface OnErrorData {
    /**
     * The ID uniquely identifies a connection; no input is required, if you do not need multiple connections.
     * @since 0.0.1
     */
    id?: string;
    /**
     * The error message.
     * @since 0.0.1
     */
    error: string;
}
