import Foundation

enum WebSocketError: Error, Equatable {
    case missingUrl
    case invalidUrl
    case sessionInvalidated

    var message: String {
        switch self {
        case .missingUrl, .invalidUrl:
            return "url can not null."
        case .sessionInvalidated:
            return "session invalidated"
        }
    }
}

/// Manages multiple `URLSessionWebSocketTask` connections keyed by id.
@objc public class WebSocket: NSObject {
    public static let defaultId = "default"
    public static let defaultCloseCode = 1000
    public static let defaultCloseReason = ""
    private static let pingInterval: TimeInterval = 30

    public static func resolvedId(_ id: String?) -> String {
        id ?? defaultId
    }

    private final class Client {
        let id: String
        let task: URLSessionWebSocketTask
        var didNotifyClose = false
        var didNotifyError = false
        var pendingCloseCode: Int?
        var pendingCloseReason: String?
        var pingTimer: DispatchSourceTimer?

        init(id: String, task: URLSessionWebSocketTask) {
            self.id = id
            self.task = task
        }

        func startPing() {
            stopPing()
            let timer = DispatchSource.makeTimerSource(queue: DispatchQueue.global(qos: .utility))
            timer.schedule(deadline: .now() + WebSocket.pingInterval, repeating: WebSocket.pingInterval)
            timer.setEventHandler { [weak self] in
                self?.task.sendPing { _ in }
            }
            timer.resume()
            pingTimer = timer
        }

        func stopPing() {
            pingTimer?.cancel()
            pingTimer = nil
        }
    }

    private final class SessionDelegate: NSObject, URLSessionWebSocketDelegate {
        weak var owner: WebSocket?

        func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didOpenWithProtocol proto: String?) {
            owner?.handleOpen(webSocketTask)
        }

