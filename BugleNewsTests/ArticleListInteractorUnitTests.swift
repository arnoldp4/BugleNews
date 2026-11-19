//
//  ArticleListInteractorUnitTests.swift
//  BugleNewsTests
//
//  Created by Arnold Pangestu on 19/11/26.
//

import XCTest
@testable import BugleNews

final class ArticleListInteractorTests: XCTestCase {
    private final class MockNewsService: NewsServiceProtocol {
        private(set) var fetchArticlesCallCount = 0
        private(set) var lastSourceId: String?
        private(set) var lastQuery: String?
        private(set) var lastPage: Int?
        private(set) var lastPageSize: Int?
        private var completions: [(Result<ArticlesResponse, NewsServiceError>) -> Void] = []

        func fetchSources(
            category: String,
            completion: @escaping (Result<[NewsSource], NewsServiceError>) -> Void
        ) {
            // Not exercised in ArticleListInteractorTests
        }

        func fetchArticles(
            sourceId: String,
            query: String?,
            page: Int,
            pageSize: Int,
            completion: @escaping (Result<ArticlesResponse, NewsServiceError>) -> Void
        ) {
            fetchArticlesCallCount += 1
            lastSourceId = sourceId
            lastQuery = query
            lastPage = page
            lastPageSize = pageSize
            completions.append(completion)
        }

        func completeAt(index: Int, with result: Result<ArticlesResponse, NewsServiceError>) {
            guard completions.indices.contains(index) else { return }
            completions[index](result)
        }
    }

    private final class MockPresenter: ArticleListInteractorOutputSpecs {
        private(set) var didFetchCallCount = 0
        private(set) var didFailCallCount = 0
        private(set) var lastFetchedPage: Int?
        private(set) var lastFetchedIsNewSearch: Bool?
        private(set) var lastFailedError: NewsServiceError?
        private(set) var lastFailedPage: Int?
        private(set) var lastFailedIsNewSearch: Bool?

        func didFetchArticles(_ response: ArticlesResponse, page: Int, isNewSearch: Bool) {
            didFetchCallCount += 1
            lastFetchedPage = page
            lastFetchedIsNewSearch = isNewSearch
        }

        func didFailFetchingArticles(_ error: NewsServiceError, page: Int, isNewSearch: Bool) {
            didFailCallCount += 1
            lastFailedError = error
            lastFailedPage = page
            lastFailedIsNewSearch = isNewSearch
        }
    }

    private var service: MockNewsService?
    private var presenter: MockPresenter?
    private var sut: ArticleListInteractor?

    override func setUp() {
        super.setUp()
        let mockService = MockNewsService()
        let mockPresenter = MockPresenter()
        let interactor = ArticleListInteractor(newsService: mockService)
        interactor.presenter = mockPresenter

        service = mockService
        presenter = mockPresenter
        sut = interactor
    }

    override func tearDown() {
        sut = nil
        presenter = nil
        service = nil
        super.tearDown()
    }

    func test_init_hasZeroCallsBaseline() throws {
        let mockService = try XCTUnwrap(service)
        let mockPresenter = try XCTUnwrap(presenter)

        XCTAssertEqual(mockService.fetchArticlesCallCount, 0)
        XCTAssertEqual(mockPresenter.didFetchCallCount, 0)
        XCTAssertEqual(mockPresenter.didFailCallCount, 0)
    }

    func test_fetchArticles_successForwardsResponseAndIsNewSearchFlag() throws {
        let mockService = try XCTUnwrap(service)
        let mockPresenter = try XCTUnwrap(presenter)
        let interactor = try XCTUnwrap(sut)

        interactor.fetchArticles(sourceId: "bbc-news", query: nil, page: 1, pageSize: 20)
        XCTAssertEqual(mockService.fetchArticlesCallCount, 1)
        XCTAssertEqual(mockService.lastSourceId, "bbc-news")
        XCTAssertEqual(mockService.lastPage, 1)
        XCTAssertEqual(mockService.lastPageSize, 20)

        let response = ArticlesResponse(status: "ok", totalResults: 1, articles: [])
        mockService.completeAt(index: 0, with: .success(response))

        XCTAssertEqual(mockPresenter.didFetchCallCount, 1)
        XCTAssertEqual(mockPresenter.lastFetchedPage, 1)
        XCTAssertEqual(mockPresenter.lastFetchedIsNewSearch, false)

        // New query on page 1 should set isNewSearch == true
        interactor.fetchArticles(sourceId: "bbc-news", query: "ai", page: 1, pageSize: 20)
        mockService.completeAt(index: 1, with: .success(response))

        XCTAssertEqual(mockService.fetchArticlesCallCount, 2)
        XCTAssertEqual(mockPresenter.didFetchCallCount, 2)
        XCTAssertEqual(mockPresenter.lastFetchedIsNewSearch, true)
    }

    func test_fetchArticles_failureForwardsErrorAndPage() throws {
        let mockService = try XCTUnwrap(service)
        let mockPresenter = try XCTUnwrap(presenter)
        let interactor = try XCTUnwrap(sut)

        interactor.fetchArticles(sourceId: "bbc-news", query: "swift", page: 2, pageSize: 20)
        XCTAssertEqual(mockService.fetchArticlesCallCount, 1)

        mockService.completeAt(index: 0, with: .failure(.networkFailure("Timed out")))

        XCTAssertEqual(mockPresenter.didFailCallCount, 1)
        XCTAssertEqual(mockPresenter.lastFailedPage, 2)
        XCTAssertEqual(mockPresenter.lastFailedIsNewSearch, false)
        XCTAssertEqual(mockPresenter.lastFailedError, .networkFailure("Timed out"))
    }
}
