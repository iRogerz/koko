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

    private enum Layout {
        static let avatarSize: CGFloat = 40
        static let starSize: CGFloat = 14
        static let transferWidth: CGFloat = 50
        static let transferHeight: CGFloat = 24
        static let invitingWidth: CGFloat = 56
        static let moreWidth: CGFloat = 20
        static let cornerRadius: CGFloat = 2
        static let separatorHeight: CGFloat = 1
        static let verticalPadding: CGFloat = 14
    }

    private enum Text {
        static let transfer = "轉帳"
        static let inviting = "邀請中"
    }

    private let nameLabel = UILabel()

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

    /// design-spec §4.5：分隔線自頭像右緣起算，非滿版。
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
        contentView.directionalLayoutMargins = .init(top: 0, leading: Spacing.l, bottom: 0, trailing: Spacing.l)

        let row = UIStackView(arrangedSubviews: [
            starView, avatarView, nameLabel, UIView(), transferLabel, invitingLabel, moreView,
        ])
        row.translatesAutoresizingMaskIntoConstraints = false
        row.axis = .horizontal
        row.alignment = .center
        row.spacing = Spacing.m

        contentView.addSubview(row)
        contentView.addSubview(separator)

        NSLayoutConstraint.activate([
            row.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor),
            row.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor),
            row.topAnchor.constraint(equalTo: contentView.topAnchor, constant: Layout.verticalPadding),
            row.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -Layout.verticalPadding),

            starView.widthAnchor.constraint(equalToConstant: Layout.starSize),
            starView.heightAnchor.constraint(equalToConstant: Layout.starSize),
            avatarView.widthAnchor.constraint(equalToConstant: Layout.avatarSize),
            avatarView.heightAnchor.constraint(equalToConstant: Layout.avatarSize),
            moreView.widthAnchor.constraint(equalToConstant: Layout.moreWidth),

            separator.leadingAnchor.constraint(equalTo: avatarView.trailingAnchor),
            separator.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
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
            label.heightAnchor.constraint(equalToConstant: Layout.transferHeight),
        ])
        return label
    }
}
