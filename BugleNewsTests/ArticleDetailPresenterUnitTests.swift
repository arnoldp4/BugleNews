//
//  ArticleDetailPresenterUnitTests.swift
//  BugleNewsTests
//
//  Created by Arnold Pangestu on 19/11/26.
//

import XCTest
@testable import BugleNews

final class ArticleDetailPresenterTests: XCTestCase {
    private final class MockInteractor: ArticleDetailInteractorInputSpecs {
        private(set) var validateURLCallCount = 0
        private(set) var lastValidatedURLString: String?

        func validateArticleURL(_ urlString: String) {
            validateURLCallCount += 1
            lastValidatedURLString = urlString
        }
    }

    private final class MockRouter: ArticleDetailRouterSpecs {
        private(set) var dismissCount = 0

        func dismissDetail() {
            dismissCount += 1
        }
    }

    private final class MockView: ArticleDetailViewSpecs {
        private(set) var renderCount = 0
        private(set) var loadRequestCount = 0
        private(set) var lastLoadedURL: URL?
        private(set) var states: [ArticleDetailViewState] = []

        func render(state: ArticleDetailViewState) {
            renderCount += 1
            states.append(state)
        }

        func load(url: URL) {
            loadRequestCount += 1
            lastLoadedURL = url
        }
    }

    private var interactor: MockInteractor?
    private var router: MockRouter?
    private var view: MockView?
    private var sut: ArticleDetailPresenter?

    override func setUpWithError() throws {
        try super.setUpWithError()
        let mockInteractor = MockInteractor()
        let mockRouter = MockRouter()
        let mockView = MockView()
        let presenter = ArticleDetailPresenter(
            urlString: "https://example.com/article-1",
            articleTitle: "Sample Headline",
            interactor: mockInteractor,
            router: mockRouter
        )
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

        XCTAssertEqual(mockInteractor.validateURLCallCount, 0)
        XCTAssertEqual(mockRouter.dismissCount, 0)
        XCTAssertEqual(mockView.renderCount, 0)
        XCTAssertEqual(mockView.loadRequestCount, 0)
    }

    func test_viewDidLoad_setsLoadingAndValidatesURL() throws {
        let mockInteractor = try XCTUnwrap(interactor)
        let mockView = try XCTUnwrap(view)
        let presenter = try XCTUnwrap(sut)

        presenter.viewDidLoad()

        XCTAssertEqual(mockInteractor.validateURLCallCount, 1)
        XCTAssertEqual(mockInteractor.lastValidatedURLString, "https://example.com/article-1")
        XCTAssertEqual(mockView.renderCount, 1)
        XCTAssertEqual(mockView.states.first?.title, "Sample Headline")
        XCTAssertEqual(mockView.states.first?.isLoading, true)
        XCTAssertNil(mockView.states.first?.errorMessage)
    }

    func test_didValidateURL_loadsURLAndKeepsLoadingTrue() throws {
        let mockView = try XCTUnwrap(view)
        let presenter = try XCTUnwrap(sut)
        let url = try XCTUnwrap(URL(string: "https://example.com/article-1"))

        presenter.didValidateURL(url)

        XCTAssertEqual(mockView.loadRequestCount, 1)
        XCTAssertEqual(mockView.lastLoadedURL, url)
        XCTAssertEqual(mockView.renderCount, 1)
        XCTAssertEqual(mockView.states.last?.isLoading, true)
        XCTAssertNil(mockView.states.last?.errorMessage)
    }

    func test_didFailValidatingURL_stopsLoadingAndSetsErrorMessage() throws {
        let mockView = try XCTUnwrap(view)
        let presenter = try XCTUnwrap(sut)

        presenter.didFailValidatingURL(message: "Invalid article URL.")

        XCTAssertEqual(mockView.loadRequestCount, 0)
        XCTAssertEqual(mockView.renderCount, 1)
        XCTAssertEqual(mockView.states.last?.isLoading, false)
        XCTAssertEqual(mockView.states.last?.errorMessage, "Invalid article URL.")
    }

    func test_loadingLifecycle_startFinishAndFailure() throws {
        let mockView = try XCTUnwrap(view)
        let presenter = try XCTUnwrap(sut)

        presenter.didStartLoading()
        XCTAssertEqual(mockView.states.last?.isLoading, true)
        XCTAssertNil(mockView.states.last?.errorMessage)

        presenter.didFinishLoading()
        XCTAssertEqual(mockView.states.last?.isLoading, false)
        XCTAssertNil(mockView.states.last?.errorMessage)

        presenter.didFailLoading(message: "")
        XCTAssertEqual(mockView.states.last?.isLoading, false)
        XCTAssertEqual(mockView.states.last?.errorMessage, "Failed to load article page.")
    }

    func test_didTapRetry_resetsStateAndRevalidatesURL() throws {
        let mockInteractor = try XCTUnwrap(interactor)
        let mockView = try XCTUnwrap(view)
        let presenter = try XCTUnwrap(sut)

        presenter.didFailLoading(message: "Network timeout")
        XCTAssertEqual(mockView.states.last?.errorMessage, "Network timeout")

        presenter.didTapRetry()

        XCTAssertEqual(mockInteractor.validateURLCallCount, 1)
        XCTAssertEqual(mockInteractor.lastValidatedURLString, "https://example.com/article-1")
        XCTAssertEqual(mockView.states.last?.isLoading, true)
        XCTAssertNil(mockView.states.last?.errorMessage)
    }
}
