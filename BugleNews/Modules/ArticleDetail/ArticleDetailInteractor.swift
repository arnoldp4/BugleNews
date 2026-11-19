//
//  ArticleDetailInteractor.swift
//  BugleNews
//
//  Created by Arnold Pangestu on 19/11/26.
//

import Foundation

final class ArticleDetailInteractor {
    weak var presenter: ArticleDetailInteractorOutputSpecs?

    init() {}
}

extension ArticleDetailInteractor: ArticleDetailInteractorInputSpecs {
    func validateArticleURL(_ urlString: String) {
        let trimmed = urlString.trimmingCharacters(in: .whitespacesAndNewlines)
        guard
            !trimmed.isEmpty,
            let url = URL(string: trimmed),
            let scheme = url.scheme?.lowercased(),
            scheme == "https" || scheme == "http"
        else {
            presenter?.didFailValidatingURL(message: "Invalid or unsupported article URL.")
            return
        }

        presenter?.didValidateURL(url)
    }
}
