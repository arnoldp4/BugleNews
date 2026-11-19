//
//  NewsServices.swift
//  BugleNews
//
//  Created by Arnold Pangestu on 19/11/26.
//

import Foundation

enum NewsServiceError: Error, Equatable {
    case missingAPIKey
    case invalidURL
    case networkFailure(String)
    case decodingFailure
    case apiError(message: String)
}

protocol NewsServiceProtocol {
    func fetchSources(
        category: String,
        completion: @escaping (Result<[NewsSource], NewsServiceError>) -> Void
    )
    func fetchArticles(
        sourceId: String,
        query: String?,
        page: Int,
        pageSize: Int,
        completion: @escaping (Result<ArticlesResponse, NewsServiceError>) -> Void
    )
}

final class NewsServices: NewsServiceProtocol {
    private let session: URLSession
    private let apiKeyProvider: () -> String?
    private let baseURLString = "https://newsapi.org/v2"

    init(
        session: URLSession = .shared,
        apiKeyProvider: @escaping () -> String? = {
            guard
                let path = Bundle.main.path(forResource: "Config", ofType: "plist"),
                let dict = NSDictionary(contentsOfFile: path),
                let key = dict["NEWS_API_KEY"] as? String,
                !key.isEmpty
            else {
                return nil
            }
            return key
        }
    ) {
        self.session = session
        self.apiKeyProvider = apiKeyProvider
    }

    func fetchSources(
        category: String,
        completion: @escaping (Result<[NewsSource], NewsServiceError>) -> Void
    ) {
        guard let apiKey = apiKeyProvider() else {
            completion(.failure(.missingAPIKey))
            return
        }

        var components = URLComponents(string: "\(baseURLString)/top-headlines/sources")
        components?.queryItems = [
            URLQueryItem(name: "category", value: category),
            URLQueryItem(name: "apiKey", value: apiKey)
        ]

        guard let url = components?.url else {
            completion(.failure(.invalidURL))
            return
        }

        performRequest(url: url) { (result: Result<SourcesResponse, NewsServiceError>) in
            switch result {
            case .success(let response):
                completion(.success(response.sources))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    func fetchArticles(
        sourceId: String,
        query: String?,
        page: Int,
        pageSize: Int,
        completion: @escaping (Result<ArticlesResponse, NewsServiceError>) -> Void
    ) {
        guard let apiKey = apiKeyProvider() else {
            completion(.failure(.missingAPIKey))
            return
        }

        var components = URLComponents(string: "\(baseURLString)/everything")
        var items: [URLQueryItem] = [
            URLQueryItem(name: "sources", value: sourceId),
            URLQueryItem(name: "page", value: String(page)),
            URLQueryItem(name: "pageSize", value: String(pageSize)),
            URLQueryItem(name: "apiKey", value: apiKey)
        ]

        if let trimmedQuery = query?.trimmingCharacters(in: .whitespacesAndNewlines), !trimmedQuery.isEmpty {
            items.append(URLQueryItem(name: "q", value: trimmedQuery))
        }

        components?.queryItems = items

        guard let url = components?.url else {
            completion(.failure(.invalidURL))
            return
        }

        performRequest(url: url, completion: completion)
    }

    private func performRequest<T: Decodable>(
        url: URL,
        completion: @escaping (Result<T, NewsServiceError>) -> Void
    ) {
        session.dataTask(with: url) { data, response, error in
            if let error = error {
                DispatchQueue.main.async {
                    completion(.failure(.networkFailure(error.localizedDescription)))
                }
                return
            }

            guard let data = data else {
                DispatchQueue.main.async {
                    completion(.failure(.decodingFailure))
                }
                return
            }

            if let httpResponse = response as? HTTPURLResponse, !(200...299).contains(httpResponse.statusCode) {
                let apiErr = try? JSONDecoder().decode(NewsAPIErrorPayload.self, from: data)
                DispatchQueue.main.async {
                    completion(.failure(.apiError(message: apiErr?.message ?? "Request failed (\(httpResponse.statusCode))")))
                }
                return
            }

            do {
                let decoded = try JSONDecoder().decode(T.self, from: data)
                DispatchQueue.main.async {
                    completion(.success(decoded))
                }
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(.decodingFailure))
                }
            }
        }.resume()
    }
}

private struct NewsAPIErrorPayload: Decodable {
    let message: String?
}
