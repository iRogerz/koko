//
//  FriendCellContent.swift
//  koko
//
//  spec.md §6.5：好友 cell 上「哪些元素該出現」的規則。
//
//  抽成純資料映射（不碰 UIKit）是為了讓 AC-7／AC-8 可以被單元測試驗證，
//  而不是只能靠肉眼看畫面。`FriendCell` 只負責照著這份結果設定 `isHidden`。
//

import Foundation

struct FriendCellContent: Equatable {

    let name: String

    /// `isTop == "1"` 才顯示星星（AC-8）。
    let showsStar: Bool

    /// `status == 2` 顯示灰色「邀請中」標籤（AC-7）。
    let showsInvitingTag: Bool

    /// `status == 1` 顯示 `⋯`，與「邀請中」互斥（AC-7）。
    let showsMoreButton: Bool

    /// 轉帳按鈕恆常顯示。
    let showsTransferButton = true

    init(friend: Friend) {
        name = friend.name
        showsStar = friend.isTop
        showsInvitingTag = friend.status == .inviting
        showsMoreButton = friend.status == .completed
    }
}
