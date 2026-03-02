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
    private let formatter: QuoteFormatting
    private let logoURLProvider: LogoURLProviding
    private let viewModel: QuotesViewModel

    init(navigationController: UINavigationController, imageLoader: ImageLoading, formatter: QuoteFormatting = QuoteFormatter(), logoURLProvider: LogoURLProviding = LogoURLProvider(), viewModel: QuotesViewModel) {
        self.navigationController = navigationController
        self.imageLoader = imageLoader
        self.formatter = formatter
        self.logoURLProvider = logoURLProvider
        self.viewModel = viewModel
    }

    func showDetail(for quote: Quote) {
        let detailVC = QuoteDetailViewController(quote: quote, imageLoader: imageLoader, formatter: formatter, logoURLProvider: logoURLProvider, viewModel: viewModel)
        navigationController?.pushViewController(detailVC, animated: true)
    }
}
