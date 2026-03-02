//
//  SocketMessageParserTests.swift
//  TradernetTestTaskTests
//

import XCTest
@testable import TradernetTestTask

final class SocketMessageParserTests: XCTestCase {

    // MARK: - Payload Parsing

    func testParseQuoteEvent() {
        let payload = "[\"q\",{\"c\":\"SBER\",\"ltp\":237.49}]"
        let result = SocketMessageParser.parse(payload)

        XCTAssertNotNil(result)
        XCTAssertEqual(result?.event, "q")

        let data = result?.data as? [String: Any]
        XCTAssertNotNil(data)
        XCTAssertEqual(data?["c"] as? String, "SBER")
        XCTAssertEqual(data?["ltp"] as? Double, 237.49)
    }

    func testParseQuotesSubscribeEvent() {
        let payload = "[\"quotes\",[\"AAPL\",\"GAZP\"]]"
        let result = SocketMessageParser.parse(payload)

        XCTAssertNotNil(result)
        XCTAssertEqual(result?.event, "quotes")

        let tickers = result?.data as? [String]
        XCTAssertEqual(tickers, ["AAPL", "GAZP"])
    }

    func testParseEventWithNoData() {
        let payload = "[\"ping\"]"
        let result = SocketMessageParser.parse(payload)

        XCTAssertNotNil(result)
        XCTAssertEqual(result?.event, "ping")
        XCTAssertNil(result?.data)
    }

    func testParseInvalidJSON() {
        let result = SocketMessageParser.parse("not json")
        XCTAssertNil(result)
    }

    func testParseEmptyArray() {
        let result = SocketMessageParser.parse("[]")
        XCTAssertNil(result)
    }

    func testParseNonStringEvent() {
        let result = SocketMessageParser.parse("[123,\"data\"]")
        XCTAssertNil(result)
    }

    // MARK: - Frame Detection

    func testDetectPingFrame() {
        let frame = SocketMessageParser.detectFrame("2")
        if case .ping = frame {} else {
            XCTFail("Expected .ping, got \(frame)")
        }
    }

    func testDetectPongFrame() {
        let frame = SocketMessageParser.detectFrame("3")
        if case .pong = frame {} else {
            XCTFail("Expected .pong, got \(frame)")
        }
    }

    func testDetectSocketIOEvent() {
        let frame = SocketMessageParser.detectFrame("42[\"q\",{\"c\":\"SBER\"}]")
        if case .socketIOEvent(let payload) = frame {
            XCTAssertEqual(payload, "[\"q\",{\"c\":\"SBER\"}]")
        } else {
            XCTFail("Expected .socketIOEvent, got \(frame)")
        }
    }

    func testDetectRawJSONEvent() {
        let frame = SocketMessageParser.detectFrame("[\"q\",{\"c\":\"SBER\"}]")
        if case .rawJSONEvent(let payload) = frame {
            XCTAssertEqual(payload, "[\"q\",{\"c\":\"SBER\"}]")
        } else {
            XCTFail("Expected .rawJSONEvent, got \(frame)")
        }
    }

    func testDetectUnknownFrame() {
        let frame = SocketMessageParser.detectFrame("0{\"sid\":\"abc\"}")
        if case .unknown = frame {} else {
            XCTFail("Expected .unknown, got \(frame)")
        }
    }

    func testPingConstant() {
        XCTAssertEqual(SocketMessageParser.pingFrame, "2")
    }

    func testPongConstant() {
        XCTAssertEqual(SocketMessageParser.pongFrame, "3")
    }
}
