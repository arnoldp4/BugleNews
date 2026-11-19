//
//  ArticleDetailViewController.swift
//  BugleNews
//
//  Created by Arnold Pangestu on 19/11/26.
//

import UIKit
import WebKit

final class ArticleDetailViewController: UIViewController {
    private let presenter: ArticleDetailPresenterSpecs

    private lazy var webView: WKWebView = {
        let configuration = WKWebViewConfiguration()
        let view = WKWebView(frame: .zero, configuration: configuration)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.navigationDelegate = self
        return view
    }()

    private lazy var progressView: UIProgressView = {
        let progress = UIProgressView(progressViewStyle: .bar)
        progress.translatesAutoresizingMaskIntoConstraints = false
        progress.isHidden = true
        return progress
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

    init(presenter: ArticleDetailPresenterSpecs) {
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

private extension ArticleDetailViewController {
    func setupViews() {
        view.backgroundColor = .systemBackground
        view.addSubview(webView)
        view.addSubview(progressView)
        view.addSubview(statusLabel)
        view.addSubview(retryButton)
    }

    func setupConstraints() {
        NSLayoutConstraint.activate([
            progressView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            progressView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            progressView.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            webView.topAnchor.constraint(equalTo: progressView.bottomAnchor),
            webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            webView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            statusLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            statusLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -16),
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

extension ArticleDetailViewController: ArticleDetailViewSpecs {
    func render(state: ArticleDetailViewState) {
        title = state.title
        progressView.isHidden = !state.isLoading
        if state.isLoading {
            progressView.setProgress(0.2, animated: false)
        }

        if let errorMessage = state.errorMessage {
            statusLabel.text = errorMessage
            statusLabel.isHidden = false
            retryButton.isHidden = false
            webView.isHidden = true
        } else {
            statusLabel.isHidden = true
            retryButton.isHidden = true
            webView.isHidden = false
        }
    }

    func load(url: URL) {
        let request = URLRequest(url: url)
        webView.load(request)
    }
}

extension ArticleDetailViewController: WKNavigationDelegate {
    func webView(_ webView: WKNavigation, didStartProvisionalNavigation navigation: WKNavigation!) {
        presenter.didStartLoading()
    }

    func webView(_ webView: WKNavigation, didFinish navigation: WKNavigation!) {
        progressView.setProgress(1.0, animated: true)
        presenter.didFinishLoading()
    }

    func webView(_ webView: WKNavigation, didFail navigation: WKNavigation!, withError error: Error) {
        presenter.didFailLoading(message: error.localizedDescription)
    }

    func webView(
        _ webView: WKNavigation,
        didFailProvisionalNavigation navigation: WKNavigation!,
        withError error: Error
    ) {
        presenter.didFailLoading(message: error.localizedDescription)
    }
}
