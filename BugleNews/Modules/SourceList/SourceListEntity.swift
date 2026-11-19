//
//  SourceListEntity.swift
//  BugleNews
//
//  Created by Arnold Pangestu on 19/11/26.
//

import Foundation

protocol SourceListViewSpecs: AnyObject {
    func render(state: SourceListViewState)
}

protocol SourceListPresenterSpecs: AnyObject {
    func viewDidLoad()
    func searchQueryChanged(_ query: String)
    func loadNextPageIfNeeded(currentIndex: Int)
    func didSelectSource(at index: Int)
    func didTapRetry()
}

protocol SourceListInteractorInputSpecs: AnyObject {
    func fetchSources(category: String)
}

protocol SourceListInteractorOutputSpecs: AnyObject {
    func didFetchSources(_ sources: [NewsSource])
    func didFailFetchingSources(_ error: NewsServiceError)
}

protocol SourceListRouterSpecs: AnyObject {
    func navigateToArticleList(source: NewsSource)
}

struct SourceListViewState: Equatable {
    let title: String
    let items: [SourceRowItem]
    let isLoading: Bool
    let errorMessage: String?
    let emptyMessage: String?
}

struct SourceRowItem: Equatable {
    let id: String
    let name: String
    let subtitle: String
}
