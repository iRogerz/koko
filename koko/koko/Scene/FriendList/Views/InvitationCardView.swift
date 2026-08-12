//
//  InvitationCardView.swift
//  koko
//
//  spec.md §6.2 / design-spec §4.4：白底圓角卡片 + 陰影，
//  頭像、姓名、副標「邀請你成為好友：）」、✓ 接受、✕ 拒絕。
//
//  ✓／✕ 皆為本地 UI 行為，無對應 API（spec §10 O-3、O-6）。
//

import UIKit

final class InvitationCardView: UIView {

    /// 尺寸依 design-spec.md §7.5。
    private enum Layout {
        static let height: CGFloat = 70
        static let avatarSize: CGFloat = 40
        static let actionSize: CGFloat = 30
        static let actionSpacing: CGFloat = 15
        /// 卡片四邊內距一致。
        static let padding: CGFloat = 15
        static let cornerRadius: CGFloat = 6
        static let shadowRadius: CGFloat = 4
        static let shadowOpacity: Float = 0.15
        static let shadowOffset = CGSize(width: 0, height: 2)
    }

    private enum Text {
        static let subtitle = "邀請你成為好友：）"
    }

    /// 接受或拒絕。兩者行為相同（spec §6.2），只是圖示不同。
    var onRespond: ((String) -> Void)?

    private var fid: String?

    private let nameLabel = UILabel()
    private let subtitleLabel = UILabel()

    private let avatarView: UIImageView = {
        let imageView = UIImageView(image: AppImage.avatarDefault.image)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFill
        imageView.layer.cornerRadius = Layout.avatarSize / 2
        imageView.layer.masksToBounds = true
        return imageView
    }()

    private lazy var acceptButton = makeActionButton(
        systemName: "checkmark",
        color: AppColor.kokoPink,
        accessibilityLabel: "接受"
    )

    private lazy var rejectButton = makeActionButton(
        systemName: "xmark",
        color: AppColor.borderDisabled,
        accessibilityLabel: "拒絕"
    )

    override init(frame: CGRect) {
        super.init(frame: frame)

        // 卡片浮在 #FCFCFC 的上半部之上，本身是純白才有層次。
        backgroundColor = AppColor.surface
        layer.cornerRadius = Layout.cornerRadius
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowRadius = Layout.shadowRadius
        layer.shadowOpacity = Layout.shadowOpacity
        layer.shadowOffset = Layout.shadowOffset

        subtitleLabel.attributedText = AppText.caption.attributedString(Text.subtitle)

        let textColumn = UIStackView(arrangedSubviews: [nameLabel, subtitleLabel])
        textColumn.axis = .vertical
        textColumn.spacing = Spacing.xs

        let actions = UIStackView(arrangedSubviews: [acceptButton, rejectButton])
        actions.axis = .horizontal
        actions.spacing = Layout.actionSpacing

        let row = UIStackView(arrangedSubviews: [avatarView, textColumn, actions])
        row.translatesAutoresizingMaskIntoConstraints = false
        row.axis = .horizontal
        row.alignment = .center
        row.spacing = Layout.padding

        addSubview(row)

        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalToConstant: Layout.height),

            row.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Layout.padding),
            row.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -Layout.padding),
            row.centerYAnchor.constraint(equalTo: centerYAnchor),

            avatarView.widthAnchor.constraint(equalToConstant: Layout.avatarSize),
            avatarView.heightAnchor.constraint(equalToConstant: Layout.avatarSize),
        ])

        acceptButton.addTarget(self, action: #selector(respond), for: .touchUpInside)
        rejectButton.addTarget(self, action: #selector(respond), for: .touchUpInside)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("純程式碼建立，不支援 Storyboard／XIB")
    }

    func configure(with friend: Friend) {
        fid = friend.fid
        nameLabel.attributedText = AppText.inviteName.attributedString(friend.name)
    }

    @objc private func respond() {
        guard let fid else { return }
        onRespond?(fid)
    }

    /// design-spec §4.4：✓ 為粉紅圓形外框、✕ 為灰色圓形外框。
    private func makeActionButton(
        systemName: String,
        color: UIColor,
        accessibilityLabel: String
    ) -> UIButton {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setImage(UIImage(systemName: systemName), for: .normal)
        button.tintColor = color
        button.layer.borderColor = color.cgColor
        button.layer.borderWidth = 1
        button.layer.cornerRadius = Layout.actionSize / 2
        button.accessibilityLabel = accessibilityLabel

        NSLayoutConstraint.activate([
            button.widthAnchor.constraint(equalToConstant: Layout.actionSize),
            button.heightAnchor.constraint(equalToConstant: Layout.actionSize),
        ])
        return button
    }
}
