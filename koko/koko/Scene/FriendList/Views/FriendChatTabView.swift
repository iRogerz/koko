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

    private enum Layout {
        static let indicatorHeight: CGFloat = 2
        static let indicatorWidth: CGFloat = 20
        static let itemSpacing: CGFloat = 36
        static let verticalPadding: CGFloat = 14
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
        backgroundColor = AppColor.surface
        directionalLayoutMargins = .init(top: 0, leading: Spacing.l, bottom: 0, trailing: Spacing.l)

        friendsBadge.isHidden = true
        chatsBadge.setText(Text.chatBadge)

        let friendsItem = makeItem(label: friendsLabel, badge: friendsBadge, control: friendsButton)
        let chatsItem = makeItem(label: chatsLabel, badge: chatsBadge, control: chatsButton)

        friendsButton.addTarget(self, action: #selector(friendsTapped), for: .touchUpInside)
        chatsButton.addTarget(self, action: #selector(chatsTapped), for: .touchUpInside)

        let row = UIStackView(arrangedSubviews: [friendsItem, chatsItem])
        row.translatesAutoresizingMaskIntoConstraints = false
        row.axis = .horizontal
        row.alignment = .center
        row.spacing = Layout.itemSpacing

        addSubview(row)
        addSubview(indicator)

        NSLayoutConstraint.activate([
            row.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor),
            row.topAnchor.constraint(equalTo: topAnchor, constant: Layout.verticalPadding),
            row.trailingAnchor.constraint(lessThanOrEqualTo: layoutMarginsGuide.trailingAnchor),

            indicator.topAnchor.constraint(equalTo: row.bottomAnchor, constant: Layout.verticalPadding),
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
