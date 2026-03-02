//
//  QuotesCoordinator.swift
//  TradernetTestTask
//

import UIKit

protocol QuotesCoordinating: AnyObject {
    func showDetail(for quote: Quote)
}

final class QuotesCoordinator: QuotesCoordinating {

    private weak var navigationController: UINavigationController?
    private let imageLoader: ImageLoading

    init(navigationController: UINavigationController, imageLoader: ImageLoading) {
        self.navigationController = navigationController
        self.imageLoader = imageLoader
    }

    func showDetail(for quote: Quote) {
        let detailVC = QuoteDetailViewController(quote: quote, imageLoader: imageLoader)
        navigationController?.pushViewController(detailVC, animated: true)
    }
}
