//
//  SocketMessageParserTests.swift
//  TradernetTestTaskTests
//

import XCTest
@testable import TradernetTestTask

final class SocketMessageParserTests: XCTestCase {

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
}
