//
//  SourceListRouter.swift
//  BugleNews
//
//  Created by Arnold Pangestu on 19/11/26.
//

import UIKit

final class SourceListRouter {
    weak var viewController: UIViewController?
    private let onNavigateToArticles: ((_ source: NewsSource, _ from: UIViewController?) -> Void)?

    init(
        viewController: UIViewController? = nil,
        onNavigateToArticles: ((_ source: NewsSource, _ from: UIViewController?) -> Void)? = nil
    ) {
        self.viewController = viewController
        self.onNavigateToArticles = onNavigateToArticles
    }

    static func createModule(
        category: NewsCategory,
        newsService: NewsServiceProtocol = NewsServices(),
        onNavigateToArticles: ((_ source: NewsSource, _ from: UIViewController?) -> Void)? = nil
    ) -> SourceListViewController {
        let interactor = SourceListInteractor(newsService: newsService)
        let router = SourceListRouter(onNavigateToArticles: onNavigateToArticles)
        let presenter = SourceListPresenter(
            category: category,
            interactor: interactor,
            router: router
        )
        let viewController = SourceListViewController(presenter: presenter)

        presenter.view = viewController
        interactor.presenter = presenter
        router.viewController = viewController

        return viewController
    }
}

extension SourceListRouter: SourceListRouterSpecs {
    func navigateToArticleList(source: NewsSource) {
        if let onNavigateToArticles = onNavigateToArticles {
            onNavigateToArticles(source, viewController)
            return
        }

        let articleListVC = ArticleListRouter.createModule(source: source)
        if let navigationController = viewController?.navigationController {
            navigationController.pushViewController(articleListVC, animated: true)
        } else {
            viewController?.present(articleListVC, animated: true)
        }
    }
}
