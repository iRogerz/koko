//
//  FriendRepositoryTests.swift
//  kokoTests
//
//  spec.md §5 三種情境 / AC-2・AC-3・AC-4・AC-6・AC-10
//  Repository 負責：依情境決定要打哪些 API、並行取得、合併去重。
//

import XCTest
@testable import koko

final class FriendRepositoryTests: XCTestCase {

    /// 併發測試需要一點延遲，並行的請求才會真的在途重疊。
    private static let concurrencyProbeDelay: UInt64 = 50_000_000  // 50ms

    private func makeSUT(delayNanoseconds: UInt64 = 0) throws -> (FriendRepository, StubHTTPClient) {
        let stub = try StubHTTPClient.withAllFixtures(delayNanoseconds: delayNanoseconds)
        return (FriendRepository(apiClient: APIClient(httpClient: stub)), stub)
    }

    // MARK: - 情境 I：無好友（AC-2）

    func test_load_noFriends_returnsEmptyFriendList() async throws {
        let (sut, _) = try makeSUT()

        let data = try await sut.load(.noFriends)

        XCTAssertTrue(data.friends.isEmpty, "F4 的 response 是空陣列")
        XCTAssertEqual(data.user.name, "蔡國泰", "情境 I 仍要打 U 來填 header（AC-10）")
    }

    func test_load_noFriends_requestsUserAndFriend4() async throws {
        let (sut, stub) = try makeSUT()

        _ = try await sut.load(.noFriends)

        let requested = await stub.requestedURLs
        XCTAssertEqual(Set(requested), [Endpoint.user.url, Endpoint.noFriends.url])
        XCTAssertEqual(requested.count, 2, "不得重複請求")
    }

    // MARK: - 情境 II：只有好友列表（AC-3 / AC-4）

    /// 合併結果必須與 spec §5.3 黃金樣本逐筆相符。
    func test_load_friendsOnly_matchesGoldenSample() async throws {
        let (sut, _) = try makeSUT()

        let data = try await sut.load(.friendsOnly)

        XCTAssertEqual(data.friends.count, 6)
        XCTAssertEqual(data.friends.map(\.fid), ["001", "002", "003", "004", "005", "012"])
        XCTAssertEqual(
            data.friends.map(\.status),
            [.completed, .inviting, .completed, .completed, .completed, .completed]
        )
        XCTAssertEqual(data.friends.map(\.isTop), [false, true, false, false, false, false])
    }

    /// §5.3 的結論：情境 II 沒有邀請卡片 → 狀態 B（需求 (2)-II）。
    func test_load_friendsOnly_hasNoInvitationCards() async throws {
        let (sut, _) = try makeSUT()

        let data = try await sut.load(.friendsOnly)

        XCTAssertTrue(data.friends.filter(\.isInvitationCard).isEmpty)
    }

    func test_load_friendsOnly_requestsUserAndBothFriendLists() async throws {
        let (sut, stub) = try makeSUT()

        _ = try await sut.load(.friendsOnly)

        let requested = await stub.requestedURLs
        XCTAssertEqual(
            Set(requested),
            [Endpoint.user.url, Endpoint.friends1.url, Endpoint.friends2.url]
        )
        XCTAssertEqual(requested.count, 3)
    }

    // MARK: - AC-3 並行

    /// AC-3 明文要求情境 II「**並行**請求兩支 API」。
    /// 加上同時要打的 U，三支請求應該同時在途。
    /// 若有人改成循序 await，maxConcurrentRequests 會掉到 1，這裡就會失敗。
    func test_load_friendsOnly_requestsInParallel() async throws {
        let (sut, stub) = try makeSUT(delayNanoseconds: Self.concurrencyProbeDelay)

        _ = try await sut.load(.friendsOnly)

        let maxConcurrent = await stub.maxConcurrentRequests
        XCTAssertEqual(maxConcurrent, 3, "U + F1 + F2 應同時在途，實測最大併發為 \(maxConcurrent)")
    }

