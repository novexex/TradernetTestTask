//
//  QuoteFormatter.swift
//  TradernetTestTask
//

import Foundation

protocol QuoteFormatting {
    func formatPercentChange(_ value: Double?) -> String
    func formatPrice(_ value: Double?, minStep: Double?) -> String
    func formatPointChange(_ value: Double?, minStep: Double?) -> String
    func formatPriceWithChange(price: Double?, change: Double?, minStep: Double?) -> String
    func decimalPlaces(for minStep: Double?) -> Int
}

struct QuoteFormatter: QuoteFormatting {

    // MARK: - Percentage

    func formatPercentChange(_ value: Double?) -> String {
        guard let value = value else { return "" }
        let sign = value > 0 ? "+" : ""
        return "\(sign)\(formatDecimal(value, minFraction: 2, maxFraction: 2))%"
    }

    // MARK: - Price

    func formatPrice(_ value: Double?, minStep: Double?) -> String {
        guard let value = value else { return "" }
        let decimals = decimalPlaces(for: minStep)
        return formatDecimal(value, minFraction: decimals, maxFraction: decimals)
    }

    // MARK: - Point Change

    func formatPointChange(_ value: Double?, minStep: Double?) -> String {
        guard let value = value else { return "" }
        let decimals = decimalPlaces(for: minStep)
        let sign = value > 0 ? "+" : ""
        return "\(sign)\(formatDecimal(value, minFraction: decimals, maxFraction: decimals))"
    }

    // MARK: - Price + Change combined

    func formatPriceWithChange(price: Double?, change: Double?, minStep: Double?) -> String {
        let priceStr = formatPrice(price, minStep: minStep)
        let changeStr = formatPointChange(change, minStep: minStep)
        if priceStr.isEmpty { return "" }
        if changeStr.isEmpty { return priceStr }
        return "\(priceStr) ( \(changeStr) )"
    }

    // MARK: - Helpers

    func decimalPlaces(for minStep: Double?) -> Int {
        guard let minStep = minStep, minStep > 0 else { return 2 }
        let str = String(minStep)
        if let dotIndex = str.firstIndex(of: ".") {
            let afterDot = str[str.index(after: dotIndex)...]
            let trimmed = afterDot.replacingOccurrences(of: "0+$", with: "", options: .regularExpression)
            return max(trimmed.count, 1)
        }
        return 0
    }

    // MARK: - Private

    private func makeDecimalFormatter(minFraction: Int, maxFraction: Int) -> NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = " "
        formatter.decimalSeparator = "."
        formatter.usesGroupingSeparator = true
        formatter.minimumFractionDigits = minFraction
        formatter.maximumFractionDigits = maxFraction
        return formatter
    }

    private func formatDecimal(_ value: Double, minFraction: Int, maxFraction: Int) -> String {
        let formatter = makeDecimalFormatter(minFraction: minFraction, maxFraction: maxFraction)
        return formatter.string(from: NSNumber(value: value)) ?? "\(value)"
    }
}
