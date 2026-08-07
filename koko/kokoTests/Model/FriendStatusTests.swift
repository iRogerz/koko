//
//  FriendStatusTests.swift
//  kokoTests
//
//  spec.md §4.1 / §4.2 / O-1：邀請卡片區的判定條件是 status == 0，
//  且必須集中定義成單一常數，不得散落多處。
//

import XCTest
@testable import koko

final class FriendStatusTests: XCTestCase {

    func test_rawValues_matchSpec() {
        XCTAssertEqual(FriendStatus.invitationSent.rawValue, 0, "0 = 邀請送出")
        XCTAssertEqual(FriendStatus.completed.rawValue, 1, "1 = 已完成")
        XCTAssertEqual(FriendStatus.inviting.rawValue, 2, "2 = 邀請中")
        XCTAssertEqual(FriendStatus.allCases.count, 3, "spec 只定義三種 status")
    }

    /// spec.md §4.2 的推導結論。若這條被改掉，等於改了整份規格。
    func test_invitationCard_isStatusZero() {
        XCTAssertEqual(FriendStatus.invitationCard, .invitationSent)
        XCTAssertEqual(FriendStatus.invitationCard.rawValue, 0)
    }

    /// 唯一性：只有 status == 0 是邀請卡片，其餘都不是。
    func test_onlyStatusZeroIsInvitationCard() {
        for status in FriendStatus.allCases {
            XCTAssertEqual(
                status.isInvitationCard,
                status.rawValue == 0,
                "\(status) 的邀請卡片判定與 status == 0 不一致"
            )
        }
    }

    func test_friendForwardsInvitationCardRule() throws {
        let friends = try FixtureLoader.friends(.friend3)

        for friend in friends {
            XCTAssertEqual(friend.isInvitationCard, friend.status.isInvitationCard)
        }
    }

    // MARK: - 對 fixture 的計數（§5.4 / §5.3 黃金樣本的前置條件）

    /// 情境 III：friend3 有 2 筆 status == 0 → 2 張邀請卡片。
    func test_friend3_hasTwoInvitationCards() throws {
        let invites = try FixtureLoader.friends(.friend3).filter(\.isInvitationCard)

        XCTAssertEqual(invites.count, 2)
        XCTAssertEqual(invites.map(\.fid), ["001", "002"])
    }

    /// §4.2 的反證前提：若把 status == 2 當成邀請卡片，情境 II 就會冒出卡片。
    /// 這裡把該前提釘死，避免日後有人「順手」改回 status == 2。
    func test_statusTwoIsNotInvitationCard() throws {
        let friend1 = try FixtureLoader.friends(.friend1)
        let statusTwo = friend1.filter { $0.status == .inviting }

        XCTAssertFalse(statusTwo.isEmpty, "前提檢查：friend1 確實有 status == 2 的資料")
        XCTAssertTrue(statusTwo.allSatisfy { !$0.isInvitationCard })
    }

    func test_friend4_hasNoInvitationCards() throws {
        XCTAssertTrue(try FixtureLoader.friends(.friend4).filter(\.isInvitationCard).isEmpty)
    }
}
