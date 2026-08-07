//
//  FriendSorterTests.swift
//  kokoTests
//
//  spec.md §5.2 排序規則 / AC-8：
//  `isTop == "1"` 置頂，其餘維持原始順序（穩定排序）。
//

import XCTest
@testable import koko

final class FriendSorterTests: XCTestCase {

    // MARK: - AC-8

    func test_sort_topPinnedFirst() throws {
        let normal = try FriendBuilder.make(fid: "001")
        let top = try FriendBuilder.make(fid: "002", isTop: true)

        XCTAssertEqual(FriendSorter.topPinnedFirst([normal, top]).map(\.fid), ["002", "001"])
    }

    /// 情境 II 合併後排序：只有 002（翁勳儀）isTop，其餘維持原順序。
    func test_sort_scenarioTwoGoldenSample() throws {
        let merged = FriendMerger.merge(
            try FixtureLoader.friends(.friend1),
            try FixtureLoader.friends(.friend2)
        )

        let sorted = FriendSorter.topPinnedFirst(merged)

        XCTAssertEqual(sorted.map(\.fid), ["002", "001", "003", "004", "005", "012"])
        XCTAssertEqual(sorted.first?.name, "翁勳儀")
        XCTAssertTrue(try XCTUnwrap(sorted.first).isTop)
    }

    // MARK: - 穩定性

    /// 非置頂的相對順序不得被打亂。
    func test_sort_isStableAmongNonTop() throws {
        let friends = try ["a", "b", "c", "d"].map { try FriendBuilder.make(fid: $0) }

        XCTAssertEqual(FriendSorter.topPinnedFirst(friends).map(\.fid), ["a", "b", "c", "d"])
    }

    /// 多筆置頂之間的相對順序也不得被打亂。
    func test_sort_isStableAmongTop() throws {
        let x = try FriendBuilder.make(fid: "x", isTop: true)
        let y = try FriendBuilder.make(fid: "y")
        let z = try FriendBuilder.make(fid: "z", isTop: true)
        let w = try FriendBuilder.make(fid: "w")

        XCTAssertEqual(
            FriendSorter.topPinnedFirst([x, y, z, w]).map(\.fid),
            ["x", "z", "y", "w"],
            "x 在 z 之前、y 在 w 之前，兩組內部順序都要保持"
        )
    }

    /// 已排好的清單再排一次不會變（冪等）。
    func test_sort_isIdempotent() throws {
        let friends = try FixtureLoader.friends(.friend3)
        let once = FriendSorter.topPinnedFirst(friends)

        XCTAssertEqual(FriendSorter.topPinnedFirst(once), once)
    }

    // MARK: - 邊界

    func test_sort_noTop_keepsOriginalOrder() throws {
        let friends = try ["a", "b", "c"].map { try FriendBuilder.make(fid: $0) }

        XCTAssertTrue(friends.allSatisfy { !$0.isTop }, "前提檢查：這份清單沒有任何置頂")
        XCTAssertEqual(FriendSorter.topPinnedFirst(friends).map(\.fid), ["a", "b", "c"])
    }

    func test_sort_allTop_keepsOriginalOrder() throws {
        let friends = try ["a", "b", "c"].map { try FriendBuilder.make(fid: $0, isTop: true) }

        XCTAssertEqual(FriendSorter.topPinnedFirst(friends).map(\.fid), ["a", "b", "c"])
    }

    func test_sort_empty() {
        XCTAssertEqual(FriendSorter.topPinnedFirst([]), [])
    }

    /// 純函式：不改動輸入，且不增減筆數。
    func test_sort_isPureAndPreservesElements() throws {
        let friends = try FixtureLoader.friends(.friend1)
        let sorted = FriendSorter.topPinnedFirst(friends)

        XCTAssertEqual(Set(sorted), Set(friends), "只重排，不增不減")
        XCTAssertEqual(sorted.count, friends.count)
        XCTAssertEqual(friends, try FixtureLoader.friends(.friend1), "輸入不得被改動")
    }
}
