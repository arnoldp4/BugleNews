//
//  CategoryListPresenterUnitTests.swift
//  BugleNewsTests
//
//  Created by Arnold Pangestu on 19/11/26.
//

import XCTest
@testable import BugleNews

final class CategoryListPresenterTests: XCTestCase {
    private final class MockInteractor: CategoryListInteractorInputSpecs {
        private(set) var fetchCategoriesCallCount = 0

        func fetchCategories() {
            fetchCategoriesCallCount += 1
        }
    }

    private final class MockRouter: CategoryListRouterSpecs {
        private(set) var navigationCount = 0
        private(set) var lastCategoryId: String?

        func navigateToSourceList(category: NewsCategory) {
            navigationCount += 1
            lastCategoryId = category.id
        }
    }

    private final class MockView: CategoryListViewSpecs {
        private(set) var renderCount = 0
        private(set) var states: [CategoryListViewState] = []

        func render(state: CategoryListViewState) {
            renderCount += 1
            states.append(state)
        }
    }

    private var interactor: MockInteractor?
    private var router: MockRouter?
    private var view: MockView?
    private var sut: CategoryListPresenter?

    override func setUp() {
        super.setUp()
        let mockInteractor = MockInteractor()
        let mockRouter = MockRouter()
        let mockView = MockView()
        let presenter = CategoryListPresenter(interactor: mockInteractor, router: mockRouter)
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

        XCTAssertEqual(mockInteractor.fetchCategoriesCallCount, 0)
        XCTAssertEqual(mockRouter.navigationCount, 0)
        XCTAssertEqual(mockView.renderCount, 0)
    }

    func test_viewDidLoad_fetchesCategoriesFromInteractor() throws {
        let mockInteractor = try XCTUnwrap(interactor)
        let mockRouter = try XCTUnwrap(router)
        let presenter = try XCTUnwrap(sut)

        presenter.viewDidLoad()

        XCTAssertEqual(mockInteractor.fetchCategoriesCallCount, 1)
        XCTAssertEqual(mockRouter.navigationCount, 0)
    }

    func test_didFetchCategories_rendersCategoriesList() throws {
        let mockView = try XCTUnwrap(view)
        let presenter = try XCTUnwrap(sut)

        let categories = [
            NewsCategory(id: "technology", title: "Technology", subtitle: "Tech updates"),
            NewsCategory(id: "business", title: "Business", subtitle: "Market news")
        ]

        presenter.didFetchCategories(categories)

        XCTAssertEqual(mockView.renderCount, 1)
        XCTAssertEqual(mockView.states.first?.items.count, 2)
    }

    func test_didSelectCategory_routesToSourceList() throws {
        let mockRouter = try XCTUnwrap(router)
        let presenter = try XCTUnwrap(sut)

        let categories = [
            NewsCategory(id: "technology", title: "Technology", subtitle: "Tech updates"),
            NewsCategory(id: "business", title: "Business", subtitle: "Market news")
        ]
        presenter.didFetchCategories(categories)
        presenter.didSelectCategory(at: 1)

        XCTAssertEqual(mockRouter.navigationCount, 1)
        XCTAssertEqual(mockRouter.lastCategoryId, "business")
    }
}
