//
//  FriendMerger.swift
//  koko
//
//  spec.md §5.1 合併規則（情境 II：F1 + F2）：
//
//  1. 以 `fid` 為唯一鍵分組。**不得用 `name`** —— friend1 中 004 / 005
//     都叫「梁立璇」，用姓名去重會少一筆。
//  2. 同 `fid` 多筆時，取正規化後 `updateDate` 較新的那一筆，**整筆取代**，
//     不做欄位級合併。
//  3. `updateDate` 相同時，取後出現的那一筆。
//  4. 輸出順序 = 各 `fid` 首次出現的順序。
//
//  純函式，無狀態、無副作用，可單獨測試（CLAUDE.md architecture rule 4）。
//

import Foundation

enum FriendMerger {

    /// 合併多份好友清單。
    ///
    /// 比較的是 `UpdateDate` 這個型別，其 `Comparable` 走的是正規化後的 `Date`，
    /// 因此 `yyyyMMdd` 與 `yyyy/MM/dd` 混用也能正確比大小。
    static func merge(_ lists: [[Friend]]) -> [Friend] {
        // 記錄每個 fid 首次出現的位置，讓輸出順序穩定可預期。
        var orderOfFirstAppearance: [String] = []
        var winnerByFID: [String: Friend] = [:]

        for friend in lists.joined() {
            guard let incumbent = winnerByFID[friend.fid] else {
                orderOfFirstAppearance.append(friend.fid)
                winnerByFID[friend.fid] = friend
                continue
            }

            // `>=` 而非 `>`：日期相同時由後出現的勝出（規則 3）。
            if friend.updateDate >= incumbent.updateDate {
                winnerByFID[friend.fid] = friend
            }
        }

        return orderOfFirstAppearance.compactMap { winnerByFID[$0] }
    }

    /// 可變參數版本，呼叫端可寫成 `FriendMerger.merge(f1, f2)`。
    static func merge(_ lists: [Friend]...) -> [Friend] {
        merge(lists)
    }
}
