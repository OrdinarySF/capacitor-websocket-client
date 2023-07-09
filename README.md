# @wahr/capacitor-websocket-client

Capacitor WebSocket Client Plugin.

## Install

```bash
npm install @wahr/capacitor-websocket-client
npx cap sync
```

## API

<docgen-index>

* [`connect(...)`](#connect)
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
connect(options: ConnectionOptions) => Promise<void>
```

Initiate a WebSocket connection.

| Param         | Type                                                            | Description                     |
| ------------- | --------------------------------------------------------------- | ------------------------------- |
| **`options`** | <code><a href="#connectionoptions">ConnectionOptions</a></code> | The options for the connection. |

**Since:** 0.0.1

--------------------


### send(...)

```typescript
send(options: SendMessageOptions) => Promise<void>
```

Send a message.

| Param         | Type                                                              | Description                  |
| ------------- | ----------------------------------------------------------------- | ---------------------------- |
| **`options`** | <code><a href="#sendmessageoptions">SendMessageOptions</a></code> | The options for the message. |

**Since:** 0.0.1

--------------------


### onOpen(...)

```typescript
onOpen(callback: OnOpenCallback, options?: OnOpenOptions | undefined) => Promise<void>
```

Register a callback to be invoked when the connection is opened.

| Param          | Type                                                      | Description                          |
| -------------- | --------------------------------------------------------- | ------------------------------------ |
| **`callback`** | <code><a href="#onopencallback">OnOpenCallback</a></code> | The callback that will be invoked.   |
| **`options`**  | <code><a href="#onopenoptions">OnOpenOptions</a></code>   | The options for the connection info. |

**Since:** 0.0.1

--------------------


### onMessage(...)

```typescript
onMessage(callback: OnMessageCallback, options?: OnMessageOptions | undefined) => Promise<void>
```

Register a callback to be invoked when a message is received.

| Param          | Type                                                            | Description                        |
| -------------- | --------------------------------------------------------------- | ---------------------------------- |
| **`callback`** | <code><a href="#onmessagecallback">OnMessageCallback</a></code> | The callback that will be invoked. |
| **`options`**  | <code><a href="#onmessageoptions">OnMessageOptions</a></code>   | The options for the message info.  |

**Since:** 0.0.1

--------------------


### onClose(...)

```typescript
onClose(callback: OnCloseCallback, options?: OnCloseOptions | undefined) => Promise<void>
```

Register a callback to be invoked when the connection is closed.

| Param          | Type                                                        | Description                          |
| -------------- | ----------------------------------------------------------- | ------------------------------------ |
| **`callback`** | <code><a href="#onclosecallback">OnCloseCallback</a></code> | The callback that will be invoked.   |
| **`options`**  | <code><a href="#oncloseoptions">OnCloseOptions</a></code>   | The options for the connection info. |

**Since:** 0.0.1

--------------------


### onError(...)

```typescript
onError(callback: OnErrorCallback, options?: OnErrorOptions | undefined) => Promise<void>
```

Register a callback to be invoked when an error occurs.

| Param          | Type                                                        | Description                        |
| -------------- | ----------------------------------------------------------- | ---------------------------------- |
| **`callback`** | <code><a href="#onerrorcallback">OnErrorCallback</a></code> | The callback that will be invoked. |
| **`options`**  | <code><a href="#onerroroptions">OnErrorOptions</a></code>   | The options for the error info.    |

**Since:** 0.0.1

--------------------


### Interfaces


#### ConnectionOptions

| Prop      | Type                | Description                                                                                             | Since |
| --------- | ------------------- | ------------------------------------------------------------------------------------------------------- | ----- |
| **`url`** | <code>string</code> | The URL to which to connect; this should be the URL to which the WebSocket server will respond.         | 0.0.1 |
| **`id`**  | <code>string</code> | The ID uniquely identifies a connection; no input is required, if you do not need multiple connections. | 0.0.1 |


#### SendMessageOptions

| Prop       | Type                | Description                                                                                             | Since |
| ---------- | ------------------- | ------------------------------------------------------------------------------------------------------- | ----- |
| **`data`** | <code>string</code> | The data to send to the server.                                                                         | 0.0.1 |
| **`id`**   | <code>string</code> | The ID uniquely identifies a connection; no input is required, if you do not need multiple connections. | 0.0.1 |


#### OnOpenData

| Prop     | Type                | Description                                                                                             | Since |
| -------- | ------------------- | ------------------------------------------------------------------------------------------------------- | ----- |
| **`id`** | <code>string</code> | The ID uniquely identifies a connection; no input is required, if you do not need multiple connections. | 0.0.1 |


#### OnOpenOptions

| Prop     | Type                | Description                                                                                             | Since |
| -------- | ------------------- | ------------------------------------------------------------------------------------------------------- | ----- |
| **`id`** | <code>string</code> | The ID uniquely identifies a connection; no input is required, if you do not need multiple connections. | 0.0.1 |


#### OnMessageData

| Prop       | Type                | Description                                                                                             | Since |
| ---------- | ------------------- | ------------------------------------------------------------------------------------------------------- | ----- |
| **`id`**   | <code>string</code> | The ID uniquely identifies a connection; no input is required, if you do not need multiple connections. | 0.0.1 |
| **`data`** | <code>string</code> | The data sent by the message emitter.                                                                   | 0.0.1 |


#### OnMessageOptions

| Prop     | Type                | Description                                                                                             | Since |
| -------- | ------------------- | ------------------------------------------------------------------------------------------------------- | ----- |
| **`id`** | <code>string</code> | The ID uniquely identifies a connection; no input is required, if you do not need multiple connections. | 0.0.1 |


#### OnCloseData

| Prop         | Type                | Description                                                                                                                                                                            | Since |
| ------------ | ------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ----- |
| **`id`**     | <code>string</code> | The ID uniquely identifies a connection; no input is required, if you do not need multiple connections.                                                                                | 0.0.1 |
| **`code`**   | <code>number</code> | An integer WebSocket connection close code value indicating a reason for closure. Status code as defined by [Section 7.4 of RFC 6455](http://tools.ietf.org/html/rfc6455#section-7.4). | 0.0.1 |
| **`reason`** | <code>string</code> | A string explaining the reason for the connection close.                                                                                                                               | 0.0.1 |


#### OnCloseOptions

| Prop     | Type                | Description                                                                                             | Since |
| -------- | ------------------- | ------------------------------------------------------------------------------------------------------- | ----- |
| **`id`** | <code>string</code> | The ID uniquely identifies a connection; no input is required, if you do not need multiple connections. | 0.0.1 |


#### OnErrorData

| Prop     | Type                | Description                                                                                             | Since |
| -------- | ------------------- | ------------------------------------------------------------------------------------------------------- | ----- |
| **`id`** | <code>string</code> | The ID uniquely identifies a connection; no input is required, if you do not need multiple connections. | 0.0.1 |


#### OnErrorOptions

| Prop     | Type                | Description                                                                                             | Since |
| -------- | ------------------- | ------------------------------------------------------------------------------------------------------- | ----- |
| **`id`** | <code>string</code> | The ID uniquely identifies a connection; no input is required, if you do not need multiple connections. | 0.0.1 |


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
