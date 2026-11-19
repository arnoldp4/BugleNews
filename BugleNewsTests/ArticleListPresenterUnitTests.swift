//
//  ArticleListPresenterUnitTests.swift
//  BugleNewsTests
//
//  Created by Arnold Pangestu on 19/11/26.
//

import XCTest
@testable import BugleNews

final class ArticleListPresenterTests: XCTestCase {
    private final class MockInteractor: ArticleListInteractorInputSpecs {
        private(set) var fetchCallCount = 0
        private(set) var lastSourceId: String?
        private(set) var lastQuery: String?
        private(set) var lastPage: Int?
        private(set) var lastPageSize: Int?

        func fetchArticles(sourceId: String, query: String?, page: Int, pageSize: Int) {
            fetchCallCount += 1
            lastSourceId = sourceId
            lastQuery = query
            lastPage = page
            lastPageSize = pageSize
        }
    }

    private final class MockRouter: ArticleListRouterSpecs {
        private(set) var navigationCount = 0
        private(set) var lastURL: String?
        private(set) var lastTitle: String?

        func navigateToArticleDetail(urlString: String, title: String) {
            navigationCount += 1
            lastURL = urlString
            lastTitle = title
        }
    }

    private final class MockView: ArticleListViewSpecs {
        private(set) var renderCount = 0
        private(set) var states: [ArticleListViewState] = []

        func render(state: ArticleListViewState) {
            renderCount += 1
            states.append(state)
        }
    }

    private var interactor: MockInteractor?
    private var router: MockRouter?
    private var view: MockView?
    private var sampleSource: NewsSource?
    private var sut: ArticleListPresenter?

    override func setUp() {
        super.setUp()
        let mockInteractor = MockInteractor()
        let mockRouter = MockRouter()
        let mockView = MockView()
        let source = NewsSource(
            id: "bbc-news",
            name: "BBC News",
            description: "UK news",
            url: "https://www.bbc.co.uk/news",
            category: "general",
            language: "en",
            country: "gb"
        )
        let presenter = ArticleListPresenter(source: source, interactor: mockInteractor, router: mockRouter)
        presenter.view = mockView

        interactor = mockInteractor
        router = mockRouter
        view = mockView
        sampleSource = source
        sut = presenter
    }

    override func tearDown() {
        sut = nil
        sampleSource = nil
        view = nil
        router = nil
        interactor = nil
        super.tearDown()
    }

    func test_init_hasZeroCallsBaseline() throws {
        let mockInteractor = try XCTUnwrap(interactor)
        let mockRouter = try XCTUnwrap(router)
        let mockView = try XCTUnwrap(view)

        XCTAssertEqual(mockInteractor.fetchCallCount, 0)
        XCTAssertEqual(mockRouter.navigationCount, 0)
        XCTAssertEqual(mockView.renderCount, 0)
    }

    func test_viewDidLoad_fetchesFirstPageAndPublishesInitialLoading() throws {
        let mockInteractor = try XCTUnwrap(interactor)
        let mockView = try XCTUnwrap(view)
        let presenter = try XCTUnwrap(sut)

        presenter.viewDidLoad()

        XCTAssertEqual(mockInteractor.fetchCallCount, 1)
        XCTAssertEqual(mockInteractor.lastSourceId, "bbc-news")
        XCTAssertNil(mockInteractor.lastQuery)
        XCTAssertEqual(mockInteractor.lastPage, 1)
        XCTAssertEqual(mockInteractor.lastPageSize, 20)
        XCTAssertGreaterThanOrEqual(mockView.renderCount, 1)
        XCTAssertEqual(mockView.states.first?.isInitialLoading, true)
        XCTAssertNil(mockView.states.first?.alertError)
    }

    func test_pagination_triggersAtThresholdAndPreventsDuplicateWhileLoading() throws {
        let mockInteractor = try XCTUnwrap(interactor)
        let mockView = try XCTUnwrap(view)
        let presenter = try XCTUnwrap(sut)

        presenter.viewDidLoad()
        let initialRenders = mockView.renderCount

        let pageOneArticles = makeArticles(count: 20, prefix: "Page1")
        presenter.didFetchArticles(
            ArticlesResponse(status: "ok", totalResults: 45, articles: pageOneArticles),
            page: 1,
            isNewSearch: false
        )

        // Below threshold (20 - 4 = 16): should not fetch page 2
        presenter.loadNextPageIfNeeded(currentIndex: 10)
        XCTAssertEqual(mockInteractor.fetchCallCount, 1)

        // At threshold (16): should fetch page 2
        presenter.loadNextPageIfNeeded(currentIndex: 16)
        XCTAssertEqual(mockInteractor.fetchCallCount, 2)
        XCTAssertEqual(mockInteractor.lastPage, 2)
        XCTAssertEqual(mockView.states.last?.isLoadingMore, true)
        XCTAssertNil(mockView.states.last?.alertError)

        // While already loading page 2: should guard and not fetch page 2 again
        presenter.loadNextPageIfNeeded(currentIndex: 18)
        XCTAssertEqual(mockInteractor.fetchCallCount, 2)
        XCTAssertGreaterThan(mockView.renderCount, initialRenders)
    }

