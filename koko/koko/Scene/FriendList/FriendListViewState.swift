//
//  FriendListViewState.swift
//  koko
//
//  spec.md §7.1：ViewModel 對外的**唯一** view state。
//  View 依此渲染，不自行推導畫面狀態（CLAUDE.md architecture rule 3）。
//
//  header（§6.1）三種狀態共用，故 `user` 與內容狀態並列，不放在個別 case 內。
//

import Foundation

struct FriendListViewState {

    /// `nil` 表示尚未載入，header 顯示骨架。
    let user: User?

    let content: Content

    enum Content {
        case loading

        /// 狀態 A —— 合併後好友總數為 0。
        case empty

        /// 狀態 B / C。
        /// - `invites`：`status == 0`，邀請卡片區，**不受搜尋關鍵字影響**（§6.4）。
        /// - `friends`：其餘好友，已套用置頂排序（§5.2）與搜尋篩選（§6.4）。
        case loaded(invites: [Friend], friends: [Friend])

        case failed(Error)
    }
}

extension FriendListViewState.Content {

    /// 「好友」tab badge 的數字，為 0 時 View 應隱藏 badge（§6.3）。
    var invitationBadgeCount: Int {
        guard case .loaded(let invites, _) = self else { return 0 }
        return invites.count
    }

    /// 狀態 A。View 用它決定要不要顯示空狀態畫面、以及收起「聊天」badge（§6.3）。
    /// 判定留在這裡，View 不自行推導（CLAUDE.md architecture rule 3）。
    var isEmptyState: Bool {
        if case .empty = self { return true }
        return false
    }
}
