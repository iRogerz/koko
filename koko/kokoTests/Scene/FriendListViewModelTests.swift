//
//  FriendListViewModelTests.swift
//  kokoTests
//
//  spec.md §4.3 狀態機 / §6.4 搜尋 / §7.1 view state
//  AC-2・AC-6・AC-7・AC-8・AC-9・AC-10・AC-11・AC-12
//

import XCTest
import Combine
@testable import koko

@MainActor
final class FriendListViewModelTests: XCTestCase {

    private func makeSUT(
        scenario: Scenario = .friendsOnly,
        friends: [Friend]
    ) -> (FriendListViewModel, StubFriendRepository) {
        let repository = StubFriendRepository(friends: friends)
        return (FriendListViewModel(scenario: scenario, repository: repository), repository)
    }

    // MARK: - 初始狀態

    /// 註：本類別標了 `@MainActor`，測試方法一律寫成 `async`。
    /// MainActor 隔離的**同步**測試方法會與 XCTest 的 ObjC 呼叫路徑衝突而 abort。
    func test_initialState_isLoadingWithoutUser() async {
        let (sut, _) = makeSUT(friends: [])

        XCTAssertNil(sut.state.user)
        assertLoading(sut.state.content)
    }

    func test_load_doesNotRequestUntilCalled() async {
        let (_, repository) = makeSUT(friends: [])

        let count = await repository.loadCount
        XCTAssertEqual(count, 0, "init 不得觸發網路請求")
    }

    // MARK: - 狀態 A：無好友（AC-2）

    /// spec.md §9 `test_state_empty`
    func test_load_withNoFriends_isEmpty() async {
        let (sut, _) = makeSUT(scenario: .noFriends, friends: [])

        await sut.load()

        assertEmpty(sut.state.content)
    }

    /// **關鍵**：空狀態以「合併後好友總數為 0」判定，不是「一般好友數為 0」。
    /// 只有邀請、沒有一般好友時仍屬狀態 C，不得掉進空狀態畫面。
    func test_load_withOnlyInvitations_isNotEmpty() async throws {
        let invitesOnly = try [
            FriendBuilder.make(fid: "001", name: "黃靖僑", status: .invitationSent),
            FriendBuilder.make(fid: "002", name: "翁勳儀", status: .invitationSent),
        ]
        let (sut, _) = makeSUT(friends: invitesOnly)

        await sut.load()

        let loaded = try unwrapLoaded(sut.state.content)
        XCTAssertEqual(loaded.invites.count, 2)
        XCTAssertTrue(loaded.friends.isEmpty)
    }

    // MARK: - 狀態 B：好友無邀請

    /// spec.md §9 `test_state_loadedWithoutInvites`
    func test_load_friendsWithoutInvitations() async throws {
        let (sut, _) = makeSUT(friends: try goldenSampleFriends())

        await sut.load()

        let loaded = try unwrapLoaded(sut.state.content)
        XCTAssertTrue(loaded.invites.isEmpty, "情境 II 不得有邀請卡片")
        XCTAssertEqual(loaded.friends.count, 6)
    }

    /// AC-8：`isTop` 置頂。002（翁勳儀）是唯一置頂者。
    func test_load_appliesTopPinnedSorting() async throws {
        let (sut, _) = makeSUT(friends: try goldenSampleFriends())

        await sut.load()

        let loaded = try unwrapLoaded(sut.state.content)
        XCTAssertEqual(loaded.friends.map(\.fid), ["002", "001", "003", "004", "005", "012"])
    }

    // MARK: - 狀態 C：好友含邀請（AC-6 / AC-7）

    /// spec.md §9 `test_state_loadedWithInvites`
    func test_load_friendsWithInvitations() async throws {
        let (sut, _) = makeSUT(scenario: .friendsWithInvites, friends: try friend3Friends())

        await sut.load()

        let loaded = try unwrapLoaded(sut.state.content)
        XCTAssertEqual(loaded.invites.map(\.fid), ["001", "002"], "邀請卡片 2 張")
        XCTAssertEqual(loaded.friends.map(\.fid), ["003", "007", "008"], "好友清單 3 筆")
    }

