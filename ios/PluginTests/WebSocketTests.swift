import XCTest
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

    func testResolvedIdDefaultsToDefault() {
        XCTAssertEqual(WebSocket.resolvedId(nil), "default")
        XCTAssertEqual(WebSocket.resolvedId(""), "default")
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

    func testLiveEchoRoundTrip() {
        let openExp = expectation(description: "open")
        let msgExp = expectation(description: "echoed ping")
        let closeExp = expectation(description: "close")

        socket.setOnOpen(id: "echo") { id in
            XCTAssertEqual(id, "echo")
            openExp.fulfill()
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
            XCTFail("unexpected error: \(error)")
        }

        let result = socket.connect(url: "wss://ws.postman-echo.com/raw", id: "echo")
        XCTAssertEqual(result, .success("echo"))
        wait(for: [openExp], timeout: 20)

        let sendExp = expectation(description: "send")
        socket.send(id: "echo", data: "ping-ios") { success in
            XCTAssertTrue(success)
            sendExp.fulfill()
        }
        wait(for: [sendExp, msgExp], timeout: 20)

        XCTAssertTrue(socket.close(id: "echo", code: 1000, reason: "done"))
        wait(for: [closeExp], timeout: 15)
    }

}
