//
//  EndpointTests.swift
//  kokoTests
//
//  spec.md §3：五支 API 的位址。
//  網址打錯是最沉默的錯誤（測試用 stub 不會發現），所以這裡逐字釘死。
//

import XCTest
@testable import koko

final class EndpointTests: XCTestCase {

    func test_endpoint_urls() {
        XCTAssertEqual(Endpoint.user.url.absoluteString, "https://dimanyen.github.io/man.json")
        XCTAssertEqual(Endpoint.friends1.url.absoluteString, "https://dimanyen.github.io/friend1.json")
        XCTAssertEqual(Endpoint.friends2.url.absoluteString, "https://dimanyen.github.io/friend2.json")
        XCTAssertEqual(Endpoint.friendsWithInvites.url.absoluteString, "https://dimanyen.github.io/friend3.json")
        XCTAssertEqual(Endpoint.noFriends.url.absoluteString, "https://dimanyen.github.io/friend4.json")
    }

    func test_endpoint_hasExactlyFiveCases() {
        XCTAssertEqual(Endpoint.allCases.count, 5)
    }

    func test_endpoint_urlsAreUnique() {
        let urls = Set(Endpoint.allCases.map(\.url))
        XCTAssertEqual(urls.count, Endpoint.allCases.count, "每支 endpoint 必須指向不同網址")
    }

    /// `StubHTTPClient` 依賴 Endpoint 與 Fixture 的 rawValue 一致來配對離線樣本。
    func test_endpoint_rawValuesMatchFixtureNames() {
        for endpoint in Endpoint.allCases {
            XCTAssertNotNil(
                Fixture(rawValue: endpoint.rawValue),
                "\(endpoint) 找不到對應的 fixture，StubHTTPClient 會配不到樣本"
            )
        }
    }

    // MARK: - 情境 → endpoint 對應（spec §5）

    func test_scenario_friendEndpoints() {
        XCTAssertEqual(Scenario.noFriends.friendEndpoints, [.noFriends], "情境 I：F4")
        XCTAssertEqual(Scenario.friendsOnly.friendEndpoints, [.friends1, .friends2], "情境 II：F1 + F2")
        XCTAssertEqual(Scenario.friendsWithInvites.friendEndpoints, [.friendsWithInvites], "情境 III：F3")
    }

    func test_scenario_hasExactlyThreeCases() {
        XCTAssertEqual(Scenario.allCases.count, 3)
    }
}
