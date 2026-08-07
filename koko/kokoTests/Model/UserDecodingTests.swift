//
//  UserDecodingTests.swift
//  kokoTests
//
//  spec.md §3.1 / §6.1：header 的姓名與 KOKO ID 取自 man.json；
//  無 kokoid 時要能判斷成「未設定」。
//

import XCTest
@testable import koko

final class UserDecodingTests: XCTestCase {

    func test_decode_man_matchesFixture() throws {
        let users = try FixtureLoader.users(.man)

        XCTAssertEqual(users.count, 1)
        let user = try XCTUnwrap(users.first)
        XCTAssertEqual(user.name, "蔡國泰")
        XCTAssertEqual(user.kokoID, "Mike")
        XCTAssertTrue(user.hasKokoID)
    }

    func test_decode_missingKokoID_isNil() throws {
        let user = try JSONDecoding.decode(User.self, from: #"{"name": "蔡國泰"}"#)

        XCTAssertNil(user.kokoID)
        XCTAssertFalse(user.hasKokoID, "無 kokoid → header 顯示「設定 KOKO ID」")
    }

    func test_decode_nullKokoID_isNil() throws {
        let user = try JSONDecoding.decode(User.self, from: #"{"name": "蔡國泰", "kokoid": null}"#)
        XCTAssertNil(user.kokoID)
    }

    /// 空字串／純空白視同未設定，否則 header 會顯示「KOKO ID : 」這種空殼。
    func test_decode_blankKokoID_isTreatedAsUnset() throws {
        for raw in ["\"\"", "\"   \""] {
            let user = try JSONDecoding.decode(User.self, from: #"{"name": "蔡國泰", "kokoid": \#(raw)}"#)
            XCTAssertNil(user.kokoID, "\(raw) 應視為未設定")
            XCTAssertFalse(user.hasKokoID)
        }
    }

    func test_decode_trimsKokoIDWhitespace() throws {
        let user = try JSONDecoding.decode(User.self, from: #"{"name": "蔡國泰", "kokoid": " Mike "}"#)
        XCTAssertEqual(user.kokoID, "Mike")
    }

    func test_decode_requiresName() {
        JSONDecoding.assertFails(User.self, from: #"{"kokoid": "Mike"}"#, "name 是必要欄位")
    }

    // MARK: - Response envelope

    func test_apiResponse_unwrapsResponseArray() throws {
        let response = try JSONDecoding.decode(APIResponse<User>.self, from: #"{"response": []}"#)
        XCTAssertTrue(response.response.isEmpty)
    }

    func test_apiResponse_requiresResponseKey() {
        JSONDecoding.assertFails(APIResponse<User>.self, from: #"{"data": []}"#, "envelope 的 key 必須是 response")
    }
}
