# @wahr/capacitor-websocket-client

[![Downloads][badge-dl]][download]
[![License][badge-license]][license]
[![Issues][badge-issues]][issues]
[![Version][badge-version]][download]

[badge-dl]: https://img.shields.io/npm/dw/%40wahr%2Fcapacitor-websocket-client?style=flat-square
[download]: https://www.npmjs.com/package/@wahr/capacitor-websocket-client?activeTab=versions
[badge-license]: https://img.shields.io/npm/l/%40wahr%2Fcapacitor-websocket-client?style=flat-square
[license]: https://github.com/OrdinarySF/capacitor-websocket-client/blob/main/LICENSE
[badge-issues]: https://img.shields.io/github/issues/OrdinarySF/capacitor-websocket-client?style=flat-square
[issues]: https://github.com/OrdinarySF/capacitor-websocket-client/issues
[badge-version]: https://img.shields.io/npm/v/%40wahr%2Fcapacitor-websocket-client?style=flat-square


Capacitor WebSocket Client Plugin.

## Install

```bash
npm install @wahr/capacitor-websocket-client
npx cap sync
```

## Platform support

- Web
- Android

> Unfortunately, we do not have a macOS device, but we are working hard.

## Example

#### Single connect

```typescript
await WebSocket.onOpen({}, (message, err) => {
    //do something...
    console.log("onOpen event have a bug: ", err?.toString())
})

await WebSocket.onMessage({}, (message, err) => {
    //do something...
    console.log(`received message content: ${message?.data}`)
})

await WebSocket.connect({url: "ws://example.com"})

setTimeout(async () => {
    await WebSocket.send({data: "hello world!"})
}, 2000);
```

#### Multiple connect

```typescript
await WebSocket.onOpen({id: "chat-websocket"}, (message, err) => {
    //do something...
    console.log("onOpen event have a bug: ", err?.toString())
})

await WebSocket.connect({url: "ws://example.com/chat", id: "chat-websocket"})

await WebSocket.onMessage({id: "notify-websocket"}, (message, err) => {
    //do something...
    console.log(`received notify content: ${message?.data}`)
})

await WebSocket.connect({url: "ws://example.com/notify", id: "notify-websocket"})

setTimeout(async () => {
    await WebSocket.send({data: "hello world!", id: "chat-websocket"})
    await WebSocket.send({data: "connect notify.", id: "notify-websocket"})
}, 2000)
```

## API

<docgen-index>

