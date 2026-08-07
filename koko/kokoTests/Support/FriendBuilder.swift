//
//  FriendBuilder.swift
//  kokoTests
//
//  給合併／排序測試用的手工資料建構器。
//  真實資料一律走 FixtureLoader，這裡只用來構造 fixture 沒有的邊界情境
//  （日期相同、全部置頂…）。
//

import Foundation
@testable import koko

enum FriendBuilder {

    static func make(
        fid: String,
        name: String = "測試",
        status: FriendStatus = .completed,
        isTop: Bool = false,
        updateDate: String = "20190801"
    ) throws -> Friend {
        Friend(
            fid: fid,
            name: name,
            status: status,
            isTop: isTop,
            updateDate: try UpdateDate(rawValue: updateDate)
        )
    }
}
