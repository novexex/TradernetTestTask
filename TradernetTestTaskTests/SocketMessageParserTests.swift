//
//  SocketMessageParserTests.swift
//  TradernetTestTaskTests
//

import XCTest
@testable import TradernetTestTask

final class SocketMessageParserTests: XCTestCase {

    private let parser = SocketMessageParser()

    // MARK: - Payload Parsing

    func testParseQuoteEvent() {
        let payload = "[\"q\",{\"c\":\"SBER\",\"ltp\":237.49}]"
        let result = parser.parse(payload)

        XCTAssertNotNil(result)
        XCTAssertEqual(result?.event, "q")

        let data = result?.data as? [String: Any]
        XCTAssertNotNil(data)
        XCTAssertEqual(data?["c"] as? String, "SBER")
        XCTAssertEqual(data?["ltp"] as? Double, 237.49)
    }

    func testParseQuotesSubscribeEvent() {
        let payload = "[\"quotes\",[\"AAPL\",\"GAZP\"]]"
        let result = parser.parse(payload)

        XCTAssertNotNil(result)
        XCTAssertEqual(result?.event, "quotes")

        let tickers = result?.data as? [String]
        XCTAssertEqual(tickers, ["AAPL", "GAZP"])
    }

    func testParseEventWithNoData() {
        let payload = "[\"ping\"]"
        let result = parser.parse(payload)

        XCTAssertNotNil(result)
        XCTAssertEqual(result?.event, "ping")
        XCTAssertNil(result?.data)
    }

    func testParseInvalidJSON() {
        let result = parser.parse("not json")
        XCTAssertNil(result)
    }

    func testParseEmptyArray() {
        let result = parser.parse("[]")
        XCTAssertNil(result)
    }

    func testParseNonStringEvent() {
        let result = parser.parse("[123,\"data\"]")
        XCTAssertNil(result)
    }

    // MARK: - Frame Detection

    func testDetectPingFrame() {
        let frame = parser.detectFrame("2")
        if case .ping = frame {} else {
            XCTFail("Expected .ping, got \(frame)")
        }
    }

    func testDetectPongFrame() {
        let frame = parser.detectFrame("3")
        if case .pong = frame {} else {
            XCTFail("Expected .pong, got \(frame)")
        }
    }

    func testDetectSocketIOEvent() {
        let frame = parser.detectFrame("42[\"q\",{\"c\":\"SBER\"}]")
        if case .socketIOEvent(let payload) = frame {
            XCTAssertEqual(payload, "[\"q\",{\"c\":\"SBER\"}]")
        } else {
            XCTFail("Expected .socketIOEvent, got \(frame)")
        }
    }

    func testDetectRawJSONEvent() {
        let frame = parser.detectFrame("[\"q\",{\"c\":\"SBER\"}]")
        if case .rawJSONEvent(let payload) = frame {
            XCTAssertEqual(payload, "[\"q\",{\"c\":\"SBER\"}]")
        } else {
            XCTFail("Expected .rawJSONEvent, got \(frame)")
        }
    }

    func testDetectUnknownFrame() {
        let frame = parser.detectFrame("0{\"sid\":\"abc\"}")
        if case .unknown = frame {} else {
            XCTFail("Expected .unknown, got \(frame)")
        }
    }

    func testPingConstant() {
        XCTAssertEqual(parser.pingFrame, "2")
    }

    func testPongConstant() {
        XCTAssertEqual(parser.pongFrame, "3")
    }
}
