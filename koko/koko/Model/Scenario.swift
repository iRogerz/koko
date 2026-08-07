//
//  Scenario.swift
//  koko
//
//  spec.md §5：起始頁的三種情境。每種情境決定要打哪些好友 API。
//  三種情境都要打 U（使用者資料），故不列在 `friendEndpoints` 內。
//

import Foundation

enum Scenario: CaseIterable {

    /// 情境 I —— U + F4，期望畫面：狀態 A（無好友）
    case noFriends

    /// 情境 II —— U + F1 + F2（合併），期望畫面：狀態 B（好友無邀請）
    case friendsOnly

    /// 情境 III —— U + F3，期望畫面：狀態 C（好友含邀請）
    case friendsWithInvites
}

extension Scenario {

    /// 該情境要取得的好友清單來源。多於一個時必須**並行**請求（AC-3）。
    var friendEndpoints: [Endpoint] {
        switch self {
        case .noFriends:
            return [.noFriends]
        case .friendsOnly:
            return [.friends1, .friends2]
        case .friendsWithInvites:
            return [.friendsWithInvites]
        }
    }
}
