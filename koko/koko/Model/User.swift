//
//  User.swift
//  koko
//
//  spec.md §3.1 / §6.1：header 的姓名與 KOKO ID 來源。
//

import Foundation

struct User: Hashable {

    let name: String

    /// 已設定的 KOKO ID。缺欄位、`null`、空字串或純空白一律正規化成 `nil`，
    /// 讓 header 只需判斷 `nil` 就能決定顯示
    /// 「KOKO ID : {id}」或「設定 KOKO ID」+ 粉紅小圓點。
    let kokoID: String?
}

extension User {

    var hasKokoID: Bool { kokoID != nil }
}

// MARK: - Decodable

extension User: Decodable {

    private enum CodingKeys: String, CodingKey {
        case name
        case kokoID = "kokoid"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        name = try container.decode(String.self, forKey: .name)

        let rawKokoID = try container.decodeIfPresent(String.self, forKey: .kokoID)?
            .trimmingCharacters(in: .whitespacesAndNewlines)
        kokoID = (rawKokoID?.isEmpty ?? true) ? nil : rawKokoID
    }
}
