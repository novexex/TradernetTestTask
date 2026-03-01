//
//  Quotir.swift
//  TradernetTestTask
//

import UIKit

enum Quotir {

    static func flash(view: UIView, direction: Quote.ChangeDirection) {
        let color = QuoteFormatter.color(for: direction)
        let originalColor = view.backgroundColor

        UIView.animate(withDuration: 0.15, animations: {
            view.backgroundColor = color.withAlphaComponent(0.3)
        }) { _ in
            UIView.animate(withDuration: 0.6) {
                view.backgroundColor = originalColor
            }
        }
    }
}
