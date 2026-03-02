//
//  QuotesViewController.swift
//  TradernetTestTask
//

import UIKit
import SnapKit

final class QuotesViewController: UIViewController {

    private let tableView = UITableView()
    private let viewModel: QuotesViewModel
    private let imageLoader: ImageLoading
    private let formatter: QuoteFormatting
    private let logoURLProvider: LogoURLProviding
    private weak var coordinator: QuotesCoordinating?

    private let statusLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 15, weight: .medium)
        label.textColor = Colors.subtitle
        label.textAlignment = .center
        label.numberOfLines = 0
        label.isHidden = true
        return label
    }()

    private let retryButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle(L10n.Quotes.retry, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        button.setTitleColor(Colors.green, for: .normal)
        button.isHidden = true
        return button
    }()

    // MARK: - Init

    init(viewModel: QuotesViewModel, imageLoader: ImageLoading, formatter: QuoteFormatting = QuoteFormatter(), logoURLProvider: LogoURLProviding = LogoURLProvider(), coordinator: QuotesCoordinating?) {
        self.viewModel = viewModel
        self.imageLoader = imageLoader
        self.formatter = formatter
        self.logoURLProvider = logoURLProvider
        self.coordinator = coordinator
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = Colors.background
        title = L10n.Quotes.title
        configureNavigationBar()
        setupTableView()
        setupStatusView()
        viewModel.delegate = self
        viewModel.start()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        if isMovingFromParent {
            viewModel.stop()
        }
    }
}

// MARK: - Private

private extension QuotesViewController {

    func configureNavigationBar() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = Colors.background
        appearance.titleTextAttributes = [.foregroundColor: Colors.title]
        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
    }

    func setupTableView() {
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(QuoteCell.self, forCellReuseIdentifier: QuoteCell.reuseIdentifier)
        tableView.rowHeight = 68
        tableView.separatorInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 0)
        tableView.backgroundColor = Colors.background

        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    func setupStatusView() {
        let stack = UIStackView(arrangedSubviews: [statusLabel, retryButton])
        stack.axis = .vertical
        stack.spacing = 12
        stack.alignment = .center

        view.addSubview(stack)
        stack.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.leading.greaterThanOrEqualToSuperview().offset(32)
            make.trailing.lessThanOrEqualToSuperview().offset(-32)
        }

        retryButton.addTarget(self, action: #selector(retryTapped), for: .touchUpInside)
    }

    @objc func retryTapped() {
        statusLabel.isHidden = true
        retryButton.isHidden = true
        viewModel.retry()
    }
}

// MARK: - UITableViewDataSource

extension QuotesViewController: UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.quotes.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: QuoteCell.reuseIdentifier,
            for: indexPath
        ) as? QuoteCell else {
            return UITableViewCell()
        }
        let quote = viewModel.quotes[indexPath.row]
        cell.configure(with: quote, imageLoader: imageLoader, formatter: formatter, logoURLProvider: logoURLProvider)
        return cell
    }
}

// MARK: - UITableViewDelegate

extension QuotesViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let quote = viewModel.quotes[indexPath.row]
        coordinator?.showDetail(for: quote)
    }
}

// MARK: - QuotesViewModelDelegate

extension QuotesViewController: QuotesViewModelDelegate {

    func quotesDidUpdate(at indexes: [Int]) {
        statusLabel.isHidden = true
        retryButton.isHidden = true

        for index in indexes {
            let indexPath = IndexPath(row: index, section: 0)
            if let cell = tableView.cellForRow(at: indexPath) as? QuoteCell {
                let quote = viewModel.quotes[index]
                cell.configure(with: quote, imageLoader: imageLoader, formatter: formatter, logoURLProvider: logoURLProvider)
            }
        }
    }

    func quotesDidReload() {
        tableView.reloadData()
    }

    func quotesDidFailToConnect() {
        statusLabel.text = L10n.Quotes.connectionFailed
        statusLabel.isHidden = false
        retryButton.isHidden = false
    }

    func quotesDidConnect() {
        statusLabel.isHidden = true
        retryButton.isHidden = true
    }
}
