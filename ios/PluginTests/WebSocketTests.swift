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
}
