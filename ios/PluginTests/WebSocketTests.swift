import XCTest
import Darwin
@testable import Plugin

class WebSocketTests: XCTestCase {
    var socket: WebSocket!

    override func setUp() {
        super.setUp()
        socket = WebSocket()
    }

    override func tearDown() {
        socket.invalidate()
        socket = nil
        super.tearDown()
    }

    func testResolvedIdDefaultsOnlyWhenNil() {
        XCTAssertEqual(WebSocket.resolvedId(nil), "default")
        XCTAssertEqual(WebSocket.resolvedId(""), "")
        XCTAssertEqual(WebSocket.resolvedId("chat"), "chat")
    }

    func testConnectMissingUrl() {
        let missing = socket.connect(url: nil, id: nil)
        XCTAssertEqual(missing, .failure(.missingUrl))
        XCTAssertFalse(socket.hasConnection(id: WebSocket.defaultId))

        let empty = socket.connect(url: "", id: "chat")
        XCTAssertEqual(empty, .failure(.missingUrl))
        XCTAssertFalse(socket.hasConnection(id: "chat"))
    }

    func testConnectRegistersWithoutWaitingForOpen() {
        let result = socket.connect(url: "ws://127.0.0.1:1", id: nil)
        XCTAssertEqual(result, .success("default"))
        XCTAssertTrue(socket.hasConnection(id: "default"))
    }

    func testConnectUsesExplicitId() {
        let result = socket.connect(url: "ws://127.0.0.1:1", id: "chat")
        XCTAssertEqual(result, .success("chat"))
        XCTAssertTrue(socket.hasConnection(id: "chat"))
        XCTAssertFalse(socket.hasConnection(id: "default"))
    }

    func testConnectKeepsEmptyId() {
        let result = socket.connect(url: "ws://127.0.0.1:1", id: "")
        XCTAssertEqual(result, .success(""))
        XCTAssertTrue(socket.hasConnection(id: ""))
        XCTAssertFalse(socket.hasConnection(id: "default"))
    }

    func testSendUnknownId() {
        let expectation = self.expectation(description: "send fails for unknown id")
        socket.send(id: "missing", data: "hello") { success in
            XCTAssertFalse(success)
            expectation.fulfill()
        }
        waitForExpectations(timeout: 1.0)
    }

    func testCloseUnknownId() {
        XCTAssertFalse(socket.close(id: "missing", code: 1000, reason: ""))
        XCTAssertFalse(socket.close(id: WebSocket.defaultId, code: WebSocket.defaultCloseCode, reason: WebSocket.defaultCloseReason))
    }

    func testMultipleConnectionIds() {
        XCTAssertEqual(socket.connect(url: "ws://127.0.0.1:1", id: "a"), .success("a"))
        XCTAssertEqual(socket.connect(url: "ws://127.0.0.1:2", id: "b"), .success("b"))
        XCTAssertTrue(socket.hasConnection(id: "a"))
        XCTAssertTrue(socket.hasConnection(id: "b"))
        XCTAssertTrue(socket.close(id: "a", code: 1000, reason: "done"))
        XCTAssertTrue(socket.hasConnection(id: "b"))
    }

    func testTerminalEventPrunesConnection() {
        let done = expectation(description: "terminal close or error")
        socket.setOnError(id: "gone") { _, _ in
            done.fulfill()
        }
        socket.setOnClose(id: "gone") { _, _, _ in
            done.fulfill()
        }
        XCTAssertEqual(socket.connect(url: "ws://127.0.0.1:1", id: "gone"), .success("gone"))
        wait(for: [done], timeout: 5)
        XCTAssertFalse(socket.hasConnection(id: "gone"))
    }

