//
//  QuoteDetailViewController.swift
//  TradernetTestTask
//

import UIKit
import SnapKit

final class QuoteDetailViewController: UIViewController {

    private let quote: Quote

    // MARK: - UI Elements

    private let logoImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        iv.clipsToBounds = true
        iv.layer.cornerRadius = 32
        iv.backgroundColor = UIColor(red: 230/255, green: 230/255, blue: 230/255, alpha: 1)
        return iv
    }()

    private let tickerLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 28, weight: .bold)
        label.textColor = UIColor(red: 33/255, green: 33/255, blue: 33/255, alpha: 1)
        label.textAlignment = .center
        return label
    }()

    private let nameLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 15, weight: .regular)
        label.textColor = UIColor(red: 120/255, green: 120/255, blue: 120/255, alpha: 1)
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()

    private let priceLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 36, weight: .semibold)
        label.textColor = UIColor(red: 33/255, green: 33/255, blue: 33/255, alpha: 1)
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

    // MARK: - Init

    init(quote: Quote) {
        self.quote = quote
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        title = quote.ticker
        setupLayout()
        configure()
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

    private func configure() {
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

        // Price
        priceLabel.text = QuoteFormatter.formatPrice(quote.lastTradePrice, minStep: quote.minStep)

        // Change
        let percentText = QuoteFormatter.formatPercentChange(quote.percentChange)
        let pointText = QuoteFormatter.formatPointChange(quote.pointChange, minStep: quote.minStep)
        changeLabel.text = "\(percentText)  ( \(pointText) )"
        changeLabel.textColor = QuoteFormatter.color(for: quote.changeDirection)

        // Info rows
        addInfoRow(title: "Ticker", value: quote.ticker)
        if let exchange = quote.lastTradeExchange {
            addInfoRow(title: "Exchange", value: exchange)
        }
        if let name = quote.name {
            addInfoRow(title: "Name", value: name)
        }
        if let price = quote.lastTradePrice {
            addInfoRow(title: "Last Trade Price", value: QuoteFormatter.formatPrice(price, minStep: quote.minStep))
        }
        if let pcp = quote.percentChange {
            addInfoRow(title: "Change (%)", value: QuoteFormatter.formatPercentChange(pcp))
        }
        if let chg = quote.pointChange {
            addInfoRow(title: "Change (pts)", value: QuoteFormatter.formatPointChange(chg, minStep: quote.minStep))
        }
        if let step = quote.minStep {
            addInfoRow(title: "Min Step", value: "\(step)")
        }

        // Logo
        if let url = Constants.logoURL(for: quote.ticker) {
            ImageLoader.shared.loadImage(from: url) { [weak self] image in
                self?.logoImageView.image = image
            }
        }
    }

    private func addInfoRow(title: String, value: String) {
        let row = UIStackView()
        row.axis = .horizontal
        row.distribution = .fill

        let titleLabel = UILabel()
        titleLabel.font = .systemFont(ofSize: 15, weight: .regular)
        titleLabel.textColor = UIColor(red: 120/255, green: 120/255, blue: 120/255, alpha: 1)
        titleLabel.text = title

        let valueLabel = UILabel()
        valueLabel.font = .systemFont(ofSize: 15, weight: .medium)
        valueLabel.textColor = UIColor(red: 33/255, green: 33/255, blue: 33/255, alpha: 1)
        valueLabel.text = value
        valueLabel.textAlignment = .right

        row.addArrangedSubview(titleLabel)
        row.addArrangedSubview(valueLabel)

        let separator = UIView()
        separator.backgroundColor = UIColor(red: 230/255, green: 230/255, blue: 230/255, alpha: 1)

        infoStack.addArrangedSubview(row)
        infoStack.addArrangedSubview(separator)

        separator.snp.makeConstraints { make in
            make.height.equalTo(1)
            make.leading.trailing.equalToSuperview()
        }
    }
}
