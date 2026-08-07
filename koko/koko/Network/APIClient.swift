//
//  APIClient.swift
//  koko
//
//  負責「打 endpoint → 解 `{ "response": [...] }` 信封 → 回 Model」。
//  網路存取本身委派給注入的 HTTPClient。
//
//  錯誤一律往上拋，不在此吞掉也不自動重試（spec.md §10 O-4）。
//

import Foundation

enum APIError: Error, Equatable {

    /// `man.json` 的 `response` 是空陣列，沒有使用者可以填 header。
    case userNotFound
}

/// 無狀態服務，可安全跨 task 邊界共用。
/// 刻意不儲存 `JSONDecoder`（它不是 Sendable），改為解碼當下建立。
final class APIClient: Sendable {

    private let httpClient: HTTPClient

    init(httpClient: HTTPClient) {
        self.httpClient = httpClient
    }

    /// spec.md §3.1：`man.json` 的 `response` 是陣列，但只取第一筆。
    func fetchUser() async throws -> User {
        let users: [User] = try await fetch(from: .user)
        guard let user = users.first else {
            throw APIError.userNotFound
        }
        return user
    }

    func fetchFriends(from endpoint: Endpoint) async throws -> [Friend] {
        try await fetch(from: endpoint)
    }

    private func fetch<T: Decodable>(from endpoint: Endpoint) async throws -> [T] {
        let data = try await httpClient.data(from: endpoint.url)
        return try JSONDecoder().decode(APIResponse<T>.self, from: data).response
    }
}
