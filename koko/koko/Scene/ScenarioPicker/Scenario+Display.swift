//
//  Scenario+Display.swift
//  koko
//
//  情境的顯示文字。`Scenario` 本身放在 Model 層且不含任何 UI 文字，
//  顯示用的字串留在 Scene 層。
//
//  標題取自 `docs/spec.md` §5 的情境表。
//

import Foundation

extension Scenario {

    /// 選單標題。
    var menuTitle: String {
        switch self {
        case .noFriends:
            return "無好友"
        case .friendsOnly:
            return "只有好友列表"
        case .friendsWithInvites:
            return "好友列表含邀請"
        }
    }

    /// 副標：說明這個情境會打哪些 API、預期看到什麼畫面。
    var menuSubtitle: String {
        switch self {
        case .noFriends:
            return "man.json + friend4.json　→　空狀態"
        case .friendsOnly:
            return "man.json + friend1 + friend2（合併）　→　好友列表"
        case .friendsWithInvites:
            return "man.json + friend3.json　→　好友列表含邀請"
        }
    }
}
