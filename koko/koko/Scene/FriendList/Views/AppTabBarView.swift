//
//  AppTabBarView.swift
//  koko
//
//  design-spec §4.7：錢錢／朋友／KO（中央凸起）／記帳／設定。
//
//  可切換。「朋友」以外的分頁內容為空白畫面（spec.md §11）。
//
//  ⚠️ 每個分頁素材都是 **icon + 分頁名稱文字的合成圖**（78×128），文字已烘焙在圖裡，
//  因此這裡不另外放 UILabel（放了會變成兩份文字），寬高也必須依 78:128 比例給。
//
//  ⚠️ 素材只有「朋友」有選中態（粉紅），其餘四個只有未選中態（灰），
//  故一律以 template rendering 上色 —— 選中粉紅、未選中灰。
//  合成圖的 icon 與文字同色，tint 後兩者一起變色，與設計稿的選中樣式一致。
//
//  中央 KO 按鈕直接用 `AppImage.tabCenterKOOff` —— 設計稿上它就是淺灰圓形
//  （底 `#F5F5F5`、KO 字 `#999999`），不是粉紅。它不是分頁，不可點。
//
//  尺寸依 design-spec.md §7.8。
//

import UIKit

final class AppTabBarView: UIView {

    enum Tab: Int, CaseIterable {
        case money
        case friends
        /// 中央凸起的 KO 按鈕。它也是一個分頁（2026-08-12 需求變更）。
        case ko
        case accounting
        case settings

        /// 四個一般分頁。`ko` 的呈現方式與它們不同（原色素材、不加 tint），
        /// 凡是「對每個分頁圖示做同一件事」的地方都該用這個而不是 `allCases`。
        static var standardTabs: [Tab] { allCases.filter { $0 != .ko } }

        var title: String {
            switch self {
            case .money: return "錢錢"
            case .friends: return "朋友"
            case .ko: return "KO"
            case .accounting: return "記帳"
            case .settings: return "設定"
            }
        }

        /// 素材已內含分頁名稱文字，`title` 只用於 accessibility。
        var image: AppImage {
            switch self {
            case .money: return .tabMoney
            case .friends: return .tabFriends
            case .ko: return .tabCenterKOOff
            case .accounting: return .tabAccounting
            case .settings: return .tabSettings
            }
        }
    }

    /// 全部取自 design-spec.md §7.8。
    private enum Layout {
        static let height: CGFloat = 55
        /// 合成圖（icon + 文字）的高度。寬度由素材的 78:128 比例推導，不另外指定。
        static let itemHeight: CGFloat = 42
        /// KO 素材的**整張**高度。素材不只有圓，還含 TabBar 上緣的凹口造型，
        /// 圓只佔寬度的 57.6% —— 直接把 imageView 設成 50×50 圓會縮成 29pt。
        /// 反推：圓要 50 → 素材寬 86.8 → 高 86.8 / 1.2503 = 69.4。
        static let koImageHeight: CGFloat = 69.4
        static let koImageAspectRatio: CGFloat = 1.2503
        static let topBorderHeight: CGFloat = 1
    }

    var onSelect: ((Tab) -> Void)?

    private(set) var selectedTab: Tab = .friends

    private var itemViews: [Tab: TabItemView] = [:]

    private lazy var koButton: UIImageView = makeKOButton()

    private let koOffImage = AppImage.tabCenterKOOff.image

    /// Zeplin 沒有 KO 的選中版素材，就地把 KO 字從灰換成粉紅。
    /// 只做一次，`applySelection()` 每次切換都會用到。詳見 `UIImage+Recolor.swift`。
    private lazy var koOnImage = koOffImage.replacingColor(
        AppColor.textSecondary,
        with: AppColor.kokoPink
    )

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = AppColor.surface

        let topBorder = UIView()
        topBorder.translatesAutoresizingMaskIntoConstraints = false
        topBorder.backgroundColor = AppColor.sectionDivider
        addSubview(topBorder)