    func test_paginationFailure_preservesExistingItemsAndRetriesFailedPage() throws {
        let mockInteractor = try XCTUnwrap(interactor)
        let mockView = try XCTUnwrap(view)
        let presenter = try XCTUnwrap(sut)

        presenter.viewDidLoad()
        presenter.didFetchArticles(
            ArticlesResponse(status: "ok", totalResults: 40, articles: makeArticles(count: 20, prefix: "Item")),
            page: 1,
            isNewSearch: false
        )

        presenter.loadNextPageIfNeeded(currentIndex: 16)
        XCTAssertEqual(mockInteractor.fetchCallCount, 2)
        XCTAssertEqual(mockInteractor.lastPage, 2)

        presenter.didFailFetchingArticles(.networkFailure("Offline"), page: 2, isNewSearch: false)

        let failureState = mockView.states.last
        XCTAssertEqual(failureState?.items.count, 20)
        XCTAssertNil(failureState?.errorMessage)
        XCTAssertNotNil(failureState?.alertError)
        XCTAssertEqual(failureState?.alertError?.message, "Network error: Offline")

        presenter.didTapRetry()

        XCTAssertEqual(mockInteractor.fetchCallCount, 3)
        XCTAssertEqual(mockInteractor.lastPage, 2)
        XCTAssertNil(mockView.states.last?.alertError)
    }

    func test_initialFailure_setsErrorMessageAndAlertAndRetriesPageOne() throws {
        let mockInteractor = try XCTUnwrap(interactor)
        let mockView = try XCTUnwrap(view)
        let presenter = try XCTUnwrap(sut)

        presenter.viewDidLoad()
        presenter.didFailFetchingArticles(.apiError(message: "Rate limit exceeded"), page: 1, isNewSearch: false)

        let failureState = mockView.states.last
        XCTAssertEqual(failureState?.errorMessage, "Rate limit exceeded")
        XCTAssertEqual(failureState?.alertError?.message, "Rate limit exceeded")
        XCTAssertTrue(failureState?.items.isEmpty ?? false)

        presenter.didTapRetry()

        XCTAssertEqual(mockInteractor.fetchCallCount, 2)
        XCTAssertEqual(mockInteractor.lastPage, 1)
    }

    func test_searchQueryChanged_normalizesQueryAndResetsToPageOne() throws {
        let mockInteractor = try XCTUnwrap(interactor)
        let presenter = try XCTUnwrap(sut)

        presenter.searchQueryChanged("   swift   ")
        XCTAssertEqual(mockInteractor.fetchCallCount, 1)
        XCTAssertEqual(mockInteractor.lastQuery, "swift")
        XCTAssertEqual(mockInteractor.lastPage, 1)

        presenter.searchQueryChanged("   ")
        XCTAssertEqual(mockInteractor.fetchCallCount, 2)
        XCTAssertNil(mockInteractor.lastQuery)
        XCTAssertEqual(mockInteractor.lastPage, 1)
    }

    func test_didSelectArticle_validIndex_routesToDetail() throws {
        let mockRouter = try XCTUnwrap(router)
        let presenter = try XCTUnwrap(sut)

        let articles = makeArticles(count: 2, prefix: "Story")
        presenter.didFetchArticles(
            ArticlesResponse(status: "ok", totalResults: 2, articles: articles),
            page: 1,
            isNewSearch: false
        )

        presenter.didSelectArticle(at: 1)

        XCTAssertEqual(mockRouter.navigationCount, 1)
        XCTAssertEqual(mockRouter.lastURL, "https://example.com/Story-1")
        XCTAssertEqual(mockRouter.lastTitle, "Story 1")
    }

    private func makeArticles(count: Int, prefix: String) -> [NewsArticle] {
        (0..<count).map { index in
            NewsArticle(
                source: ArticleSourceRef(id: "bbc-news", name: "BBC News"),
                author: "",
                title: "\(prefix) \(index)",
                description: "Summary \(index)",
                url: "https://example.com/\(prefix)-\(index)",
                publishedAt: "2026-11-19T12:00:00Z"
            )
        }
    }
}
