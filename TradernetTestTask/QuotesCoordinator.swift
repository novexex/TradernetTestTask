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
    private let viewModel: QuotesViewModel

    init(navigationController: UINavigationController, imageLoader: ImageLoading, viewModel: QuotesViewModel) {
        self.navigationController = navigationController
        self.imageLoader = imageLoader
        self.viewModel = viewModel
    }

    func showDetail(for quote: Quote) {
        let detailVC = QuoteDetailViewController(quote: quote, imageLoader: imageLoader, viewModel: viewModel)
        navigationController?.pushViewController(detailVC, animated: true)
    }
}
