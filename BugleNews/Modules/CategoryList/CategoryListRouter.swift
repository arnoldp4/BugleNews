//
//  CategoryListRouter.swift
//  BugleNews
//
//  Created by Arnold Pangestu on 19/11/26.
//

import UIKit

final class CategoryListRouter {
    weak var viewController: UIViewController?
    private let newsService: NewsServiceProtocol

    init(
        viewController: UIViewController? = nil,
        newsService: NewsServiceProtocol = NewsServices()
    ) {
        self.viewController = viewController
        self.newsService = newsService
    }

    static func createModule(
        newsService: NewsServiceProtocol = NewsServices()
    ) -> CategoryListViewController {
        let interactor = CategoryListInteractor()
        let router = CategoryListRouter(newsService: newsService)
        let presenter = CategoryListPresenter(interactor: interactor, router: router)
        let viewController = CategoryListViewController(presenter: presenter)

        presenter.view = viewController
        interactor.presenter = presenter
        router.viewController = viewController

        return viewController
    }
}

extension CategoryListRouter: CategoryListRouterSpecs {
    func navigateToSourceList(category: NewsCategory) {
        let sourceListVC = SourceListRouter.createModule(
            category: category,
            newsService: newsService
        )

        if let navigationController = viewController?.navigationController {
            navigationController.pushViewController(sourceListVC, animated: true)
        } else {
            viewController?.present(sourceListVC, animated: true)
        }
    }
}
