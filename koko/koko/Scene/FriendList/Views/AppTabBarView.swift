//
//  AppTabBarView.swift
//  koko
//
//  design-spec §4.7：錢錢／朋友／KO（中央凸起）／記帳／設定。
//
//  可切換。「朋友」以外的分頁內容為空白畫面（spec.md §11）。
//
//  ⚠️ 素材只有 `icTabbarFriendsOn`（粉紅）與其餘四個 `Off`（灰），
//  缺少各分頁的 On／Off 兩種狀態，故一律以 template rendering 上色 ——
//  選中粉紅、未選中灰。代價是圖示原本烘焙的顏色會被 tint 取代。
//
//  ⚠️ 中央 KO 按鈕的素材 Zeplin 未匯出，以粉紅圓形 + 文字繪製近似。
//

import UIKit

final class AppTabBarView: UIView {

    enum Tab: Int, CaseIterable {
        case money
        case friends
        case accounting
        case settings

        var title: String {
            switch self {
            case .money: return "錢錢"
            case .friends: return "朋友"
            case .accounting: return "記帳"
            case .settings: return "設定"
            }
        }

        var image: AppImage {
            switch self {
            case .money: return .tabHome
            case .friends: return .tabFriendsSelected
            case .accounting: return .tabAccounting
            case .settings: return .tabSettings
            }
        }
    }

    private enum Layout {
        static let height: CGFloat = 56
        static let iconSize: CGFloat = 24
        static let koSize: CGFloat = 52
        static let koRaise: CGFloat = 12
        static let topBorderHeight: CGFloat = 1
    }

    var onSelect: ((Tab) -> Void)?

    private(set) var selectedTab: Tab = .friends

    private var itemViews: [Tab: TabItemView] = [:]

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = AppColor.surface

        let topBorder = UIView()
        topBorder.translatesAutoresizingMaskIntoConstraints = false
        topBorder.backgroundColor = AppColor.separator
        addSubview(topBorder)

        // 中央留一格空位給凸起的 KO 按鈕（design-spec §4.7 的第三格）。
        var slots: [UIView] = []
        for tab in Tab.allCases {
            let item = TabItemView(tab: tab)
            item.addTarget(self, action: #selector(itemTapped(_:)), for: .touchUpInside)
            itemViews[tab] = item
            slots.append(item)

            if tab == .friends {
                slots.append(UIView())
            }
        }

        let row = UIStackView(arrangedSubviews: slots)
        row.translatesAutoresizingMaskIntoConstraints = false
        row.axis = .horizontal
        row.distribution = .fillEqually
        row.alignment = .fill
        addSubview(row)

        let koButton = makeKOButton()
        addSubview(koButton)

        NSLayoutConstraint.activate([
            topBorder.leadingAnchor.constraint(equalTo: leadingAnchor),
            topBorder.trailingAnchor.constraint(equalTo: trailingAnchor),
            topBorder.topAnchor.constraint(equalTo: topAnchor),
            topBorder.heightAnchor.constraint(equalToConstant: Layout.topBorderHeight),

            row.leadingAnchor.constraint(equalTo: leadingAnchor),
            row.trailingAnchor.constraint(equalTo: trailingAnchor),
            row.topAnchor.constraint(equalTo: topAnchor),
            row.heightAnchor.constraint(equalToConstant: Layout.height),
            row.bottomAnchor.constraint(equalTo: bottomAnchor),

            koButton.centerXAnchor.constraint(equalTo: centerXAnchor),
            koButton.centerYAnchor.constraint(equalTo: topAnchor, constant: Layout.height / 2 - Layout.koRaise),
            koButton.widthAnchor.constraint(equalToConstant: Layout.koSize),
            koButton.heightAnchor.constraint(equalToConstant: Layout.koSize),
        ])

        applySelection()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("純程式碼建立，不支援 Storyboard／XIB")
    }

    func select(_ tab: Tab) {
        guard tab != selectedTab else { return }
        selectedTab = tab
        applySelection()
    }

    private func applySelection() {
        for (tab, item) in itemViews {
            item.setSelected(tab == selectedTab)
        }
    }

    @objc private func itemTapped(_ sender: TabItemView) {
        select(sender.tab)
        onSelect?(sender.tab)
    }

    /// Zeplin 未匯出此素材，以粉紅圓形 + 「KO」文字近似。不可點。
    private func makeKOButton() -> UIView {
        let button = UIView()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.backgroundColor = AppColor.kokoPink
        button.layer.cornerRadius = Layout.koSize / 2
        button.layer.borderColor = AppColor.surface.cgColor
        button.layer.borderWidth = 3
        button.isUserInteractionEnabled = false

        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.attributedText = AppText.name
            .withColor(AppColor.surface)
            .attributedString("KO", alignment: .center)
        label.textAlignment = .center
        button.addSubview(label)

        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: button.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: button.centerYAnchor),
        ])
        return button
    }
}

// MARK: - Item

private final class TabItemView: UIControl {

    let tab: AppTabBarView.Tab

    private let imageView = UIImageView()
    private let label = UILabel()

    init(tab: AppTabBarView.Tab) {
        self.tab = tab
        super.init(frame: .zero)

        // 素材缺少 On／Off 兩種狀態，改以 template + tintColor 表現選中與否。
        imageView.image = tab.image.image.withRenderingMode(.alwaysTemplate)
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        label.textAlignment = .center

        let column = UIStackView(arrangedSubviews: [imageView, label])
        column.translatesAutoresizingMaskIntoConstraints = false
        column.axis = .vertical
        column.alignment = .center
        column.spacing = 4
        column.isUserInteractionEnabled = false
        addSubview(column)

        NSLayoutConstraint.activate([
            column.centerXAnchor.constraint(equalTo: centerXAnchor),
            column.centerYAnchor.constraint(equalTo: centerYAnchor),
            imageView.widthAnchor.constraint(equalToConstant: 24),
            imageView.heightAnchor.constraint(equalToConstant: 24),
        ])
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("純程式碼建立，不支援 Storyboard／XIB")
    }

    func setSelected(_ isSelected: Bool) {
        let color = isSelected ? AppColor.kokoPink : AppColor.textSecondary
        imageView.tintColor = color
        label.attributedText = AppText.caption
            .withColor(color)
            .attributedString(tab.title, alignment: .center)
    }
}
