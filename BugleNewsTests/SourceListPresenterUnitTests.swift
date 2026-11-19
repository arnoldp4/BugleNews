//
//  SourceListPresenterUnitTests.swift
//  BugleNewsTests
//
//  Created by Arnold Pangestu on 19/11/26.
//

import XCTest
@testable import BugleNews

final class SourceListPresenterTests: XCTestCase {
    private final class MockInteractor: SourceListInteractorInputSpecs {
        private(set) var fetchCallCount = 0
        private(set) var lastCategory: String?

        func fetchSources(category: String) {
            fetchCallCount += 1
            lastCategory = category
        }
    }

    private final class MockRouter: SourceListRouterSpecs {
        private(set) var navigationCount = 0
        private(set) var lastSource: NewsSource?

        func navigateToArticleList(source: NewsSource) {
            navigationCount += 1
            lastSource = source
        }
    }

    private final class MockView: SourceListViewSpecs {
        private(set) var renderCount = 0
        private(set) var states: [SourceListViewState] = []

        func render(state: SourceListViewState) {
            renderCount += 1
            states.append(state)
        }
    }

    private var interactor: MockInteractor?
    private var router: MockRouter?
    private var view: MockView?
    private var sut: SourceListPresenter?

    override func setUp() {
        super.setUp()
        let mockInteractor = MockInteractor()
        let mockRouter = MockRouter()
        let mockView = MockView()
        let category = NewsCategory(id: "technology", title: "technology", subtitle: "tech-test")
        let presenter = SourceListPresenter(category: category, interactor: mockInteractor, router: mockRouter)
        presenter.view = mockView

        interactor = mockInteractor
        router = mockRouter
        view = mockView
        sut = presenter
    }

    override func tearDown() {
        sut = nil
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

    func test_viewDidLoad_fetchesSourcesForCategoryAndPublishesLoading() throws {
        let mockInteractor = try XCTUnwrap(interactor)
        let mockView = try XCTUnwrap(view)
        let presenter = try XCTUnwrap(sut)

        presenter.viewDidLoad()

        XCTAssertEqual(mockInteractor.fetchCallCount, 1)
        XCTAssertEqual(mockInteractor.lastCategory, "technology")
        XCTAssertEqual(mockView.renderCount, 1)
        XCTAssertEqual(mockView.states.first?.isLoading, true)
    }

    func test_didFetchSources_successFiltersBySearchQuery() throws {
        let mockView = try XCTUnwrap(view)
        let presenter = try XCTUnwrap(sut)

        presenter.viewDidLoad()
        let sources = [
            makeSource(id: "techcrunch", name: "TechCrunch"),
            makeSource(id: "the-verge", name: "The Verge"),
            makeSource(id: "ars-technica", name: "Ars Technica")
        ]

        presenter.didFetchSources(sources)
        XCTAssertEqual(mockView.states.last?.items.count, 3)

        presenter.searchQueryChanged("verge")
        XCTAssertEqual(mockView.states.last?.items.count, 1)
        XCTAssertEqual(mockView.states.last?.items.first?.name, "The Verge")

        presenter.searchQueryChanged("")
        XCTAssertEqual(mockView.states.last?.items.count, 3)
    }

    func test_didFailFetchingSources_setsErrorAndAllowsRetry() throws {
        let mockInteractor = try XCTUnwrap(interactor)
        let mockView = try XCTUnwrap(view)
        let presenter = try XCTUnwrap(sut)

        presenter.viewDidLoad()
        presenter.didFailFetchingSources(.networkFailure("No internet"))

        XCTAssertNotNil(mockView.states.last?.errorMessage)

        presenter.didTapRetry()

        XCTAssertEqual(mockInteractor.fetchCallCount, 2)
        XCTAssertEqual(mockInteractor.lastCategory, "technology")
    }

    func test_didSelectSource_routesToArticleList() throws {
        let mockRouter = try XCTUnwrap(router)
        let presenter = try XCTUnwrap(sut)

        let sources = [
            makeSource(id: "techcrunch", name: "TechCrunch"),
            makeSource(id: "wired", name: "Wired")
        ]
        presenter.didFetchSources(sources)

        presenter.didSelectSource(at: 1)

        XCTAssertEqual(mockRouter.navigationCount, 1)
        XCTAssertEqual(mockRouter.lastSource?.id, "wired")
        XCTAssertEqual(mockRouter.lastSource?.name, "Wired")
    }

    private func makeSource(id: String, name: String) -> NewsSource {
        NewsSource(
            id: id,
            name: name,
            description: "\(name) updates",
            url: "https://example.com/\(id)",
            category: "technology",
            language: "en",
            country: "us"
        )
    }
}
