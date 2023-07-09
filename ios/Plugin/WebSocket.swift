import Foundation

@objc public class WebSocket: NSObject {
    @objc public func echo(_ value: String) -> String {
        print(value)
        return value
    }
}