    /// 單一好友清單的情境，使用者 API 也要與好友 API 並行（spec §5）。
    func test_load_singleListScenarios_requestUserInParallel() async throws {
        for scenario in [Scenario.noFriends, .friendsWithInvites] {
            let (sut, stub) = try makeSUT(delayNanoseconds: Self.concurrencyProbeDelay)

            _ = try await sut.load(scenario)

            let maxConcurrent = await stub.maxConcurrentRequests
            XCTAssertEqual(maxConcurrent, 2, "\(scenario)：U 與好友 API 應並行")
        }
    }

    /// 併發正確性的反面檢查：並行不得讓結果錯亂。
    func test_load_isDeterministicUnderConcurrency() async throws {
        for _ in 0..<20 {
            let (sut, _) = try makeSUT()
            let data = try await sut.load(.friendsOnly)

            XCTAssertEqual(data.friends.map(\.fid), ["001", "002", "003", "004", "005", "012"])
        }
    }

    // MARK: - 情境 III：好友含邀請（AC-6）

    func test_load_friendsWithInvites_splitsIntoTwoAndThree() async throws {
        let (sut, _) = try makeSUT()

        let data = try await sut.load(.friendsWithInvites)

        let invites = data.friends.filter(\.isInvitationCard)
        let list = data.friends.filter { !$0.isInvitationCard }

        XCTAssertEqual(invites.map(\.fid), ["001", "002"], "邀請卡片 2 張")
        XCTAssertEqual(list.map(\.fid), ["003", "007", "008"], "好友清單 3 筆")
        XCTAssertEqual(list.map(\.status), [.completed, .inviting, .inviting])
    }

    func test_load_friendsWithInvites_requestsUserAndFriend3() async throws {
        let (sut, stub) = try makeSUT()

        _ = try await sut.load(.friendsWithInvites)

        let requested = await stub.requestedURLs
        XCTAssertEqual(Set(requested), [Endpoint.user.url, Endpoint.friendsWithInvites.url])
    }

    // MARK: - AC-10 header 資料

    func test_load_allScenarios_returnUser() async throws {
        for scenario in Scenario.allCases {
            let (sut, _) = try makeSUT()

            let data = try await sut.load(scenario)

            XCTAssertEqual(data.user.name, "蔡國泰", "\(scenario) 也要取得使用者資料")
            XCTAssertEqual(data.user.kokoID, "Mike")
        }
    }

    // MARK: - 錯誤（spec §10 O-4：往上拋，不自動重試）

    func test_load_propagatesUserAPIError() async throws {
        struct Offline: Error, Equatable {}
        let (sut, stub) = try makeSUT()
        await stub.setStub(.failure(Offline()), for: .user)

        await XCTAssertThrowsErrorAsync(try await sut.load(.friendsOnly)) { error in
            XCTAssertEqual(error as? Offline, Offline())
        }
    }

    /// §5.1 規則 1：F1、F2 兩者都成功才合併。任一失敗即整體失敗。
    func test_load_friendsOnly_failsIfEitherListFails() async throws {
        struct Offline: Error, Equatable {}

        for failing in [Endpoint.friends1, .friends2] {
            let (sut, stub) = try makeSUT()
            await stub.setStub(.failure(Offline()), for: failing)

            await XCTAssertThrowsErrorAsync(try await sut.load(.friendsOnly), "\(failing) 失敗時應整體失敗") { error in
                XCTAssertEqual(error as? Offline, Offline())
            }
        }
    }

    func test_load_doesNotRetryOnFailure() async throws {
        struct Offline: Error, Equatable {}
        let (sut, stub) = try makeSUT()
        await stub.setStub(.failure(Offline()), for: .friends1)

        await XCTAssertThrowsErrorAsync(try await sut.load(.friendsOnly))

        let requested = await stub.requestedURLs
        let attempts = requested.filter { $0 == Endpoint.friends1.url }
        XCTAssertEqual(attempts.count, 1, "O-4：不做自動重試")
    }
}
