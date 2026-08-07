//
//  FixtureLoader.swift
//  kokoTests
//
//  測試一律讀 Fixtures/ 內的離線 JSON，不打真實網路（spec.md §9）。
//

import Foundation
import XCTest
@testable import koko

enum Fixture: String, CaseIterable {
    case man
    case friend1
    case friend2
    case friend3
    case friend4
}

enum FixtureLoader {

    /// 用來定位 test bundle。
    private final class BundleToken {}

    static func data(_ fixture: Fixture, file: StaticString = #filePath, line: UInt = #line) throws -> Data {
        let bundle = Bundle(for: BundleToken.self)
        guard let url = bundle.url(forResource: fixture.rawValue, withExtension: "json") else {
            XCTFail(
                "找不到 fixture \(fixture.rawValue).json — 確認它在 kokoTests target 的 Copy Bundle Resources 內。",
                file: file,
                line: line
            )
            throw CocoaError(.fileNoSuchFile)
        }
        return try Data(contentsOf: url)
    }

    static func decode<T: Decodable>(
        _ type: T.Type,
        from fixture: Fixture,
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws -> T {
        let data = try data(fixture, file: file, line: line)
        return try JSONDecoder().decode(T.self, from: data)
    }

    static func friends(_ fixture: Fixture, file: StaticString = #filePath, line: UInt = #line) throws -> [Friend] {
        try decode(APIResponse<Friend>.self, from: fixture, file: file, line: line).response
    }

    static func users(_ fixture: Fixture, file: StaticString = #filePath, line: UInt = #line) throws -> [User] {
        try decode(APIResponse<User>.self, from: fixture, file: file, line: line).response
    }
}

/// 讓測試可以直接用 JSON 字面值組出單筆物件，驗證型別假設。
enum JSONDecoding {

    static func decode<T: Decodable>(_ type: T.Type, from json: String) throws -> T {
        try JSONDecoder().decode(T.self, from: Data(json.utf8))
    }

    /// 期望解碼失敗。成功就是測試失敗。
    static func assertFails<T: Decodable>(
        _ type: T.Type,
        from json: String,
        _ message: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        XCTAssertThrowsError(try decode(type, from: json), message, file: file, line: line)
    }
}
