//
//  EmptyStateView.swift
//  koko
//
//  spec.md §6.6 狀態 A（New Comer）：合併後好友總數為 0。
//
//  插圖 → 主標 → 副標兩行 → 綠色漸層「加好友」按鈕 →（底部）設定 KOKO ID 連結。
//  尺寸依 design-spec.md §7.9。
//
//  按鈕與連結**都不接行為**（spec.md §11 Out of Scope），但保留按鈕的觸感與
//  accessibility trait，錄影時看起來才正常。
//

import UIKit

final class EmptyStateView: UIView {

    /// 位置全部以白色內容區頂端（設計稿 y=192）為基準。
    ///
    /// ⚠️ 設計稿量到的是**字的外框**，不是 label 的行框。行框比字框高，
    /// 所以下面的間距已經扣掉上下的行距餘量（21pt 約 5、13pt 約 3），
    /// 直接填量測值會比設計稿鬆。
    private enum Layout {
        static let illustrationWidth: CGFloat = 245
        static let illustrationHeight: CGFloat = 171.5
        static let illustrationTop: CGFloat = 30.5

        /// 插圖 → 主標（量測 46.5，扣掉主標行框餘量 5）。
        static let titleTop: CGFloat = 41.5
        /// 主標 → 副標（量測 17，扣掉兩端餘量 5 + 3）。
        static let subtitleTop: CGFloat = 9
        /// 副標 → 按鈕（量測 29，扣掉副標行框餘量 2）。
        static let buttonTop: CGFloat = 27

        static let buttonWidth: CGFloat = 192
        static let buttonHeight: CGFloat = 40

        /// 連結靠下對齊，不跟著上面的內容浮動（量測 21，扣掉行框餘量 3）。
        static let linkBottom: CGFloat = 18
    }

    private enum Text {
        static let title = "就從加好友開始吧：）"
        static let subtitle = "與好友們一起用 KOKO 聊起來！\n還能互相收付款、發紅包喔：）"
        static let linkPrefix = "幫助好友更快找到你？"
        static let linkAction = "設定 KOKO ID"
    }

    private let illustration: UIImageView = {
        let imageView = UIImageView(image: AppImage.emptyStateIllustration.image)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textAlignment = .center
        label.attributedText = AppText.emptyStateTitle
            .attributedString(Text.title, alignment: .center)
        return label
    }()

    private let subtitleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.numberOfLines = 0
        label.textAlignment = .center
        label.attributedText = AppText.body
            .withColor(AppColor.textSecondary)
            .attributedString(Text.subtitle, alignment: .center)
        return label
    }()

    private let addFriendButton = GradientButton(title: "加好友", icon: .addFriend)

    private let linkLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textAlignment = .center
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = AppColor.surface

        linkLabel.attributedText = makeLinkText()

        addSubview(illustration)
        addSubview(titleLabel)
        addSubview(subtitleLabel)
        addSubview(addFriendButton)
        addSubview(linkLabel)

        NSLayoutConstraint.activate([
            illustration.topAnchor.constraint(equalTo: topAnchor, constant: Layout.illustrationTop),
            illustration.centerXAnchor.constraint(equalTo: centerXAnchor),
            illustration.widthAnchor.constraint(equalToConstant: Layout.illustrationWidth),
            illustration.heightAnchor.constraint(equalToConstant: Layout.illustrationHeight),

            titleLabel.topAnchor.constraint(
                equalTo: illustration.bottomAnchor, constant: Layout.titleTop
            ),
            titleLabel.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor),
            titleLabel.centerXAnchor.constraint(equalTo: centerXAnchor),

            subtitleLabel.topAnchor.constraint(
                equalTo: titleLabel.bottomAnchor, constant: Layout.subtitleTop
            ),
            subtitleLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            subtitleLabel.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor),
            subtitleLabel.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor),

            addFriendButton.topAnchor.constraint(
                equalTo: subtitleLabel.bottomAnchor, constant: Layout.buttonTop
            ),
            addFriendButton.centerXAnchor.constraint(equalTo: centerXAnchor),
            addFriendButton.widthAnchor.constraint(equalToConstant: Layout.buttonWidth),
            addFriendButton.heightAnchor.constraint(equalToConstant: Layout.buttonHeight),

            // 連結靠底，中間留白吸收不同機型的高度差。
            linkLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -Layout.linkBottom),
            linkLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
        ])

        // 設計稿畫布是 375×705，比 iPhone 8 的 667 高。矮機型上這段留白會被壓到 0，
        // 所以它不能是 required，否則會噴無解約束。
        let gapAboveLink = linkLabel.topAnchor.constraint(
            greaterThanOrEqualTo: addFriendButton.bottomAnchor, constant: Spacing.l
        )
        gapAboveLink.priority = .defaultHigh
        gapAboveLink.isActive = true
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("純程式碼建立，不支援 Storyboard／XIB")
    }

    /// 「幫助好友更快找到你？」灰字 +「設定 KOKO ID」粉紅加底線。
    private func makeLinkText() -> NSAttributedString {
        let text = NSMutableAttributedString(
            attributedString: AppText.body
                .withColor(AppColor.textSecondary)
                .attributedString(Text.linkPrefix, alignment: .center)
        )

        let action = NSMutableAttributedString(
            attributedString: AppText.body
                .withColor(AppColor.kokoPink)
                .attributedString(Text.linkAction, alignment: .center)
        )
        action.addAttribute(
            .underlineStyle,
            value: NSUnderlineStyle.single.rawValue,
            range: NSRange(location: 0, length: action.length)
        )

        text.append(action)
        return text
    }
}

