//
//  ArticleListEntity.swift
//  BugleNews
//
//  Created by Arnold Pangestu on 19/11/26.
//

import UIKit

// MARK: - Protocols
protocol ArticleListViewSpecs: AnyObject {
    func render(state: ArticleListViewState)
}

protocol ArticleListPresenterSpecs: AnyObject {
    func viewDidLoad()
    func searchQueryChanged(_ query: String)
    func loadNextPageIfNeeded(currentIndex: Int)
    func didSelectArticle(at index: Int)
    func didTapRetry()
}

protocol ArticleListInteractorInputSpecs: AnyObject {
    func fetchArticles(sourceId: String, query: String?, page: Int, pageSize: Int)
}

protocol ArticleListInteractorOutputSpecs: AnyObject {
    func didFetchArticles(_ response: ArticlesResponse, page: Int, isNewSearch: Bool)
    func didFailFetchingArticles(_ error: NewsServiceError, page: Int, isNewSearch: Bool)
}

protocol ArticleListRouterSpecs: AnyObject {
    func navigateToArticleDetail(urlString: String, title: String)
}

struct ArticleListViewState: Equatable {
    let items: [ArticleRowItem]
    let isInitialLoading: Bool
    let isLoadingMore: Bool
    let errorMessage: String?
    let emptyMessage: String?
    let alertError: ErrorAlertState?
}

struct ArticleRowItem: Equatable {
    let title: String
    let metaText: String
    let summaryText: String
}
