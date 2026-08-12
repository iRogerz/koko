//
//  FriendCell.swift
//  koko
//
//  spec.md §6.5 / design-spec §4.5：
//
//  | 元素 | 規則 |
//  |---|---|
//  | 星星 | `isTop == "1"` 才顯示 |
//  | 頭像 | 一律用 default（Zeplin 註解 #1） |
//  | 轉帳按鈕 | 粉紅外框，恆常顯示 |
//  | 邀請中標籤 | `status == 2` 才顯示，不可點 |
//  | `⋯` | `status == 1` 顯示（與「邀請中」互斥） |
//

import UIKit

final class FriendCell: UITableViewCell {

    static let reuseIdentifier = String(describing: FriendCell.self)

    /// 尺寸依 design-spec.md §7.7。
    private enum Layout {
        static let rowHeight: CGFloat = 60
        static let avatarSize: CGFloat = 40
        static let starSize: CGFloat = 14
        /// 大頭貼的 leading。**與星星有無無關** —— 設計稿上有星星的列，
        /// 大頭貼仍在同一條線上，星星是疊在它左邊的空位，不會把它推開。
        static let avatarLeading: CGFloat = 50
        /// 大頭貼右緣到姓名的距離。分隔線也對齊姓名的 leading。
        static let nameSpacing: CGFloat = 15.5
        static let transferWidth: CGFloat = 47
        static let actionHeight: CGFloat = 24
        static let invitingWidth: CGFloat = 55
        /// 轉帳 → 邀請中 的間距。
        static let actionSpacing: CGFloat = 15.5
        /// 轉帳 → ⋯ 的間距。設計稿這兩個間距**不一樣**，不是筆誤，量測值分別是
        /// 284.5→300（15.5）與 301.5→327（25.5）。
        static let moreSpacing: CGFloat = 25.5
        static let moreWidth: CGFloat = 18
        static let cornerRadius: CGFloat = 2
        static let separatorHeight: CGFloat = 1
    }

    private enum Text {
        static let transfer = "轉帳"
        static let inviting = "邀請中"
    }

    private let nameLabel = UILabel()

    private let actions: UIStackView = {
        let stack = UIStackView()
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()

    private let starView: UIImageView = {
        let imageView = UIImageView(image: UIImage(systemName: "star.fill"))
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.tintColor = AppColor.star
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    private let avatarView: UIImageView = {
        let imageView = UIImageView(image: AppImage.avatarDefault.image)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFill
        imageView.layer.cornerRadius = Layout.avatarSize / 2
        imageView.layer.masksToBounds = true
        return imageView
    }()

    private lazy var transferLabel = makeOutlinedLabel(
        text: Text.transfer,
        color: AppColor.kokoPink,
        width: Layout.transferWidth
    )

    private lazy var invitingLabel = makeOutlinedLabel(
        text: Text.inviting,
        color: AppColor.borderDisabled,
        width: Layout.invitingWidth
    )

    private let moreView: UIImageView = {
        let imageView = UIImageView(image: UIImage(systemName: "ellipsis"))
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.tintColor = AppColor.borderDisabled
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    /// design-spec §7.7：分隔線 leading 對齊**姓名**（105.5），非滿版也非自頭像右緣起算。
    private let separator: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = AppColor.separator
        return view
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        selectionStyle = .none
        backgroundColor = AppColor.surface
        contentView.directionalLayoutMargins = .init(
            top: 0, leading: Spacing.pageMargin, bottom: 0, trailing: Spacing.pageMargin
        )

        nameLabel.translatesAutoresizingMaskIntoConstraints = false

        // 轉帳／邀請中／⋯ 是靠右的一組，整組右緣對齊頁面邊距。
        actions.axis = .horizontal
        actions.alignment = .center
        actions.spacing = Layout.actionSpacing
        actions.addArrangedSubview(transferLabel)
        actions.addArrangedSubview(invitingLabel)
        actions.addArrangedSubview(moreView)

        contentView.addSubview(starView)
        contentView.addSubview(avatarView)
        contentView.addSubview(nameLabel)
        contentView.addSubview(actions)
        contentView.addSubview(separator)

        NSLayoutConstraint.activate([
            contentView.heightAnchor.constraint(equalToConstant: Layout.rowHeight),

            // 星星獨立定位，不參與水平堆疊 —— 否則沒星星的列會整排左移。
            starView.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor),
            starView.centerYAnchor.constraint(equalTo: avatarView.centerYAnchor),
            starView.widthAnchor.constraint(equalToConstant: Layout.starSize),
            starView.heightAnchor.constraint(equalToConstant: Layout.starSize),

            avatarView.leadingAnchor.constraint(
                equalTo: contentView.leadingAnchor, constant: Layout.avatarLeading
            ),
            avatarView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            avatarView.widthAnchor.constraint(equalToConstant: Layout.avatarSize),
            avatarView.heightAnchor.constraint(equalToConstant: Layout.avatarSize),

            nameLabel.leadingAnchor.constraint(
                equalTo: avatarView.trailingAnchor, constant: Layout.nameSpacing
            ),
            nameLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            nameLabel.trailingAnchor.constraint(lessThanOrEqualTo: actions.leadingAnchor, constant: -Spacing.s),

            actions.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor),
            actions.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            moreView.widthAnchor.constraint(equalToConstant: Layout.moreWidth),

            // 分隔線對齊姓名的 leading，不是滿版也不是從頭像右緣起算。
            separator.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            separator.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor),
            separator.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            separator.heightAnchor.constraint(equalToConstant: Layout.separatorHeight),
        ])
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("純程式碼建立，不支援 Storyboard／XIB")
    }

    /// 顯示規則全部來自 `FriendCellContent`（可單獨測試），
    /// 這裡只把結果套到 `isHidden`。
    func configure(with friend: Friend) {
        let content = FriendCellContent(friend: friend)

        nameLabel.attributedText = AppText.name.attributedString(content.name)

        // 用 isHidden 而非移除，維持各欄位的水平對齊。
        starView.isHidden = !content.showsStar
        invitingLabel.isHidden = !content.showsInvitingTag
        moreView.isHidden = !content.showsMoreButton
        transferLabel.isHidden = !content.showsTransferButton

        // 「邀請中」與「⋯」互斥（FriendCellContent 保證），兩者與轉帳的間距不同。
        actions.setCustomSpacing(
            content.showsInvitingTag ? Layout.actionSpacing : Layout.moreSpacing,
            after: transferLabel
        )
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        starView.isHidden = true
        invitingLabel.isHidden = true
        moreView.isHidden = true
    }

    private func makeOutlinedLabel(text: String, color: UIColor, width: CGFloat) -> UILabel {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.attributedText = AppText.actionButton.withColor(color).attributedString(text, alignment: .center)
        label.textAlignment = .center
        label.layer.borderColor = color.cgColor
        label.layer.borderWidth = 1
        label.layer.cornerRadius = Layout.cornerRadius

        NSLayoutConstraint.activate([
            label.widthAnchor.constraint(equalToConstant: width),
            label.heightAnchor.constraint(equalToConstant: Layout.actionHeight),
        ])
        return label
    }
}
