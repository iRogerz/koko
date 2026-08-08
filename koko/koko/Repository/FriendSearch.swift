//
//  FriendSearch.swift
//  koko
//
//  spec.md §6.4：對**已取得的**好友清單做姓名關鍵字篩選（本地，不重打 API）。
//  大小寫不敏感、可子字串比對；清空關鍵字還原完整清單。
//
//  純函式，可單獨測試（CLAUDE.md architecture rule 4）。
//

import Foundation

enum FriendSearch {

    /// - Parameter keyword: 空字串或純空白視同「沒有關鍵字」，回傳完整清單。
    /// - Returns: 依原順序保留的符合項。
    static func filter(_ friends: [Friend], keyword: String) -> [Friend] {
        let trimmed = keyword.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return friends }

        return friends.filter { $0.name.localizedCaseInsensitiveContains(trimmed) }
    }
}
