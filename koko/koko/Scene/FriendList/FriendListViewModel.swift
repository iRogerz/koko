//
//  FriendListViewModel.swift
//  koko
//
//  spec.md §4.3 狀態機 / §6.4 搜尋 / §7.1 view state
//
//  **本檔不得 import UIKit**（CLAUDE.md architecture rule 1）。
//  Combine 只用來做狀態發布，與 UIKit 無關。
//

import Combine
import Foundation

@MainActor
final class FriendListViewModel {

    @Published private(set) var state: FriendListViewState

    /// `@Published` 搭配 `private(set)` 時，投影值 `$state` 在型別外不可見，
    /// 因此另外開一個唯讀的 publisher 給 View 訂閱。
    var statePublisher: AnyPublisher<FriendListViewState, Never> {
        $state.eraseToAnyPublisher()
    }

    private let scenario: Scenario
    private let repository: FriendLoading

    // MARK: 狀態推導的來源

    /// 合併去重後的**完整**清單，不受搜尋影響。
    /// 搜尋與分區都是從這份資料即時推導，所以清空關鍵字必定能還原。
    private var allFriends: [Friend] = []
    private var user: User?
    private var keyword = ""

    init(scenario: Scenario, repository: FriendLoading) {
        self.scenario = scenario
        self.repository = repository
        self.state = FriendListViewState(user: nil, content: .loading)
    }

    // MARK: - Intent

    func load() async {
        await load(showingLoadingState: true)
    }

    /// AC-12 下拉更新：重新呼叫該情境的 API。
    /// 不切回 `.loading` —— 下拉本身已有轉圈動畫，再閃一次骨架很突兀。
    func refresh() async {
        await load(showingLoadingState: false)
    }

    /// AC-9：即時篩選。純本地運算，不重打 API（§6.4）。
    func search(_ keyword: String) {
        self.keyword = keyword
        updateState()
    }

    /// 邀請卡片的 ✓ 接受 / ✕ 拒絕。
    ///
    /// spec.md §6.2：兩者都是純 UI 行為 —— 本地移除該筆邀請並更新畫面狀態，
    /// **無對應 API，不做後端請求**。接受後是否該轉成好友見 §10 O-6。
    func respondToInvitation(fid: String) {
        allFriends.removeAll { $0.fid == fid && $0.isInvitationCard }
        updateState()
    }

    // MARK: - 內部

    private func load(showingLoadingState: Bool) async {
        if showingLoadingState {
            state = FriendListViewState(user: user, content: .loading)
        }

        do {
            let data = try await repository.load(scenario)
            user = data.user
            allFriends = data.friends
            updateState()
        } catch {
            // §10 O-4：往上呈現錯誤 + 由使用者重試，不自動重試。
            state = FriendListViewState(user: user, content: .failed(error))
        }
    }

    private func updateState() {
        state = FriendListViewState(user: user, content: makeContent())
    }

    private func makeContent() -> FriendListViewState.Content {
        // 狀態 A 以「合併後好友**總數**為 0」判定，不是「一般好友數為 0」。
        // 若某次資料只有邀請沒有好友，仍屬狀態 C（spec.md §4.3）。
        guard !allFriends.isEmpty else { return .empty }

        let invites = allFriends.filter(\.isInvitationCard)
        let friendList = FriendSorter.topPinnedFirst(allFriends.filter { !$0.isInvitationCard })

        // 搜尋只作用在好友清單，不篩邀請卡片區（§6.4）。
        // 搜尋無結果時仍是 .loaded（空清單），不會掉回 .empty。
        return .loaded(invites: invites, friends: FriendSearch.filter(friendList, keyword: keyword))
    }
}
