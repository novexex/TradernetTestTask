//
//  QuoteFormatter.swift
//  TradernetTestTask
//

import UIKit

enum QuoteFormatter {

    // MARK: - Percentage

    static func formatPercentChange(_ value: Double?) -> String {
        guard let value = value else { return "" }
        let sign = value > 0 ? "+" : ""
        return "\(sign)\(formatDecimal(value, minFraction: 2, maxFraction: 2))%"
    }

    // MARK: - Price

    static func formatPrice(_ value: Double?, minStep: Double?) -> String {
        guard let value = value else { return "" }
        let decimals = decimalPlaces(for: minStep)
        return formatDecimal(value, minFraction: decimals, maxFraction: decimals)
    }

    // MARK: - Point Change

    static func formatPointChange(_ value: Double?, minStep: Double?) -> String {
        guard let value = value else { return "" }
        let decimals = decimalPlaces(for: minStep)
        let sign = value > 0 ? "+" : ""
        return "\(sign)\(formatDecimal(value, minFraction: decimals, maxFraction: decimals))"
    }

    // MARK: - Price + Change combined

    static func formatPriceWithChange(price: Double?, change: Double?, minStep: Double?) -> String {
        let priceStr = formatPrice(price, minStep: minStep)
        let changeStr = formatPointChange(change, minStep: minStep)
        if priceStr.isEmpty { return "" }
        if changeStr.isEmpty { return priceStr }
        return "\(priceStr) ( \(changeStr) )"
    }

    // MARK: - Colors

    static func color(for direction: Quote.ChangeDirection) -> UIColor {
        switch direction {
        case .up: return Colors.green
        case .down: return Colors.red
        case .none: return Colors.placeholder
        }
    }

    // MARK: - Helpers

    static func decimalPlaces(for minStep: Double?) -> Int {
        guard let minStep = minStep, minStep > 0 else { return 2 }
        let str = String(minStep)
        if let dotIndex = str.firstIndex(of: ".") {
            let afterDot = str[str.index(after: dotIndex)...]
            // Trim trailing zeros for a cleaner count
            let trimmed = afterDot.replacingOccurrences(of: "0+$", with: "", options: .regularExpression)
            return max(trimmed.count, 1)
        }
        return 0
    }

    private static func makeDecimalFormatter(minFraction: Int, maxFraction: Int) -> NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = " "
        formatter.decimalSeparator = "."
        formatter.usesGroupingSeparator = true
        formatter.minimumFractionDigits = minFraction
        formatter.maximumFractionDigits = maxFraction
        return formatter
    }

    private static func formatDecimal(_ value: Double, minFraction: Int, maxFraction: Int) -> String {
        let formatter = makeDecimalFormatter(minFraction: minFraction, maxFraction: maxFraction)
        return formatter.string(from: NSNumber(value: value)) ?? "\(value)"
    }
}
