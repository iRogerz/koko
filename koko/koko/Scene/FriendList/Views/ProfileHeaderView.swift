//
//  ProfileHeaderView.swift
//  koko
//
//  spec.md §6.1 / design-spec §4.1：三種狀態共用的 header。
//
//  - 有 `kokoid` → 「KOKO ID : {id}」+ `>`
//  - 無 `kokoid` → 「設定 KOKO ID」+ `>` + 粉紅小圓點
//

import UIKit

final class ProfileHeaderView: UIView {

    /// 尺寸依 design-spec.md §7.3。
    private enum Layout {
        static let avatarSize: CGFloat = 52
        static let chevronSize: CGFloat = 10
        /// New Comer 稿量測值（design-spec §7.9 的 header 部分）。
        static let dotSize: CGFloat = 10
        /// 大頭貼上下各留 16，header 總高 84。
        static let verticalPadding: CGFloat = 16
        /// 姓名與 KOKO ID 列的垂直間距。
        static let textSpacing: CGFloat = 12
    }

    private enum Text {
        static let unsetKokoID = "設定 KOKO ID"
        static func kokoID(_ id: String) -> String { "KOKO ID : \(id)" }
    }

    private let nameLabel = UILabel()
    private let kokoIDLabel = UILabel()

    private let chevron: UIImageView = {
        let imageView = UIImageView(image: UIImage(systemName: "chevron.right"))
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.tintColor = AppColor.textSecondary
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    /// 未設定 KOKO ID 時的粉紅小圓點（New Comer 稿）。
    private let unsetDot: UIView = {
        let dot = UIView()
        dot.translatesAutoresizingMaskIntoConstraints = false
        dot.backgroundColor = AppColor.kokoPink
        dot.layer.cornerRadius = Layout.dotSize / 2
        return dot
    }()

    private let avatarView: UIImageView = {
        let imageView = UIImageView(image: AppImage.avatarDefault.image)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFill
        imageView.layer.cornerRadius = Layout.avatarSize / 2
        imageView.layer.masksToBounds = true
        return imageView
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        // 上半部（nav／header／邀請卡片／tab）統一是 #FCFCFC，不是純白。
        backgroundColor = AppColor.cardBackground
        directionalLayoutMargins = .init(
            top: 0, leading: Spacing.pageMargin, bottom: 0, trailing: Spacing.pageMargin
        )

        let kokoIDRow = UIStackView(arrangedSubviews: [kokoIDLabel, chevron, unsetDot])
        kokoIDRow.axis = .horizontal
        kokoIDRow.alignment = .center
        kokoIDRow.spacing = Spacing.xs
        // 設計稿上圓點離 `>` 比較開（123 →〔`>`〕→ 148）。
        kokoIDRow.setCustomSpacing(Spacing.s, after: chevron)

        let textColumn = UIStackView(arrangedSubviews: [nameLabel, kokoIDRow])
        textColumn.translatesAutoresizingMaskIntoConstraints = false
        textColumn.axis = .vertical
        textColumn.alignment = .leading
        textColumn.spacing = Layout.textSpacing

        addSubview(textColumn)
        addSubview(avatarView)

        NSLayoutConstraint.activate([
            textColumn.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor),
            textColumn.centerYAnchor.constraint(equalTo: avatarView.centerYAnchor),
            textColumn.trailingAnchor.constraint(lessThanOrEqualTo: avatarView.leadingAnchor, constant: -Spacing.m),

            // 高度由大頭貼決定（52 + 上下各 16 = 84），文字再置中對齊它。
            avatarView.topAnchor.constraint(equalTo: topAnchor, constant: Layout.verticalPadding),
            avatarView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -Layout.verticalPadding),
            avatarView.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor),
            avatarView.widthAnchor.constraint(equalToConstant: Layout.avatarSize),
            avatarView.heightAnchor.constraint(equalToConstant: Layout.avatarSize),

            chevron.widthAnchor.constraint(equalToConstant: Layout.chevronSize),
            chevron.heightAnchor.constraint(equalToConstant: Layout.chevronSize),
            unsetDot.widthAnchor.constraint(equalToConstant: Layout.dotSize),
            unsetDot.heightAnchor.constraint(equalToConstant: Layout.dotSize),
        ])
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("純程式碼建立，不支援 Storyboard／XIB")
    }

    /// `user` 為 `nil` 表示尚未載入，此時不顯示任何文字。
    func configure(with user: User?) {
        nameLabel.attributedText = AppText.name.attributedString(user?.name ?? "")

        guard let user else {
            kokoIDLabel.attributedText = nil
            unsetDot.isHidden = true
            return
        }

        if let kokoID = user.kokoID {
            kokoIDLabel.attributedText = AppText.body.attributedString(Text.kokoID(kokoID))
            unsetDot.isHidden = true
        } else {
            kokoIDLabel.attributedText = AppText.body.attributedString(Text.unsetKokoID)
            unsetDot.isHidden = false
        }
    }
}
