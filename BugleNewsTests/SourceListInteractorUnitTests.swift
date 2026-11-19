//
//  SourceListInteractorUnitTests.swift
//  BugleNewsTests
//
//  Created by Arnold Pangestu on 19/11/26.
//

import XCTest
@testable import BugleNews

final class SourceListInteractorTests: XCTestCase {
    private final class MockNewsService: NewsServiceProtocol {
        private(set) var fetchSourcesCallCount = 0
        private(set) var lastCategory: String?
        private var completions: [(Result<[NewsSource], NewsServiceError>) -> Void] = []

        func fetchSources(
            category: String,
            completion: @escaping (Result<[NewsSource], NewsServiceError>) -> Void
        ) {
            fetchSourcesCallCount += 1
            lastCategory = category
            completions.append(completion)
        }

        func fetchArticles(
            sourceId: String,
            query: String?,
            page: Int,
            pageSize: Int,
            completion: @escaping (Result<ArticlesResponse, NewsServiceError>) -> Void
        ) {
            // Not exercised in SourceListInteractorTests
        }

        func completeAt(index: Int, with result: Result<[NewsSource], NewsServiceError>) {
            guard completions.indices.contains(index) else { return }
            completions[index](result)
        }
    }

    private final class MockPresenter: SourceListInteractorOutputSpecs {
        private(set) var didFetchCallCount = 0
        private(set) var didFailCallCount = 0
        private(set) var lastSources: [NewsSource] = []
        private(set) var lastError: NewsServiceError?

        func didFetchSources(_ sources: [NewsSource]) {
            didFetchCallCount += 1
            lastSources = sources
        }

        func didFailFetchingSources(_ error: NewsServiceError) {
            didFailCallCount += 1
            lastError = error
        }
    }

    private var service: MockNewsService?
    private var presenter: MockPresenter?
    private var sut: SourceListInteractor?

    override func setUp() {
        super.setUp()
        let mockService = MockNewsService()
        let mockPresenter = MockPresenter()
        let interactor = SourceListInteractor(newsService: mockService)
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

        XCTAssertEqual(mockService.fetchSourcesCallCount, 0)
        XCTAssertEqual(mockPresenter.didFetchCallCount, 0)
        XCTAssertEqual(mockPresenter.didFailCallCount, 0)
    }

    func test_fetchSources_successForwardsSourcesToPresenter() throws {
        let mockService = try XCTUnwrap(service)
        let mockPresenter = try XCTUnwrap(presenter)
        let interactor = try XCTUnwrap(sut)

        interactor.fetchSources(category: "science")
        XCTAssertEqual(mockService.fetchSourcesCallCount, 1)
        XCTAssertEqual(mockService.lastCategory, "science")

        let expected = [
            NewsSource(
                id: "new-scientist",
                name: "New Scientist",
                description: "Science news",
                url: "https://www.newscientist.com",
                category: "science",
                language: "en",
                country: "gb"
            )
        ]
        mockService.completeAt(index: 0, with: .success(expected))

        XCTAssertEqual(mockPresenter.didFetchCallCount, 1)
        XCTAssertEqual(mockPresenter.lastSources.count, 1)
        XCTAssertEqual(mockPresenter.lastSources.first?.id, "new-scientist")
    }

    func test_fetchSources_failureForwardsErrorToPresenter() throws {
        let mockService = try XCTUnwrap(service)
        let mockPresenter = try XCTUnwrap(presenter)
        let interactor = try XCTUnwrap(sut)

        interactor.fetchSources(category: "business")
        XCTAssertEqual(mockService.fetchSourcesCallCount, 1)

        mockService.completeAt(index: 0, with: .failure(.apiError(message: "API key invalid")))

        XCTAssertEqual(mockPresenter.didFailCallCount, 1)
        XCTAssertEqual(mockPresenter.lastError, .apiError(message: "API key invalid"))
    }
}