        // 中央那一格留空，位置讓給凸起的 KO 按鈕（它不在 stack 裡）。
        var slots: [UIView] = []
        for tab in Tab.allCases {
            guard tab != .ko else {
                slots.append(UIView())
                continue
            }
            let item = TabItemView(tab: tab, itemHeight: Layout.itemHeight)
            item.addTarget(self, action: #selector(itemTapped(_:)), for: .touchUpInside)
            itemViews[tab] = item
            slots.append(item)
        }

        let row = UIStackView(arrangedSubviews: slots)
        row.translatesAutoresizingMaskIntoConstraints = false
        row.axis = .horizontal
        row.distribution = .fillEqually
        row.alignment = .fill
        addSubview(row)

        addSubview(koButton)

        NSLayoutConstraint.activate([
            topBorder.leadingAnchor.constraint(equalTo: leadingAnchor),
            topBorder.trailingAnchor.constraint(equalTo: trailingAnchor),
            topBorder.topAnchor.constraint(equalTo: topAnchor),
            topBorder.heightAnchor.constraint(equalToConstant: Layout.topBorderHeight),

            // 整個 TabBar 延伸到螢幕最底（底色蓋掉 home indicator 區），
            // 但圖示那一列停在 safe area 上緣 —— 否則圖示會被 home indicator 壓到。
            row.leadingAnchor.constraint(equalTo: leadingAnchor),
            row.trailingAnchor.constraint(equalTo: trailingAnchor),
            row.topAnchor.constraint(equalTo: topAnchor),
            row.heightAnchor.constraint(equalToConstant: Layout.height),
            row.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor),

            // 素材下緣切齊圖示列下緣，其餘往上凸出 —— 設計稿即是如此。
            koButton.centerXAnchor.constraint(equalTo: centerXAnchor),
            koButton.bottomAnchor.constraint(equalTo: row.bottomAnchor),
            koButton.heightAnchor.constraint(equalToConstant: Layout.koImageHeight),
            koButton.widthAnchor.constraint(
                equalTo: koButton.heightAnchor, multiplier: Layout.koImageAspectRatio
            ),
        ])

        applySelection()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("純程式碼建立，不支援 Storyboard／XIB")
    }

    /// KO 按鈕比 TabBar 高，凸出去的那截落在 bounds 之外，預設收不到觸控。
    /// 把它的 frame 一併算進來，整顆圓都可點。
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        super.point(inside: point, with: event) || koButton.frame.contains(point)
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
        koButton.image = selectedTab == .ko ? koOnImage : koOffImage
    }

    @objc private func itemTapped(_ sender: TabItemView) {
        select(sender.tab)
        onSelect?(sender.tab)
    }

    @objc private func koTapped() {
        select(.ko)
        onSelect?(.ko)
    }

    /// 設計稿的 KO 是淺灰圓形，用素材原色（**不可** template，會被壓成實心色塊）。
    /// 選中時換成 `koOnImage`（KO 字轉粉紅），由 `applySelection()` 切換。
    private func makeKOButton() -> UIImageView {
        let imageView = UIImageView(image: koOffImage)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        imageView.isUserInteractionEnabled = true
        imageView.isAccessibilityElement = true
        imageView.accessibilityLabel = Tab.ko.title
        imageView.accessibilityTraits = .button
        imageView.addGestureRecognizer(
            UITapGestureRecognizer(target: self, action: #selector(koTapped))
        )
        return imageView
    }
}

// MARK: - Item

private final class TabItemView: UIControl {

    let tab: AppTabBarView.Tab

    private let imageView = UIImageView()

    init(tab: AppTabBarView.Tab, itemHeight: CGFloat) {
        self.tab = tab
        super.init(frame: .zero)

        // 素材缺少 On／Off 兩種狀態，改以 template + tintColor 表現選中與否。
        let image = tab.image.image
        imageView.image = image.withRenderingMode(.alwaysTemplate)
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.isUserInteractionEnabled = false
        addSubview(imageView)

        // 素材已內含分頁名稱文字，這裡不能再放 UILabel。寬度依素材比例推導，
        // 寫死成正方形會把合成圖壓扁。
        let aspectRatio = image.size.height > 0 ? image.size.width / image.size.height : 1

        NSLayoutConstraint.activate([
            imageView.centerXAnchor.constraint(equalTo: centerXAnchor),
            imageView.centerYAnchor.constraint(equalTo: centerYAnchor),
            imageView.heightAnchor.constraint(equalToConstant: itemHeight),
            imageView.widthAnchor.constraint(
                equalTo: imageView.heightAnchor,
                multiplier: aspectRatio
            ),
        ])

        isAccessibilityElement = true
        accessibilityLabel = tab.title
        accessibilityTraits = .button
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("純程式碼建立，不支援 Storyboard／XIB")
    }

    func setSelected(_ isSelected: Bool) {
        imageView.tintColor = isSelected ? AppColor.kokoPink : AppColor.textSecondary
        accessibilityTraits = isSelected ? [.button, .selected] : .button
    }
}
