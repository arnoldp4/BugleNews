//
//  CategoryListPresenter.swift
//  BugleNews
//
//  Created by Arnold Pangestu on 19/11/26.
//

import Foundation

final class CategoryListPresenter {
    weak var view: CategoryListViewSpecs?

    private let interactor: CategoryListInteractorInputSpecs
    private let router: CategoryListRouterSpecs
    private var categories: [NewsCategory] = []

    init(
        interactor: CategoryListInteractorInputSpecs,
        router: CategoryListRouterSpecs
    ) {
        self.interactor = interactor
        self.router = router
    }
}

extension CategoryListPresenter: CategoryListPresenterSpecs {
    func viewDidLoad() {
        interactor.fetchCategories()
    }

    func didSelectCategory(at index: Int) {
        guard categories.indices.contains(index) else { return }
        router.navigateToSourceList(category: categories[index])
    }
}

extension CategoryListPresenter: CategoryListInteractorOutputSpecs {
    func didFetchCategories(_ categories: [NewsCategory]) {
        self.categories = categories
        let rows = categories.map { category in
            CategoryRowItem(title: category.title, subtitle: category.subtitle)
        }
        view?.render(state: CategoryListViewState(title: "Categories", items: rows))
    }
}
