//
//  QuoteCell.swift
//  TradernetTestTask
//

import UIKit
import SnapKit

final class QuoteCell: UITableViewCell {

    static let reuseIdentifier = "QuoteCell"

    // MARK: - UI Elements

    private let logoImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        iv.clipsToBounds = true
        iv.layer.cornerRadius = 16
        iv.backgroundColor = UIColor(red: 230/255, green: 230/255, blue: 230/255, alpha: 1)
        return iv
    }()

    private let tickerLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 17, weight: .bold)
        label.textColor = UIColor(red: 33/255, green: 33/255, blue: 33/255, alpha: 1)
        return label
    }()

    private let subtitleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 13, weight: .regular)
        label.textColor = UIColor(red: 150/255, green: 150/255, blue: 150/255, alpha: 1)
        label.lineBreakMode = .byTruncatingTail
        return label
    }()

    private let percentBadge: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 15, weight: .semibold)
        label.textColor = .white
        label.textAlignment = .center
        label.layer.cornerRadius = 6
        label.clipsToBounds = true
        return label
    }()

    private let priceChangeLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 13, weight: .regular)
        label.textColor = UIColor(red: 100/255, green: 100/255, blue: 100/255, alpha: 1)
        label.textAlignment = .right
        return label
    }()

    // MARK: - Properties

    private var currentTicker: String?
    private var imageLoadTask: URLSessionDataTask?

    // MARK: - Init

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .white
        setupLayout()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        imageLoadTask?.cancel()
        imageLoadTask = nil
        logoImageView.image = nil
        currentTicker = nil
        percentBadge.isHidden = true
        priceChangeLabel.text = nil
        subtitleLabel.text = nil
    }

    // MARK: - Layout

    private func setupLayout() {
        let leftStack = UIStackView(arrangedSubviews: [tickerLabel, subtitleLabel])
        leftStack.axis = .vertical
        leftStack.spacing = 2

        let rightStack = UIStackView(arrangedSubviews: [percentBadge, priceChangeLabel])
        rightStack.axis = .vertical
        rightStack.spacing = 4
        rightStack.alignment = .trailing

        contentView.addSubview(logoImageView)
        contentView.addSubview(leftStack)
        contentView.addSubview(rightStack)

        logoImageView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(32)
        }

        leftStack.snp.makeConstraints { make in
            make.leading.equalTo(logoImageView.snp.trailing).offset(12)
            make.centerY.equalToSuperview()
            make.trailing.lessThanOrEqualTo(rightStack.snp.leading).offset(-8)
        }

        rightStack.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-16)
            make.centerY.equalToSuperview()
        }

        percentBadge.snp.makeConstraints { make in
            make.height.equalTo(28)
            make.width.greaterThanOrEqualTo(70)
        }

        // Internal padding for badge
        percentBadge.layoutMargins = UIEdgeInsets(top: 4, left: 8, bottom: 4, right: 8)
    }

    // MARK: - Configure

    func configure(with quote: Quote, direction: Quote.ChangeDirection?) {
        currentTicker = quote.ticker
        tickerLabel.text = quote.ticker

        // Subtitle: exchange | name
        var subtitleParts: [String] = []
        if let exchange = quote.lastTradeExchange, !exchange.isEmpty {
            subtitleParts.append(exchange)
        }
        if let name = quote.name, !name.isEmpty {
            subtitleParts.append(name)
        }
        subtitleLabel.text = subtitleParts.joined(separator: " | ")

        // Percent badge
        if quote.percentChange != nil {
            let percentText = QuoteFormatter.formatPercentChange(quote.percentChange)
            percentBadge.text = "  \(percentText)  "
            let badgeColor = QuoteFormatter.color(for: quote.changeDirection)
            percentBadge.backgroundColor = badgeColor
            percentBadge.isHidden = false
        } else {
            percentBadge.text = nil
            percentBadge.backgroundColor = .clear
            percentBadge.isHidden = true
        }

        // Price + change
        priceChangeLabel.text = QuoteFormatter.formatPriceWithChange(
            price: quote.lastTradePrice,
            change: quote.pointChange,
            minStep: quote.minStep
        )

        // Flash animation on update
        if let direction = direction, direction != .none {
            Quotir.flash(view: percentBadge, direction: direction)
        }

        // Load logo
        loadLogo(for: quote.ticker)
    }

    // MARK: - Logo Loading

    private func loadLogo(for ticker: String) {
        guard let url = Constants.logoURL(for: ticker) else { return }
        imageLoadTask = ImageLoader.shared.loadImage(from: url) { [weak self] image in
            guard let self = self, self.currentTicker == ticker else { return }
            self.logoImageView.image = image
        }
    }
}
