//
//  FriendRepository.swift
//  koko
//
//  spec.md §5：依情境決定要打哪些 API，**並行**取得後合併去重。
//
//  這是 View / ViewModel 取得資料的唯一入口 ——
//  View 不得直接呼叫網路（CLAUDE.md architecture rule 2）。
//

import Foundation

/// 單一情境載入完成後的資料。
///
/// `friends` 是**合併去重後的完整清單**，尚未拆成邀請卡片區與好友清單，
/// 也尚未套用置頂排序 —— 那兩件事屬於畫面狀態的推導，在 ViewModel 做。
struct FriendListData: Equatable {
    let user: User
    let friends: [Friend]
}

protocol FriendLoading: Sendable {
    func load(_ scenario: Scenario) async throws -> FriendListData
}

final class FriendRepository: FriendLoading {

    private let apiClient: APIClient

    init(apiClient: APIClient) {
        self.apiClient = apiClient
    }

    /// 使用者資料與好友清單**並行**取得（spec.md §5：所有請求皆為非同步且並行）。
    func load(_ scenario: Scenario) async throws -> FriendListData {
        async let user = apiClient.fetchUser()
        async let friends = loadFriends(for: scenario)

        return FriendListData(user: try await user, friends: try await friends)
    }

    private func loadFriends(for scenario: Scenario) async throws -> [Friend] {
        switch scenario {
        case .noFriends:
            return FriendMerger.merge(try await apiClient.fetchFriends(from: .noFriends))

        case .friendsWithInvites:
            return FriendMerger.merge(try await apiClient.fetchFriends(from: .friendsWithInvites))

        case .friendsOnly:
            // AC-3：F1 與 F2 必須並行送出，兩者都成功才合併（§5.1 規則 1）。
            // 任一失敗即整體 throw —— async let 的錯誤傳遞天然滿足這點。
            async let first = apiClient.fetchFriends(from: .friends1)
            async let second = apiClient.fetchFriends(from: .friends2)

            return FriendMerger.merge(try await first, try await second)
        }
    }
}
