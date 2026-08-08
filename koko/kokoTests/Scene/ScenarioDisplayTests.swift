//
//  ScenarioDisplayTests.swift
//  kokoTests
//
//  spec.md §5 / AC-1：起始頁列出三個情境。
//

import XCTest
@testable import koko

final class ScenarioDisplayTests: XCTestCase {

    func test_allScenarios_haveDistinctNonEmptyTitles() {
        let titles = Scenario.allCases.map(\.menuTitle)

        XCTAssertEqual(titles.count, 3)
        XCTAssertTrue(titles.allSatisfy { !$0.isEmpty })
        XCTAssertEqual(Set(titles).count, 3, "三個情境的標題不得重複")
    }

    func test_menuTitles_matchSpec() {
        XCTAssertEqual(Scenario.noFriends.menuTitle, "無好友")
        XCTAssertEqual(Scenario.friendsOnly.menuTitle, "只有好友列表")
        XCTAssertEqual(Scenario.friendsWithInvites.menuTitle, "好友列表含邀請")
    }

    func test_allScenarios_haveSubtitles() {
        XCTAssertTrue(Scenario.allCases.allSatisfy { !$0.menuSubtitle.isEmpty })
    }

    /// 選單順序即 `allCases` 順序，應與 spec §5 的情境 I／II／III 一致。
    func test_scenarioOrder_matchesSpec() {
        XCTAssertEqual(Scenario.allCases, [.noFriends, .friendsOnly, .friendsWithInvites])
    }
}
