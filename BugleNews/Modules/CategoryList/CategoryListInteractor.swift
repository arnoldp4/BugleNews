//
//  CategoryListInteractor.swift
//  BugleNews
//
//  Created by Arnold Pangestu on 19/11/26.
//

import Foundation

final class CategoryListInteractor {
    weak var presenter: CategoryListInteractorOutputSpecs?

    private let defaultCategories: [NewsCategory] = [
        NewsCategory(id: "business", title: "Business", subtitle: "Markets, finance, and industry updates"),
        NewsCategory(id: "entertainment", title: "Entertainment", subtitle: "Movies, music, and pop culture"),
        NewsCategory(id: "general", title: "General", subtitle: "Top headlines and world news"),
        NewsCategory(id: "health", title: "Health", subtitle: "Medical research and wellness"),
        NewsCategory(id: "science", title: "Science", subtitle: "Discoveries, space, and environment"),
        NewsCategory(id: "sports", title: "Sports", subtitle: "Scores, leagues, and athletics"),
        NewsCategory(id: "technology", title: "Technology", subtitle: "Software, hardware, and innovation")
    ]

    init() {}
}

extension CategoryListInteractor: CategoryListInteractorInputSpecs {
    func fetchCategories() {
        presenter?.didFetchCategories(defaultCategories)
    }
}
