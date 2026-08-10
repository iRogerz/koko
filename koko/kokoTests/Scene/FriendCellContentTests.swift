//
//  FriendCellContentTests.swift
//  kokoTests
//
//  spec.md §6.5 / AC-7・AC-8：好友 cell 的元素顯示規則。
//

import XCTest
@testable import koko

final class FriendCellContentTests: XCTestCase {

    // MARK: - AC-8 星星

    func test_star_showsOnlyWhenIsTop() throws {
        let top = FriendCellContent(friend: try FriendBuilder.make(fid: "1", isTop: true))
        let normal = FriendCellContent(friend: try FriendBuilder.make(fid: "2", isTop: false))

        XCTAssertTrue(top.showsStar)
        XCTAssertFalse(normal.showsStar)
    }

    // MARK: - AC-7 邀請中 / ⋯

    func test_invitingTag_showsOnlyForStatusTwo() throws {
        for status in FriendStatus.allCases {
            let content = FriendCellContent(friend: try FriendBuilder.make(fid: "1", status: status))
            XCTAssertEqual(content.showsInvitingTag, status == .inviting, "\(status)")
        }
    }

    func test_moreButton_showsOnlyForStatusOne() throws {
        for status in FriendStatus.allCases {
            let content = FriendCellContent(friend: try FriendBuilder.make(fid: "1", status: status))
            XCTAssertEqual(content.showsMoreButton, status == .completed, "\(status)")
        }
    }

    /// spec §6.5 明講兩者互斥。
    func test_invitingTagAndMoreButton_areMutuallyExclusive() throws {
        for status in FriendStatus.allCases {
            let content = FriendCellContent(friend: try FriendBuilder.make(fid: "1", status: status))
            XCTAssertFalse(
                content.showsInvitingTag && content.showsMoreButton,
                "\(status) 同時顯示了「邀請中」與「⋯」"
            )
        }
    }

    // MARK: - 恆常顯示

    func test_transferButton_alwaysShows() throws {
        for status in FriendStatus.allCases {
            let content = FriendCellContent(friend: try FriendBuilder.make(fid: "1", status: status))
            XCTAssertTrue(content.showsTransferButton, "轉帳按鈕恆常顯示")
        }
    }

    func test_name_comesFromFriend() throws {
        let content = FriendCellContent(friend: try FriendBuilder.make(fid: "1", name: "翁勳儀"))
        XCTAssertEqual(content.name, "翁勳儀")
    }

    // MARK: - 對真實 fixture

    /// friend3：003 已完成顯示 `⋯`；007／008 邀請中顯示標籤。
    func test_friend3_cellContents() throws {
        let friends = try FixtureLoader.friends(.friend3)
        let contents = Dictionary(
            uniqueKeysWithValues: friends.map { ($0.fid, FriendCellContent(friend: $0)) }
        )

        XCTAssertEqual(contents["003"]?.showsMoreButton, true)
        XCTAssertEqual(contents["003"]?.showsInvitingTag, false)
        XCTAssertEqual(contents["007"]?.showsInvitingTag, true)
        XCTAssertEqual(contents["008"]?.showsInvitingTag, true)
        XCTAssertEqual(contents["002"]?.showsStar, true, "翁勳儀 isTop")
    }
}

final class InvitationBadgeTests: XCTestCase {

    /// spec §6.3：好友 badge 為邀請卡片數，0 時隱藏（由 BadgeLabel.setCount 處理）。
    func test_badgeCount_isInvitationCount() throws {
        let invites = try [
            FriendBuilder.make(fid: "1", status: .invitationSent),
            FriendBuilder.make(fid: "2", status: .invitationSent),
        ]
        let friends = try [FriendBuilder.make(fid: "3", status: .completed)]

        let content = FriendListViewState.Content.loaded(invites: invites, friends: friends)
        XCTAssertEqual(content.invitationBadgeCount, 2)
    }

    func test_badgeCount_isZeroForNonLoadedStates() {
        XCTAssertEqual(FriendListViewState.Content.loading.invitationBadgeCount, 0)
        XCTAssertEqual(FriendListViewState.Content.empty.invitationBadgeCount, 0)
        XCTAssertEqual(FriendListViewState.Content.loaded(invites: [], friends: []).invitationBadgeCount, 0)
    }
}
