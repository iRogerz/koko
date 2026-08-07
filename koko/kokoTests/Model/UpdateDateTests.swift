//
//  UpdateDateTests.swift
//  kokoTests
//
//  spec.md §3.3 / AC-5：`yyyyMMdd` 與 `yyyy/MM/dd` 兩種格式並存，
//  必須先正規化再比較。
//

import XCTest
@testable import koko

final class UpdateDateTests: XCTestCase {

    // MARK: - AC-5 核心

    /// spec.md §9 `test_updateDate_normalization`
    func test_updateDate_normalization() throws {
        let older = try UpdateDate(rawValue: "20190801")     // friend1 格式
        let newer = try UpdateDate(rawValue: "2019/08/02")   // friend2 格式

        XCTAssertLessThan(older, newer, "2019/08/02 必須被判定為晚於 20190801")
        XCTAssertGreaterThan(newer, older)
        XCTAssertFalse(newer < older)
    }

    /// 這個測試是本題最主要陷阱的機械化防線：
    /// 直接字串比較會得到相反答案（`/` 的 ASCII 0x2F 小於 `0` 的 0x30）。
    /// 若哪天有人把 UpdateDate 換回字串比較，這裡會失敗。
    func test_updateDate_normalizationBeatsNaiveStringComparison() throws {
        let rawOlder = "20190801"
        let rawNewer = "2019/08/02"

        XCTAssertTrue(rawNewer < rawOlder, "前提檢查：字串比較確實是反的")

        let older = try UpdateDate(rawValue: rawOlder)
        let newer = try UpdateDate(rawValue: rawNewer)
        XCTAssertTrue(older < newer, "正規化後必須推翻字串比較的結果")
    }

    // MARK: - 正規化語意

    func test_updateDate_bothFormatsNormalizeToSameInstant() throws {
        let compact = try UpdateDate(rawValue: "20190801")
        let slashed = try UpdateDate(rawValue: "2019/08/01")

        XCTAssertEqual(compact, slashed, "同一天的兩種寫法，正規化後必須相等")
        XCTAssertEqual(compact.date, slashed.date)
        XCTAssertFalse(compact < slashed)
        XCTAssertFalse(slashed < compact)
    }

    func test_updateDate_keepsRawValueForDisplay() throws {
        let date = try UpdateDate(rawValue: "2019/08/02")
        XCTAssertEqual(date.rawValue, "2019/08/02", "原始字串要保留，不能被正規化覆寫")
    }

    func test_updateDate_isTimeZoneStable() throws {
        // 正規化用固定 UTC + POSIX locale，不受裝置時區／曆法影響。
        let a = try UpdateDate(rawValue: "20190801")
        let b = try UpdateDate(rawValue: "20190802")
        XCTAssertEqual(b.date.timeIntervalSince(a.date), 86_400, accuracy: 0.001)
    }

    // MARK: - 嚴格解析（未知格式必須大聲失敗，不能靜默排錯序）

    func test_updateDate_rejectsUnrecognizedFormats() {
        let invalid = [
            "2019-08-01",   // 破折號不在允許清單
            "08/01/2019",   // 日月年
            "20190841",     // 不存在的日期
            "2019/13/01",   // 不存在的月份
            "201908",       // 位數不足
            "20190801 ",    // 尾端空白
            "",
            "hello",
        ]

        for raw in invalid {
            XCTAssertThrowsError(try UpdateDate(rawValue: raw), "「\(raw)」不該被接受") { error in
                XCTAssertEqual(error as? UpdateDate.ParsingError, .unrecognizedFormat(raw))
            }
        }
    }

    func test_updateDate_acceptsExactlyTheTwoSpecFormats() {
        XCTAssertEqual(UpdateDate.acceptedFormats, ["yyyyMMdd", "yyyy/MM/dd"])
    }

    // MARK: - Decodable

    func test_updateDate_decodesFromJSONString() throws {
        let decoded = try JSONDecoding.decode(UpdateDate.self, from: "\"2019/08/02\"")
        XCTAssertEqual(decoded, try UpdateDate(rawValue: "20190802"))
    }

    func test_updateDate_decodingRejectsNumber() {
        JSONDecoding.assertFails(UpdateDate.self, from: "20190801", "updateDate 在 JSON 中是 String，不是 Number")
    }

    // MARK: - 對真實 fixture 的排序驗證

    /// friend1 的 002（20190802）必須晚於 friend2 的 002（2019/08/01）——
    /// 這正是 §5.3 黃金樣本中 002 由 F1 勝出的原因。
    func test_updateDate_fixtureCase002_friend1WinsOverFriend2() throws {
        let (inFriend1, inFriend2) = try records(fid: "002")
        XCTAssertGreaterThan(inFriend1.updateDate, inFriend2.updateDate)
    }

    /// 反向案例：001 由 friend2（2019/08/02）勝出。
    func test_updateDate_fixtureCase001_friend2WinsOverFriend1() throws {
        let (inFriend1, inFriend2) = try records(fid: "001")
        XCTAssertGreaterThan(inFriend2.updateDate, inFriend1.updateDate)
    }

    private func records(fid: String) throws -> (friend1: Friend, friend2: Friend) {
        let inFriend1 = try FixtureLoader.friends(.friend1)
        let inFriend2 = try FixtureLoader.friends(.friend2)
        return (
            try XCTUnwrap(inFriend1.first(where: { $0.fid == fid })),
            try XCTUnwrap(inFriend2.first(where: { $0.fid == fid }))
        )
    }
}
