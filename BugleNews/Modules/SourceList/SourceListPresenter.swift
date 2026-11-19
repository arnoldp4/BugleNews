//
//  SourceListPresenter.swift
//  BugleNews
//
//  Created by Arnold Pangestu on 19/11/26.
//

import Foundation

final class SourceListPresenter {
    weak var view: SourceListViewSpecs?

    private let interactor: SourceListInteractorInputSpecs
    private let router: SourceListRouterSpecs
    private let category: NewsCategory
    private let pageSize = 15

    private var allSources: [NewsSource] = []
    private var filteredSources: [NewsSource] = []
    private var visibleCount = 0
    private var searchQuery = ""
    private var isLoading = false
    private var isAppendingPage = false
    private var errorMessage: String?

    init(
        category: NewsCategory,
        interactor: SourceListInteractorInputSpecs,
        router: SourceListRouterSpecs
    ) {
        self.category = category
        self.interactor = interactor
        self.router = router
    }
}

extension SourceListPresenter: SourceListPresenterSpecs {
    func viewDidLoad() {
        startInitialLoad()
    }

    func searchQueryChanged(_ query: String) {
        searchQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        applyFilterAndResetPagination()
        publishState()
    }

    func loadNextPageIfNeeded(currentIndex: Int) {
        guard !isLoading, !isAppendingPage, visibleCount < filteredSources.count else { return }
        let thresholdIndex = max(0, visibleCount - 3)
        if currentIndex >= thresholdIndex {
            isAppendingPage = true
            visibleCount = min(filteredSources.count, visibleCount + pageSize)
            isAppendingPage = false
            publishState()
        }
    }

    func didSelectSource(at index: Int) {
        let displayed = displayedSources()
        guard displayed.indices.contains(index) else { return }
        router.navigateToArticleList(source: displayed[index])
    }

    func didTapRetry() {
        startInitialLoad()
    }
}

extension SourceListPresenter: SourceListInteractorOutputSpecs {
    func didFetchSources(_ sources: [NewsSource]) {
        isLoading = false
        errorMessage = nil
        allSources = sources
        applyFilterAndResetPagination()
        publishState()
    }

    func didFailFetchingSources(_ error: NewsServiceError) {
        isLoading = false
        allSources = []
        filteredSources = []
        visibleCount = 0
        errorMessage = mapErrorMessage(error)
        publishState()
    }
}

private extension SourceListPresenter {
    func startInitialLoad() {
        isLoading = true
        isAppendingPage = false
        errorMessage = nil
        allSources = []
        filteredSources = []
        visibleCount = 0
        publishState()
        interactor.fetchSources(category: category.id)
    }

    func applyFilterAndResetPagination() {
        if searchQuery.isEmpty {
            filteredSources = allSources
        } else {
            let needle = searchQuery.lowercased()
            filteredSources = allSources.filter { source in
                source.name.lowercased().contains(needle) ||
                source.description.lowercased().contains(needle)
            }
        }
        visibleCount = min(filteredSources.count, pageSize)
    }

    func displayedSources() -> [NewsSource] {
        Array(filteredSources.prefix(visibleCount))
    }

    func publishState() {
        let rows = displayedSources().map { source in
            SourceRowItem(
                id: source.id,
                name: source.name,
                subtitle: source.description.isEmpty ? source.url : source.description
            )
        }

        let emptyText: String?
        if !isLoading && errorMessage == nil && rows.isEmpty {
            emptyText = searchQuery.isEmpty
                ? "No news sources found for \(category.title)."
                : "No sources match \"\(searchQuery)\"."
        } else {
            emptyText = nil
        }

        let state = SourceListViewState(
            title: category.title,
            items: rows,
            isLoading: isLoading,
            errorMessage: errorMessage,
            emptyMessage: emptyText
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