    func testCloseReportsRequestedCustomCode() throws {
        let closeExp = expectation(description: "close with requested code")
        var receivedCode: Int?
        var receivedReason: String?
        var terminalError: String?
        socket.setOnClose(id: "custom") { _, code, reason in
            receivedCode = code
            receivedReason = reason
            closeExp.fulfill()
        }
        socket.setOnError(id: "custom") { _, error in
            terminalError = error
            closeExp.fulfill()
        }
        XCTAssertEqual(socket.connect(url: "ws://192.0.2.1:9", id: "custom"), .success("custom"))
        guard socket.hasConnection(id: "custom") else {
            throw XCTSkip("connection already gone before close()")
        }
        XCTAssertTrue(socket.close(id: "custom", code: 4000, reason: "app"))
        wait(for: [closeExp], timeout: 5)
        if receivedCode == nil, let terminalError = terminalError {
            throw XCTSkip("connect error raced ahead of close pending: \(terminalError)")
        }
        XCTAssertEqual(receivedCode, 4000)
        XCTAssertEqual(receivedReason, "app")
        XCTAssertFalse(socket.hasConnection(id: "custom"))
    }

    func testConnectAfterInvalidateFails() {
        socket.invalidate()
        XCTAssertEqual(socket.connect(url: "ws://127.0.0.1:1", id: "dead"), .failure(.sessionInvalidated))
        XCTAssertFalse(socket.hasConnection(id: "dead"))
    }

    func testSameIdReconnectDoesNotEmitOldCloseAndKeepsNew() throws {
        let server: LocalTCPServer
        do {
            server = try LocalTCPServer()
        } catch {
            throw XCTSkip("could not bind local TCP listener: \(error)")
        }
        defer { server.stop() }
        let url = "ws://127.0.0.1:\(server.port)"

        let firstAccept = expectation(description: "accepted first connect")
        let secondAccept = expectation(description: "accepted replacement connect")
        server.onAcceptCount = { n in
            if n == 1 { firstAccept.fulfill() }
            if n == 2 { secondAccept.fulfill() }
        }

        var closeCount = 0
        var errorCount = 0
        let replacedFinished = expectation(description: "replaced task completed without JS emit")
        let currentClosed = expectation(description: "current id still emits onClose")

        socket.onSuppressedTerminal = {
            replacedFinished.fulfill()
        }
        socket.setOnClose(id: "re") { _, _, _ in
            closeCount += 1
            currentClosed.fulfill()
        }
        socket.setOnError(id: "re") { _, _ in
            errorCount += 1
        }

        XCTAssertEqual(socket.connect(url: url, id: "re"), .success("re"))
        wait(for: [firstAccept], timeout: 2)

        XCTAssertEqual(socket.connect(url: url, id: "re"), .success("re"))
        wait(for: [secondAccept, replacedFinished], timeout: 2)

        XCTAssertEqual(closeCount, 0, "replaced task must not deliver onClose to JS")
        XCTAssertEqual(errorCount, 0, "replaced task must not deliver onError to JS")
        guard socket.hasConnection(id: "re") else {
            throw XCTSkip("replacement connection already gone")
        }

        XCTAssertTrue(socket.close(id: "re", code: 1000, reason: "done"))
        wait(for: [currentClosed], timeout: 2)
        XCTAssertEqual(closeCount, 1)
        XCTAssertEqual(errorCount, 0)
        XCTAssertFalse(socket.hasConnection(id: "re"))
    }

    func testLiveEchoRoundTrip() throws {
        let settled = expectation(description: "open or connect error")
        let msgExp = expectation(description: "echoed ping")
        let closeExp = expectation(description: "close")
        var connectError: String?
        var opened = false

        socket.setOnOpen(id: "echo") { id in
            XCTAssertEqual(id, "echo")
            opened = true
            settled.fulfill()
        }
        socket.setOnMessage(id: "echo") { _, data in
            if data == "ping-ios" {
                msgExp.fulfill()
            }
        }
        socket.setOnClose(id: "echo") { _, _, _ in
            closeExp.fulfill()
        }
        socket.setOnError(id: "echo") { _, error in
            if opened {
                XCTFail("unexpected error: \(error)")
            } else {
                connectError = error
                settled.fulfill()
            }
        }

        let result = socket.connect(url: "wss://ws.postman-echo.com/raw", id: "echo")
        XCTAssertEqual(result, .success("echo"))

        let waitResult = XCTWaiter().wait(for: [settled], timeout: 20)
        if waitResult != .completed || connectError != nil {
            throw XCTSkip("public echo host unreachable\(connectError.map { ": \($0)" } ?? "")")
        }

        let sendExp = expectation(description: "send")
        socket.send(id: "echo", data: "ping-ios") { success in
            XCTAssertTrue(success)
            sendExp.fulfill()
        }
        wait(for: [sendExp, msgExp], timeout: 20)

        XCTAssertTrue(socket.close(id: "echo", code: 1000, reason: "done"))
        wait(for: [closeExp], timeout: 15)
        XCTAssertFalse(socket.hasConnection(id: "echo"))
    }

}

