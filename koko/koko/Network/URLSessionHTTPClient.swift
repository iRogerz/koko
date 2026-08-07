//
//  URLSessionHTTPClient.swift
//  koko
//
//  HTTPClient 的正式實作。刻意做到極薄 —— 只有「發請求 + 檢查狀態碼」，
//  所有值得測的邏輯都在 APIClient 與 Repository，那兩層用 StubHTTPClient 測。
//

import Foundation

final class URLSessionHTTPClient: HTTPClient {

    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func data(from url: URL) async throws -> Data {
        let (data, response) = try await session.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw HTTPClientError.invalidResponse
        }
        guard (200..<300).contains(httpResponse.statusCode) else {
            throw HTTPClientError.unacceptableStatusCode(httpResponse.statusCode)
        }

        return data
    }
}
