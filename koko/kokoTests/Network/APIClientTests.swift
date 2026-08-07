//
//  APIClientTests.swift
//  kokoTests
//
//  APIClient 負責「打 endpoint → 解 response 信封 → 回 Model」。
//  網路層以 HTTPClient protocol 注入，測試全程不碰真實網路。
//

import XCTest
@testable import koko

final class APIClientTests: XCTestCase {

    private func makeSUT(delayNanoseconds: UInt64 = 0) throws -> (APIClient, StubHTTPClient) {
        let stub = try StubHTTPClient.withAllFixtures(delayNanoseconds: delayNanoseconds)
        return (APIClient(httpClient: stub), stub)
    }

    // MARK: - User

    func test_fetchUser_decodesManFixture() async throws {
        let (sut, _) = try makeSUT()

        let user = try await sut.fetchUser()

        XCTAssertEqual(user.name, "蔡國泰")
        XCTAssertEqual(user.kokoID, "Mike")
    }

    func test_fetchUser_requestsUserEndpoint() async throws {
        let (sut, stub) = try makeSUT()

        _ = try await sut.fetchUser()

        let requested = await stub.requestedURLs
        XCTAssertEqual(requested, [Endpoint.user.url])
    }

    /// man.json 的 response 若是空陣列，沒有使用者可填 header —— 應明確報錯。
    func test_fetchUser_throwsWhenResponseIsEmpty() async throws {
        let (sut, stub) = try makeSUT()
        await stub.setStub(.success(Data(#"{"response": []}"#.utf8)), for: .user)

        await XCTAssertThrowsErrorAsync(try await sut.fetchUser()) { error in
            XCTAssertEqual(error as? APIError, .userNotFound)
        }
    }

    // MARK: - Friends

    func test_fetchFriends_decodesFixture() async throws {
        let (sut, _) = try makeSUT()

        let friends = try await sut.fetchFriends(from: .friends1)

        XCTAssertEqual(friends.map(\.fid), ["001", "002", "003", "004", "005"])
    }

    func test_fetchFriends_emptyResponse() async throws {
        let (sut, _) = try makeSUT()

        let friends = try await sut.fetchFriends(from: .noFriends)
        XCTAssertEqual(friends, [])
    }

    func test_fetchFriends_requestsCorrectEndpoint() async throws {
        let (sut, stub) = try makeSUT()

        _ = try await sut.fetchFriends(from: .friendsWithInvites)

        let requested = await stub.requestedURLs
        XCTAssertEqual(requested, [Endpoint.friendsWithInvites.url])
    }

    // MARK: - 錯誤傳遞（spec §10 O-4：不自動重試，錯誤往上拋）

    func test_fetchFriends_propagatesTransportError() async throws {
        struct Offline: Error, Equatable {}
        let (sut, stub) = try makeSUT()
        await stub.setStub(.failure(Offline()), for: .friends1)

        await XCTAssertThrowsErrorAsync(try await sut.fetchFriends(from: .friends1)) { error in
            XCTAssertEqual(error as? Offline, Offline())
        }
    }

    func test_fetchFriends_propagatesDecodingError() async throws {
        let (sut, stub) = try makeSUT()
        await stub.setStub(.success(Data(#"{"response": "not an array"}"#.utf8)), for: .friends1)

        await XCTAssertThrowsErrorAsync(try await sut.fetchFriends(from: .friends1))
    }

    /// 未知的 updateDate 格式應讓整份解碼失敗，而不是靜默略過該筆。
    func test_fetchFriends_propagatesUpdateDateParsingError() async throws {
        let (sut, stub) = try makeSUT()
        let malformed = #"""
        {"response": [{"name": "A", "status": 1, "isTop": "0", "fid": "001", "updateDate": "2019-08-01"}]}
        """#
        await stub.setStub(.success(Data(malformed.utf8)), for: .friends1)

        await XCTAssertThrowsErrorAsync(try await sut.fetchFriends(from: .friends1)) { error in
            XCTAssertEqual(error as? UpdateDate.ParsingError, .unrecognizedFormat("2019-08-01"))
        }
    }
}
