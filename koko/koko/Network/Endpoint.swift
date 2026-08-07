//
//  Endpoint.swift
//  koko
//
//  spec.md §3 Datasource。
//

import Foundation

/// 五支 API。rawValue 即檔名，`Fixtures/` 的離線樣本也用同一組名稱。
enum Endpoint: String, CaseIterable {

    /// U — 使用者資料
    case user = "man"

    /// F1 — 好友列表 1
    case friends1 = "friend1"

    /// F2 — 好友列表 2
    case friends2 = "friend2"

    /// F3 — 好友列表含邀請
    case friendsWithInvites = "friend3"

    /// F4 — 無資料
    case noFriends = "friend4"
}

extension Endpoint {

    private static let baseURL = URL(string: "https://dimanyen.github.io")!

    var url: URL {
        Self.baseURL.appendingPathComponent("\(rawValue).json")
    }
}
