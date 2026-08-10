//
//  InvitationSectionView.swift
//  koko
//
//  spec.md §6.2 邀請卡片區。
//
//  - 收合態：只露出第一張，第二張以錯位方式露出底邊，暗示可展開
//  - 展開態：所有卡片完整列出，間距 8pt
//  - 點擊切換收合／展開（AC-14；動畫在 Step 7）
//

import UIKit

final class InvitationSectionView: UIView {

    private enum Layout {
        /// 收合時，後方卡片露出的高度。
        static let peekHeight: CGFloat = 6
        /// 收合時，後方卡片左右內縮的量，做出錯位堆疊感。
        static let peekInset: CGFloat = 8
        static let expandedSpacing: CGFloat = Spacing.s
        static let maximumPeekCards = 1
    }

    private(set) var isExpanded = false

    /// 使用者點擊卡片區（非按鈕處）時切換收合／展開。
    var onToggle: (() -> Void)?

    /// 接受或拒絕某張邀請。
    var onRespond: ((String) -> Void)?

    private var invites: [Friend] = []
    private var cards: [InvitationCardView] = []

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear

        let tap = UITapGestureRecognizer(target: self, action: #selector(toggle))
        addGestureRecognizer(tap)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("純程式碼建立，不支援 Storyboard／XIB")
    }

    func configure(with invites: [Friend], isExpanded: Bool) {
        self.invites = invites
        self.isExpanded = isExpanded
        rebuild()
    }

    // MARK: -

    private func rebuild() {
        // 移除 subview 會連帶移除參照到它的 constraint，不需要另外 deactivate。
        cards.forEach { $0.removeFromSuperview() }
        cards = []

        guard !invites.isEmpty else {
            isHidden = true
            return
        }
        isHidden = false

        // 收合時只放「第一張 + 一張墊底」，避免建立看不到的 view。
        let visible = isExpanded ? invites : Array(invites.prefix(1 + Layout.maximumPeekCards))

        for friend in visible {
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

        isExpanded ? layoutExpanded() : layoutCollapsed()
    }

    private func layoutExpanded() {
        var previousBottom = topAnchor

        for (index, card) in cards.enumerated() {
            NSLayoutConstraint.activate([
                card.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Spacing.l),
                card.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -Spacing.l),
                card.topAnchor.constraint(
                    equalTo: previousBottom,
                    constant: index == 0 ? 0 : Layout.expandedSpacing
                ),
            ])
            previousBottom = card.bottomAnchor
        }

        cards.last.map { bottomAnchor.constraint(equalTo: $0.bottomAnchor).isActive = true }
    }

    private func layoutCollapsed() {
        guard let front = cards.first else { return }

        NSLayoutConstraint.activate([
            front.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Spacing.l),
            front.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -Spacing.l),
            front.topAnchor.constraint(equalTo: topAnchor),
        ])

        // 墊底的那張只露出 peekHeight，並左右內縮做出堆疊感。
        if cards.count > 1 {
            let behind = cards[1]
            NSLayoutConstraint.activate([
                behind.leadingAnchor.constraint(equalTo: front.leadingAnchor, constant: Layout.peekInset),
                behind.trailingAnchor.constraint(equalTo: front.trailingAnchor, constant: -Layout.peekInset),
                behind.topAnchor.constraint(equalTo: front.topAnchor, constant: Layout.peekHeight),
                bottomAnchor.constraint(equalTo: behind.bottomAnchor),
            ])
        } else {
            bottomAnchor.constraint(equalTo: front.bottomAnchor).isActive = true
        }
    }

    @objc private func toggle() {
        onToggle?()
    }
}
