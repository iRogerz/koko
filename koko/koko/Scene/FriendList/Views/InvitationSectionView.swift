//
//  InvitationSectionView.swift
//  koko
//
//  spec.md §6.2 邀請卡片區。
//
//  - 收合態：只露出第一張，第二張以錯位方式露出底邊，暗示可展開
//  - 展開態：所有卡片完整列出，間距 8pt
//  - 點擊切換收合／展開，含動畫（AC-14）
//
//  尺寸依 design-spec.md §7.5。
//
//  **卡片一次全部建好，收合只是換一組約束。** 這樣切換時沒有 view 生成／移除，
//  單純 `layoutIfNeeded()` 就能動起來 —— 邊建 view 邊做動畫只會看到卡片憑空跳出來。
//

import UIKit

final class InvitationSectionView: UIView {

    private enum Layout {
        /// 收合時，後方卡片露出的高度。
        static let peekHeight: CGFloat = 10
        /// 收合時，後方卡片左右內縮的量，做出錯位堆疊感。
        static let peekInset: CGFloat = 10
        static let expandedSpacing: CGFloat = Spacing.s
        /// 與上方 header 的距離。
        static let topMargin: CGFloat = 19
        /// 與下方好友／聊天 tab 列的距離。
        static let bottomMargin: CGFloat = 8
    }

    private(set) var isExpanded = false

    /// 使用者點擊卡片區（非按鈕處）時切換收合／展開。
    var onToggle: (() -> Void)?

    /// 接受或拒絕某張邀請。
    var onRespond: ((String) -> Void)?

    /// `nil` 代表**一次都還沒建過**。用 optional 而非空陣列，是為了讓第一次
    /// `configure(with: [], …)` 也會走進重建 —— 否則「空陣列 vs 空陣列」比對相等，
    /// 整區不會被收起來。
    private var builtInvites: [Friend]?
    private var cards: [InvitationCardView] = []

    private var expandedConstraints: [NSLayoutConstraint] = []
    private var collapsedConstraints: [NSLayoutConstraint] = []

    override init(frame: CGRect) {
        super.init(frame: frame)
        // 卡片區位在 header 與 tab 列之間，屬於 #FCFCFC 的上半部。
        backgroundColor = AppColor.cardBackground

        let tap = UITapGestureRecognizer(target: self, action: #selector(toggle))
        addGestureRecognizer(tap)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("純程式碼建立，不支援 Storyboard／XIB")
    }

    func configure(with invites: [Friend], isExpanded: Bool) {
        // 名單沒變就不要重建 —— 重建會讓進行中的展開動畫斷掉。
        if builtInvites?.map(\.fid) != invites.map(\.fid) {
            builtInvites = invites
            rebuildCards(with: invites)
        }
        self.isExpanded = isExpanded
        applyExpansion()
    }

    // MARK: - 建卡片

    private func rebuildCards(with invites: [Friend]) {
        // 移除 subview 會連帶移除參照到它的 constraint，不需要另外 deactivate。
        cards.forEach { $0.removeFromSuperview() }
        cards = []
        expandedConstraints = []
        collapsedConstraints = []

        guard !invites.isEmpty else {
            isHidden = true
            return
        }
        isHidden = false

        for friend in invites {
            let card = InvitationCardView()
            card.translatesAutoresizingMaskIntoConstraints = false
            card.configure(with: friend)
            card.onRespond = { [weak self] fid in self?.onRespond?(fid) }
            addSubview(card)
            cards.append(card)
        }

        // 後方的卡片要疊在前一張下面，所以反序把第一張帶到最上層。
        for card in cards.reversed() {
            bringSubviewToFront(card)
        }

        makeExpandedConstraints()
        makeCollapsedConstraints()
    }

    private func makeExpandedConstraints() {
        var previousBottom = topAnchor

        for (index, card) in cards.enumerated() {
            expandedConstraints += [
                card.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Spacing.pageMargin),
                card.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -Spacing.pageMargin),
                card.topAnchor.constraint(
                    equalTo: previousBottom,
                    constant: index == 0 ? Layout.topMargin : Layout.expandedSpacing
                ),
            ]
            previousBottom = card.bottomAnchor
        }

        if let last = cards.last {
            expandedConstraints.append(
                bottomAnchor.constraint(equalTo: last.bottomAnchor, constant: Layout.bottomMargin)
            )
        }
    }

    /// 收合時第二張以後**全部疊在同一個位置**，只有第二張露得出來，
    /// 其餘被它擋住。這樣展開／收合都不需要新增或移除卡片。
    private func makeCollapsedConstraints() {
        guard let front = cards.first else { return }

        collapsedConstraints += [
            front.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Spacing.pageMargin),
            front.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -Spacing.pageMargin),
            front.topAnchor.constraint(equalTo: topAnchor, constant: Layout.topMargin),
        ]

        for card in cards.dropFirst() {
            collapsedConstraints += [
                card.leadingAnchor.constraint(equalTo: front.leadingAnchor, constant: Layout.peekInset),
                card.trailingAnchor.constraint(equalTo: front.trailingAnchor, constant: -Layout.peekInset),
                card.topAnchor.constraint(equalTo: front.topAnchor, constant: Layout.peekHeight),
            ]
        }

        let last = cards.count > 1 ? cards[1] : front
        collapsedConstraints.append(
            bottomAnchor.constraint(equalTo: last.bottomAnchor, constant: Layout.bottomMargin)
        )
    }

    private func applyExpansion() {
        NSLayoutConstraint.deactivate(isExpanded ? collapsedConstraints : expandedConstraints)
        NSLayoutConstraint.activate(isExpanded ? expandedConstraints : collapsedConstraints)
    }

    @objc private func toggle() {
        onToggle?()
    }
}
