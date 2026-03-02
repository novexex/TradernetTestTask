//
//  SocketMessageParser.swift
//  TradernetTestTask
//

import Foundation

struct ParsedMessage {
    let event: String
    let data: Any?
}

enum FrameType {
    case ping
    case pong
    case socketIOEvent(payload: String)
    case rawJSONEvent(payload: String)
    case unknown
}

protocol SocketMessageParsing {
    var pingFrame: String { get }
    var pongFrame: String { get }
    func detectFrame(_ text: String) -> FrameType
    func parse(_ payload: String) -> ParsedMessage?
}

struct SocketMessageParser: SocketMessageParsing {

    let pingFrame = "2"
    let pongFrame = "3"
    private let socketIOPrefix = "42"

    func detectFrame(_ text: String) -> FrameType {
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

    func parse(_ payload: String) -> ParsedMessage? {
        guard let data = payload.data(using: .utf8),
              let array = try? JSONSerialization.jsonObject(with: data) as? [Any],
              let event = array.first as? String else {
            return nil
        }
        let eventData = array.count > 1 ? array[1] : nil
        return ParsedMessage(event: event, data: eventData)
    }
}
