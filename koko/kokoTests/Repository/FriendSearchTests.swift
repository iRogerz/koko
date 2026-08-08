//
//  FriendSearchTests.swift
//  kokoTests
//
//  spec.md §6.4 搜尋框：對已取得的好友清單做姓名關鍵字篩選（本地）。
//  大小寫不敏感、可子字串比對；清空關鍵字還原完整清單。
//

import XCTest
@testable import koko

final class FriendSearchTests: XCTestCase {

    private func friends() throws -> [Friend] {
        try [
            FriendBuilder.make(fid: "001", name: "黃靖僑"),
            FriendBuilder.make(fid: "002", name: "翁勳儀"),
            FriendBuilder.make(fid: "004", name: "梁立璇"),
            FriendBuilder.make(fid: "005", name: "梁立璇"),
            FriendBuilder.make(fid: "100", name: "Mike Chen"),
        ]
    }

    // MARK: - 基本比對

    func test_search_matchesSubstring() throws {
        let result = FriendSearch.filter(try friends(), keyword: "立")

        XCTAssertEqual(result.map(\.fid), ["004", "005"], "子字串比對，非前綴比對")
    }

    func test_search_matchesFullName() throws {
        let result = FriendSearch.filter(try friends(), keyword: "黃靖僑")

        XCTAssertEqual(result.map(\.fid), ["001"])
    }

    func test_search_isCaseInsensitive() throws {
        for keyword in ["mike", "MIKE", "MiKe"] {
            let result = FriendSearch.filter(try friends(), keyword: keyword)
            XCTAssertEqual(result.map(\.fid), ["100"], "「\(keyword)」應比對到 Mike Chen")
        }
    }

    func test_search_noMatch_returnsEmpty() throws {
        XCTAssertTrue(FriendSearch.filter(try friends(), keyword: "查無此人").isEmpty)
    }

    // MARK: - 清空還原（spec §9 test_search_emptyKeywordRestoresAll）

    func test_search_emptyKeywordRestoresAll() throws {
        let all = try friends()

        XCTAssertEqual(FriendSearch.filter(all, keyword: ""), all)
    }

    /// 使用者只打了空白，視同沒有關鍵字。
    func test_search_whitespaceOnlyKeywordRestoresAll() throws {
        let all = try friends()

        for keyword in [" ", "   ", "\n", "\t"] {
            XCTAssertEqual(FriendSearch.filter(all, keyword: keyword), all, "「\(keyword)」應視同空關鍵字")
        }
    }

    /// 關鍵字前後的空白不應影響比對結果。
    func test_search_trimsSurroundingWhitespace() throws {
        let result = FriendSearch.filter(try friends(), keyword: "  立  ")

        XCTAssertEqual(result.map(\.fid), ["004", "005"])
    }

    // MARK: - 順序與純粹性

    func test_search_preservesOrder() throws {
        let all = try friends()
        let result = FriendSearch.filter(all, keyword: "")

        XCTAssertEqual(result.map(\.fid), all.map(\.fid))
    }

    func test_search_isPure() throws {
        let all = try friends()
        _ = FriendSearch.filter(all, keyword: "立")

        XCTAssertEqual(all.map(\.fid), ["001", "002", "004", "005", "100"], "輸入不得被改動")
    }

    func test_search_emptyInput() {
        XCTAssertEqual(FriendSearch.filter([], keyword: "立"), [])
    }

    /// 同名不同 fid 的兩筆都要被搜到（呼應 §5.1 不得用 name 當唯一鍵）。
    func test_search_returnsAllRecordsWithSameName() throws {
        let result = FriendSearch.filter(try friends(), keyword: "梁立璇")

        XCTAssertEqual(result.count, 2)
        XCTAssertEqual(Set(result.map(\.fid)), ["004", "005"])
    }
}
