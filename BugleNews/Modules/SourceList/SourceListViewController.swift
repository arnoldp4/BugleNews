//
//  SourceListViewController.swift
//  BugleNews
//
//  Created by Arnold Pangestu on 19/11/26.
//

import UIKit

final class SourceListViewController: UIViewController {
    private let presenter: SourceListPresenterSpecs
    private var state = SourceListViewState(
        title: "Sources",
        items: [],
        isLoading: false,
        errorMessage: nil,
        emptyMessage: nil
    )

    private lazy var searchBar: UISearchBar = {
        let bar = UISearchBar()
        bar.translatesAutoresizingMaskIntoConstraints = false
        bar.placeholder = "Search sources..."
        bar.delegate = self
        return bar
    }()

    private lazy var tableView: UITableView = {
        let table = UITableView(frame: .zero, style: .plain)
        table.translatesAutoresizingMaskIntoConstraints = false
        table.dataSource = self
        table.delegate = self
        table.rowHeight = UITableView.automaticDimension
        table.estimatedRowHeight = 76
        table.register(UITableViewCell.self, forCellReuseIdentifier: "SourceCell")
        return table
    }()

    private lazy var statusLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.numberOfLines = 0
        label.textAlignment = .center
        label.isHidden = true
        return label
    }()

    private lazy var retryButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Retry", for: .normal)
        button.isHidden = true
        button.addTarget(self, action: #selector(handleRetryTapped), for: .touchUpInside)
        return button
    }()

    init(presenter: SourceListPresenterSpecs) {
        self.presenter = presenter
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        setupConstraints()
        presenter.viewDidLoad()
    }
}

private extension SourceListViewController {
    func setupViews() {
        view.backgroundColor = .systemBackground
        title = state.title
        view.addSubview(searchBar)
        view.addSubview(tableView)
        view.addSubview(statusLabel)
        view.addSubview(retryButton)
    }

    func setupConstraints() {
        NSLayoutConstraint.activate([
            searchBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            searchBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            searchBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            tableView.topAnchor.constraint(equalTo: searchBar.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            statusLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            statusLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -20),
            statusLabel.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 24),
            statusLabel.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -24),

            retryButton.topAnchor.constraint(equalTo: statusLabel.bottomAnchor, constant: 12),
            retryButton.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
    }

    @objc func handleRetryTapped() {
        presenter.didTapRetry()
    }
}

extension SourceListViewController: SourceListViewSpecs {
    func render(state: SourceListViewState) {
        self.state = state
        title = state.title
        tableView.reloadData()

        if let errorMessage = state.errorMessage {
            statusLabel.text = errorMessage
            statusLabel.isHidden = false
            retryButton.isHidden = false
            tableView.isHidden = true
        } else if let emptyMessage = state.emptyMessage {
            statusLabel.text = emptyMessage
            statusLabel.isHidden = false
            retryButton.isHidden = true
            tableView.isHidden = true
        } else if state.isLoading {
            statusLabel.text = "Loading sources..."
            statusLabel.isHidden = false
            retryButton.isHidden = true
            tableView.isHidden = true
        } else {
            statusLabel.isHidden = true
            retryButton.isHidden = true
            tableView.isHidden = false
        }
    }
}

extension SourceListViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        state.items.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SourceCell", for: indexPath)
        let item = state.items[indexPath.row]
        var content = cell.defaultContentConfiguration()
        content.text = item.name
        content.secondaryText = item.subtitle
        cell.contentConfiguration = content
        presenter.loadNextPageIfNeeded(currentIndex: indexPath.row)
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        presenter.didSelectSource(at: indexPath.row)
    }
}

extension SourceListViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        presenter.searchQueryChanged(searchText)
    }

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
        presenter.searchQueryChanged(searchBar.text ?? "")
    }
}
