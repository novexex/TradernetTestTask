//
//  SocketMessageParser.swift
//  TradernetTestTask
//

import Foundation

enum SocketMessageParser {

    struct ParsedMessage {
        let event: String
        let data: Any?
    }

    // MARK: - Engine.IO Frame Types

    enum FrameType {
        case ping
        case pong
        case socketIOEvent(payload: String)
        case rawJSONEvent(payload: String)
        case unknown
    }

    // MARK: - Engine.IO Constants

    static let pingFrame = "2"
    static let pongFrame = "3"
    private static let socketIOPrefix = "42"

    // MARK: - Frame Detection

    static func detectFrame(_ text: String) -> FrameType {
        if text == pingFrame { return .ping }
        if text == pongFrame { return .pong }
        if text.hasPrefix(socketIOPrefix) {
            return .socketIOEvent(payload: String(text.dropFirst(socketIOPrefix.count)))
        }
        if text.hasPrefix("[") {
            return .rawJSONEvent(payload: text)
        }
        return .unknown
    }

    // MARK: - Payload Parsing

    static func parse(_ payload: String) -> ParsedMessage? {
        guard let data = payload.data(using: .utf8),
              let array = try? JSONSerialization.jsonObject(with: data) as? [Any],
              let event = array.first as? String else {
            return nil
        }
        let eventData = array.count > 1 ? array[1] : nil
        return ParsedMessage(event: event, data: eventData)
    }
}
