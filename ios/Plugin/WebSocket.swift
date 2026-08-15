import Foundation

enum WebSocketError: Error, Equatable {
    case missingUrl
    case invalidUrl

    var message: String {
        switch self {
        case .missingUrl, .invalidUrl:
            return "url can not null."
        }
    }
}

/// Manages multiple `URLSessionWebSocketTask` connections keyed by id.
@objc public class WebSocket: NSObject {
    public static let defaultId = "default"
    public static let defaultCloseCode = 1000
    public static let defaultCloseReason = ""

    public static func resolvedId(_ id: String?) -> String {
        guard let id = id, !id.isEmpty else {
            return defaultId
        }
        return id
    }

    private struct Client {
        let task: URLSessionWebSocketTask
        var didNotifyClose = false
        var didNotifyError = false
        var pendingCloseCode: Int?
        var pendingCloseReason: String?
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
    private var openHandlers: [String: (String) -> Void] = [:]
    private var messageHandlers: [String: (String, String) -> Void] = [:]
    private var closeHandlers: [String: (String, Int, String) -> Void] = [:]
    private var errorHandlers: [String: (String, String) -> Void] = [:]

    private let sessionDelegate = SessionDelegate()
    private var session: URLSession!

    public override init() {
        super.init()
        sessionDelegate.owner = self
        let queue = OperationQueue()
        queue.name = "cn.holmescraft.capacitor.websocket"
        queue.maxConcurrentOperationCount = 1
        session = URLSession(configuration: .default, delegate: sessionDelegate, delegateQueue: queue)
    }

    deinit {
        session.invalidateAndCancel()
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
        if let existing = clients[connId] {
            existing.task.cancel(with: .goingAway, reason: nil)
        }
        let task = session.webSocketTask(with: wsURL)
        clients[connId] = Client(task: task)
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
        guard var client = clients[id] else {
            lock.unlock()
            return false
        }
        client.pendingCloseCode = code
        client.pendingCloseReason = reason
        clients[id] = client
        let task = client.task
        lock.unlock()

        let closeCode = URLSessionWebSocketTask.CloseCode(rawValue: code) ?? .normalClosure
        task.cancel(with: closeCode, reason: Self.closeReasonData(reason))
        return true
    }

    func hasConnection(id: String) -> Bool {
        lock.lock()
        defer { lock.unlock() }
        return clients[id] != nil
    }

    func invalidate() {
        lock.lock()
        let tasks = clients.values.map { $0.task }
        clients.removeAll()
        lock.unlock()
        for task in tasks {
            task.cancel(with: .goingAway, reason: nil)
        }
        session.invalidateAndCancel()
    }

    // MARK: - Receive loop

    private func listen(id: String, task: URLSessionWebSocketTask) {
        task.receive { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let message):
                switch message {
                case .string(let text):
                    self.emitMessage(id: id, data: text)
                case .data(let data):
                    if let text = String(data: data, encoding: .utf8) {
                        self.emitMessage(id: id, data: text)
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
        guard let id = connectionId(for: task) else { return }
        lock.lock()
        let handler = openHandlers[id]
        lock.unlock()
        handler?(id)
    }

    fileprivate func handleClose(_ task: URLSessionWebSocketTask, code: URLSessionWebSocketTask.CloseCode, reason: Data?) {
        guard let id = connectionId(for: task) else { return }
        let reasonString = reason.flatMap { String(data: $0, encoding: .utf8) } ?? ""
        emitCloseOnce(id: id, code: code.rawValue, reason: reasonString)
    }

    fileprivate func handleComplete(_ task: URLSessionTask, error: Error?) {
        guard let id = connectionId(for: task) else { return }

        if let error = error {
            let nsError = error as NSError
            if nsError.domain == NSURLErrorDomain && nsError.code == NSURLErrorCancelled {
                emitPendingOrDefaultClose(id: id)
                return
            }
            emitErrorOnce(id: id, message: error.localizedDescription)
            return
        }

        emitPendingOrDefaultClose(id: id)
    }

    // MARK: - Helpers

    private func connectionId(for task: URLSessionTask) -> String? {
        lock.lock()
        defer { lock.unlock() }
        for (id, client) in clients where client.task === task {
            return id
        }
        return nil
    }

    private func isCurrent(_ task: URLSessionWebSocketTask, id: String) -> Bool {
        lock.lock()
        defer { lock.unlock() }
        return clients[id]?.task === task
    }

    private func emitMessage(id: String, data: String) {
        lock.lock()
        let handler = messageHandlers[id]
        lock.unlock()
        handler?(id, data)
    }

    private func emitCloseOnce(id: String, code: Int, reason: String) {
        lock.lock()
        guard var client = clients[id], !client.didNotifyClose else {
            lock.unlock()
            return
        }
        client.didNotifyClose = true
        clients[id] = client
        let handler = closeHandlers[id]
        lock.unlock()
        handler?(id, code, reason)
    }

    private func emitPendingOrDefaultClose(id: String) {
        lock.lock()
        let code = clients[id]?.pendingCloseCode ?? URLSessionWebSocketTask.CloseCode.normalClosure.rawValue
        let reason = clients[id]?.pendingCloseReason ?? ""
        lock.unlock()
        emitCloseOnce(id: id, code: code, reason: reason)
    }

    private func emitErrorOnce(id: String, message: String) {
        lock.lock()
        guard var client = clients[id], !client.didNotifyError else {
            lock.unlock()
            return
        }
        client.didNotifyError = true
        clients[id] = client
        let handler = errorHandlers[id]
        lock.unlock()
        handler?(id, message)
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
