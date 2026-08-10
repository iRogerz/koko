//
//  BadgeLabel.swift
//  koko
//
//  design-spec §4.2：圓角膠囊，底 `#F9B2DC`、字 `#EC008C`。
//  聊天固定 `99+`；好友為邀請卡片數，**0 時隱藏**（spec.md §6.3）。
//

import UIKit

final class BadgeLabel: UIView {

    private enum Layout {
        static let height: CGFloat = 18
        static let minimumWidth: CGFloat = 18
        static let horizontalPadding: CGFloat = 5
    }

    private let label = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)

        backgroundColor = AppColor.kokoPinkLight
        layer.cornerRadius = Layout.height / 2
        layer.masksToBounds = true

        label.translatesAutoresizingMaskIntoConstraints = false
        label.textAlignment = .center
        addSubview(label)

        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalToConstant: Layout.height),
            widthAnchor.constraint(greaterThanOrEqualToConstant: Layout.minimumWidth),
            label.centerYAnchor.constraint(equalTo: centerYAnchor),
            label.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Layout.horizontalPadding),
            label.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -Layout.horizontalPadding),
        ])
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("純程式碼建立，不支援 Storyboard／XIB")
    }

    /// 直接指定文字（聊天 tab 的固定 `99+`）。
    func setText(_ text: String) {
        label.attributedText = AppText.caption
            .withColor(AppColor.kokoPink)
            .attributedString(text, alignment: .center)
        isHidden = false
    }

    /// 依數量顯示；**0 時整個 badge 隱藏**。
    func setCount(_ count: Int) {
        guard count > 0 else {
            isHidden = true
            return
        }
        setText("\(count)")
    }
}
