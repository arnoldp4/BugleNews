//
//  ArticleListInteractor.swift
//  BugleNews
//
//  Created by Arnold Pangestu on 19/11/26.
//

import Foundation

final class ArticleListInteractor {
    weak var presenter: ArticleListInteractorOutputSpecs?

    private let newsService: NewsServiceProtocol
    private var activeQuery: String?

    init(newsService: NewsServiceProtocol = NewsServices()) {
        self.newsService = newsService
    }
}

extension ArticleListInteractor: ArticleListInteractorInputSpecs {
    func fetchArticles(sourceId: String, query: String?, page: Int, pageSize: Int) {
        let isNewSearch = activeQuery != query && page == 1
        activeQuery = query

        newsService.fetchArticles(sourceId: sourceId, query: query, page: page, pageSize: pageSize) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let response):
                self.presenter?.didFetchArticles(response, page: page, isNewSearch: isNewSearch)
            case .failure(let error):
                self.presenter?.didFailFetchingArticles(error, page: page, isNewSearch: isNewSearch)
            }
        }
    }
}
