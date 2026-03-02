//
//  QuoteFormatterTests.swift
//  TradernetTestTaskTests
//

import XCTest
@testable import TradernetTestTask

final class QuoteFormatterTests: XCTestCase {

    private let formatter = QuoteFormatter()

    // MARK: - Percent Change

    func testFormatPositivePercent() {
        let result = formatter.formatPercentChange(3.37)
        XCTAssertEqual(result, "+3.37%")
    }

    func testFormatNegativePercent() {
        let result = formatter.formatPercentChange(-0.22)
        XCTAssertEqual(result, "-0.22%")
    }

    func testFormatZeroPercent() {
        let result = formatter.formatPercentChange(0.0)
        XCTAssertEqual(result, "0.00%")
    }

    func testFormatNilPercent() {
        let result = formatter.formatPercentChange(nil)
        XCTAssertEqual(result, "")
    }

    // MARK: - Price

    func testFormatPriceWithMinStep() {
        let result = formatter.formatPrice(201.73, minStep: 0.01)
        XCTAssertEqual(result, "201.73")
    }

    func testFormatLargePrice() {
        let result = formatter.formatPrice(31435.0, minStep: 1.0)
        XCTAssertTrue(result.contains("31"))
        XCTAssertTrue(result.contains("435"))
    }

    func testFormatPriceNilValue() {
        let result = formatter.formatPrice(nil, minStep: 0.01)
        XCTAssertEqual(result, "")
    }

    func testFormatPriceNilMinStep() {
        // Defaults to 2 decimal places
        let result = formatter.formatPrice(100.5, minStep: nil)
        XCTAssertEqual(result, "100.50")
    }

    // MARK: - Point Change

    func testFormatPositivePointChange() {
        let result = formatter.formatPointChange(1.73, minStep: 0.01)
        XCTAssertEqual(result, "+1.73")
    }

    func testFormatNegativePointChange() {
        let result = formatter.formatPointChange(-0.0005, minStep: 0.0001)
        XCTAssertTrue(result.hasPrefix("-"))
    }

    func testFormatNilPointChange() {
        let result = formatter.formatPointChange(nil, minStep: 0.01)
        XCTAssertEqual(result, "")
    }

    // MARK: - Price With Change

    func testFormatPriceWithChange() {
        let result = formatter.formatPriceWithChange(price: 201.73, change: 1.73, minStep: 0.01)
        XCTAssertTrue(result.contains("201.73"))
        XCTAssertTrue(result.contains("+1.73"))
    }

    func testFormatPriceWithChangeNilPrice() {
        let result = formatter.formatPriceWithChange(price: nil, change: 1.0, minStep: 0.01)
        XCTAssertEqual(result, "")
    }

    // MARK: - Decimal Places

    func testDecimalPlacesForSmallStep() {
        XCTAssertEqual(formatter.decimalPlaces(for: 0.01), 2)
    }

    func testDecimalPlacesForWholeStep() {
        XCTAssertEqual(formatter.decimalPlaces(for: 1.0), 1)
    }

    func testDecimalPlacesForNil() {
        XCTAssertEqual(formatter.decimalPlaces(for: nil), 2)
    }

    func testDecimalPlacesForZero() {
        XCTAssertEqual(formatter.decimalPlaces(for: 0.0), 2)
    }

    // MARK: - Color

    func testColorForUp() {
        let color = Colors.color(for: .up)
        XCTAssertEqual(color, Colors.green)
    }

    func testColorForDown() {
        let color = Colors.color(for: .down)
        XCTAssertEqual(color, Colors.red)
    }

    func testColorForNone() {
        let color = Colors.color(for: .none)
        XCTAssertEqual(color, Colors.placeholder)
    }
}
