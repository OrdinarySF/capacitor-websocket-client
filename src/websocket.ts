class WebsocketClient {
    clients: Map<string, WebSocket>;

    openCalls: Map<string, ((this: WebSocket, ev: Event) => any) | null>
    closedCalls: Map<string, ((this: WebSocket, ev: CloseEvent) => any) | null>
    messageCalls: Map<string, ((this: WebSocket, ev: MessageEvent) => any) | null>
    failureCalls: Map<string, ((this: WebSocket, ev: Event) => any) | null>

    constructor() {
        this.clients = new Map();
        this.openCalls = new Map()
        this.closedCalls = new Map()
        this.messageCalls = new Map()
        this.failureCalls = new Map()
    }

    public async connect(url: string, id: string) {
        const client = new WebSocket(url)
        const openCall = this.openCalls.get(id)
        if (openCall !== undefined)
            client.onopen = openCall
        const closedCall = this.closedCalls.get(id)
        if (closedCall !== undefined)
            client.onclose = closedCall
        const messageCall = this.messageCalls.get(id)
        if (messageCall !== undefined)
            client.onmessage = messageCall
        const failureCall = this.failureCalls.get(id)
        if (failureCall !== undefined)
            client.onerror = failureCall
        this.clients.set(id, client)

    }

    public async send(data: string, id: string) {
        const client = this.clients.get(id)
        if (client === undefined) throw new Error(`The connection with id: ${id} does not exist.`)
        client.send(data)
    }

    async close(id: string, code?: number, reason?: string) {
        const client = this.clients.get(id)
        if (client === undefined) throw new Error(`The connection with id: ${id} does not exist.`)
        client.close(code,reason)
    }
}

const client = new WebsocketClient()
export default client
