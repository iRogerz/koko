//
//  FriendStatus.swift
//  koko
//
//  spec.md §4.1：`status` 在 JSON 中是 **Number**（不是字串）。
//

import Foundation

/// 好友關係狀態。rawValue 直接對應 API 的數字。
enum FriendStatus: Int, Codable, Hashable, CaseIterable {

    /// `0` — 「邀請送出」，待用戶同意。呈現在上方邀請卡片區。
    case invitationSent = 0

    /// `1` — 已完成。呈現在好友清單，右側 `⋯`。
    case completed = 1

    /// `2` — 「邀請中」，待對方同意。呈現在好友清單，附灰色「邀請中」標籤。
    case inviting = 2
}

extension FriendStatus {

    /// **邀請卡片區的唯一判定條件**（spec.md §4.2、O-1）。
    ///
    /// 推導：需求 (2)-II 規定 F1+F2 合併後必須是「好友列表無邀請」，
    /// 而合併結果中 `翁勳儀` 是 `status == 2`。
    /// 若 `2` 是邀請卡片，情境 II 就會冒出一張卡片，與需求矛盾；
    /// 若 `0` 是邀請卡片，合併後 `status == 0` 為 0 筆 → 無卡片 → 符合需求。
    ///
    /// 設計稿把 `status == 2` 的人畫成卡片，屬示意用的假資料，不具規範效力。
    /// 若面試官認定相反，**只改這一行**即可全案切換。
    static let invitationCard: FriendStatus = .invitationSent

    /// 是否屬於上方邀請卡片區。判定邏輯只存在這裡，不得散落他處。
    var isInvitationCard: Bool { self == FriendStatus.invitationCard }
}
