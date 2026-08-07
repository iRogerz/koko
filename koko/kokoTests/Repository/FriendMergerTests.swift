//
//  FriendMergerTests.swift
//  kokoTests
//
//  spec.md §5.1 合併規則 / §5.3 黃金樣本 / AC-3・AC-4・AC-5
//

import XCTest
@testable import koko

final class FriendMergerTests: XCTestCase {

    /// 情境 II：F1 + F2 合併結果。
    private func scenarioTwo() throws -> [Friend] {
        FriendMerger.merge(
            try FixtureLoader.friends(.friend1),
            try FixtureLoader.friends(.friend2)
        )
    }

    // MARK: - AC-4 黃金樣本

    /// spec.md §9 `test_merge_goldenSample` —— 對照 §5.3 表格逐筆驗證。
    func test_merge_goldenSample() throws {
        let merged = try scenarioTwo()

        XCTAssertEqual(merged.count, 6, "合併後必須是 6 筆")
        XCTAssertEqual(merged.map(\.fid), ["001", "002", "003", "004", "005", "012"])
        XCTAssertEqual(merged.map(\.name), ["黃靖僑", "翁勳儀", "洪佳妤", "梁立璇", "梁立璇", "林宜真"])
        XCTAssertEqual(
            merged.map(\.status),
            [.completed, .inviting, .completed, .completed, .completed, .completed]
        )
        XCTAssertEqual(merged.map(\.isTop), [false, true, false, false, false, false])
        XCTAssertEqual(
            merged.map(\.updateDate.rawValue),
            ["2019/08/02", "20190802", "20190804", "20190801", "20190804", "2019/08/01"],
            "勝出那一筆的原始字串應原樣保留（001 / 012 來自 F2，其餘來自 F1）"
        )
    }

    /// §5.3 的結論：合併後 status == 0 有 0 筆 → 無邀請卡片 → 狀態 B。
    /// 這正是 §4.2 用來反證「status == 0 才是邀請卡片」的關鍵事實。
    func test_merge_scenarioTwoHasNoInvitationCards() throws {
        let merged = try scenarioTwo()

        XCTAssertTrue(
            merged.filter(\.isInvitationCard).isEmpty,
            "情境 II 必須是「好友列表無邀請」（需求 (2)-II）"
        )
    }

    // MARK: - §5.1 規則 2 / 3：以 fid 去重，取較新者

    /// spec.md §9 `test_merge_picksNewerRecord`
    func test_merge_picksNewerRecord() throws {
        let merged = try scenarioTwo()

        let first = try XCTUnwrap(merged.first { $0.fid == "001" })
        XCTAssertEqual(first.updateDate.rawValue, "2019/08/02", "001 應取 F2（較新）")
        XCTAssertEqual(first.status, .completed)

        let second = try XCTUnwrap(merged.first { $0.fid == "002" })
        XCTAssertEqual(second.updateDate.rawValue, "20190802", "002 應取 F1（較新）")
        XCTAssertEqual(second.status, .inviting)
    }

    /// 整筆取代，不做欄位級合併（§5.1 規則 3）。
    func test_merge_replacesWholeRecord_notFieldByField() throws {
        let older = try FriendBuilder.make(fid: "900", name: "舊", status: .invitationSent, isTop: true, updateDate: "20190801")
        let newer = try FriendBuilder.make(fid: "900", name: "新", status: .completed, isTop: false, updateDate: "20190802")

        let merged = FriendMerger.merge([older], [newer])

        XCTAssertEqual(merged, [newer], "應整筆換成新的，不得保留舊筆的 isTop 或 name")
    }

    // MARK: - 本題主陷阱的防線

    /// 若哪天有人把 updateDate 比較換回字串比較，這個測試會失敗。
    ///
    /// fid 001：F1 是 `20190801`(status 0)、F2 是 `2019/08/02`(status 1)。
    /// 字串比較會判定 `"2019/08/02" < "20190801"` → 誤取 F1 → status 變成 0
    /// → 情境 II 冒出一張邀請卡片 → 畫錯畫面。
    func test_merge_usesNormalizedDate_notStringOrder() throws {
        let merged = try scenarioTwo()
        let first = try XCTUnwrap(merged.first { $0.fid == "001" })

        XCTAssertEqual(first.status, .completed, "字串比較會在這裡得到 .invitationSent")
        XCTAssertFalse(first.isInvitationCard, "誤判會讓情境 II 多出一張邀請卡片")
    }

