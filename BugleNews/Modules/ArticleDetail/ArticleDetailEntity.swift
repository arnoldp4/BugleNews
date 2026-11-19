//
//  ArticleDetailEntity.swift
//  BugleNews
//
//  Created by Arnold Pangestu on 19/11/26.
//

import Foundation

protocol ArticleDetailViewSpecs: AnyObject {
    func render(state: ArticleDetailViewState)
    func load(url: URL)
}

protocol ArticleDetailPresenterSpecs: AnyObject {
    func viewDidLoad()
    func didStartLoading()
    func didFinishLoading()
    func didFailLoading(message: String)
    func didTapRetry()
}

protocol ArticleDetailInteractorInputSpecs: AnyObject {
    func validateArticleURL(_ urlString: String)
}

protocol ArticleDetailInteractorOutputSpecs: AnyObject {
    func didValidateURL(_ url: URL)
    func didFailValidatingURL(message: String)
}

protocol ArticleDetailRouterSpecs: AnyObject {
    
}

struct ArticleDetailViewState: Equatable {
    let title: String
    let isLoading: Bool
    let errorMessage: String?
}
