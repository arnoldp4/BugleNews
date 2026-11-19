//
//  NewsModels.swift
//  BugleNews
//
//  Created by Arnold Pangestu on 19/11/26.
//

import Foundation

struct NewsCategory: Equatable {
    let id: String
    let title: String
    let subtitle: String
}

struct SourcesResponse: Decodable {
    let status: String
    let sources: [NewsSource]
}

struct NewsSource: Decodable, Equatable {
    let id: String
    let name: String
    let description: String
    let url: String
    let category: String
    let language: String
    let country: String
}

struct ArticlesResponse: Decodable {
    let status: String
    let totalResults: Int
    let articles: [NewsArticle]
}

struct NewsArticle: Decodable, Equatable {
    let source: ArticleSourceRef
    let author: String?
    let title: String
    let description: String?
    let url: String
    let publishedAt: String
}

struct ArticleSourceRef: Decodable, Equatable {
    let id: String?
    let name: String
}

struct ErrorAlertState: Equatable {
    let title: String
    let message: String
}
