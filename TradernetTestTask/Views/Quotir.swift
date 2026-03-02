//
//  Quotir.swift
//  TradernetTestTask
//

import UIKit

enum Quotir {

    private static var restingColors = NSMapTable<UIView, UIColor>.weakToStrongObjects()

    static func flash(view: UIView, direction: Quote.ChangeDirection) {
        let color = QuoteFormatter.color(for: direction)

        // Store the resting color only on the first flash
        if restingColors.object(forKey: view) == nil {
            restingColors.setObject(view.backgroundColor ?? .clear, forKey: view)
        }
        let resting = restingColors.object(forKey: view) ?? .clear

        // Cancel any in-flight animation so we don't capture mid-flash state
        view.layer.removeAllAnimations()

        UIView.animate(withDuration: 0.15, animations: {
            view.backgroundColor = color.withAlphaComponent(0.3)
        }) { finished in
            UIView.animate(withDuration: 0.6, animations: {
                view.backgroundColor = resting
            }) { _ in
                self.restingColors.removeObject(forKey: view)
            }
        }
    }
}
