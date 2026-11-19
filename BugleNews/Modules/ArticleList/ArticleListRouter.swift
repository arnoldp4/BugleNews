//
//  ArticleListRouter.swift
//  BugleNews
//
//  Created by Arnold Pangestu on 19/11/26.
//

import UIKit

final class ArticleListRouter {
    weak var viewController: UIViewController?
    private let onNavigateToDetail: ((_ urlString: String, _ title: String, _ from: UIViewController?) -> Void)?

    init(
        viewController: UIViewController? = nil,
        onNavigateToDetail: ((_ urlString: String, _ title: String, _ from: UIViewController?) -> Void)? = nil
    ) {
        self.viewController = viewController
        self.onNavigateToDetail = onNavigateToDetail
    }

    static func createModule(
        source: NewsSource,
        newsService: NewsServiceProtocol = NewsServices(),
        onNavigateToDetail: ((_ urlString: String, _ title: String, _ from: UIViewController?) -> Void)? = nil
    ) -> ArticleListViewController {
        let interactor = ArticleListInteractor(newsService: newsService)
        let router = ArticleListRouter(onNavigateToDetail: onNavigateToDetail)
        let presenter = ArticleListPresenter(
            source: source,
            interactor: interactor,
            router: router
        )
        let viewController = ArticleListViewController(presenter: presenter)

        presenter.view = viewController
        interactor.presenter = presenter
        router.viewController = viewController

        return viewController
    }
}

extension ArticleListRouter: ArticleListRouterSpecs {
    func navigateToArticleDetail(urlString: String, title: String) {
        if let onNavigateToDetail = onNavigateToDetail {
            onNavigateToDetail(urlString, title, viewController)
            return
        }

        let detailViewController = ArticleDetailRouter.createModule(
            urlString: urlString,
            title: title
        )

        if let navigationController = viewController?.navigationController {
            navigationController.pushViewController(detailViewController, animated: true)
        } else {
            viewController?.present(detailViewController, animated: true)
        }
    }
}
