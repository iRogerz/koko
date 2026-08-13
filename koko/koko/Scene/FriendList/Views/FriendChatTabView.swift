//
//  FriendChatTabView.swift
//  koko
//
//  spec.md §6.3 / design-spec §4.2：「好友」／「聊天」兩個 tab。
//  聊天 badge 固定 `99+`；好友 badge 為邀請卡片數，0 時隱藏。
//
//  可切換；「聊天」的內容為空白畫面（spec.md §11）。
//

import UIKit

final class FriendChatTabView: UIView {

    enum Segment: CaseIterable {
        case friends
        case chats

        var title: String {
            switch self {
            case .friends: return "好友"
            case .chats: return "聊天"
            }
        }
    }

    /// 尺寸依 design-spec.md §7.4。
    private enum Layout {
        static let indicatorHeight: CGFloat = 4
        static let indicatorWidth: CGFloat = 20
        /// 「聊天」的 leading 相對「好友」是**固定**的 —— 設計稿上兩張稿的「聊天」
        /// 都在 x=94.5，好友 badge 出現時不會把它推開。用固定距離才對得上。
        static let chatsOffset: CGFloat = 62.5
        /// tab 列總高（150 → 191.5）。指示器貼底，文字距上緣 14。
        static let height: CGFloat = 42
        static let topPadding: CGFloat = 14
    }

    private enum Text {
        static let chatBadge = "99+"
    }

    var onSelect: ((Segment) -> Void)?

    private(set) var selectedSegment: Segment = .friends

    private let friendsLabel = UILabel()
    private let chatsLabel = UILabel()
    private let friendsBadge = BadgeLabel()
    private let chatsBadge = BadgeLabel()

    private let friendsButton = UIControl()
    private let chatsButton = UIControl()

    private var indicatorCenterX: NSLayoutConstraint?

    private let indicator: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = AppColor.kokoPink
        view.layer.cornerRadius = Layout.indicatorHeight / 2
        return view
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = AppColor.cardBackground
        directionalLayoutMargins = .init(
            top: 0, leading: Spacing.pageMargin, bottom: 0, trailing: Spacing.pageMargin
        )

        friendsBadge.isHidden = true
        chatsBadge.setText(Text.chatBadge)

        let friendsItem = makeItem(label: friendsLabel, badge: friendsBadge, control: friendsButton)
        let chatsItem = makeItem(label: chatsLabel, badge: chatsBadge, control: chatsButton)

        friendsButton.addTarget(self, action: #selector(friendsTapped), for: .touchUpInside)
        chatsButton.addTarget(self, action: #selector(chatsTapped), for: .touchUpInside)

        addSubview(friendsItem)
        addSubview(chatsItem)
        addSubview(indicator)

        // 設計稿的固定距離；好友 badge 變寬（三位數）時讓位給下面的防重疊約束。
        let chatsOffset = chatsItem.leadingAnchor.constraint(
            equalTo: friendsItem.leadingAnchor, constant: Layout.chatsOffset
        )
        chatsOffset.priority = .defaultHigh

        NSLayoutConstraint.activate([
            // 總高固定，指示器貼底 —— 文字的行高會隨字體版本浮動，
            // 用「文字高 + 間距」相加會讓整列跟著飄。
            heightAnchor.constraint(equalToConstant: Layout.height),

            friendsItem.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor),
            friendsItem.topAnchor.constraint(equalTo: topAnchor, constant: Layout.topPadding),

            chatsOffset,
            chatsItem.leadingAnchor.constraint(
                greaterThanOrEqualTo: friendsItem.trailingAnchor, constant: Spacing.s
            ),
            chatsItem.centerYAnchor.constraint(equalTo: friendsItem.centerYAnchor),
            chatsItem.trailingAnchor.constraint(lessThanOrEqualTo: layoutMarginsGuide.trailingAnchor),

            // 指示器貼齊上半部底緣，與下方的全寬分隔線相接。
            indicator.bottomAnchor.constraint(equalTo: bottomAnchor),
            indicator.widthAnchor.constraint(equalToConstant: Layout.indicatorWidth),
            indicator.heightAnchor.constraint(equalToConstant: Layout.indicatorHeight),
        ])

        applySelection(animated: false)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("純程式碼建立，不支援 Storyboard／XIB")
    }

    /// 「好友」badge 的數字，即邀請卡片數（spec §6.3）。
    func setInvitationCount(_ count: Int) {
        friendsBadge.setCount(count)
    }

    /// 「聊天」badge 平常固定 `99+`（Zeplin 註解 #3），但 New Comer 稿上沒有它 ——
    /// 一個好友都沒有的新用戶不會有 99+ 則聊天。空狀態時收起來（spec §6.3）。
    func setChatBadgeHidden(_ isHidden: Bool) {
        chatsBadge.isHidden = isHidden
    }

    func select(_ segment: Segment) {
        guard segment != selectedSegment else { return }
        selectedSegment = segment
        applySelection(animated: true)
    }

    // MARK: -

    private func makeItem(label: UILabel, badge: BadgeLabel, control: UIControl) -> UIView {
        let stack = UIStackView(arrangedSubviews: [label, badge])
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .horizontal
        stack.alignment = .center
        stack.spacing = Spacing.xs
        stack.isUserInteractionEnabled = false

        control.translatesAutoresizingMaskIntoConstraints = false
        control.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: control.topAnchor),
            stack.bottomAnchor.constraint(equalTo: control.bottomAnchor),
            stack.leadingAnchor.constraint(equalTo: control.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: control.trailingAnchor),
        ])
        return control
    }

    private func applySelection(animated: Bool) {
        friendsLabel.attributedText = title(for: .friends)
        chatsLabel.attributedText = title(for: .chats)

        indicatorCenterX?.isActive = false
        let target = selectedSegment == .friends ? friendsLabel : chatsLabel
        indicatorCenterX = indicator.centerXAnchor.constraint(equalTo: target.centerXAnchor)
        indicatorCenterX?.isActive = true

        guard animated else { return }
        UIView.animate(withDuration: 0.2) { self.layoutIfNeeded() }
    }

    private func title(for segment: Segment) -> NSAttributedString {
        AppText.tabTitle
            .withColor(segment == selectedSegment ? AppColor.kokoPink : AppColor.textSecondary)
            .attributedString(segment.title)
    }

    @objc private func friendsTapped() {
        select(.friends)
        onSelect?(.friends)
    }

    @objc private func chatsTapped() {
        select(.chats)
        onSelect?(.chats)
    }
}
