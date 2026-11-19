//
//  CategoryListEntity.swift
//  BugleNews
//
//  Created by Arnold Pangestu on 19/11/26.
//

import Foundation

protocol CategoryListViewSpecs: AnyObject {
    func render(state: CategoryListViewState)
}

protocol CategoryListPresenterSpecs: AnyObject {
    func viewDidLoad()
    func didSelectCategory(at index: Int)
}

protocol CategoryListInteractorInputSpecs: AnyObject {
    func fetchCategories()
}

protocol CategoryListInteractorOutputSpecs: AnyObject {
    func didFetchCategories(_ categories: [NewsCategory])
}

protocol CategoryListRouterSpecs: AnyObject {
    func navigateToSourceList(category: NewsCategory)
}

struct CategoryListViewState: Equatable {
    let title: String
    let items: [CategoryRowItem]
}

struct CategoryRowItem: Equatable {
    let title: String
    let subtitle: String
}
