import Foundation
import Capacitor

/**
 * Native WebSocket client for iOS, matching the Android plugin API.
 */
@objc(WebSocketPlugin)
public class WebSocketPlugin: CAPPlugin {
    private let implementation = WebSocket()

    @objc func connect(_ call: CAPPluginCall) {
        let result = implementation.connect(url: call.getString("url"), id: call.getString("id"))
        switch result {
        case .success:
            resolveOnMain(call)
        case .failure(let error):
            rejectOnMain(call, error.message)
        }
    }

    @objc func close(_ call: CAPPluginCall) {
        let id = WebSocket.resolvedId(call.getString("id"))
        let code = call.getInt("code") ?? WebSocket.defaultCloseCode
        let reason = call.getString("reason") ?? WebSocket.defaultCloseReason
        if implementation.close(id: id, code: code, reason: reason) {
            resolveOnMain(call)
        } else {
            rejectOnMain(call, "Close fail")
        }
    }

    @objc func send(_ call: CAPPluginCall) {
        guard let data = call.getString("data") else {
            rejectOnMain(call, "data can not null.")
            return
        }
        let id = WebSocket.resolvedId(call.getString("id"))
        implementation.send(id: id, data: data) { [weak self] success in
            if success {
                self?.resolveOnMain(call)
            } else {
                self?.rejectOnMain(call, "send message fail")
            }
        }
    }

    @objc func onOpen(_ call: CAPPluginCall) {
        let id = WebSocket.resolvedId(call.getString("id"))
        call.keepAlive = true
        implementation.setOnOpen(id: id) { connId in
            DispatchQueue.main.async {
                call.resolve([
                    "id": connId
                ])
            }
        }
    }

    @objc func onMessage(_ call: CAPPluginCall) {
        let id = WebSocket.resolvedId(call.getString("id"))
        call.keepAlive = true
        implementation.setOnMessage(id: id) { connId, data in
            DispatchQueue.main.async {
                call.resolve([
                    "id": connId,
                    "data": data
                ])
            }
        }
    }

    @objc func onClose(_ call: CAPPluginCall) {
        let id = WebSocket.resolvedId(call.getString("id"))
        call.keepAlive = true
        implementation.setOnClose(id: id) { connId, code, reason in
            DispatchQueue.main.async {
                call.resolve([
                    "id": connId,
                    "code": code,
                    "reason": reason
                ])
            }
        }
    }

    @objc func onError(_ call: CAPPluginCall) {
        let id = WebSocket.resolvedId(call.getString("id"))
        call.keepAlive = true
        implementation.setOnError(id: id) { connId, error in
            DispatchQueue.main.async {
                call.resolve([
                    "id": connId,
                    "error": error
                ])
            }
        }
    }

    private func resolveOnMain(_ call: CAPPluginCall) {
        DispatchQueue.main.async {
            call.resolve()
        }
    }

    private func rejectOnMain(_ call: CAPPluginCall, _ message: String) {
        DispatchQueue.main.async {
            call.reject(message)
        }
    }
}