    /// AC-7：status 2 留在好友清單（顯示「邀請中」），不進邀請卡片區。
    func test_load_statusTwoStaysInFriendList() async throws {
        let (sut, _) = makeSUT(scenario: .friendsWithInvites, friends: try friend3Friends())

        await sut.load()

        let loaded = try unwrapLoaded(sut.state.content)
        XCTAssertTrue(loaded.invites.allSatisfy { $0.status == .invitationSent })
        XCTAssertEqual(loaded.friends.filter { $0.status == .inviting }.map(\.fid), ["007", "008"])
    }

    // MARK: - AC-10 header

    func test_load_exposesUserForHeader() async {
        let (sut, _) = makeSUT(friends: [])

        await sut.load()

        XCTAssertEqual(sut.state.user?.name, "蔡國泰")
        XCTAssertEqual(sut.state.user?.kokoID, "Mike")
    }

    // MARK: - AC-9 搜尋

    /// spec.md §9 `test_search_filtersFriendsOnly` —— 關鍵字不影響邀請卡片區。
    func test_search_filtersFriendListButNotInvitations() async throws {
        let (sut, _) = makeSUT(scenario: .friendsWithInvites, friends: try friend3Friends())
        await sut.load()

        sut.search("彭")

        let loaded = try unwrapLoaded(sut.state.content)
        XCTAssertEqual(loaded.friends.map(\.fid), ["007"], "好友清單被篩選")
        XCTAssertEqual(loaded.invites.map(\.fid), ["001", "002"], "邀請卡片區不受影響")
    }

    /// spec.md §9 `test_search_emptyKeywordRestoresAll`
    func test_search_emptyKeywordRestoresFullList() async throws {
        let (sut, _) = makeSUT(friends: try goldenSampleFriends())
        await sut.load()

        sut.search("梁")
        XCTAssertEqual(try unwrapLoaded(sut.state.content).friends.count, 2)

        sut.search("")
        XCTAssertEqual(try unwrapLoaded(sut.state.content).friends.count, 6)
    }

    /// spec.md §6.4：搜尋無結果顯示空清單，**不切換成狀態 A 空狀態畫面**。
    func test_search_withNoMatches_staysLoadedWithEmptyList() async throws {
        let (sut, _) = makeSUT(friends: try goldenSampleFriends())
        await sut.load()

        sut.search("查無此人")

        // 狀態若退化成 .empty，unwrapLoaded 會直接失敗 —— 這正是本測試要擋的。
        let loaded = try unwrapLoaded(sut.state.content)
        XCTAssertTrue(loaded.friends.isEmpty, "清單為空，但畫面仍是 .loaded")
    }

    func test_search_keepsTopPinnedSorting() async throws {
        let (sut, _) = makeSUT(friends: try goldenSampleFriends())
        await sut.load()

        sut.search("儀")

        XCTAssertEqual(try unwrapLoaded(sut.state.content).friends.map(\.fid), ["002"])
    }

    // MARK: - AC-12 下拉更新

    func test_refresh_reloadsSameScenario() async throws {
        let (sut, repository) = makeSUT(scenario: .friendsWithInvites, friends: try friend3Friends())
        await sut.load()

        await sut.refresh()

        let scenarios = await repository.requestedScenarios
        XCTAssertEqual(scenarios, [.friendsWithInvites, .friendsWithInvites])
    }

    func test_refresh_picksUpNewData() async throws {
        let (sut, repository) = makeSUT(friends: try goldenSampleFriends())
        await sut.load()

        await repository.setFriends(try [FriendBuilder.make(fid: "999", name: "新朋友")])
        await sut.refresh()

        XCTAssertEqual(try unwrapLoaded(sut.state.content).friends.map(\.fid), ["999"])
    }

    func test_refresh_keepsActiveKeyword() async throws {
        let (sut, _) = makeSUT(friends: try goldenSampleFriends())
        await sut.load()
        sut.search("梁")

        await sut.refresh()

        XCTAssertEqual(try unwrapLoaded(sut.state.content).friends.count, 2, "下拉更新不應清掉搜尋關鍵字")
    }

    /// 下拉更新時不該閃回 loading 骨架（下拉本身已有轉圈動畫）。
    func test_refresh_doesNotShowLoadingState() async throws {
        let (sut, _) = makeSUT(friends: try goldenSampleFriends())
        await sut.load()

        var observedContents: [FriendListViewState.Content] = []
        let cancellable = sut.statePublisher.sink { observedContents.append($0.content) }
        defer { cancellable.cancel() }

        await sut.refresh()

        XCTAssertFalse(
            observedContents.contains { if case .loading = $0 { return true } else { return false } },
            "refresh 期間不得進入 .loading"
        )
    }