* [`connect(...)`](#connect)
* [`close(...)`](#close)
* [`send(...)`](#send)
* [`onOpen(...)`](#onopen)
* [`onMessage(...)`](#onmessage)
* [`onClose(...)`](#onclose)
* [`onError(...)`](#onerror)
* [Interfaces](#interfaces)
* [Type Aliases](#type-aliases)

</docgen-index>

<docgen-api>
<!--Update the source file JSDoc comments and rerun docgen to update the docs below-->

### connect(...)

```typescript
connect(options
:
ConnectionOptions
) =>
Promise<void>
```

Initiate a WebSocket connection.

| Param         | Type                                                            | Description                     |
|---------------|-----------------------------------------------------------------|---------------------------------|
| **`options`** | <code><a href="#connectionoptions">ConnectionOptions</a></code> | The options for the connection. |

**Since:** 0.0.1

--------------------

### close(...)

```typescript
close(options ? : CloseOptions | undefined)
=>
Promise<void>
```

Close the connection.

| Param         | Type                                                  |
|---------------|-------------------------------------------------------|
| **`options`** | <code><a href="#closeoptions">CloseOptions</a></code> |

--------------------

### send(...)

```typescript
send(options
:
SendMessageOptions
) =>
Promise<void>
```

Send a message.

| Param         | Type                                                              | Description                  |
|---------------|-------------------------------------------------------------------|------------------------------|
| **`options`** | <code><a href="#sendmessageoptions">SendMessageOptions</a></code> | The options for the message. |

**Since:** 0.0.1

--------------------

### onOpen(...)

```typescript
onOpen(options
:
OnOpenOptions, callback
:
OnOpenCallback
) =>
Promise<void>
```

Register a callback to be invoked when the connection is opened.

| Param          | Type                                                      | Description                          |
|----------------|-----------------------------------------------------------|--------------------------------------|
| **`options`**  | <code><a href="#onopenoptions">OnOpenOptions</a></code>   | The options for the connection info. |
| **`callback`** | <code><a href="#onopencallback">OnOpenCallback</a></code> | The callback that will be invoked.   |

**Since:** 0.0.3

--------------------

### onMessage(...)

```typescript
onMessage(options
:
OnMessageOptions, callback
:
OnMessageCallback
) =>
Promise<void>
```

Register a callback to be invoked when a message is received.

| Param          | Type                                                            | Description                        |
|----------------|-----------------------------------------------------------------|------------------------------------|
| **`options`**  | <code><a href="#onmessageoptions">OnMessageOptions</a></code>   | The options for the message info.  |
| **`callback`** | <code><a href="#onmessagecallback">OnMessageCallback</a></code> | The callback that will be invoked. |

**Since:** 0.0.3

--------------------

### onClose(...)

```typescript
onClose(options
:
OnCloseOptions, callback
:
OnCloseCallback
) =>
Promise<void>
```

Register a callback to be invoked when the connection is closed.

| Param          | Type                                                        | Description                          |
|----------------|-------------------------------------------------------------|--------------------------------------|
| **`options`**  | <code><a href="#oncloseoptions">OnCloseOptions</a></code>   | The options for the connection info. |
| **`callback`** | <code><a href="#onclosecallback">OnCloseCallback</a></code> | The callback that will be invoked.   |

**Since:** 0.0.3

--------------------

### onError(...)

```typescript
onError(options
:
OnErrorOptions, callback
:
OnErrorCallback
) =>
Promise<void>
```

Register a callback to be invoked when an error occurs.

| Param          | Type                                                        | Description                        |
|----------------|-------------------------------------------------------------|------------------------------------|
| **`options`**  | <code><a href="#onerroroptions">OnErrorOptions</a></code>   | The options for the error info.    |
| **`callback`** | <code><a href="#onerrorcallback">OnErrorCallback</a></code> | The callback that will be invoked. |

**Since:** 0.0.3

--------------------

### Interfaces

#### ConnectionOptions

| Prop      | Type                | Description                                                                                             | Since |
|-----------|---------------------|---------------------------------------------------------------------------------------------------------|-------|
| **`url`** | <code>string</code> | The URL to which to connect; this should be the URL to which the WebSocket server will respond.         | 0.0.1 |
| **`id`**  | <code>string</code> | The ID uniquely identifies a connection; no input is required, if you do not need multiple connections. | 0.0.1 |

#### CloseOptions

| Prop         | Type                | Description                                                                                                                                                                            |
|--------------|---------------------|----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| **`id`**     | <code>string</code> | The ID uniquely identifies a connection; no input is required, if you do not need multiple connections.                                                                                |
| **`code`**   | <code>number</code> | An integer WebSocket connection close code value indicating a reason for closure. Status code as defined by [Section 7.4 of RFC 6455](http://tools.ietf.org/html/rfc6455#section-7.4). |
| **`reason`** | <code>string</code> | A string explaining the reason for the connection close.                                                                                                                               |

#### SendMessageOptions

| Prop       | Type                | Description                                                                                             | Since |
|------------|---------------------|---------------------------------------------------------------------------------------------------------|-------|
| **`data`** | <code>string</code> | The data to send to the server.                                                                         | 0.0.1 |
| **`id`**   | <code>string</code> | The ID uniquely identifies a connection; no input is required, if you do not need multiple connections. | 0.0.1 |

#### OnOpenOptions

| Prop     | Type                | Description                                                                                             | Since |
|----------|---------------------|---------------------------------------------------------------------------------------------------------|-------|
| **`id`** | <code>string</code> | The ID uniquely identifies a connection; no input is required, if you do not need multiple connections. | 0.0.1 |

#### OnOpenData

| Prop     | Type                | Description                                                                                             | Since |
|----------|---------------------|---------------------------------------------------------------------------------------------------------|-------|
| **`id`** | <code>string</code> | The ID uniquely identifies a connection; no input is required, if you do not need multiple connections. | 0.0.1 |

#### OnMessageOptions

| Prop     | Type                | Description                                                                                             | Since |
|----------|---------------------|---------------------------------------------------------------------------------------------------------|-------|
| **`id`** | <code>string</code> | The ID uniquely identifies a connection; no input is required, if you do not need multiple connections. | 0.0.1 |

#### OnMessageData

| Prop       | Type                | Description                                                                                             | Since |
|------------|---------------------|---------------------------------------------------------------------------------------------------------|-------|
| **`id`**   | <code>string</code> | The ID uniquely identifies a connection; no input is required, if you do not need multiple connections. | 0.0.1 |
| **`data`** | <code>string</code> | The data sent by the message emitter.                                                                   | 0.0.1 |

#### OnCloseOptions

| Prop     | Type                | Description                                                                                             | Since |
|----------|---------------------|---------------------------------------------------------------------------------------------------------|-------|
| **`id`** | <code>string</code> | The ID uniquely identifies a connection; no input is required, if you do not need multiple connections. | 0.0.1 |

#### OnCloseData

| Prop         | Type                | Description                                                                                                                                                                            | Since |
|--------------|---------------------|----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|-------|
| **`id`**     | <code>string</code> | The ID uniquely identifies a connection; no input is required, if you do not need multiple connections.                                                                                | 0.0.1 |
| **`code`**   | <code>number</code> | An integer WebSocket connection close code value indicating a reason for closure. Status code as defined by [Section 7.4 of RFC 6455](http://tools.ietf.org/html/rfc6455#section-7.4). | 0.0.1 |
| **`reason`** | <code>string</code> | A string explaining the reason for the connection close.                                                                                                                               | 0.0.1 |

#### OnErrorOptions

| Prop     | Type                | Description                                                                                             | Since |
|----------|---------------------|---------------------------------------------------------------------------------------------------------|-------|
| **`id`** | <code>string</code> | The ID uniquely identifies a connection; no input is required, if you do not need multiple connections. | 0.0.1 |

#### OnErrorData

| Prop        | Type                | Description                                                                                             | Since |
|-------------|---------------------|---------------------------------------------------------------------------------------------------------|-------|
| **`id`**    | <code>string</code> | The ID uniquely identifies a connection; no input is required, if you do not need multiple connections. | 0.0.1 |
| **`error`** | <code>string</code> | The error message.                                                                                      | 0.0.1 |

### Type Aliases

#### OnOpenCallback

<code>(message: <a href="#onopendata">OnOpenData</a> | null, err?: any): void</code>

#### OnMessageCallback

<code>(message: <a href="#onmessagedata">OnMessageData</a> | null, err?: any): void</code>

#### OnCloseCallback

<code>(message: <a href="#onclosedata">OnCloseData</a> | null, err?: any): void</code>

#### OnErrorCallback

<code>(message: <a href="#onerrordata">OnErrorData</a> | null, err?: any): void</code>

</docgen-api>