    /// 跨格式比較：yyyy/MM/dd 的較新筆必須贏過 yyyyMMdd 的較舊筆，反之亦然。
    func test_merge_comparesAcrossDateFormats() throws {
        let compact = try FriendBuilder.make(fid: "901", name: "compact", updateDate: "20190801")
        let slashed = try FriendBuilder.make(fid: "901", name: "slashed", updateDate: "2019/08/02")

        XCTAssertEqual(FriendMerger.merge([compact], [slashed]).map(\.name), ["slashed"])
        XCTAssertEqual(FriendMerger.merge([slashed], [compact]).map(\.name), ["slashed"])
    }

    // MARK: - §5.1 註記：不得用 name 去重

    /// spec.md §9 `test_merge_dedupeByFid_notByName`
    func test_merge_dedupeByFid_notByName() throws {
        let merged = try scenarioTwo()
        let liang = merged.filter { $0.name == "梁立璇" }

        XCTAssertEqual(liang.count, 2, "004 / 005 同名不同 fid，兩筆都要保留")
        XCTAssertEqual(Set(liang.map(\.fid)), ["004", "005"])
    }

    func test_merge_sameNameDifferentFid_areBothKept() throws {
        let a = try FriendBuilder.make(fid: "004", name: "梁立璇", updateDate: "20190801")
        let b = try FriendBuilder.make(fid: "005", name: "梁立璇", updateDate: "20190804")

        XCTAssertEqual(FriendMerger.merge([a, b]).count, 2)
    }

    // MARK: - §5.1 規則 4：日期相同取後出現者

    func test_merge_sameDate_takesLaterOccurrence() throws {
        let earlier = try FriendBuilder.make(fid: "902", name: "先", updateDate: "20190801")
        let later = try FriendBuilder.make(fid: "902", name: "後", updateDate: "20190801")

        XCTAssertEqual(FriendMerger.merge([earlier], [later]).map(\.name), ["後"])
        XCTAssertEqual(FriendMerger.merge([later], [earlier]).map(\.name), ["先"], "順序對調則結果對調")
    }

    /// 同一份清單內出現重複 fid 時，同樣適用。
    func test_merge_handlesDuplicatesWithinSingleList() throws {
        let a = try FriendBuilder.make(fid: "903", name: "舊", updateDate: "20190801")
        let b = try FriendBuilder.make(fid: "903", name: "新", updateDate: "20190802")

        XCTAssertEqual(FriendMerger.merge([a, b]).map(\.name), ["新"])
    }

    // MARK: - 順序

    /// 輸出順序 = fid 首次出現的順序（黃金樣本是 001…005 來自 F1，012 來自 F2）。
    func test_merge_preservesFirstAppearanceOrder() throws {
        let a = try FriendBuilder.make(fid: "c", updateDate: "20190801")
        let b = try FriendBuilder.make(fid: "a", updateDate: "20190801")
        let c = try FriendBuilder.make(fid: "b", updateDate: "20190801")

        XCTAssertEqual(FriendMerger.merge([a, b], [c]).map(\.fid), ["c", "a", "b"])
    }

    /// 即使某 fid 是被後面的清單取代，位置仍留在首次出現的地方。
    func test_merge_replacedRecordKeepsOriginalPosition() throws {
        let merged = try scenarioTwo()

        XCTAssertEqual(merged.first?.fid, "001", "001 由 F2 勝出，但位置仍在最前（F1 中的位置）")
    }

    // MARK: - 邊界

    func test_merge_singleList_isIdentity() throws {
        let friends = try FixtureLoader.friends(.friend3)
        XCTAssertEqual(FriendMerger.merge(friends), friends)
    }

    func test_merge_emptyInput() {
        XCTAssertEqual(FriendMerger.merge(), [])
        XCTAssertEqual(FriendMerger.merge([], []), [])
    }

    func test_merge_withEmptyList_isIdentity() throws {
        let friends = try FixtureLoader.friends(.friend1)

        XCTAssertEqual(FriendMerger.merge(friends, []), friends)
        XCTAssertEqual(FriendMerger.merge([], friends), friends)
    }

    /// 情境 I：F4 是空陣列。
    func test_merge_friend4_isEmpty() throws {
        XCTAssertEqual(FriendMerger.merge(try FixtureLoader.friends(.friend4)), [])
    }

    /// 純函式：同樣輸入必得同樣輸出，且不改動輸入。
    func test_merge_isPureAndDeterministic() throws {
        let f1 = try FixtureLoader.friends(.friend1)
        let f2 = try FixtureLoader.friends(.friend2)

        XCTAssertEqual(FriendMerger.merge(f1, f2), FriendMerger.merge(f1, f2))
        XCTAssertEqual(f1, try FixtureLoader.friends(.friend1), "輸入不得被改動")
        XCTAssertEqual(f2, try FixtureLoader.friends(.friend2))
    }
}