    // MARK: - 錯誤（spec §10 O-4）

    func test_load_failure_setsFailedState() async {
        struct Offline: Error {}
        let repository = StubFriendRepository(result: .failure(Offline()))
        let sut = FriendListViewModel(scenario: .friendsOnly, repository: repository)

        await sut.load()

        guard case .failed(let error) = sut.state.content else {
            return XCTFail("預期 .failed，實際 \(sut.state.content)")
        }
        XCTAssertTrue(error is Offline)
    }

    func test_load_failureThenRetry_recovers() async throws {
        struct Offline: Error {}
        let repository = StubFriendRepository(result: .failure(Offline()))
        let sut = FriendListViewModel(scenario: .friendsOnly, repository: repository)
        await sut.load()

        await repository.setFriends(try goldenSampleFriends())
        await sut.load()

        XCTAssertEqual(try unwrapLoaded(sut.state.content).friends.count, 6)
    }

    // MARK: - 邀請卡片的 ✓ / ✕（spec §6.2、§10 O-6）

    func test_respondToInvitation_removesItLocally() async throws {
        let (sut, repository) = makeSUT(scenario: .friendsWithInvites, friends: try friend3Friends())
        await sut.load()

        sut.respondToInvitation(fid: "001")

        let loaded = try unwrapLoaded(sut.state.content)
        XCTAssertEqual(loaded.invites.map(\.fid), ["002"])
        XCTAssertEqual(loaded.friends.map(\.fid), ["003", "007", "008"], "好友清單不受影響")

        let count = await repository.loadCount
        XCTAssertEqual(count, 1, "§6.2：無對應 API，不得重打後端")
    }

    /// 所有邀請都處理完 → 邀請區清空，但仍有好友 → 狀態 B，不是狀態 A。
    func test_respondToAllInvitations_fallsBackToStateB() async throws {
        let (sut, _) = makeSUT(scenario: .friendsWithInvites, friends: try friend3Friends())
        await sut.load()

        sut.respondToInvitation(fid: "001")
        sut.respondToInvitation(fid: "002")

        let loaded = try unwrapLoaded(sut.state.content)
        XCTAssertTrue(loaded.invites.isEmpty)
        XCTAssertEqual(loaded.friends.count, 3)
    }

    /// 全部處理完且沒有其他好友 → 這時才是狀態 A。
    func test_respondToAllInvitations_withNoOtherFriends_becomesEmpty() async throws {
        let invitesOnly = try [FriendBuilder.make(fid: "001", status: .invitationSent)]
        let (sut, _) = makeSUT(friends: invitesOnly)
        await sut.load()

        sut.respondToInvitation(fid: "001")

        assertEmpty(sut.state.content)
    }

    func test_respondToUnknownInvitation_isNoOp() async throws {
        let (sut, _) = makeSUT(scenario: .friendsWithInvites, friends: try friend3Friends())
        await sut.load()

        sut.respondToInvitation(fid: "does-not-exist")

        XCTAssertEqual(try unwrapLoaded(sut.state.content).invites.count, 2)
    }

    // MARK: - Fixtures

    private func goldenSampleFriends() throws -> [Friend] {
        FriendMerger.merge(
            try FixtureLoader.friends(.friend1),
            try FixtureLoader.friends(.friend2)
        )
    }

    private func friend3Friends() throws -> [Friend] {
        try FixtureLoader.friends(.friend3)
    }

    // MARK: - Assertions

    private func unwrapLoaded(
        _ content: FriendListViewState.Content,
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws -> (invites: [Friend], friends: [Friend]) {
        guard case .loaded(let invites, let friends) = content else {
            XCTFail("預期 .loaded，實際 \(content)", file: file, line: line)
            throw UnexpectedState()
        }
        return (invites, friends)
    }

    private func assertEmpty(
        _ content: FriendListViewState.Content,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        guard case .empty = content else {
            return XCTFail("預期 .empty，實際 \(content)", file: file, line: line)
        }
    }

    private func assertLoading(
        _ content: FriendListViewState.Content,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        guard case .loading = content else {
            return XCTFail("預期 .loading，實際 \(content)", file: file, line: line)
        }
    }

    private struct UnexpectedState: Error {}
}
