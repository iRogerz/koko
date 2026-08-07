//
//  FriendDecodingTests.swift
//  kokoTests
//
//  spec.md §3.2 / §9 `test_decode_isTopIsString_statusIsNumber`
//  `isTop` 是 String（"0"/"1"）、`status` 是 Number，型別不一致，不得混用假設。
//

import XCTest
@testable import koko

final class FriendDecodingTests: XCTestCase {

    private func json(
        name: String = "翁勳儀",
        status: String = "2",
        isTop: String = "\"1\"",
        fid: String = "002",
        updateDate: String = "\"20190802\""
    ) -> String {
        """
        {
          "name": "\(name)",
          "status": \(status),
          "isTop": \(isTop),
          "fid": "\(fid)",
          "updateDate": \(updateDate)
        }
        """
    }

    // MARK: - 型別假設（spec §9 必測項）

    func test_decode_isTopIsString_statusIsNumber() throws {
        let friend = try JSONDecoding.decode(Friend.self, from: json())

        XCTAssertEqual(friend.fid, "002")
        XCTAssertEqual(friend.name, "翁勳儀")
        XCTAssertEqual(friend.status, .inviting, "status 是 Number 2")
        XCTAssertTrue(friend.isTop, "isTop 是 String \"1\"")
        XCTAssertEqual(friend.updateDate, try UpdateDate(rawValue: "20190802"))
    }

    func test_decode_isTopZeroString_isFalse() throws {
        let friend = try JSONDecoding.decode(Friend.self, from: json(isTop: "\"0\""))
        XCTAssertFalse(friend.isTop)
    }

    // MARK: - 機械化防線：不得把型別假設放寬

    /// 若有人把 isTop 改成寬鬆解碼（同時吃 Bool/Int/String），這裡會失敗。
    func test_decode_rejectsNonStringIsTop() {
        for raw in ["1", "0", "true", "false"] {
            JSONDecoding.assertFails(
                Friend.self,
                from: json(isTop: raw),
                "isTop 必須是 String，\(raw) 不該被接受"
            )
        }
    }

    /// 若有人把 status 改成同時吃字串，這裡會失敗。
    func test_decode_rejectsNonNumberStatus() {
        for raw in ["\"2\"", "\"inviting\"", "true"] {
            JSONDecoding.assertFails(
                Friend.self,
                from: json(status: raw),
                "status 必須是 Number，\(raw) 不該被接受"
            )
        }
    }

    func test_decode_rejectsUnknownStatusValue() {
        for raw in ["3", "-1", "99"] {
            JSONDecoding.assertFails(Friend.self, from: json(status: raw), "未定義的 status \(raw) 應解碼失敗")
        }
    }

    func test_decode_rejectsUnknownIsTopValue() {
        for raw in ["\"2\"", "\"\"", "\"YES\""] {
            JSONDecoding.assertFails(Friend.self, from: json(isTop: raw), "isTop 只接受 \"0\"/\"1\"，\(raw) 不該被接受")
        }
    }

    func test_decode_rejectsUnrecognizedUpdateDateFormat() {
        JSONDecoding.assertFails(Friend.self, from: json(updateDate: "\"2019-08-02\""), "未知日期格式應解碼失敗")
    }

    func test_decode_requiresAllFields() {
        JSONDecoding.assertFails(Friend.self, from: #"{"status": 1, "isTop": "0", "fid": "001", "updateDate": "20190801"}"#, "缺 name")
        JSONDecoding.assertFails(Friend.self, from: #"{"name": "A", "isTop": "0", "fid": "001", "updateDate": "20190801"}"#, "缺 status")
        JSONDecoding.assertFails(Friend.self, from: #"{"name": "A", "status": 1, "fid": "001", "updateDate": "20190801"}"#, "缺 isTop")
        JSONDecoding.assertFails(Friend.self, from: #"{"name": "A", "status": 1, "isTop": "0", "updateDate": "20190801"}"#, "缺 fid")
        JSONDecoding.assertFails(Friend.self, from: #"{"name": "A", "status": 1, "isTop": "0", "fid": "001"}"#, "缺 updateDate")
    }

    // MARK: - Fixture 逐筆驗證

    func test_decode_friend1_matchesFixture() throws {
        let friends = try FixtureLoader.friends(.friend1)

        XCTAssertEqual(friends.count, 5)
        XCTAssertEqual(friends.map(\.fid), ["001", "002", "003", "004", "005"])
        XCTAssertEqual(friends.map(\.name), ["黃靖僑", "翁勳儀", "洪佳妤", "梁立璇", "梁立璇"])
        XCTAssertEqual(friends.map(\.status), [.invitationSent, .inviting, .completed, .completed, .completed])
        XCTAssertEqual(friends.map(\.isTop), [false, true, false, false, false])
        XCTAssertEqual(friends.map(\.updateDate.rawValue), ["20190801", "20190802", "20190804", "20190801", "20190804"])
    }

    func test_decode_friend2_usesSlashDateFormat() throws {
        let friends = try FixtureLoader.friends(.friend2)

        XCTAssertEqual(friends.count, 3)
        XCTAssertEqual(friends.map(\.fid), ["001", "002", "012"])
        XCTAssertEqual(friends.map(\.updateDate.rawValue), ["2019/08/02", "2019/08/01", "2019/08/01"])
        XCTAssertTrue(friends.allSatisfy { $0.updateDate.rawValue.contains("/") }, "friend2 應全部是 yyyy/MM/dd")
    }

    func test_decode_friend3_matchesFixture() throws {
        let friends = try FixtureLoader.friends(.friend3)

        XCTAssertEqual(friends.count, 5)
        XCTAssertEqual(friends.map(\.fid), ["001", "002", "003", "007", "008"])
        XCTAssertEqual(friends.map(\.status), [.invitationSent, .invitationSent, .completed, .inviting, .inviting])
    }

    func test_decode_friend4_isEmpty() throws {
        XCTAssertEqual(try FixtureLoader.friends(.friend4), [])
    }

    /// spec.md §5.1：friend1 的 004 / 005 同名不同 fid，去重只能用 fid。
    /// 這是「不得用 name 去重」在 Model 層的前提檢查。
    func test_decode_friend1_hasSameNameWithDistinctFids() throws {
        let liang = try FixtureLoader.friends(.friend1).filter { $0.name == "梁立璇" }

        XCTAssertEqual(liang.count, 2)
        XCTAssertEqual(Set(liang.map(\.fid)), ["004", "005"])
    }

    // MARK: - 值語意

    func test_friend_equalityIsValueBased() throws {
        let a = try JSONDecoding.decode(Friend.self, from: json())
        let b = try JSONDecoding.decode(Friend.self, from: json())
        XCTAssertEqual(a, b)

        let c = try JSONDecoding.decode(Friend.self, from: json(fid: "003"))
        XCTAssertNotEqual(a, c)
    }
}
