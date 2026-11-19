//
//  ArticleListPresenter.swift
//  BugleNews
//
//  Created by Arnold Pangestu on 19/11/26.
//

import Foundation

final class ArticleListPresenter {
    weak var view: ArticleListViewSpecs?

    private let interactor: ArticleListInteractorInputSpecs
    private let router: ArticleListRouterSpecs
    private let source: NewsSource
    private let pageSize = 20

    private var articles: [NewsArticle] = []
    private var currentPage = 1
    private var isLoading = false
    private var hasMorePages = true
    private var currentQuery: String?
    
    private var failedPaginationPage: Int?

    init(
        source: NewsSource,
        interactor: ArticleListInteractorInputSpecs,
        router: ArticleListRouterSpecs
    ) {
        self.source = source
        self.interactor = interactor
        self.router = router
    }
}

extension ArticleListPresenter: ArticleListPresenterSpecs {
    func viewDidLoad() {
        resetAndLoad(query: nil)
    }

    func searchQueryChanged(_ query: String) {
        let normalized = query.trimmingCharacters(in: .whitespacesAndNewlines)
        resetAndLoad(query: normalized.isEmpty ? nil : normalized)
    }

    func loadNextPageIfNeeded(currentIndex: Int) {
        guard !isLoading, hasMorePages, !articles.isEmpty else { return }
        let thresholdIndex = max(0, articles.count - 4)
        if currentIndex >= thresholdIndex {
            isLoading = true
            let nextPage = currentPage + 1
            publishState(errorMessage: nil, emptyMessage: nil, alertError: nil)
            interactor.fetchArticles(sourceId: source.id, query: currentQuery, page: nextPage, pageSize: pageSize)
        }
    }

    func didSelectArticle(at index: Int) {
        guard articles.indices.contains(index) else { return }
        let article = articles[index]
        router.navigateToArticleDetail(urlString: article.url, title: article.title)
    }

    func didTapRetry() {
        if let failedPage = failedPaginationPage {
            failedPaginationPage = nil
            isLoading = true
            publishState(errorMessage: nil, emptyMessage: nil, alertError: nil)
            interactor.fetchArticles(
                sourceId: source.id,
                query: currentQuery,
                page: failedPage,
                pageSize: pageSize
            )
            return
        }
        resetAndLoad(query: currentQuery)
    }
}

extension ArticleListPresenter: ArticleListInteractorOutputSpecs {
    func didFetchArticles(_ response: ArticlesResponse, page: Int, isNewSearch: Bool) {
        isLoading = false
        failedPaginationPage = nil
        currentPage = page

        if page == 1 || isNewSearch {
            articles = response.articles
        } else {
            articles.append(contentsOf: response.articles)
        }

        hasMorePages = !response.articles.isEmpty && articles.count < response.totalResults && response.articles.count >= pageSize

        let emptyText: String? = articles.isEmpty
            ? (currentQuery == nil ? "No articles available for \(source.name)." : "No articles match \"\(currentQuery!)\".")
            : nil

        publishState(errorMessage: nil, emptyMessage: emptyText, alertError: nil)
    }

    func didFailFetchingArticles(_ error: NewsServiceError, page: Int, isNewSearch: Bool) {
        isLoading = false
        let message = mapErrorMessage(error)
        let alert = ErrorAlertState(title: "Failed to Load Articles", message: message)

        if page > 1 {
            failedPaginationPage = page
            publishState(errorMessage: nil, emptyMessage: nil, alertError: alert)
            return
        }

        failedPaginationPage = nil
        if page == 1 || isNewSearch {
            articles = []
        }
        publishState(errorMessage: message, emptyMessage: nil, alertError: alert)
    }
}

private extension ArticleListPresenter {
    func resetAndLoad(query: String?) {
        currentQuery = query
        currentPage = 1
        failedPaginationPage = nil
        hasMorePages = true
        isLoading = true
        articles = []
        publishState(errorMessage: nil, emptyMessage: nil, alertError: nil)
        interactor.fetchArticles(sourceId: source.id, query: query, page: 1, pageSize: pageSize)
    }

    func publishState(
        errorMessage: String?,
        emptyMessage: String?,
        alertError: ErrorAlertState?
    ) {
        let rows = articles.map { article in
            ArticleRowItem(
                title: article.title,
                metaText: "\(article.source.name) • \(article.publishedAt)",
                summaryText: article.description ?? "Tap to read full article."
            )
        }

        let state = ArticleListViewState(
            items: rows,
            isInitialLoading: isLoading && articles.isEmpty && errorMessage == nil,
            isLoadingMore: isLoading && !articles.isEmpty,
            errorMessage: errorMessage,
            emptyMessage: emptyMessage,
            alertError: alertError
        )
        view?.render(state: state)
    }

    func mapErrorMessage(_ error: NewsServiceError) -> String {
        switch error {
        case .missingAPIKey:
            return "Missing API key. Check Config.plist."
        case .invalidURL:
            return "Invalid request URL."
        case .networkFailure(let detail):
            return "Network error: \(detail)"
        case .decodingFailure:
            return "Unexpected response format from server."
        case .apiError(let message):
            return message
        }
    }
}
