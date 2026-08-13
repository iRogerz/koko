//
//  InvitationSectionViewTests.swift
//  kokoTests
//
//  AC-14 展開／收合動畫的前提條件。
//
//  動畫能不能做出來，取決於「切換時不新增也不移除卡片」——
//  卡片一次全部建好，收合只是換一組約束，所以 `layoutIfNeeded()` 就能補間。
//  若有人改回「收合時只建兩張、展開時再補建」，動畫會變成卡片憑空跳出來，
//  而且畫面上**不會有任何錯誤**。這裡就釘這件事。
//

import XCTest
@testable import koko

@MainActor
final class InvitationSectionViewTests: XCTestCase {

    private let width: CGFloat = 375

    /// 展開／收合來回切，卡片必須是**同一批 view 實例**。
    func test_togglingExpansion_reusesTheSameCardViews() async throws {
        let section = InvitationSectionView()
        let invites = try makeInvites(count: 3)

        section.configure(with: invites, isExpanded: false)
        let collapsed = cardIdentities(in: section)

        section.configure(with: invites, isExpanded: true)
        let expanded = cardIdentities(in: section)

        section.configure(with: invites, isExpanded: false)
        let collapsedAgain = cardIdentities(in: section)

        XCTAssertEqual(collapsed.count, 3, "三筆邀請就該建三張卡片，收合時也一樣")
        XCTAssertEqual(collapsed, expanded, "展開時重建了卡片，動畫會變成憑空跳出來")
        XCTAssertEqual(expanded, collapsedAgain, "收合時重建了卡片")
    }

    /// 名單換了才可以重建 —— 否則接受／拒絕邀請後畫面不會更新。
    func test_changingInvites_rebuildsCards() async throws {
        let section = InvitationSectionView()

        section.configure(with: try makeInvites(count: 3), isExpanded: false)
        let before = cardIdentities(in: section)

        section.configure(with: try makeInvites(count: 2), isExpanded: false)
        let after = cardIdentities(in: section)

        XCTAssertEqual(after.count, 2)
        XCTAssertNotEqual(before, after, "名單變了卻沿用舊卡片")
    }

    /// 展開一定比收合高，否則動畫沒有可見的變化。
    func test_expanded_isTallerThanCollapsed() async throws {
        let invites = try makeInvites(count: 3)

        let collapsedHeight = height(of: invites, isExpanded: false)
        let expandedHeight = height(of: invites, isExpanded: true)

        XCTAssertGreaterThan(expandedHeight, collapsedHeight)
    }

    /// **第一張卡片在展開／收合時不得移動。** 它是使用者的視覺錨點，
    /// 動起來就會看到「跳一下」。兩組約束對第一張的 leading／trailing／top
    /// 本來就寫成一樣，這條保證之後不會有人不小心改掉其中一組。
    func test_frontCard_doesNotMoveBetweenStates() async throws {
        let invites = try makeInvites(count: 3)

        let collapsed = laidOutSection(with: invites, isExpanded: false)
        let expanded = laidOutSection(with: invites, isExpanded: true)

        let collapsedFront = try XCTUnwrap(cards(in: collapsed).first).frame
        let expandedFront = try XCTUnwrap(cards(in: expanded).first).frame

        XCTAssertEqual(collapsedFront, expandedFront, "展開／收合時第一張卡片位移了，畫面上會看到它跳一下")
    }

    /// 收合時第二張以後全部疊在同一個位置，只有第二張露得出來。
    func test_collapsed_stacksTrailingCardsAtTheSamePlace() async throws {
        let section = laidOutSection(with: try makeInvites(count: 3), isExpanded: false)
        let cards = cards(in: section)

        XCTAssertEqual(cards.count, 3)
        XCTAssertEqual(cards[1].frame, cards[2].frame, "第三張沒有被第二張擋住")
        XCTAssertNotEqual(cards[0].frame, cards[1].frame, "第二張沒有露出底邊")
    }

    /// 無邀請時整區收起來，不佔高度。
    func test_noInvites_hidesSection() async {
        let section = InvitationSectionView()
        section.configure(with: [], isExpanded: false)

        XCTAssertTrue(section.isHidden)
    }

    // MARK: -

    private func makeInvites(count: Int) throws -> [Friend] {
        try (0..<count).map {
            try FriendBuilder.make(fid: "invite-\($0)", name: "邀請 \($0)", status: .invitationSent)
        }
    }

    /// 卡片依建立順序回傳（第一張＝最前面那張）。
    private func cards(in section: InvitationSectionView) -> [InvitationCardView] {
        section.subviews.compactMap { $0 as? InvitationCardView }
    }

    private func cardIdentities(in section: InvitationSectionView) -> [ObjectIdentifier] {
        cards(in: section).map(ObjectIdentifier.init)
    }

    private func laidOutSection(with invites: [Friend], isExpanded: Bool) -> InvitationSectionView {
        let section = InvitationSectionView()
        section.configure(with: invites, isExpanded: isExpanded)
        section.frame = CGRect(x: 0, y: 0, width: width, height: height(of: invites, isExpanded: isExpanded))
        section.layoutIfNeeded()
        return section
    }

    private func height(of invites: [Friend], isExpanded: Bool) -> CGFloat {
        let section = InvitationSectionView()
        section.configure(with: invites, isExpanded: isExpanded)
        return section.systemLayoutSizeFitting(
            CGSize(width: width, height: UIView.layoutFittingCompressedSize.height),
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel
        ).height
    }
}
