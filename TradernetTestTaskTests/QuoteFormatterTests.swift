//
//  QuoteFormatterTests.swift
//  TradernetTestTaskTests
//

import XCTest
@testable import TradernetTestTask

final class QuoteFormatterTests: XCTestCase {

    // MARK: - Percent Change

    func testFormatPositivePercent() {
        let result = QuoteFormatter.formatPercentChange(3.37)
        XCTAssertEqual(result, "+3.37%")
    }

    func testFormatNegativePercent() {
        let result = QuoteFormatter.formatPercentChange(-0.22)
        XCTAssertEqual(result, "-0.22%")
    }

    func testFormatZeroPercent() {
        let result = QuoteFormatter.formatPercentChange(0.0)
        XCTAssertEqual(result, "0.00%")
    }

    func testFormatNilPercent() {
        let result = QuoteFormatter.formatPercentChange(nil)
        XCTAssertEqual(result, "")
    }

    // MARK: - Price

    func testFormatPriceWithMinStep() {
        let result = QuoteFormatter.formatPrice(201.73, minStep: 0.01)
        XCTAssertEqual(result, "201.73")
    }

    func testFormatLargePrice() {
        let result = QuoteFormatter.formatPrice(31435.0, minStep: 1.0)
        XCTAssertTrue(result.contains("31"))
        XCTAssertTrue(result.contains("435"))
    }

    func testFormatPriceNilValue() {
        let result = QuoteFormatter.formatPrice(nil, minStep: 0.01)
        XCTAssertEqual(result, "")
    }

    func testFormatPriceNilMinStep() {
        // Defaults to 2 decimal places
        let result = QuoteFormatter.formatPrice(100.5, minStep: nil)
        XCTAssertEqual(result, "100.50")
    }

    // MARK: - Point Change

    func testFormatPositivePointChange() {
        let result = QuoteFormatter.formatPointChange(1.73, minStep: 0.01)
        XCTAssertEqual(result, "+1.73")
    }

    func testFormatNegativePointChange() {
        let result = QuoteFormatter.formatPointChange(-0.0005, minStep: 0.0001)
        XCTAssertTrue(result.hasPrefix("-"))
    }

    func testFormatNilPointChange() {
        let result = QuoteFormatter.formatPointChange(nil, minStep: 0.01)
        XCTAssertEqual(result, "")
    }

    // MARK: - Price With Change

    func testFormatPriceWithChange() {
        let result = QuoteFormatter.formatPriceWithChange(price: 201.73, change: 1.73, minStep: 0.01)
        XCTAssertTrue(result.contains("201.73"))
        XCTAssertTrue(result.contains("+1.73"))
    }

    func testFormatPriceWithChangeNilPrice() {
        let result = QuoteFormatter.formatPriceWithChange(price: nil, change: 1.0, minStep: 0.01)
        XCTAssertEqual(result, "")
    }

    // MARK: - Decimal Places

    func testDecimalPlacesForSmallStep() {
        XCTAssertEqual(QuoteFormatter.decimalPlaces(for: 0.01), 2)
    }

    func testDecimalPlacesForWholeStep() {
        XCTAssertEqual(QuoteFormatter.decimalPlaces(for: 1.0), 1)
    }

    func testDecimalPlacesForNil() {
        XCTAssertEqual(QuoteFormatter.decimalPlaces(for: nil), 2)
    }

    func testDecimalPlacesForZero() {
        XCTAssertEqual(QuoteFormatter.decimalPlaces(for: 0.0), 2)
    }

    // MARK: - Color

    func testColorForUp() {
        let color = QuoteFormatter.color(for: .up)
        XCTAssertNotNil(color)
    }

    func testColorForDown() {
        let color = QuoteFormatter.color(for: .down)
        XCTAssertNotNil(color)
    }

    func testColorForNone() {
        let color = QuoteFormatter.color(for: .none)
        XCTAssertNotNil(color)
    }
}