        func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didCloseWith closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
            owner?.handleClose(webSocketTask, code: closeCode, reason: reason)
        }

        func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
            owner?.handleComplete(task, error: error)
        }
    }

    private let lock = NSLock()
    private var clients: [String: Client] = [:]
    private var clientsByTask: [ObjectIdentifier: Client] = [:]
    private var openHandlers: [String: (String) -> Void] = [:]
    private var messageHandlers: [String: (String, String) -> Void] = [:]
    private var closeHandlers: [String: (String, Int, String) -> Void] = [:]
    private var errorHandlers: [String: (String, String) -> Void] = [:]
    private var sessionInvalidated = false
    /// Test seam: replaced client pruned without emitting to JS.
    var onSuppressedTerminal: (() -> Void)?

    private let sessionDelegate = SessionDelegate()
    private var session: URLSession!

    public override init() {
        super.init()
        sessionDelegate.owner = self
        let queue = OperationQueue()
        queue.name = "cn.holmescraft.capacitor.websocket"
        queue.maxConcurrentOperationCount = 1
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = .infinity
        configuration.timeoutIntervalForResource = .infinity
        session = URLSession(configuration: configuration, delegate: sessionDelegate, delegateQueue: queue)
    }

    deinit {
        teardownLockedClients(cancelTasks: false)
        invalidateSessionIfNeeded()
    }

    // MARK: - Callbacks

    func setOnOpen(id: String, handler: @escaping (String) -> Void) {
        lock.lock()
        openHandlers[id] = handler
        lock.unlock()
    }

    func setOnMessage(id: String, handler: @escaping (String, String) -> Void) {
        lock.lock()
        messageHandlers[id] = handler
        lock.unlock()
    }

    func setOnClose(id: String, handler: @escaping (String, Int, String) -> Void) {
        lock.lock()
        closeHandlers[id] = handler
        lock.unlock()
    }

    func setOnError(id: String, handler: @escaping (String, String) -> Void) {
        lock.lock()
        errorHandlers[id] = handler
        lock.unlock()
    }

    // MARK: - Connections

    @discardableResult
    func connect(url: String?, id: String?) -> Result<String, WebSocketError> {
        guard let urlString = url, !urlString.isEmpty else {
            return .failure(.missingUrl)
        }
        guard let wsURL = URL(string: urlString) else {
            return .failure(.invalidUrl)
        }

        let connId = WebSocket.resolvedId(id)

        lock.lock()
        if sessionInvalidated {
            lock.unlock()
            return .failure(.sessionInvalidated)
        }
        if let existing = clients[connId] {
            existing.stopPing()
            existing.pendingCloseCode = URLSessionWebSocketTask.CloseCode.goingAway.rawValue
            existing.task.cancel(with: .goingAway, reason: nil)
        }
        let task = session.webSocketTask(with: wsURL)
        let client = Client(id: connId, task: task)
        clients[connId] = client
        clientsByTask[ObjectIdentifier(task)] = client
        lock.unlock()

        task.resume()
        listen(id: connId, task: task)
        return .success(connId)
    }

    func send(id: String, data: String, completion: @escaping (Bool) -> Void) {
        lock.lock()
        let task = clients[id]?.task
        lock.unlock()

        guard let task = task else {
            completion(false)
            return
        }

        task.send(.string(data)) { error in
            completion(error == nil)
        }
    }

    @discardableResult
    func close(id: String, code: Int, reason: String) -> Bool {
        lock.lock()
        guard let client = clients[id] else {
            lock.unlock()
            return false
        }
        client.pendingCloseCode = code
        client.pendingCloseReason = reason
        let task = client.task
        lock.unlock()

        task.cancel(with: Self.wireCloseCode(for: code), reason: Self.closeReasonData(reason))
        return true
    }

    func hasConnection(id: String) -> Bool {
        lock.lock()
        defer { lock.unlock() }
        return clients[id] != nil
    }

    func invalidate() {
        teardownLockedClients(cancelTasks: true)
        invalidateSessionIfNeeded()
    }

    // MARK: - Receive loop

    private func listen(id: String, task: URLSessionWebSocketTask) {
        task.receive { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let message):
                guard self.isCurrent(task, id: id) else { return }
                switch message {
                case .string(let text):
                    self.emitMessage(id: id, task: task, data: text)
                case .data(let data):
                    // Skip non-UTF-8 binary frames (Android is text-only; no binary JS API).
                    if let text = String(data: data, encoding: .utf8) {
                        self.emitMessage(id: id, task: task, data: text)
                    }
                @unknown default:
                    break
                }
                if self.isCurrent(task, id: id) {
                    self.listen(id: id, task: task)
                }
            case .failure:
                break
            }
        }
    }

    // MARK: - Delegate handlers

    fileprivate func handleOpen(_ task: URLSessionWebSocketTask) {
        lock.lock()
        guard let client = client(for: task), isCurrentLocked(client) else {
            lock.unlock()
            return
        }
        client.startPing()
        let id = client.id
        let handler = openHandlers[id]
        lock.unlock()
        guard isCurrent(task, id: id) else { return }
        handler?(id)
    }

    fileprivate func handleClose(_ task: URLSessionWebSocketTask, code: URLSessionWebSocketTask.CloseCode, reason: Data?) {
        let reasonString = reason.flatMap { String(data: $0, encoding: .utf8) } ?? ""
        lock.lock()
        guard let client = client(for: task) else {
            lock.unlock()
            return
        }
        let emit = emitCloseOnceLocked(client, code: code.rawValue, reason: reasonString)
        lock.unlock()
        emit?()
    }

    fileprivate func handleComplete(_ task: URLSessionTask, error: Error?) {
        lock.lock()
        guard let client = client(for: task) else {
            lock.unlock()
            return
        }

        if let error = error {
            let nsError = error as NSError
            if nsError.domain == NSURLErrorDomain && nsError.code == NSURLErrorCancelled {
                let emit = emitCloseOnceLocked(
                    client,
                    code: URLSessionWebSocketTask.CloseCode.normalClosure.rawValue,
                    reason: ""
                )
                lock.unlock()
                emit?()
                return
            }
            let emit = emitErrorOnceLocked(client, message: error.localizedDescription)
            lock.unlock()
            emit?()
            return
        }

        let emit = emitCloseOnceLocked(
            client,
            code: URLSessionWebSocketTask.CloseCode.normalClosure.rawValue,
            reason: ""
        )
        lock.unlock()
        emit?()
    }

    // MARK: - Helpers

    private func client(for task: URLSessionTask) -> Client? {
        clientsByTask[ObjectIdentifier(task)]
    }

    private func isCurrentLocked(_ client: Client) -> Bool {
        clients[client.id] === client
    }

    private func isCurrent(_ task: URLSessionWebSocketTask, id: String) -> Bool {
        lock.lock()
        defer { lock.unlock() }
        return clients[id]?.task === task
    }

    private func removeClientLocked(_ client: Client) {
        client.stopPing()
        clientsByTask.removeValue(forKey: ObjectIdentifier(client.task))
        if clients[client.id] === client {
            clients.removeValue(forKey: client.id)
        }
    }

    private func teardownLockedClients(cancelTasks: Bool) {
        lock.lock()
        let leftover = Array(clientsByTask.values)
        clients.removeAll()
        clientsByTask.removeAll()
        openHandlers.removeAll()
        messageHandlers.removeAll()
        closeHandlers.removeAll()
        errorHandlers.removeAll()
        lock.unlock()
        for client in leftover {
            client.stopPing()
            if cancelTasks {
                client.task.cancel(with: .goingAway, reason: nil)
            }
        }
    }

    private func invalidateSessionIfNeeded() {
        lock.lock()
        let already = sessionInvalidated
        sessionInvalidated = true
        lock.unlock()
        guard !already else { return }
        session.invalidateAndCancel()
    }

    private func emitMessage(id: String, task: URLSessionWebSocketTask, data: String) {
        lock.lock()
        guard clients[id]?.task === task else {
            lock.unlock()
            return
        }
        let handler = messageHandlers[id]
        lock.unlock()
        handler?(id, data)
    }

    private func emitCloseOnceLocked(_ client: Client, code: Int, reason: String) -> (() -> Void)? {
        guard !client.didNotifyClose else { return nil }
        client.didNotifyClose = true
        let emitCode = client.pendingCloseCode ?? code
        let emitReason = client.pendingCloseReason ?? reason
        let wasCurrent = isCurrentLocked(client)
        let handler = wasCurrent ? closeHandlers[client.id] : nil
        removeClientLocked(client)
        if let handler = handler {
            return { handler(client.id, emitCode, emitReason) }
        }
        if !wasCurrent {
            let notify = onSuppressedTerminal
            return { notify?() }
        }
        return nil
    }

    private func emitErrorOnceLocked(_ client: Client, message: String) -> (() -> Void)? {
        guard !client.didNotifyError else { return nil }
        client.didNotifyError = true
        let wasCurrent = isCurrentLocked(client)
        let handler = wasCurrent ? errorHandlers[client.id] : nil
        removeClientLocked(client)
        if let handler = handler {
            return { handler(client.id, message) }
        }
        if !wasCurrent {
            let notify = onSuppressedTerminal
            return { notify?() }
        }
        return nil
    }

    private static func wireCloseCode(for code: Int) -> URLSessionWebSocketTask.CloseCode {
        guard let closeCode = URLSessionWebSocketTask.CloseCode(rawValue: code) else {
            return .goingAway
        }
        switch closeCode {
        case .invalid, .noStatusReceived, .abnormalClosure, .tlsHandshakeFailure:
            return .goingAway
        default:
            return closeCode
        }
    }

    private static func closeReasonData(_ reason: String) -> Data? {
        guard !reason.isEmpty, var data = reason.data(using: .utf8) else {
            return nil
        }
        if data.count > 123 {
            data = Data(data.prefix(123))
        }
        return data
    }
}