// MARK: - 綠色漸層按鈕

/// design-spec §7.9：192×40 膠囊，**水平**漸層（左 `#56B30B` → 右 `#A6CC42`）、
/// 下方 `#79C41B` 40% 陰影，白色文字置中、白色圖示靠右。
///
/// 陰影與圓角必須分兩層：漸層那層要 `masksToBounds = true` 才會被圓角裁掉，
/// 但那會連陰影一起裁掉，所以陰影掛在外層。
private final class GradientButton: UIControl {

    private enum Layout {
        static let cornerRadius: CGFloat = 20
        static let iconSize: CGFloat = 24
        static let iconTrailing: CGFloat = 4.5
        static let shadowOffset = CGSize(width: 0, height: 4)
        static let shadowRadius: CGFloat = 5.5
    }

    private let gradientView: GradientView = {
        let view = GradientView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.isUserInteractionEnabled = false
        view.layer.cornerRadius = Layout.cornerRadius
        view.layer.masksToBounds = true
        return view
    }()

    init(title: String, icon: AppImage) {
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false

        layer.shadowColor = AppColor.greenShadow.cgColor
        layer.shadowOffset = Layout.shadowOffset
        layer.shadowRadius = Layout.shadowRadius
        layer.shadowOpacity = 1

        let titleLabel = UILabel()
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.attributedText = AppText.name
            .withColor(AppColor.surface)
            .attributedString(title, alignment: .center)

        // 素材是單一平塗色 + 透明，template 上白色不會有副作用。
        let iconView = UIImageView(image: icon.image.withRenderingMode(.alwaysTemplate))
        iconView.translatesAutoresizingMaskIntoConstraints = false
        iconView.tintColor = AppColor.surface
        iconView.contentMode = .scaleAspectFit

        addSubview(gradientView)
        addSubview(titleLabel)
        addSubview(iconView)

        NSLayoutConstraint.activate([
            gradientView.topAnchor.constraint(equalTo: topAnchor),
            gradientView.bottomAnchor.constraint(equalTo: bottomAnchor),
            gradientView.leadingAnchor.constraint(equalTo: leadingAnchor),
            gradientView.trailingAnchor.constraint(equalTo: trailingAnchor),

            // 文字對齊按鈕正中，圖示另外靠右 —— 設計稿上兩者不是並排的一組。
            titleLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: centerYAnchor),

            iconView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -Layout.iconTrailing),
            iconView.centerYAnchor.constraint(equalTo: centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: Layout.iconSize),
            iconView.heightAnchor.constraint(equalToConstant: Layout.iconSize),
        ])

        isAccessibilityElement = true
        accessibilityLabel = title
        accessibilityTraits = .button
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("純程式碼建立，不支援 Storyboard／XIB")
    }

    override var isHighlighted: Bool {
        didSet { alpha = isHighlighted ? 0.8 : 1 }
    }
}

/// 用 `layerClass` 換掉 backing layer，就不必在 `layoutSubviews` 手動同步 frame。
private final class GradientView: UIView {

    override class var layerClass: AnyClass { CAGradientLayer.self }

    override init(frame: CGRect) {
        super.init(frame: frame)

        guard let gradient = layer as? CAGradientLayer else { return }
        gradient.colors = [AppColor.greenDark.cgColor, AppColor.greenLight.cgColor]
        // 水平：實測 y 方向幾乎不變，x 方向從 #58B30C 走到 #A1CB3E。
        gradient.startPoint = CGPoint(x: 0, y: 0.5)
        gradient.endPoint = CGPoint(x: 1, y: 0.5)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("純程式碼建立，不支援 Storyboard／XIB")
    }
}
