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
        button.setTitle("Retry", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        button.setTitleColor(Colors.green, for: .normal)
        button.isHidden = true
        return button
    }()

    private let activityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .medium)
        indicator.color = Colors.subtitle
        indicator.hidesWhenStopped = true
        return indicator
    }()

    // MARK: - Init

    init(viewModel: QuotesViewModel, imageLoader: ImageLoading, coordinator: QuotesCoordinating?) {
        self.viewModel = viewModel
        self.imageLoader = imageLoader
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
        title = "Quotes"
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

    // MARK: - Setup

    private func configureNavigationBar() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = Colors.background
        appearance.titleTextAttributes = [.foregroundColor: Colors.title]
        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
    }

    private func setupTableView() {
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

    private func setupStatusView() {
        let stack = UIStackView(arrangedSubviews: [activityIndicator, statusLabel, retryButton])
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
        activityIndicator.startAnimating()
    }

    @objc private func retryTapped() {
        statusLabel.isHidden = true
        retryButton.isHidden = true
        activityIndicator.startAnimating()
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
        cell.configure(with: quote, imageLoader: imageLoader)
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
        activityIndicator.stopAnimating()
        statusLabel.isHidden = true
        retryButton.isHidden = true

        for index in indexes {
            let indexPath = IndexPath(row: index, section: 0)
            if let cell = tableView.cellForRow(at: indexPath) as? QuoteCell {
                let quote = viewModel.quotes[index]
                cell.configure(with: quote, imageLoader: imageLoader)
            }
        }
    }

    func quotesDidReload() {
        tableView.reloadData()
    }

    func quotesDidFailToConnect() {
        activityIndicator.stopAnimating()
        statusLabel.text = "Connection failed"
        statusLabel.isHidden = false
        retryButton.isHidden = false
    }

    func quotesDidConnect() {
        activityIndicator.stopAnimating()
        statusLabel.isHidden = true
        retryButton.isHidden = true
    }
}
