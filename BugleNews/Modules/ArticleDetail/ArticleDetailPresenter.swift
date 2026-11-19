//
//  ArticleDetailPresenter.swift
//  BugleNews
//
//  Created by Arnold Pangestu on 19/11/26.
//

import Foundation

final class ArticleDetailPresenter {
    weak var view: ArticleDetailViewSpecs?

    private let interactor: ArticleDetailInteractorInputSpecs
    private let router: ArticleDetailRouterSpecs
    private let urlString: String
    private let articleTitle: String

    private var isLoading = false
    private var errorMessage: String?

    init(
        urlString: String,
        articleTitle: String,
        interactor: ArticleDetailInteractorInputSpecs,
        router: ArticleDetailRouterSpecs
    ) {
        self.urlString = urlString
        self.articleTitle = articleTitle
        self.interactor = interactor
        self.router = router
    }
}

extension ArticleDetailPresenter: ArticleDetailPresenterSpecs {
    func viewDidLoad() {
        isLoading = true
        errorMessage = nil
        publishState()
        interactor.validateArticleURL(urlString)
    }

    func didStartLoading() {
        isLoading = true
        errorMessage = nil
        publishState()
    }

    func didFinishLoading() {
        isLoading = false
        errorMessage = nil
        publishState()
    }

    func didFailLoading(message: String) {
        isLoading = false
        errorMessage = message.isEmpty ? "Failed to load article page." : message
        publishState()
    }

    func didTapRetry() {
        isLoading = true
        errorMessage = nil
        publishState()
        interactor.validateArticleURL(urlString)
    }
}

extension ArticleDetailPresenter: ArticleDetailInteractorOutputSpecs {
    func didValidateURL(_ url: URL) {
        isLoading = true
        errorMessage = nil
        publishState()
        view?.load(url: url)
    }

    func didFailValidatingURL(message: String) {
        isLoading = false
        errorMessage = message
        publishState()
    }
}

private extension ArticleDetailPresenter {
    func publishState() {
        let state = ArticleDetailViewState(
            title: articleTitle,
            isLoading: isLoading,
            errorMessage: errorMessage
        )
        view?.render(state: state)
    }
}