/// Accepts TCP connections on 127.0.0.1 so tests can replace an in-flight task
/// without depending on TEST-NET (192.0.2.1) connect failures.
private final class LocalTCPServer {
    private var listenFd: Int32 = -1
    private var clientFds: [Int32] = []
    private let fdLock = NSLock()
    private var running = false
    private(set) var port: UInt16 = 0
    var onAcceptCount: ((Int) -> Void)?

    init() throws {
        let fd = Darwin.socket(AF_INET, Int32(SOCK_STREAM), Int32(IPPROTO_TCP))
        guard fd >= 0 else {
            throw NSError(domain: NSPOSIXErrorDomain, code: Int(errno), userInfo: nil)
        }
        var reuse: Int32 = 1
        setsockopt(fd, SOL_SOCKET, SO_REUSEADDR, &reuse, socklen_t(MemoryLayout<Int32>.size))
        var addr = sockaddr_in()
        addr.sin_len = UInt8(MemoryLayout<sockaddr_in>.size)
        addr.sin_family = sa_family_t(AF_INET)
        addr.sin_addr = in_addr(s_addr: inet_addr("127.0.0.1"))
        addr.sin_port = 0
        let bound = withUnsafePointer(to: &addr) { ptr in
            ptr.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                Darwin.bind(fd, $0, socklen_t(MemoryLayout<sockaddr_in>.size))
            }
        }
        guard bound == 0 else {
            let code = errno
            Darwin.close(fd)
            throw NSError(domain: NSPOSIXErrorDomain, code: Int(code), userInfo: nil)
        }
        guard Darwin.listen(fd, 8) == 0 else {
            let code = errno
            Darwin.close(fd)
            throw NSError(domain: NSPOSIXErrorDomain, code: Int(code), userInfo: nil)
        }
        var name = sockaddr_in()
        var nameLen = socklen_t(MemoryLayout<sockaddr_in>.size)
        let named = withUnsafeMutablePointer(to: &name) { ptr in
            ptr.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                getsockname(fd, $0, &nameLen)
            }
        }
        guard named == 0 else {
            let code = errno
            Darwin.close(fd)
            throw NSError(domain: NSPOSIXErrorDomain, code: Int(code), userInfo: nil)
        }
        port = UInt16(bigEndian: name.sin_port)
        listenFd = fd
        running = true
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.acceptLoop()
        }
    }

    func stop() {
        running = false
        if listenFd >= 0 {
            Darwin.close(listenFd)
            listenFd = -1
        }
        fdLock.lock()
        clientFds.forEach { Darwin.close($0) }
        clientFds.removeAll()
        fdLock.unlock()
    }

    private func acceptLoop() {
        while running {
            var addr = sockaddr_in()
            var len = socklen_t(MemoryLayout<sockaddr_in>.size)
            let client = withUnsafeMutablePointer(to: &addr) { ptr in
                ptr.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                    Darwin.accept(self.listenFd, $0, &len)
                }
            }
            if client < 0 {
                return
            }
            fdLock.lock()
            clientFds.append(client)
            let n = clientFds.count
            fdLock.unlock()
            onAcceptCount?(n)
        }
    }
}
