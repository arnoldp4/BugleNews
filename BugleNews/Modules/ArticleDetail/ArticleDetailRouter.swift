//
//  ArticleDetailRouter.swift
//  BugleNews
//
//  Created by Arnold Pangestu on 19/11/26.
//

import UIKit

final class ArticleDetailRouter {
    weak var viewController: UIViewController?

    init(viewController: UIViewController? = nil) {
        self.viewController = viewController
    }

    static func createModule(urlString: String, title: String) -> ArticleDetailViewController {
        let interactor = ArticleDetailInteractor()
        let router = ArticleDetailRouter()
        let presenter = ArticleDetailPresenter(
            urlString: urlString,
            articleTitle: title,
            interactor: interactor,
            router: router
        )
        let viewController = ArticleDetailViewController(presenter: presenter)

        presenter.view = viewController
        interactor.presenter = presenter
        router.viewController = viewController

        return viewController
    }
}

extension ArticleDetailRouter: ArticleDetailRouterSpecs {
    
}
