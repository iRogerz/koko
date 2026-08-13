//
//  FriendSearchBarViewTests.swift
//  kokoTests
//
//  AC-13「取消時還原」的防線。
//
//  「取消」按鈕與外部呼叫必須走同一條路徑（`cancelSearch()`），
//  否則會出現「按按鈕有清關鍵字、切分頁沒清」這種只在特定操作順序下才顯現的差異。
//

import XCTest
@testable import koko

@MainActor
final class FriendSearchBarViewTests: XCTestCase {

    /// 取消要同時做三件事：清空關鍵字、通知外部關鍵字變成空字串、通知外部還原畫面。
    /// 少做任何一件，畫面就會停在「上推 + 已篩選」的狀態。
    func test_cancelSearch_clearsKeywordAndNotifies() async {
        let view = FriendSearchBarView()

        var keywords: [String] = []
        var didCancel = false
        view.onKeywordChange = { keywords.append($0) }
        view.onCancel = { didCancel = true }

        view.cancelSearch()

        XCTAssertEqual(keywords, [""], "取消時沒有把空關鍵字送出去，清單不會還原")
        XCTAssertTrue(didCancel, "取消時沒有通知外部還原畫面")
    }

    /// 取消之後要離開搜尋狀態，「取消」按鈕才會換回「加好友」。
    func test_cancelSearch_leavesSearchingState() async {
        let view = FriendSearchBarView()

        view.cancelSearch()

        XCTAssertFalse(view.isSearching)
    }

    func test_initialState_isNotSearching() async {
        XCTAssertFalse(FriendSearchBarView().isSearching)
    }
}
