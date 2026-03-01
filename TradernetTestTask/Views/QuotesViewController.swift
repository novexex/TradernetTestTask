//
//  QuotesViewController.swift
//  TradernetTestTask
//

import UIKit
import SnapKit

final class QuotesViewController: UIViewController {

    private let tableView = UITableView()
    private let viewModel: QuotesViewModel

    // MARK: - Init

    init(viewModel: QuotesViewModel? = nil) {
        let service = TradernetSocketService()
        self.viewModel = viewModel ?? QuotesViewModel(service: service)
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        title = "Quotes"
        configureNavigationBar()
        setupTableView()
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
        appearance.backgroundColor = .white
        appearance.titleTextAttributes = [.foregroundColor: UIColor(red: 33/255, green: 33/255, blue: 33/255, alpha: 1)]
        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
    }

    private func setupTableView() {
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(QuoteCell.self, forCellReuseIdentifier: QuoteCell.reuseIdentifier)
        tableView.rowHeight = 64
        tableView.separatorInset = UIEdgeInsets(top: 0, left: 60, bottom: 0, right: 0)
        tableView.backgroundColor = .white

        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
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
        let direction = viewModel.changeDirections[quote.ticker]
        cell.configure(with: quote, direction: direction)
        return cell
    }
}

// MARK: - UITableViewDelegate

extension QuotesViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

// MARK: - QuotesViewModelDelegate

extension QuotesViewController: QuotesViewModelDelegate {

    func quotesDidUpdate(at indexes: [Int]) {
        let indexPaths = indexes.map { IndexPath(row: $0, section: 0) }
        tableView.reloadRows(at: indexPaths, with: .none)
    }

    func quotesDidReload() {
        tableView.reloadData()
    }
}
