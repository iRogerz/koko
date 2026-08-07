//
//  StubHTTPClient.swift
//  kokoTests
//
//  取代 URLSession 的測試替身。除了回傳離線 fixture，還負責記錄：
//  - 實際請求了哪些 URL（順序）
//  - 同時在途的最大請求數 —— 用來驗證 AC-3 的「並行」要求
//
//  用 actor 是因為多個請求會並行進來，計數必須安全。
//  actor 的 reentrancy 讓請求在 Task.sleep 掛起時可以彼此重疊，
//  正好可以觀測到真實的併發程度。
//

import Foundation
@testable import koko

actor StubHTTPClient: HTTPClient {

    enum Stub {
        case success(Data)
        case failure(Error)
    }

    struct UnstubbedURL: Error, Equatable {
        let url: URL
    }

    private var stubs: [URL: Stub]
    private let delayNanoseconds: UInt64

    private(set) var requestedURLs: [URL] = []
    private(set) var maxConcurrentRequests = 0
    private var inFlightRequests = 0

    init(stubs: [URL: Stub] = [:], delayNanoseconds: UInt64 = 0) {
        self.stubs = stubs
        self.delayNanoseconds = delayNanoseconds
    }

    func data(from url: URL) async throws -> Data {
        requestedURLs.append(url)
        inFlightRequests += 1
        maxConcurrentRequests = max(maxConcurrentRequests, inFlightRequests)
        defer { inFlightRequests -= 1 }

        if delayNanoseconds > 0 {
            try await Task.sleep(nanoseconds: delayNanoseconds)
        }

        switch stubs[url] {
        case .success(let data):
            return data
        case .failure(let error):
            throw error
        case nil:
            throw UnstubbedURL(url: url)
        }
    }

    func setStub(_ stub: Stub, for endpoint: Endpoint) {
        stubs[endpoint.url] = stub
    }
}

extension StubHTTPClient {

    /// 五支 endpoint 全部對應到 `Fixtures/` 的離線 JSON。
    ///
    /// - Parameter delayNanoseconds: 給併發測試用。加一點延遲，
    ///   並行的請求才會真的在途重疊，`maxConcurrentRequests` 才量得到。
    static func withAllFixtures(delayNanoseconds: UInt64 = 0) throws -> StubHTTPClient {
        var stubs: [URL: Stub] = [:]
        for endpoint in Endpoint.allCases {
            let fixture = try fixture(for: endpoint)
            stubs[endpoint.url] = .success(try FixtureLoader.data(fixture))
        }
        return StubHTTPClient(stubs: stubs, delayNanoseconds: delayNanoseconds)
    }

    /// `Endpoint` 與 `Fixture` 的 rawValue 刻意一致（man / friend1…friend4）。
    private static func fixture(for endpoint: Endpoint) throws -> Fixture {
        guard let fixture = Fixture(rawValue: endpoint.rawValue) else {
            throw UnstubbedURL(url: endpoint.url)
        }
        return fixture
    }
}
