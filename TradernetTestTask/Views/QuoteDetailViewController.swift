//
//  QuoteDetailViewController.swift
//  TradernetTestTask
//

import UIKit
import SnapKit

final class QuoteDetailViewController: UIViewController {

    private var quote: Quote
    private let imageLoader: ImageLoading
    private let formatter: QuoteFormatting
    private let logoURLProvider: LogoURLProviding
    private let viewModel: QuotesViewModel
    private var observationId: UUID?

    // MARK: - UI Elements

    private let logoImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        iv.clipsToBounds = true
        iv.layer.cornerRadius = 32
        iv.backgroundColor = Colors.separator
        return iv
    }()

    private let tickerLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 28, weight: .bold)
        label.textColor = Colors.title
        label.textAlignment = .center
        return label
    }()

    private let nameLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 15, weight: .regular)
        label.textColor = Colors.subtitle
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()

    private let priceLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 36, weight: .semibold)
        label.textColor = Colors.title
        label.textAlignment = .center
        return label
    }()

    private let changeLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 17, weight: .medium)
        label.textAlignment = .center
        return label
    }()

    private let infoStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 12
        return stack
    }()

    private var infoValueLabels: [QuoteKey: UILabel] = [:]

    // MARK: - Init

    init(quote: Quote, imageLoader: ImageLoading, formatter: QuoteFormatting = QuoteFormatter(), logoURLProvider: LogoURLProviding = LogoURLProvider(), viewModel: QuotesViewModel) {
        self.quote = quote
        self.imageLoader = imageLoader
        self.formatter = formatter
        self.logoURLProvider = logoURLProvider
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        if let id = observationId {
            viewModel.removeObservation(id)
        }
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = Colors.background
        title = quote.ticker
        setupLayout()
        configure(with: quote)
        loadLogo()

        observationId = viewModel.observeQuote(for: quote.ticker) { [weak self] updatedQuote in
            self?.quote = updatedQuote
            self?.updateDynamicContent(with: updatedQuote)
        }
    }

    // MARK: - Setup

    private func setupLayout() {
        let headerStack = UIStackView(arrangedSubviews: [logoImageView, tickerLabel, nameLabel])
        headerStack.axis = .vertical
        headerStack.spacing = 8
        headerStack.alignment = .center

        let priceStack = UIStackView(arrangedSubviews: [priceLabel, changeLabel])
        priceStack.axis = .vertical
        priceStack.spacing = 4
        priceStack.alignment = .center

        let mainStack = UIStackView(arrangedSubviews: [headerStack, priceStack, infoStack])
        mainStack.axis = .vertical
        mainStack.spacing = 24
        mainStack.alignment = .center

        view.addSubview(mainStack)

        logoImageView.snp.makeConstraints { make in
            make.width.height.equalTo(64)
        }

        mainStack.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(24)
            make.leading.equalToSuperview().offset(24)
            make.trailing.equalToSuperview().offset(-24)
        }

        infoStack.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
        }
    }

    // MARK: - Configure

    private func configure(with quote: Quote) {
        tickerLabel.text = quote.ticker

        // Name
        var nameParts: [String] = []
        if let exchange = quote.lastTradeExchange, !exchange.isEmpty {
            nameParts.append(exchange)
        }
        if let name = quote.name, !name.isEmpty {
            nameParts.append(name)
        }
        nameLabel.text = nameParts.joined(separator: " | ")

        updateDynamicContent(with: quote)

        // Info rows
        addInfoRow(key: .ticker, title: L10n.QuoteDetail.ticker, value: quote.ticker)
        addInfoRow(key: .lastTradeExchange, title: L10n.QuoteDetail.exchange, value: quote.lastTradeExchange)
        addInfoRow(key: .name, title: L10n.QuoteDetail.name, value: quote.name)
        addInfoRow(key: .lastTradePrice, title: L10n.QuoteDetail.lastTradePrice,
                   value: quote.lastTradePrice.map { formatter.formatPrice($0, minStep: quote.minStep) })
        addInfoRow(key: .percentChange, title: L10n.QuoteDetail.changePercent,
                   value: quote.percentChange.map { formatter.formatPercentChange($0) })
        addInfoRow(key: .pointChange, title: L10n.QuoteDetail.changePoints,
                   value: quote.pointChange.map { formatter.formatPointChange($0, minStep: quote.minStep) })
        addInfoRow(key: .minStep, title: L10n.QuoteDetail.minStep,
                   value: quote.minStep.map { "\($0)" })
    }

    private func updateDynamicContent(with quote: Quote) {
        // Price
        priceLabel.text = formatter.formatPrice(quote.lastTradePrice, minStep: quote.minStep)

        // Change
        let percentText = formatter.formatPercentChange(quote.percentChange)
        let pointText = formatter.formatPointChange(quote.pointChange, minStep: quote.minStep)
        changeLabel.text = "\(percentText)  ( \(pointText) )"
        changeLabel.textColor = Colors.color(for: quote.changeDirection)

        // Update info row values
        infoValueLabels[.lastTradePrice]?.text = quote.lastTradePrice.map {
            formatter.formatPrice($0, minStep: quote.minStep)
        }
        infoValueLabels[.percentChange]?.text = quote.percentChange.map {
            formatter.formatPercentChange($0)
        }
        infoValueLabels[.pointChange]?.text = quote.pointChange.map {
            formatter.formatPointChange($0, minStep: quote.minStep)
        }

        // Name/exchange might update too
        var nameParts: [String] = []
        if let exchange = quote.lastTradeExchange, !exchange.isEmpty {
            nameParts.append(exchange)
        }
        if let name = quote.name, !name.isEmpty {
            nameParts.append(name)
        }
        nameLabel.text = nameParts.joined(separator: " | ")
        infoValueLabels[.lastTradeExchange]?.text = quote.lastTradeExchange
        infoValueLabels[.name]?.text = quote.name
    }

    private func loadLogo() {
        guard let url = logoURLProvider.logoURL(for: quote.ticker) else { return }
        imageLoader.loadImage(from: url) { [weak self] image in
            self?.logoImageView.image = image
        }
    }

    private func addInfoRow(key: QuoteKey, title: String, value: String?) {
        guard let value else { return }

        let row = UIStackView()
        row.axis = .horizontal
        row.distribution = .fill

        let titleLabel = UILabel()
        titleLabel.font = .systemFont(ofSize: 15, weight: .regular)
        titleLabel.textColor = Colors.subtitle
        titleLabel.text = title

        let valueLabel = UILabel()
        valueLabel.font = .systemFont(ofSize: 15, weight: .medium)
        valueLabel.textColor = Colors.title
        valueLabel.text = value
        valueLabel.textAlignment = .right

        infoValueLabels[key] = valueLabel

        row.addArrangedSubview(titleLabel)
        row.addArrangedSubview(valueLabel)

        let separator = UIView()
        separator.backgroundColor = Colors.separator

        infoStack.addArrangedSubview(row)
        infoStack.addArrangedSubview(separator)

        separator.snp.makeConstraints { make in
            make.height.equalTo(1)
            make.leading.trailing.equalToSuperview()
        }
    }
}
