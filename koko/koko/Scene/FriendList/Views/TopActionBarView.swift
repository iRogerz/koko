//
//  TopActionBarView.swift
//  koko
//
//  設計稿最上方那一列功能圖示：ATM／換匯（轉帳）在左、掃描在右。
//  三張稿都有這一列，對應 Zeplin 的 `icNavPink*` 三個素材。
//
//  設計稿**沒有 navigation bar 也沒有返回鍵**，好友列表頁是分頁的根畫面，
//  這一列就是它的頂部。返回改用邊緣滑動（見 `FriendListViewController`）。
//
//  尺寸依 design-spec.md §7.2。
//

import UIKit

final class TopActionBarView: UIView {

    private enum Layout {
        static let iconSize: CGFloat = 24
        static let scanSize: CGFloat = 21
        static let iconSpacing: CGFloat = 24
        static let verticalPadding: CGFloat = 11
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = AppColor.cardBackground
        directionalLayoutMargins = .init(
            top: 0, leading: Spacing.navMargin, bottom: 0, trailing: Spacing.navMargin
        )

        let atm = makeButton(.navWithdraw, accessibilityLabel: "ATM")
        let transfer = makeButton(.navTransfer, accessibilityLabel: "轉帳")
        let scan = makeButton(.navScan, accessibilityLabel: "掃描")

        addSubview(atm)
        addSubview(transfer)
        addSubview(scan)

        NSLayoutConstraint.activate([
            atm.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor),
            atm.topAnchor.constraint(equalTo: topAnchor, constant: Layout.verticalPadding),
            atm.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -Layout.verticalPadding),
            atm.widthAnchor.constraint(equalToConstant: Layout.iconSize),
            atm.heightAnchor.constraint(equalToConstant: Layout.iconSize),

            transfer.leadingAnchor.constraint(
                equalTo: atm.trailingAnchor, constant: Layout.iconSpacing
            ),
            transfer.centerYAnchor.constraint(equalTo: atm.centerYAnchor),
            transfer.widthAnchor.constraint(equalToConstant: Layout.iconSize),
            transfer.heightAnchor.constraint(equalToConstant: Layout.iconSize),

            scan.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor),
            scan.centerYAnchor.constraint(equalTo: atm.centerYAnchor),
            scan.widthAnchor.constraint(equalToConstant: Layout.scanSize),
            scan.heightAnchor.constraint(equalToConstant: Layout.scanSize),
        ])
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("純程式碼建立，不支援 Storyboard／XIB")
    }

    /// 素材本身已是粉紅，用原色。三個按鈕都不接行為（spec.md §11 Out of Scope）。
    private func makeButton(_ image: AppImage, accessibilityLabel: String) -> UIImageView {
        let imageView = UIImageView(image: image.image.withRenderingMode(.alwaysOriginal))
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        imageView.isAccessibilityElement = true
        imageView.accessibilityLabel = accessibilityLabel
        imageView.accessibilityTraits = .button
        return imageView
    }
}
