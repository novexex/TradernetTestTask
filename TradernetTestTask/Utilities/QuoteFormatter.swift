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
        case .up: return UIColor(red: 76/255, green: 175/255, blue: 80/255, alpha: 1)   // #4CAF50
        case .down: return UIColor(red: 244/255, green: 67/255, blue: 54/255, alpha: 1)  // #F44336
        case .none: return UIColor(red: 150/255, green: 150/255, blue: 150/255, alpha: 1) // gray
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

    private static func formatDecimal(_ value: Double, minFraction: Int, maxFraction: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = minFraction
        formatter.maximumFractionDigits = maxFraction
        formatter.groupingSeparator = " "
        formatter.decimalSeparator = "."
        formatter.usesGroupingSeparator = true
        return formatter.string(from: NSNumber(value: value)) ?? "\(value)"
    }
}
