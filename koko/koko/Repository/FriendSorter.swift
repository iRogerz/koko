//
//  FriendSorter.swift
//  koko
//
//  spec.md §5.2 排序規則：
//  `isTop == "1"` 置頂，其餘維持原始順序（**穩定**排序）。
//
//  註：設計稿中星號好友（翁勳儀、洪佳妤）並未排在最前，但置頂是 `isTop`
//  唯一合理的語意。此為明確的規格決定，見 spec.md §10 開放議題 O-2。
//
//  純函式，可單獨測試（CLAUDE.md architecture rule 4）。
//

import Foundation

enum FriendSorter {

    /// 置頂的排前面，兩組內部都維持原本的相對順序。
    ///
    /// 刻意不用 `sorted(by:)` —— Swift 的 `sort` **不保證穩定**，
    /// 而 §5.2 要求「其餘維持合併後的原始順序」。
    /// 用兩次 `filter` 串接可以從實作上保證穩定性。
    static func topPinnedFirst(_ friends: [Friend]) -> [Friend] {
        friends.filter(\.isTop) + friends.filter { !$0.isTop }
    }
}
