//
//  HTTPClient.swift
//  koko
//
//  網路存取的最小介面。抽成 protocol 是為了讓 APIClient 與 Repository
//  可以在完全不碰真實網路的情況下被測試（測試注入 StubHTTPClient）。
//

import Foundation

protocol HTTPClient: Sendable {

    /// 取得該 URL 的原始回應內容。
    /// - Throws: 傳輸錯誤，或非 2xx 的 `HTTPClientError.unacceptableStatusCode`。
    func data(from url: URL) async throws -> Data
}

enum HTTPClientError: Error, Equatable {

    /// 回應不是 `HTTPURLResponse`。
    case invalidResponse

    /// 狀態碼不在 200..<300。
    case unacceptableStatusCode(Int)
}
