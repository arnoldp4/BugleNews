//
//  SourceListInteractor.swift
//  BugleNews
//
//  Created by Arnold Pangestu on 19/11/26.
//

import Foundation

final class SourceListInteractor {
    weak var presenter: SourceListInteractorOutputSpecs?

    private let newsService: NewsServiceProtocol

    init(newsService: NewsServiceProtocol = NewsServices()) {
        self.newsService = newsService
    }
}

extension SourceListInteractor: SourceListInteractorInputSpecs {
    func fetchSources(category: String) {
        newsService.fetchSources(category: category) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let sources):
                self.presenter?.didFetchSources(sources)
            case .failure(let error):
                self.presenter?.didFailFetchingSources(error)
            }
        }
    }
}
